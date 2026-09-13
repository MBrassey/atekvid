<p align="center"><img src="logo.png" width="160" alt="atekvid"></p>

<h1 align="center">atekvid</h1>

<p align="center">Private, end-to-end encrypted video chat for Linux, for a small circle of GitHub accounts.<br>
No accounts to create, no server to run, no address to type. Two laptops on a hotel Wi-Fi, a phone hotspot and a VPN, or the same living room: they find each other and talk directly.</p>

<p align="center">
<a href="#install-or-update">Install</a> ·
<a href="#what-it-does">What it does</a> ·
<a href="#screens">Screens</a> ·
<a href="#how-it-works">How it works</a> ·
<a href="#security">Security</a> ·
<a href="#libraries">Libraries</a> ·
<a href="#command-line">Command line</a> ·
<a href="#configuration">Configuration</a> ·
<a href="#troubleshooting">Troubleshooting</a>
</p>

This repository holds the installer and the signed release binaries. The
source code lives in a private repository; this page documents how the
application is built and how it behaves.

## Install or update

```sh
curl -fsSL https://raw.githubusercontent.com/MBrassey/atekvid/main/install.sh | bash
```

One line on Arch, Manjaro, CachyOS, Linux Mint, Ubuntu, Debian, Fedora,
openSUSE, Void and Alpine (x86_64). The script:

1. installs the small system libraries the app needs (`libpulse`,
   `libasound`, `libopus`; present on every desktop already);
2. downloads the latest release, **verifies its Ed25519 signature** against
   the atekvid release key and its SHA-256 checksum;
3. installs `atekvid` to `~/.local/bin`, adds it to the application menu with
   the logo, pins it to your panel once (the taskbar or dock on Cinnamon,
   GNOME and KDE Plasma; take it off and it stays off), and starts it in the
   system tray at login;
4. registers this device's key on your GitHub account when the GitHub CLI is
   signed in (GitHub asks once, in the browser); otherwise the app does it at
   first start.

Prefer not to pipe from the network? Download the release archive, check the
`.sig` and `.sha256`, extract, and run `./install.sh` from it. `install.sh
--help` lists the options (`--prefix`, `--no-pin`, `--no-autostart`,
`--autostart`, `--uninstall`, …).

**Updating** happens by itself: the app checks these releases shortly after
launch and every six hours, verifies the signature, installs the new binary
next to the running one and offers a restart. `atekvid update` does the same
by hand.

### Requirements

| | |
|---|---|
| CPU / OS | x86_64 Linux, glibc 2.35 or newer (Mint 21+, Ubuntu 22.04+, Debian 12+, Fedora 36+, Arch and derivatives) |
| Sound | PipeWire or PulseAudio, or plain ALSA with no sound server running |
| Camera | any V4L2 camera (MJPEG, YUYV, UYVY, NV12, NV21, YU12, YV12, grey, RGB); optional, a test pattern stands in |
| Display | X11 or Wayland; OpenGL 3.x |
| Screen sharing | Wayland: the desktop's ScreenCast portal (`xdg-desktop-portal` with the KDE, GNOME, wlr or Hyprland backend) and PipeWire. X11: nothing extra |
| Tray | KDE, Cinnamon, XFCE, MATE, LXQt, Budgie; GNOME with the AppIndicator extension Ubuntu ships |
| Account | a GitHub account on the circle's allow-list, with this device's key registered as an SSH signing key |

## What it does

- **Calls** with H.264 video (up to 1080p, adapting to the connection) and
  Opus voice, direct between machines when the network allows, through an
  encrypted relay otherwise, over ordinary HTTPS, so hotel, airport and
  plane Wi-Fi and a phone's hotspot still carry a call. Each side remembers
  where the others were last reached.
- **Group calls.** Call one person, then add the others from *Add people*.
  Every participant holds a direct encrypted media session with every other
  participant, everyone sees and hears everyone, and every connection has its
  own safety code. Calls of three and four people keep up: with two or more
  others, Auto holds the picture at 480p, and the voices are mixed under a
  soft limiter.
- **Calls you can see, and walk into.** When people in your circle are on a
  call, you know: the status bar says who, the People list shows it under
  *Happening now* and says who each person is with, and the tray menu lists
  it. *Join* walks you straight in, no invitation needed. A call is open to
  the circle only while everyone on it lets it be: anyone can make it private
  from the call's header, and a private call stays out of sight, told only to
  the people in it and those they invite, and nobody walks in uninvited.
  People who arrive at the same moment find each other on their own, so a
  call of four always ends up with everyone connected to everyone. While a
  call is open, the people in it show as small live pictures under
  *Happening now* (and when you rest on the status bar's note), refreshed
  every couple of seconds, with no sound and nothing shared but their camera;
  everyone in the call sees who is looking in.
- **Screen sharing.** Share your entire screen or a single window with
  everyone in the call; several people can share at once. The picker has a
  section for each: on X11 it lists every monitor and window with a small
  picture of it, captured directly, pointer included; on Wayland *Choose a
  screen…* and *Choose a window…* open the desktop's own dialog (the
  ScreenCast portal, with PipeWire). Shared screens take the stage and the
  cameras move to a strip beside them. Each share is its own end-to-end
  encrypted stream, up to 1600 px wide, tuned for legible text.
