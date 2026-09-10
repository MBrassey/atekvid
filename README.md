<p align="center"><img src="logo.png" width="160" alt="atekvid"></p>

<h1 align="center">atekvid</h1>

<p align="center">Private, end-to-end encrypted video chat for Linux, for a small circle of GitHub accounts.</p>

This repository holds the installer and the release binaries. The source code
lives in a private repository.

## Install or update

```sh
curl -fsSL https://raw.githubusercontent.com/MBrassey/atekvid/main/install.sh | bash
```

Works on Arch, Manjaro, CachyOS, Linux Mint, Ubuntu, Debian, Fedora, openSUSE,
Void and Alpine (x86_64). The script installs the few system libraries the app
needs, downloads the latest release (checksum verified), installs `atekvid` to
`~/.local/bin`, adds it to the application menu, and runs `atekvid doctor`.

The app updates itself: it checks these releases shortly after launch and every
six hours, installs a newer version in the background, and offers a restart.
`atekvid update` does the same by hand.

## Releases

Each release ships `atekvid-x86_64-unknown-linux-gnu.tar.gz` (glibc 2.35 or
newer: Mint 21+, Ubuntu 22.04+, Debian 12+, Fedora, Arch and derivatives) with a
`.sha256` checksum, plus a copy of `install.sh`.

Extract and run `./install.sh` if you prefer not to pipe from the network.

## Runtime requirements

`libpulse` and `libopus` (present on every desktop Linux), PipeWire
(`pipewire-pulse`) or PulseAudio running, a camera (optional), and a GitHub
account on the circle's allow-list with this device's key registered as an SSH
signing key. The app's first screen walks through the key step.
