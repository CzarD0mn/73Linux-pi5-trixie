# 73Linux Pi fork changelog

Unofficial fork of [km4ack/73Linux](https://github.com/km4ack/73Linux) 4.1.13.
First line of `changelog` is `version=4.2.0` so 73.sh can read a version string.

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

## 4.1.15 — 2026-10-15

### Remaining Pi apps patched for Trixie / arm64
- 27 more installers in `app/stable/pi` patched and added to
  `bootstrap.sh` `patch_files` (35 `.bapp` files total). See the per-app
  table in `PI5_TRIXIE.md`.
- New helpers in `bin/trixie-apt.sh`: generic `*t64` fallback,
  `bap_apt_install_available`, `bap_enable_armhf`, `bap_install_deb`,
  `bap_gh_asset_url`, `bap_unsupported`, plus mappings for `conky`,
  `libpcre3-dev`, `libdb++-dev`, `libqt5core5a` and `openjdk-*-jre/jdk/dbg`.

### Notable fixes
- **JS8Call** now comes from Debian (`js8call` 2.2.0); `files.js8call.com`
  is dead and the GitHub releases are x86_64 only.
- **WSJT-X** finds the `wsjtx-*-linux-aarch64.deb` filename used since 3.0.
- **Pat** uses the GitHub releases API so the 1.0.0 `.deb` installs.
- **HamClock** builds from `openhamclock/hamclock` and points at a live
  backend; Clear Sky Institute went offline in 2026.
- **GridTracker** installs GridTracker 2's arm64 `.deb` (`libgconf-2-4` is gone).
- **HAMRS** uses the native arm64 AppImage instead of armv7l + armhf.
- **CQRLOG, TQSL, Xastir, VNC, YAAC** use distro packages where the old
  package names or download URLs no longer exist.
- **VARA** refuses to install on the Pi 5 16K-page kernel with instructions.
- **PISTATS** reports that its source is no longer published instead of
  failing mid-download.

### Verified unchanged
AX25, BATT, DIPOLE, GPREDICT, GPSUPDATE, PATMENU, PIQSO, SECURITY, SHOWLOG,
XYGRIB and the three community apps (CHECK, DASHBOARD, SPOT_POTA).

## 4.2.0 — 2026-10-15 (arch-pacman branch)

This branch targets **Arch-based aarch64** (Arch Linux ARM, Manjaro ARM, ...),
not Debian Trixie. It installs only with `pacman` and `yay`.

### Package manager
- `bin/trixie-apt.sh` replaced by `bin/arch-pkg.sh`; the old file is deleted
  and `bootstrap.sh` removes a leftover copy from earlier installs.
- `bap_pkg_install` runs `sudo pacman -S --needed --noconfirm` for repo
  packages and `yay -S --needed --noconfirm` for AUR packages. If yay is
  missing it prints install steps for yay and fails (no other AUR helper).
- `bap_resolve_pkg` maps Debian names to Arch (build-essential→base-devel,
  `*-dev`→Arch libs, php8.x→php, default-jre→jre-openjdk, conky-std→conky,
  libfuse2t64→fuse2, Qt5 libs→qt5-base, ...). Table in `ARCH.md`.
- Removed every apt / apt-get / apt-cache / dpkg / dpkg-query call, the
  armhf multiarch path, the `*t64` rename logic and `.deb` installs.
- VERSION / REMOVE use `pacman -Q`, `pacman -Si` and `pacman -R` wrappers.

### OS detection
- `bootstrap.sh`, `73.sh` and `set-enviroment.sh` read `/etc/os-release`
  (`ID` arch/archarm/manjaro/endeavouros/... or `ID_LIKE` containing arch)
  and stop with a message on Debian / Raspberry Pi OS.
- `73.sh` exports all `bap_*` helpers so app-check, VERSION and REMOVE can use them.

### Apps
- **AUR via yay:** js8call, trustedqsl, cqrlog, xastir, plus fallbacks for
  flrig, direwolf and wsjtx (when the ALARM repo has no aarch64 build).
- **GridTracker** installs the official `GridTracker2-*-aarch64.pacman`.
- **Pat** installs the `linux_arm64.tar.gz` binary and writes `pat@.service`.
- **WSJT-X** uses the `wsjtx` package instead of the upstream `.deb`.
- **HAMLIB** uses `pacman -S hamlib` (source build fallback).
- **RepeaterSTART** unpacks its arch-independent package with `bsdtar`.
- **VARA** unsupported (Pi-Apps is Debian-only). **PISTATS** still
  unsupported. BPQ's 32-bit `piBPQConfigGen` cannot run (no armhf multiarch).
- `PI5_TRIXIE.md` renamed to `ARCH.md`.
