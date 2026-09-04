# 73Linux Pi 5 / Trixie fork changelog

Unofficial fork of [km4ack/73Linux](https://github.com/km4ack/73Linux) 4.1.13.
First line of `changelog` is `version=4.1.14` so 73.sh can read a version string.

## 4.1.14 — 2026-09-04

### Why this fork exists
- Upstream dropped Raspberry Pi support in 4.1.9 and targets x86_64.
- Goal: run the installer on Raspberry Pi 5 (and CM5 / similar aarch64 boards)
  under Debian 13 / Raspberry Pi OS Trixie.

### Install layout
- `bootstrap.sh` clones official 73Linux into **`$HOME/73Linux`** (for example
  `/home/pi/73Linux`) and copies this fork’s patched files over it.
- Refuses to run as root and refuses `/`, `/root`, or a missing `HOME`.
- Removed the short-lived `overlay/` directory; patched `73.sh` lives at the
  repo root and is installed into the user home tree.
- Fixed bootstrap syntax errors caused by `\` line continuations (space or
  Windows CR after the backslash).

### 73.sh
- Detects `.pi5-trixie-fork` and skips the upstream git self-replace that
  would wipe Pi support.
- Sources `bin/trixie-apt.sh` when present.
- Checks “not root” before any `apt` call.
- `set-enviroment.sh` does not use sudo. It only reads `/etc/os-release`,
  `lscpu`, and the device tree, then writes `cache/cpu.bap` under the
  install tree.

### Trixie package names (`bin/trixie-apt.sh`)
- `libfuse2` → `libfuse2t64`
- `libasound2` → `libasound2t64`
- `libgtk-3-0` / `libglib2.0-0` t64 variants
- `php8.2` → `php8.4` (then 8.3, then `php`)
- `swig4.0` → `swig`
- Shared W1HKJ downloader prefers `https://www.w1hkj.org/files/<app>/`,
  then SourceForge. `www.w1hkj.com` no longer hosts the file index (HTTP 404).

### App installers
- **HAMLIB** — no longer pinned to 4.4; downloads the current SourceForge
  hamlib tarball.
- **CHIRP** — `libfuse2t64` + `fuse3` on Trixie.
- **FLDIGI, FLRIG, FLAMP, FLMSG, FLNET, FLWRAP** — source and `flxmlrpc`
  come from `https://www.w1hkj.org`. Current upstream tarballs at the time
  of this note:
  - fldigi-4.2.13
  - flrig-2.0.12
  - flamp-2.2.14
  - flmsg-4.0.24
  - flnet-7.5.0
  - flwrap-1.3.6
  - flxmlrpc-0.1.4
- **FLRIG** — Trixie build deps (`libfltk1.3-dev`, `libjpeg62-turbo-dev` or
  `libjpeg-dev`, `pkg-config`). If configure/make still fail, install the
  Debian `flrig` package.

### How to pick up these changes
```bash
cd ~/73Linux-pi5-trixie
git pull
bash ~/73Linux-pi5-trixie/bootstrap.sh
bash ~/73Linux/73.sh
```

Original project: Jason Oleham, KM4ACK. This fork is unofficial and
unsupported by KM4ACK.
