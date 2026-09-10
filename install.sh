#!/usr/bin/env bash
# atekvid installer — sets up dependencies, the app, and a menu entry on any
# mainstream Linux distribution. Safe to re-run; use --update to upgrade.
#
#   curl -fsSL https://raw.githubusercontent.com/MBrassey/atekvid/main/install.sh | bash
#   ./install.sh                # from a checkout or an extracted release tarball
#   ./install.sh --update       # fetch the latest release (or source) and reinstall
#   ./install.sh --uninstall    # remove the app (keeps your identity and settings)
#
# Binaries come from the public releases at github.com/MBrassey/atekvid; building
# from source needs the GitHub CLI signed in to an account that can read the
# private source repository.
set -euo pipefail

RELEASES_REPO="MBrassey/atekvid"
REPO="MBrassey/atekvid.io"
APP="atekvid"
PREFIX="${ATEKVID_PREFIX:-$HOME/.local}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/atekvid"
SRC_DIR="$DATA_DIR/src"
MODE="auto"          # auto | prebuilt | source
ASSUME_YES=0
NO_DESKTOP=0
NO_PACKAGES=0
REGISTER_KEY=0
DO_UNINSTALL=0
DO_UPDATE=0
MIN_RUST="1.85"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  cat <<USAGE

Options:
  --prebuilt        only use a released binary (fails if none fits this machine)
  --source          always build from source
  --prefix DIR      install under DIR/bin (default: ~/.local)
  --no-desktop      skip the application-menu entry
  --no-packages     do not install system packages (they are already present)
  --register-key    register this device's key on GitHub without asking
  --update          update an existing installation
  --uninstall       remove the installed files
  -y, --yes         answer yes to every question
  -h, --help        this text
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prebuilt) MODE=prebuilt ;;
    --source) MODE=source ;;
    --prefix) PREFIX="$2"; shift ;;
    --prefix=*) PREFIX="${1#*=}" ;;
    --no-desktop) NO_DESKTOP=1 ;;
    --no-packages) NO_PACKAGES=1 ;;
    --register-key) REGISTER_KEY=1 ;;
    --update) DO_UPDATE=1 ;;
    --uninstall) DO_UNINSTALL=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'; C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
  C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_RESET=""
fi
info() { printf '%s==>%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
ok()   { printf '%s ✓ %s %s\n' "$C_OK" "$C_RESET" "$*"; }
warn() { printf '%s ! %s %s\n' "$C_WARN" "$C_RESET" "$*"; }
die()  { printf '%s ✗ %s %s\n' "$C_ERR" "$C_RESET" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Questions are read from the terminal even when the script itself is piped in.
# Without a usable terminal the answer is always "no" (except under -y).
confirm() {
  local prompt="$1" default="${2:-y}" ans
  if [ "$ASSUME_YES" = 1 ]; then return 0; fi
  if [ "$default" = y ]; then prompt="$prompt [Y/n] "; else prompt="$prompt [y/N] "; fi
  { printf '%s' "$prompt" > /dev/tty; } 2>/dev/null || return 1
  read -r ans < /dev/tty 2>/dev/null || return 1
  ans="${ans:-$default}"
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

has_tty() { { : < /dev/tty; } 2>/dev/null; }

as_root() {
  if [ "$(id -u)" = 0 ]; then "$@"
  elif have sudo; then sudo "$@"
  elif have doas; then doas "$@"
  else die "need root to install packages; run as root or install sudo"; fi
}

# ---------------------------------------------------------------------------
# Distribution detection
# ---------------------------------------------------------------------------
PM=""
for candidate in pacman apt-get dnf zypper apk xbps-install; do
  if have "$candidate"; then PM="$candidate"; break; fi
done

pkg_install() {
  case "$PM" in
    pacman) as_root pacman -S --needed --noconfirm "$@" ;;
    apt-get) as_root apt-get update -qq && as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
    dnf) as_root dnf install -y "$@" ;;
    zypper) as_root zypper --non-interactive install "$@" ;;
    apk) as_root apk add "$@" ;;
    xbps-install) as_root xbps-install -Sy "$@" ;;
    *) return 1 ;;
  esac
}

runtime_pkgs() {
  case "$PM" in
    pacman) echo "libpulse opus libxkbcommon mesa" ;;
    apt-get) echo "libpulse0 libopus0 libxkbcommon0 libgl1" ;;
    dnf) echo "pulseaudio-libs opus libxkbcommon mesa-libGL" ;;
    zypper) echo "libpulse0 libopus0 libxkbcommon0 Mesa-libGL1" ;;
    apk) echo "pulseaudio-libs opus libxkbcommon mesa-gl" ;;
    xbps-install) echo "pulseaudio opus libxkbcommon MesaLib" ;;
  esac
}