- **Art board.** Draw, paint and collage together, live. Twelve brushes
  (pen, marker, crayon, spray, rainbow, neon, and heart, star, sparkle,
  snowflake, confetti and bubble stamps) and an eraser; shapes with a fill;
  text in six typefaces with an outline; the full emoji set; the effects'
  props as stickers; and pictures from disk (PNG, JPEG, WebP, BMP, animated
  GIF) dropped straight onto the board or picked with *Choose pictures…*. Two sticker packs: a gamer pack (a
  pixel cube, spikes, a jump orb and a portal, a creeper, blocks, gems and
  tools, TNT, a blocky avatar, a robot, a rocket, 8-bit hearts and stars) and
  a sea-and-magic pack (mermaids, shells, fish, a dolphin, angels and wings,
  hearts of every kind, a rainbow, a castle, a wand, a tiara and more). A
  pixel brush paints squares on a grid, a glitter brush sparkles in every
  colour, and starter boards give scenes to add to and pixel pictures to
  colour in. Everything can be selected, moved, scaled, rotated, layered,
  duplicated and undone; clearing a board or deleting one for everyone asks
  twice. Boards have a name and a backdrop (ocean, blocky world, neon,
  rainbow, clouds, hearts, paper, sky, night and more), live in a gallery
  with thumbnails, save themselves, merge cleanly when two devices drew
  apart, are offered
  to everyone who comes online, and export to PNG. In a call the board takes
  the stage with the cameras beside it; strokes appear on the others' screens
  as they are drawn, with everyone's cursor and name. The gallery shows who
  is looking at each board and what is new since you last looked, and marks
  others added while you were away are outlined for a moment when you return.
  Chat has a *Draw together* button that opens a board beside the
  conversation, and a video call button.
- **Presence that is true.** *Online* means the other person's atekvid is
  open. Clients connect to each other the moment they start and drop off the
  list within seconds of closing. The list also says who is on which art
  board, trial or Lab program, with a link to join them.
- **The Lab.** A modular synthesiser and three hacker games. The synth is a
  rack of modules (oscillator, LFO, envelope, filter, amp, noise, sample and
  hold, a sixteen-step sequencer, keys, looper, delay, reverb, wavefolder,
  chorus, mixer, scope, output) patched with cables between colour-coded
  sockets, with knobs to turn, ten starting racks to begin from (four of them voices), a spectrum
  analyser and an oscilloscope along the bottom, and up to ten racks of your
  own kept by name.
  The rack zooms in and out (Ctrl and the wheel, a pinch, or the buttons in
  its corner) and fits every module on screen with a double-click. Any
  module can be taken out, the Output too (its ×, a right-click, or Delete
  or Backspace), and Undo or Ctrl+Z puts it back as it was.
  *Only me* plays it on your speakers; *Everyone* mixes it into what the call
  hears. Voice in and Voice out put your own voice through the rack, so a
  call hears the rack instead of your microphone. The hacker games are a
  field terminal: Keycrack, Cipher and Packet run, each with a best score.
- **Voice changer.** Nine voices (natural, robot, deep, chipmunk, alien,
  monster, hall, echo, radio) applied to your microphone before it is sent,
  so everyone on the call hears the changed voice, with no delay added.
  It is on the call bar (the wave button) and in the Effects panel. *Hear my
  changed voice* lets you hear yourself the way the call does (use
  headphones), or leave it off and sound normal to yourself while everyone
  else hears the change. The choice is remembered, and the Lab has the same
  switch while a rack is changing your voice, so a voice rack such as
  Cathedral (Voice in through a hall reverb) works as a voice changer on its
  own, in a call or not. The mute button wears a small mark while your voice
  is changed.
- **Ringtones.** Twelve tunes made by atekvid itself: bells, an old phone,
  the opening of Mozart's *Eine kleine Nachtmusik*, hip hop, trap, drum and
  bass, techno, EDM, dubstep, synthwave, chiptune and an alien theremin.
  Give everyone the same one or each person their own, or add your own
  music (MP3, M4A, AAC, ALAC, FLAC, Ogg Vorbis, Opus or WAV) from the file
  chooser or by dropping it
  on the Devices screen. A robot voice, made by atekvid too, says who is
  calling: after every third ring of a short ringtone, or over a long one
  while the music dips. Every choice has a listen button.