build_pkgs() {
  case "$PM" in
    pacman) echo "base-devel cmake pkgconf libpulse opus nasm git curl" ;;
    apt-get) echo "build-essential cmake pkg-config libpulse-dev libopus-dev nasm git curl ca-certificates" ;;
    dnf) echo "gcc gcc-c++ make cmake pkgconf-pkg-config pulseaudio-libs-devel opus-devel nasm git curl" ;;
    zypper) echo "gcc gcc-c++ make cmake pkgconf-pkg-config libpulse-devel libopus-devel nasm git curl" ;;
    apk) echo "build-base cmake pkgconf pulseaudio-dev opus-dev nasm git curl" ;;
    xbps-install) echo "base-devel cmake pkg-config pulseaudio-devel opus-devel nasm git curl" ;;
  esac
}

gh_pkg() {
  case "$PM" in
    pacman|apk|xbps-install) echo "github-cli" ;;
    *) echo "gh" ;;
  esac
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
if [ "$DO_UNINSTALL" = 1 ]; then
  info "Removing $APP"
  rm -f "$PREFIX/bin/$APP" && ok "removed $PREFIX/bin/$APP"
  rm -f "$HOME/.local/share/applications/$APP.desktop" "$HOME/.local/share/icons/hicolor/256x256/apps/$APP.png"
  have update-desktop-database && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  if [ -d "$SRC_DIR" ] && confirm "Delete the downloaded source in $SRC_DIR?" n; then rm -rf "$SRC_DIR"; fi
  warn "Your identity key and settings in ~/.config/atekvid were kept (delete them by hand to unlink this device)."
  exit 0
fi

# ---------------------------------------------------------------------------
# Locate the source (a checkout next to this script, or clone it)
# ---------------------------------------------------------------------------
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
CHECKOUT=""
if [ -n "$SCRIPT_DIR" ] && grep -q '^name = "atekvid"' "$SCRIPT_DIR/Cargo.toml" 2>/dev/null; then
  CHECKOUT="$SCRIPT_DIR"
fi
# A release tarball ships this script next to a prebuilt binary.
TARBALL_BIN=""
if [ -n "$SCRIPT_DIR" ] && [ -x "$SCRIPT_DIR/$APP" ] && [ -z "$CHECKOUT" ]; then
  TARBALL_BIN="$SCRIPT_DIR/$APP"
fi

ensure_gh() {
  if ! have gh; then
    info "The GitHub CLI is needed to fetch the private repository"
    if [ -n "$PM" ] && confirm "Install the GitHub CLI ($(gh_pkg)) with $PM?"; then
      pkg_install "$(gh_pkg)" || die "could not install the GitHub CLI; see https://cli.github.com"
    else
      die "install the GitHub CLI (https://cli.github.com) and run: gh auth login"
    fi
  fi
  if ! gh auth status >/dev/null 2>&1; then
    info "Signing in to GitHub (a browser window will open)"
    [ -r /dev/tty ] || die "run 'gh auth login' first, then re-run this installer"
    gh auth login -h github.com -p https -w < /dev/tty > /dev/tty 2>&1 || die "GitHub sign-in did not complete"
  fi
  ok "GitHub CLI signed in as $(gh api user --jq .login 2>/dev/null || echo '?')"
}

clone_or_update_source() {
  ensure_gh
  if [ -d "$SRC_DIR/.git" ]; then
    info "Updating source in $SRC_DIR"
    git -C "$SRC_DIR" pull --ff-only -q || warn "could not fast-forward; keeping the current checkout"
  else
    info "Cloning $REPO into $SRC_DIR"
    mkdir -p "$(dirname "$SRC_DIR")"
    gh repo clone "$REPO" "$SRC_DIR" -- -q || die "clone failed (is your account allowed to read $REPO?)"
  fi
  CHECKOUT="$SRC_DIR"
}

# ---------------------------------------------------------------------------
# Toolchain
# ---------------------------------------------------------------------------
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

ensure_rust() {
  local ver=""
  if have cargo; then ver="$(cargo --version 2>/dev/null | awk '{print $2}')"; fi
  if [ -n "$ver" ] && version_ge "$ver" "$MIN_RUST"; then ok "Rust $ver"; return; fi
  if [ -x "$HOME/.cargo/bin/cargo" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    ver="$(cargo --version | awk '{print $2}')"
    if version_ge "$ver" "$MIN_RUST"; then ok "Rust $ver (from ~/.cargo)"; return; fi
    info "Updating the Rust toolchain"; rustup update stable -q && return
  fi
  if [ -n "$ver" ]; then info "Rust $ver is older than $MIN_RUST; installing a current toolchain with rustup (does not touch the system one)"
  else info "Installing Rust with rustup"; fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path >/dev/null
  export PATH="$HOME/.cargo/bin:$PATH"
  ok "Rust $(cargo --version | awk '{print $2}')"
}

pkg_installed() {
  case "$PM" in
    pacman) pacman -Qq "$1" >/dev/null 2>&1 ;;
    apt-get) dpkg-query -W -f '${Status}' "$1" 2>/dev/null | grep -q "install ok installed" ;;
    dnf|zypper) rpm -q "$1" >/dev/null 2>&1 ;;
    apk) apk info -e "$1" >/dev/null 2>&1 ;;
    xbps-install) xbps-query "$1" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