- **Effects** baked into your picture, so everyone sees them: face-tracked
  props (sunglasses, hats, crown, cat and bunny ears, mustache, googly eyes,
  rosy cheeks, a ring of stars circling your head…), funhouse warps, looks
  (old film, thermal, night vision, cartoon, a dreamy glow…), star glints
  that twinkle on the lights in view, fairy dust that trails your hand as
  you wave, northern lights, drifting bokeh lights and hearts, particles
  (hearts, snow, confetti, bubbles, sparkles), a name tag, a speech bubble,
  reaction bursts, and a translucent CRT-style *where am I* map showing your
  city, nearest cross streets, the hotel, museum or airport you are in, a
  scale bar and a north arrow, tucked into a corner. Your own PNG overlays
  load as plugins. Text and the map are drawn over your mirrored self-preview
  the right way round, so you read exactly what everyone else sees. In a
  call, drag your own picture to any corner and make it bigger or smaller
  from its corner grip (double-click it, or press **P**, to step through
  sizes), so you can watch your effects up close; size and corner are
  remembered.
- **Chat**, end-to-end encrypted per session, with Markdown, links, a custom
  emoji set drawn in the app's palette, typing indicator and delivery ticks.
  In a group call the chat drawer reaches everyone in the call.
- **Drop box.** Drag files onto the window, or press *Choose files…* to pick
  them (pictures, videos, documents, anything) in your desktop's own file
  chooser; the other person decides whether
  to download it. Files stream directly over the encrypted link with progress
  and previews, and land in `~/Downloads/atekvid/`.
- **Snapshots and recording** (MKV, remote video with both voices mixed),
  written from the already-encoded streams.
- **Tray.** Closing the window keeps atekvid running: calls, messages and
  files still arrive with desktop notifications, an incoming call opens the
  window, and the tray menu answers, declines, calls, invites and quits. While
  hidden with no call, the camera and microphone are released, so other
  programs can use the webcam.
- **Devices.** Camera, resolution and frame rate, microphone with meter,
  automatic level, gain and noise gate, speaker with test tone, echo
  cancellation using the sound server's WebRTC canceller (on by itself
  during calls on speakers), and a quality selector. Plug a webcam or a headset in while the app runs and it is picked
  up within a second; the device you chose is used again whenever it comes
  back.
- **Sound that keeps working.** atekvid talks to PipeWire or PulseAudio,
  and straight to the sound card through ALSA on a system with no sound
  server at all. A microphone or speaker that drops out (the sound server
  restarting, a headset unplugged) comes back by itself within seconds, on
  the default device if the chosen one is gone. The automatic level keeps a
  quiet laptop microphone as easy to hear as a headset. A microphone or
  speaker muted or turned all the way down in the system's mixer, or a
  microphone that sends no sound at all, is shown on the Devices screen and
  during a call, with a button that unmutes it. On a laptop's own speakers
  the echo canceller turns on by itself for the call, so the other side does
  not hear themselves come back; with headphones or a headset it stays off.
- **Temporal monitoring.** The Health page reads link steadiness the way
  A-TEK reads a planet: as rift activity on the Planetary Rift Activity Index,
  from Pluto's 0.5% up.
- A launch splash, soft fades, glass surfaces, a custom title bar and window
  controls, a hand-drawn icon set, and quiet sounds for rings, messages, files
  and reactions.
- **Something hidden.** A small probe keeps watch beside the version number.
  It goes somewhere, and it is better with company.

Keyboard in a call: **M** mute · **V** camera · **X** share screen ·
**A** art board · **E** effects · **C** chat · **D** drop box · **I** add
people · **S** snapshot · **R** record · **P** the size of your own picture · **F** fullscreen · **Esc** leave
fullscreen · **Ctrl+Q** quit. On the art board: **B** draw · **V** select ·
**S** shapes · **T** text · **K** stickers · **H** pan · **E** eraser ·
**Ctrl+Z / Ctrl+Y** undo and redo · **Ctrl+D** duplicate · **Del** delete ·
**+ − 0** zoom and fit · **Space** or the middle button drags the view ·
**Ctrl+wheel** zooms. In the Lab: **+ − 0 1** zoom the rack, fit it and
show it at actual size; **Del** or **Backspace** takes out the selected
module and **Ctrl+Z** puts it back; with the synth on, **A** to **;** play notes and
**Z** and **X** change octave; in the terminal, digits, arrows, **Enter**
and **Esc** do what they say.

## Screens

<p align="center"><img src="docs/splash.png" width="820" alt="Launch"></p>

**People.** The circle, who is online, and one button to call or invite.

<p align="center"><img src="docs/people.png" width="820" alt="People"></p>

**Incoming call.** Answer opens the call straight away; in a group call the
dialog says who is already in it.

<p align="center"><img src="docs/incoming.png" width="820" alt="Incoming call"></p>