# Install only what is missing, so re-runs and updates rarely need sudo at all.
ensure_packages() {
  local pkgs="$1" missing="" p
  [ "$NO_PACKAGES" = 1 ] && return
  [ -n "$PM" ] || { warn "Unknown package manager; make sure these are installed: $pkgs"; return; }
  for p in $pkgs; do
    # Meta packages (base-devel, build-essential) are groups on some systems; probe their members loosely.
    if ! pkg_installed "$p"; then missing="$missing $p"; fi
  done
  missing="${missing# }"
  if [ -z "$missing" ]; then ok "System packages already present"; return; fi
  info "Installing system packages with $PM: $missing"
  if ! has_tty && [ "$(id -u)" != 0 ]; then
    warn "No terminal to ask for a password; skipping package installation for: $missing"
    warn "If the app fails to start, install them by hand with $PM."
    return
  fi
  # shellcheck disable=SC2086
  pkg_install $missing || die "package installation failed"
}

# ---------------------------------------------------------------------------
# Install steps
# ---------------------------------------------------------------------------
install_binary() {
  local src="$1"
  mkdir -p "$PREFIX/bin"
  install -m 755 "$src" "$PREFIX/bin/$APP"
  have strip && strip --strip-debug "$PREFIX/bin/$APP" 2>/dev/null || true
  ok "Installed $PREFIX/bin/$APP ($("$PREFIX/bin/$APP" --version 2>/dev/null | awk '{print $2}'))"
}

# Keep a copy of this script so `atekvid update` can find it later.
save_self() {
  local src=""
  mkdir -p "$DATA_DIR"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/install.sh" ]; then src="$SCRIPT_DIR/install.sh"
  elif [ -f "$SRC_DIR/install.sh" ]; then src="$SRC_DIR/install.sh"
  else return 0; fi
  # Running from the saved copy itself: nothing to do.
  if [ -e "$DATA_DIR/install.sh" ] && [ "$src" -ef "$DATA_DIR/install.sh" ]; then return 0; fi
  cp "$src" "$DATA_DIR/install.sh"
  chmod +x "$DATA_DIR/install.sh"
}

install_desktop_entry() {
  [ "$NO_DESKTOP" = 1 ] && return
  local apps="$HOME/.local/share/applications" icons="$HOME/.local/share/icons/hicolor/256x256/apps"
  mkdir -p "$apps" "$icons"
  "$PREFIX/bin/$APP" export-icon "$icons/$APP.png" >/dev/null 2>&1 || true
  cat > "$apps/$APP.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=atekvid
GenericName=Video chat
Comment=Private, end-to-end encrypted video chat
Exec=$PREFIX/bin/$APP
Icon=$APP
Terminal=false
Categories=Network;VideoConference;AudioVideo;
Keywords=video;call;chat;family;
StartupWMClass=atekvid
DESKTOP
  have update-desktop-database && update-desktop-database "$apps" 2>/dev/null || true
  have gtk-update-icon-cache && gtk-update-icon-cache -q -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  ok "Added atekvid to the application menu"
}

ASSET="atekvid-x86_64-unknown-linux-gnu.tar.gz"

try_prebuilt() {
  local arch tmp base
  arch="$(uname -m)"
  [ "$arch" = "x86_64" ] || { warn "No prebuilt binary for $arch"; return 1; }
  if [ -n "$TARBALL_BIN" ]; then
    if "$TARBALL_BIN" --version >/dev/null 2>&1; then install_binary "$TARBALL_BIN"; return 0; fi
    warn "The bundled binary does not run on this system (older glibc?)"; return 1
  fi
  have curl || { warn "curl is needed to download releases"; return 1; }
  tmp="$(mktemp -d)"
  base="https://github.com/$RELEASES_REPO/releases/latest/download"
  info "Downloading the latest release from github.com/$RELEASES_REPO"
  if ! curl -fsSL --retry 3 -o "$tmp/$ASSET" "$base/$ASSET" || ! curl -fsSL --retry 3 -o "$tmp/$ASSET.sha256" "$base/$ASSET.sha256"; then
    warn "No released build could be downloaded"; rm -rf "$tmp"; return 1
  fi
  # Verify the checksum published with the release before trusting the archive.
  if ! (cd "$tmp" && sha256sum -c --quiet "$ASSET.sha256" >/dev/null 2>&1); then
    warn "Checksum mismatch on the downloaded release; not installing it"; rm -rf "$tmp"; return 1
  fi
  ok "Release checksum verified"
  tar -xzf "$tmp/$ASSET" -C "$tmp"
  local bin
  bin="$(find "$tmp" -type f -name "$APP" | head -n1)"
  if [ -z "$bin" ] || ! "$bin" --version >/dev/null 2>&1; then
    warn "The released binary does not run here; building from source instead"; rm -rf "$tmp"; return 1
  fi
  install_binary "$bin"
  rm -rf "$tmp"
  return 0
}