**A call with two other people.** Tiles for every participant with a speaking
ring, connection quality and a name pill; your own picture in the corner; the
control bar, reactions, *Add people*, safety codes and statistics.

<p align="center"><img src="docs/call.png" width="820" alt="Group call"></p>

**Screen sharing.** A participant's shared window takes the stage; the cameras
move to a strip beside it. Several people can share at the same time, and the
person sharing sees their own share with a *Stop* button.

<p align="center"><img src="docs/call-share.png" width="820" alt="A shared screen in a call"></p>

**Art board.** A shared board two people are drawing on: brushes (each
chip shows what it paints), shapes, text in several typefaces, emoji,
stickers and an animated picture, with the tools down the side, the other
person's pen on the board, and everything sized for small hands.

<p align="center"><img src="docs/art-board.png" width="820" alt="The art board"></p>

**Starter boards.** Scenes to add to and pixel pictures to colour in, with a
sticker pack for gamers and one for mermaid-and-angel fans.

<p align="center"><img src="docs/art-sea.png" width="820" alt="Under the sea"></p>
<p align="center"><img src="docs/art-pixel.png" width="820" alt="Pixel world with the gamer stickers"></p>
<p align="center"><img src="docs/art-geometry.png" width="820" alt="Geometry run"></p>
<p align="center"><img src="docs/art-magic.png" width="820" alt="Angel clouds with the sea-and-magic stickers"></p>
<p align="center"><img src="docs/art-colour.png" width="820" alt="A pixel colouring page, filled in with the pixel brush"></p>

**Stickers and pictures.** The sticker panel: emoji, the effects' props, and
a place to add a picture from disk (or drop one on the board).

<p align="center"><img src="docs/art-stickers.png" width="820" alt="Stickers on the art board"></p>

**The gallery.** Starting points first (a blank board, five scenes, eight
pixel pictures to colour in), then every board the circle has, with a
thumbnail, its owner and what is on it.

<p align="center"><img src="docs/art-gallery.png" width="820" alt="The board gallery"></p>

**The art board in a call.** The board takes the stage and the cameras line
the side; a slim tool strip stays over the board.

<p align="center"><img src="docs/art-call.png" width="820" alt="The art board in a call"></p>

**Who is where.** The People list says who is on which board, trial or Lab
program, with a link to join them.

<p align="center"><img src="docs/presence-people.png" width="820" alt="The People list showing where everyone is"></p>

**The Lab.** The synth rack, with a sequencer driving an oscillator through
a filter and an amp into a delay, and the screens along the bottom reading
the sound. The rack zooms out to take in a whole patch and in to read every
value.

<p align="center"><img src="docs/lab-synth.png" width="820" alt="The modular synthesiser"></p>
<p align="center"><img src="docs/lab-synth-drone.png" width="820" alt="An alien drone patch"></p>
<p align="center"><img src="docs/lab-zoom-in.png" width="820" alt="The rack zoomed in"></p>

**The Lab on a call.** The rack takes the stage (the flask in the bar, or
**L**), the cameras line the side, and with *Everyone* chosen the other
people hear it, microphone muted or not.

<p align="center"><img src="docs/lab-call.png" width="820" alt="The synth on a call"></p>

**Hacker games.** The field terminal and its three programs.

<p align="center"><img src="docs/lab-hacker.png" width="820" alt="The field terminal"></p>
<p align="center"><img src="docs/lab-keycrack.png" width="820" alt="Keycrack"></p>
<p align="center"><img src="docs/lab-cipher.png" width="820" alt="Cipher"></p>
<p align="center"><img src="docs/lab-packet.png" width="820" alt="Packet run"></p>

**Voice changer.** The wave button on the call bar opens the voices, and the
mute button wears a small mark while yours is changed. In the Lab, Voice in
and Voice out put your voice through a rack, here the Robot voice.

<p align="center"><img src="docs/voice-call.png" width="820" alt="The voice changer on a call"></p>
<p align="center"><img src="docs/voice-rack.png" width="820" alt="The Robot voice rack"></p>

**Happening now.** A call between two people in the circle, with small live
pictures of them and a way in from the People list, the status bar and the
tray. *Join* shows who you are joining until they take you in, and can be
cancelled.

<p align="center"><img src="docs/calls.png" width="820" alt="A call in the circle, ready to join"></p>

**Your own picture, as big as you like.** Drag it to any corner and pull its
grip to resize it, to see your effects up close.

<p align="center"><img src="docs/self-view.png" width="820" alt="A bigger self view in a call"></p>