build_from_source() {
  ensure_packages "$(build_pkgs)"
  ensure_rust
  [ -n "$CHECKOUT" ] || clone_or_update_source
  info "Building $APP in release mode (a few minutes the first time)"
  (cd "$CHECKOUT" && cargo build --release --quiet)
  install_binary "$CHECKOUT/target/release/$APP"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
info "atekvid installer"
[ "$(uname -s)" = Linux ] || die "this installer is for Linux"
[ -n "$PM" ] && ok "Package manager: $PM" || warn "No known package manager found"

if [ "$DO_UPDATE" = 1 ]; then
  if [ "$MODE" != prebuilt ] && [ -d "$SRC_DIR/.git" ]; then clone_or_update_source; fi
fi

ensure_packages "$(runtime_pkgs)"

installed=0
if [ "$MODE" != source ]; then
  if try_prebuilt; then installed=1; elif [ "$MODE" = prebuilt ]; then die "no usable prebuilt binary"; fi
fi
if [ "$installed" = 0 ]; then
  if [ "$MODE" = auto ]; then info "Falling back to a source build (needs access to the private repository)"; fi
  build_from_source
fi
install_desktop_entry
save_self

case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *)
    warn "$PREFIX/bin is not on your PATH."
    # Shell start-up files are only touched for the default prefix, and only when
    # you say so at the prompt (never with -y alone).
    if [ "$PREFIX" = "$HOME/.local" ] && [ "$ASSUME_YES" = 0 ]; then
      line="export PATH=\"$PREFIX/bin:\$PATH\""
      for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc" ] && ! grep -qF "$PREFIX/bin" "$rc" && confirm "Add it to $rc?"; then
          printf '\n# atekvid\n%s\n' "$line" >> "$rc"; ok "updated $rc (open a new terminal)"
        fi
      done
      if [ -d "$HOME/.config/fish" ] && confirm "Add it for fish too?"; then
        mkdir -p "$HOME/.config/fish/conf.d"; printf 'fish_add_path -g %s/bin\n' "$PREFIX" > "$HOME/.config/fish/conf.d/atekvid.fish"; ok "updated fish"
      fi
    else
      warn "Add it yourself, e.g.:  export PATH=\"$PREFIX/bin:\$PATH\""
    fi
    ;;
esac

info "Checking the environment"
"$PREFIX/bin/$APP" doctor 2>/dev/null | sed 's/^/   /' || true

# Registering the key changes your GitHub account, so -y alone never does it:
# it needs --register-key or an explicit answer at the prompt.
if have gh && gh auth status >/dev/null 2>&1; then
  if ! "$PREFIX/bin/$APP" identity 2>/dev/null | grep -q "Linked to   : github.com/"; then
    want=0
    if [ "$REGISTER_KEY" = 1 ]; then want=1
    elif [ "$ASSUME_YES" = 0 ] && confirm "Register this device's key on your GitHub account as a signing key now?"; then want=1; fi
    if [ "$want" = 1 ]; then
      # The signing-key scope is not part of gh's default login.
      if ! gh auth status 2>&1 | grep -q "admin:ssh_signing_key"; then
        if has_tty; then
          info "Granting gh the signing-key scope (a browser window will open)"
          gh auth refresh -h github.com -s admin:ssh_signing_key < /dev/tty > /dev/tty 2>&1 || warn "scope refresh did not complete"
        else
          warn "gh lacks the admin:ssh_signing_key scope; run: gh auth refresh -h github.com -s admin:ssh_signing_key"
        fi
      fi
      "$PREFIX/bin/$APP" register-key || warn "Registration failed; the app's first screen offers other ways."
    else
      warn "Key not registered yet: run 'atekvid register-key' or use the app's first screen."
    fi
  fi
fi

printf '\n%sAll set.%s Start it from the application menu or run: %s\n' "$C_OK" "$C_RESET" "$APP"
printf '%sUpdate later with:%s atekvid update\n' "$C_DIM" "$C_RESET"