**Share a screen or a window.** The call bar's screen button (or **X**) opens
the picker: your entire screen in one section, a single window in the other,
each with a small picture (on Wayland, the desktop's own dialog picks).

<p align="center"><img src="docs/share-picker.png" width="820" alt="The share picker"></p>

**Drop box in a call.** A file offered by a participant, ready to download.

<p align="center"><img src="docs/call-dropbox.png" width="820" alt="Drop box drawer"></p>

**Chat in a call.** *Everyone* addresses the whole call; a name addresses one person.

<p align="center"><img src="docs/call-chat.png" width="820" alt="Chat drawer"></p>

**Ringtones.** A tune for everyone, one for each person, and sounds of your
own, each with a listen button.

<p align="center"><img src="docs/ringtones.png" width="820" alt="The Ringtones card"></p>

**Chat, Drop box, Effects, Devices, Health.**

<p align="center"><img src="docs/chat.png" width="820" alt="Chat"></p>
<p align="center"><img src="docs/files.png" width="820" alt="Drop box"></p>
<p align="center"><img src="docs/effects.png" width="820" alt="Effects"></p>
<p align="center"><img src="docs/devices.png" width="820" alt="Devices"></p>
<p align="center"><img src="docs/health-temporal.png" width="820" alt="Health, with the temporal monitoring readout"></p>

<details>
<summary><b>What the probe does</b> (a small spoiler)</summary>

The probe opens GeometryKing: a one-key rhythm runner through the planets in
order of rift activity, with a tune composed for each by a small synthesiser,
practice markers, an endless run, and The Core, a rotating icositetrachoron
to turn over in four dimensions. Trials run together: everyone on the same
trial sees the others' probes as ghosts with a race board of how far each has
got, and a call carries on in a strip at the side.

<p align="center"><img src="docs/game-title.png" width="820" alt="GeometryKing"></p>
<p align="center"><img src="docs/game-play.png" width="820" alt="A trial"></p>
<p align="center"><img src="docs/presence-race.png" width="820" alt="A trial run together, on a call"></p>
<p align="center"><img src="docs/game-core.png" width="820" alt="The Core"></p>
</details>

**First run.** With the GitHub CLI installed, the device links itself: signed
out, it signs you in; then GitHub asks once, in the browser, whether atekvid
may add signing keys (the code is on your clipboard). Without `gh`, the key
is shown to paste on GitHub.

<p align="center"><img src="docs/link.png" width="820" alt="Link this device"></p>

## How it works

### Identity and trust

Each installation generates one Ed25519 key, stored in
`~/.config/atekvid/identity.key` (mode 0600). That key is at the same time:

- the **iroh endpoint id**, which is what peers connect to and what the QUIC
  handshake authenticates (TLS 1.3 with the endpoint key as certificate);
- an **SSH public key** the user registers on their GitHub account as a
  *signing* key (it cannot push code).

The circle is a fixed allow-list of GitHub usernames in the configuration.
The app reads each user's public keys from GitHub's public API, caches them,
and accepts a connection only from an endpoint whose key GitHub lists for one
of those users. Nothing else is trusted: no accounts, no passwords, no
directory server of its own. Removing a key on GitHub removes that device from
the circle within minutes.

### Finding each other

- **n0 address lookup** (DNS/pkarr): every endpoint publishes where it can be
  reached under its public key; peers resolve each other by key from anywhere.
- **mDNS** on the local network, so two machines on the same Wi-Fi find each
  other with no internet at all.
- Every client dials every other allow-listed key as soon as it starts and
  keeps retrying with a short back-off. Between two peers the lower endpoint
  id dials and the higher one gives it five seconds before dialling itself;
  when dials still cross, both keep the connection the lower id initiated. Links carry QUIC keep-alives every 5 s with a
  20 s idle timeout, so presence follows reality within seconds.

### Transport

Built on [iroh](https://iroh.computer) (QUIC over UDP). Connections hole-punch
through NATs and, when that fails, fall back to n0's public relay servers over
HTTPS on port 443, which is why hotel, airport and captive-portal networks work
once you are past the portal. The relay only ever forwards ciphertext.

On one link: a bidirectional control stream (signalling, chat, file offers),
QUIC datagrams for audio (a lost packet costs 20 ms, concealed by Opus), and
one unidirectional stream per video picture (a lost packet costs at most one
picture). Files travel on their own streams once accepted.

### Calls

A call is a full mesh with one call id. Inviting someone sends the current
participant list; when they answer, they open a media session to every listed
member (`Join`), each of which answers with its own key exchange. N
participants means N−1 sessions per client, each with its own keys, so nobody
relays, mixes or decrypts anyone else's picture. Leaving removes one member;
the call continues for the rest.

### Media pipeline

```
camera (V4L2) → JPEG/YUV decode → effects (face tracking, sprites, warps, map)
   → OpenH264 encode (adaptive ladder 180p…1080p) → seal → QUIC streams
microphone (PipeWire/PulseAudio, or ALSA) → automatic level, gain, noise gate → Opus (32 kb/s, FEC) → seal → datagrams
shared screen (portal + PipeWire helper, or X11 GetImage) → scale to ≤1600 px
   → OpenH264 encode (10 fps, own bit budget) → seal → QUIC streams
network → open → per-participant OpenH264 decoders (camera and screen) → tiles
network → open → per-participant Opus decoders + jitter buffers → mix → speaker
```

Encoding happens once per frame regardless of participants. The encoder
ladder reacts to send latency and queue depth; a keyframe is requested
whenever a participant loses sync. Recording muxes the already-encoded H.264
and both voices into MKV, so it costs nothing extra. A shared screen travels
as a second video stream on its own key lane; on Wayland the capture runs in
the separate `atekvid-screencast` process (XDG ScreenCast portal, PipeWire),
so the app itself links no PipeWire library and a portal problem cannot touch
a call; on X11 the app reads the X server directly (RandR monitors, any
window, XFixes cursor).

### Effects and the map

Face detection uses a bundled SeetaFace model (`rustface`), sprites are drawn
with `tiny-skia`, text with `ab_glyph`. Effects are baked into the outgoing
picture; the name tag, the speech bubble and the map are composed last and
reported to the interface as layers, which draws them over the mirrored
self-preview without mirroring the text (a bubble's tail still flips with the
face it points at). Plugins are folders with a `plugin.toml`
and PNG layers anchored to face landmarks. The map overlay locates the machine
through nearby Wi-Fi networks (BeaconDB) or the public IP, describes the place
with OpenStreetMap data (Nominatim, Overpass) and renders CARTO dark tiles in a
CRT style; it is off unless you turn it on.

### Desktop integration

The window is drawn by egui/eframe with its own title bar and controls, on X11
or Wayland. Hiding to the tray destroys the window and recreates it on demand,
because Wayland allows neither hiding nor restoring a window on request; the
application state lives on regardless. The tray item speaks the
StatusNotifierItem protocol over D-Bus (pure Rust, `ksni`); notifications use
`org.freedesktop.Notifications`. The installer adds a `.desktop` entry and,
once, a login autostart entry (`atekvid --hidden`): turned off in the
desktop's startup settings it stays off, `--no-autostart` removes it and
`--autostart` brings it back. It puts the `atekvid-screencast` helper next to
the app.

### Releases and updates

Releases are built from a tag of the private source repository, in Docker on
Ubuntu 22.04 (glibc 2.35), and published here. The archive holds the app, the
`atekvid-screencast` helper, the installer and the packaging files. Each archive is signed with the atekvid release
key using OpenSSH signatures (`ssh-keygen -Y sign`, namespace
`atekvid-release`); the public half is compiled into the app and written into
`install.sh`. The app refuses any update whose signature does not verify, and
so does the installer.

```
release key (Ed25519): ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlC37bWYuceYyD1LCazmK6wyWxsu1P6ju0Qsnroe0l1
```

Verify a download yourself:

```sh
echo "atekvid-release ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlC37bWYuceYyD1LCazmK6wyWxsu1P6ju0Qsnroe0l1" > allowed_signers
ssh-keygen -Y verify -f allowed_signers -I atekvid-release -n atekvid-release \
  -s atekvid-x86_64-unknown-linux-gnu.tar.gz.sig < atekvid-x86_64-unknown-linux-gnu.tar.gz
sha256sum -c atekvid-x86_64-unknown-linux-gnu.tar.gz.sha256
```

## Security

| Layer | What |
|---|---|
| Transport | QUIC with TLS 1.3 (`rustls`, ring). The peer's certificate *is* its Ed25519 endpoint key; the connection is accepted only if GitHub lists that key for an allow-listed user. |
| Session keys | Inside every authenticated connection, an ephemeral X25519 exchange per link and per call, HKDF-SHA256 with both endpoint ids and the context (link or call id) in the salt, giving forward secrecy and one key set per direction. |
| Payloads | ChaCha20-Poly1305 over every chat message, audio packet, video picture and file chunk, with the packet header as associated data. Nonces are `lane ‖ counter`: control, audio, video, the shared screen, the art board and each file transfer have their own lane and monotonic counter, so a nonce is never reused. |
| Replay | The receiver keeps an anti-replay window per lane (RFC 6479 style, 2048 deep): every packet is accepted once, late packets within the window are fine, anything older or seen before is dropped. Chat is also de-duplicated by message id. |
| Bounds | A device flooding control messages loses its link; reactions, typing notices and file offers are rate-limited per device; a link carries a bounded number of pictures in flight, each bounded in size, and nothing is buffered for pictures outside a call; decoded pictures beyond 4096×4096 are refused; chat messages are capped at 8 KiB. Art board changes are rate-limited per device and validated (bounded coordinates, points, revisions, text and element counts); an element carries its author and only that device may add it; a board may only be deleted by its owner and stays deleted; board pictures are content-addressed, capped at 8 MiB, decoded with size limits no larger than 1200 px a side, and accepted only from a device they were asked from; snapshot and picture requests are answered at most every few seconds; bulk board data travels on its own streams so it cannot hold up call signalling. |
| Accounts | A key listed under two circle accounts is trusted for neither; each login's numeric GitHub id is pinned, so a login that changes hands is not the same person; a key removed from GitHub loses its link at the next refresh; GitHub's rate limits are honoured with validators, so unchanged answers cost no quota. |
| Verification | A 30-digit safety code per connection, derived from the same exchange, shown in the call. If both screens agree, nobody is in the middle. |
| Files | Chunks are bound to the transfer id and index, sizes are enforced, names are sanitised, writes go to a `.part` file renamed on completion. Nothing is downloaded until the recipient accepts. |
| Identity | Private key in a 0600 file inside a 0700 directory; never leaves the machine. The GitHub token `gh` holds is only used, optionally, to raise API rate limits and is sent to `api.github.com` alone. |
| Updates | Ed25519-signed release archives verified against a key compiled into the app; SHA-256 as a second check; the new binary is test-run and must report exactly the version the release claims (and a newer one than the running app) before it replaces the old one; assets come only from this repository's download URLs, with size limits. |
| Peer input | Chat links open only for `http`, `https` and `mailto`; anything else is plain text, and a link whose text reads like a different address shows its real host. Invitations may only name allow-listed users. A peer can have at most 16 unanswered file offers, chat history is bounded, received files open only as documents and media (never as launchers), and a misbehaving effect is switched off rather than ending the camera thread. |
| Privacy | The map effect positions the machine only while it is drawing; map tiles are cached in a private directory for thirty days at most, and no coordinates are written to the log. |
| Build | Release builds contain no test overrides; the development trust override used for testing several identities on one machine is a compile-time feature that release builds do not include. |

What atekvid does **not** do: store messages or files anywhere in between,
phone home (the only outbound connections are GitHub for keys, avatars and
updates; n0 lookup and relays; and, only when the map overlay is on,
BeaconDB, geojs, OpenStreetMap and CARTO), or accept connections from anyone
outside the allow-list.

## Libraries

atekvid is written in Rust. The main building blocks:

| Area | Crate | Version |
|---|---|---|
| Peer-to-peer QUIC, hole punching, relays | `iroh` | 1.2.0 |
| Local network discovery | `iroh-mdns-address-lookup` | 0.5.0 |
| User interface | `egui` / `eframe` (glow, X11 and Wayland) | 0.36.2 |
| Video codec | `openh264` (built from source) | 0.9.8 |
| Voice codec | `opus` | 0.4.0 |
| Camera capture | `v4l` | 0.14.0 |
| JPEG decoding | `zune-jpeg` | 0.4.21 |
| Sound server | `libpulse-binding`, `libpulse-simple-binding` | 2.30.1 |
| Sound without a server | `alsa` | 0.12.1 |
| Face detection | `rustface` (SeetaFace model) | 0.1.7 |
| Sprites, overlays, text | `tiny-skia`, `ab_glyph`, `image` | 0.12.0, 0.2.32, 0.25.10 |
| Key exchange and encryption | `x25519-dalek`, `hkdf`, `sha2`, `chacha20poly1305` | 3.0.0, 0.13.0, 0.11.0, 0.11.0 |
| Release signature verification | `ssh-key` | 0.6.7 |
| Screen sharing (Wayland portal, PipeWire; helper only) | `ashpd`, `pipewire`, `libspa` | 0.13.13, 0.10.1, 0.10.1 |
| Screen sharing (X11 capture) | `x11rb` (RandR, XFixes) | 0.14 |
| Async runtime | `tokio` | 1.53 |
| Wire format | `postcard`, `serde` | 1.1.3 |
| System tray, notifications | `ksni`, `notify-rust` | 0.3.6, 4.17.0 |
| HTTP (GitHub, updates, map) | `ureq` (rustls) | 3.4.1 |
| Command line | `clap` | 4.6 |

Runtime dependencies of the binary are the C libraries `libpulse`,
`libpulse-simple`, `libasound` and `libopus` (with what they pull in: `libsndfile`,
`libdbus`, `libxcb`); everything else, including the H.264 codec and TLS, is
compiled in. The `atekvid-screencast` helper additionally needs
`libpipewire-0.3`. The archive is about 20 MB.

## Command line

```
atekvid                       the app
atekvid --call thepearlking   the app, calling as soon as they are online
atekvid --hidden              start in the tray (what the login autostart uses)
atekvid --start home          skip the device screen
atekvid --view health         start on a view: people, chat, files, effects, devices, health
atekvid --drawer files        in a call, open the drop box (or chat / effects) drawer
atekvid update                install the latest signed release now
atekvid devices               list cameras, microphones, speakers
atekvid camera-test           save one frame from the camera
atekvid identity              show this device's key and which account it is linked to
atekvid register-key          register the key on GitHub via gh
atekvid doctor                environment and connectivity check
atekvid doctor --mic          … and listen to the microphone for a second
atekvid effects               list effects and their parameters
atekvid effects-preview --image me.jpg --out out.png --effects sunglasses,sepia
atekvid where                 print what the map overlay would show
atekvid headless [--call USER[,USER…]] [--duration N] [--no-audio] [--send FILE]
                              stay online without a window; answers calls and
                              accepts files automatically
```

`--config-dir DIR` keeps identity, configuration and plugins somewhere else,
which lets two instances run on one machine.

## Configuration

`~/.config/atekvid/config.toml`, written on first run:

```toml
allowed_users = ["mbrassey", "thepearlking", "angelaivl"]   # the circle
auto_update = true                 # install signed releases in the background

[devices]                          # chosen on the Devices screen
camera = "/dev/video0"
camera_width = 1280
camera_height = 720
camera_fps = 30
microphone = "alsa_input…"
speaker = "alsa_output…"

[video]
quality = "auto"                   # auto, low, medium, high, ultra
mirror_preview = true

[audio]
mic_gain = 1.0
noise_gate = true
gate_threshold_db = -48.0
echo_cancel = false                # loads the sound server's WebRTC canceller
volume = 1.0
ringtone = true
announce = true                    # a robot voice says who is calling
voice = "none"                     # voice changer: robot, deep, chipmunk, alien, monster, hall, echo, radio

[ringtones]
default = "bells"                  # bells, phone, classical, hiphop, trap, dnb, techno, edm, dubstep,
                                   # synthwave, chiptune, alien, or "file:<name>" for a sound you added

[ringtones.people]
thepearlking = "dubstep"           # someone's own ringtone

[ui]
tray = true                        # keep running in the tray when the window closes
open_calls = true                  # let the circle see your calls and walk in (everyone on a call must)
notifications = true
show_stats = false

[effects]                          # what is switched on, and parameters
enabled = []
```

Plugins go in `~/.config/atekvid/plugins/<name>/plugin.toml` with PNG layers;
the example shipped in every release shows the format.

## Troubleshooting

- **Nobody shows as online.** Both sides must have registered their device key
  on GitHub (Health screen shows `GitHub · name: n key(s)`). Keys are re-read
  every five minutes; the Refresh button on People forces it.
- **"connecting to relay" stays.** Outbound UDP or HTTPS is blocked. atekvid
  needs UDP for direct connections and HTTPS (443) to the relay as a fallback.
- **No sound / no microphone.** Run `atekvid doctor --mic`: it says whether
  the microphone or the speaker is muted or turned down in the system's
  mixer, whether sound only goes to a dummy output, and whether the
  microphone sends anything at all. The Devices screen and the call show the
  same and offer *Unmute*. With no sound server running, atekvid uses ALSA
  directly (the Devices screen says so); a microphone that is silent there
  may have its capture switched off in `alsamixer` (F4 shows capture).
  `atekvid devices` lists everything the app can use.
- **Camera busy.** Another program holds the device. atekvid sends a
  placeholder picture meanwhile and tries the camera again every few
  seconds, so closing the other program is enough: the picture comes back
  by itself.
- **The camera takes a moment, or shows nothing.** Some cameras (the Logitech
  Brio 500 among them) deliver their first picture a second or two after
  they start. atekvid waits up to eight seconds for it, skips frames the
  driver marks as damaged, supplies the tables of MJPEG frames that leave
  them out, reopens a camera that stalls, and tries up to four of the
  camera's modes (the last a small one, for busy USB hubs) before it reports
  a problem, then keeps trying every few seconds with a placeholder picture
  standing in. `atekvid camera-test` saves one frame through the same path and
  says how long the first picture took; `~/.cache/atekvid/atekvid.log` lists
  what was tried.
- **The update was refused.** The archive's signature did not verify against
  the release key. Do not install it; the same check protects the installer.
- **Share screen does nothing, or says the helper is missing.** On Wayland
  sharing needs `atekvid-screencast` next to the app (the installer puts it
  there) and a desktop that offers the ScreenCast portal; `atekvid doctor`
  says which. On X11 the whole screen is offered only when the X server lets
  the root window be read (under Xwayland only windows can be shared).
  `ATEKVID_SHARE_BACKEND=x11` or `=portal` forces one path.
- **Nothing in the tray on GNOME.** Install the AppIndicator extension
  (`gnome-shell-extension-appindicator`); the window still works without it,
  and closing it then quits.

`atekvid doctor` checks the sound server, camera, screen sharing, GitHub
keys, the relay and the identity link, and `atekvid --view health` shows the same live. The app
also writes `~/.cache/atekvid/atekvid.log` (link ups and downs, dial failures,
update checks); send that file along when reporting a problem.

## License

MIT. See [LICENSE](LICENSE).
