# 73Linux on Raspberry Pi 5 + Debian 13 (Trixie)

Upstream 73Linux (km4ack) dropped Raspberry Pi support in 4.1.9.
This repository is an unofficial patched copy for 64-bit Raspberry Pi OS Trixie on a Pi 5 / CM5.

## Install on the Pi

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git yad jq bc curl wget
sudo raspi-config   # Advanced Options -> Wayland -> X11, then reboot
sudo usermod -aG dialout,tty,plugdev,gpio,i2c,spi "$USER"
# log out / reboot

git clone https://github.com/CzarD0mn/73Linux-pi5-trixie.git $HOME/73Linux-pi5-trixie
bash $HOME/73Linux-pi5-trixie/bootstrap.sh
bash $HOME/73Linux/73.sh
```

`bootstrap.sh` clones upstream into `$HOME/73Linux` and copies this fork's patched files over it.
Keep `.pi5-trixie-fork` in the tree so 73.sh does not replace itself with upstream.

Original project: Jason Oleham, KM4ACK. This fork is unofficial and unsupported by KM4ACK.

## App status on Pi 5 / Trixie (arm64)

Verified statically against the Debian 13 arm64 package index and live download
URLs (2026-10-15). Not yet run on real hardware — see "Testing" below.

### Patched in this fork

| App | What changed |
|---|---|
| HAMLIB | Current SourceForge tarball instead of a pinned 4.4 |
| CHIRP | `libfuse2t64` + `fuse3` |
| FLDIGI, FLRIG, FLAMP, FLMSG, FLNET, FLWRAP | Source from `https://www.w1hkj.org`; FLRIG falls back to the Debian package |
| ARDOP | GitHub API asset download (`ardopcf_arm_Linux_64`) instead of HTML scraping |
| ARDOPGUI | Native aarch64 `piARDOP_GUI64` + native Qt5 (`*t64`) libs |
| BPQ | Native aarch64 `pilinbpq64` and `piQtBPQAPRS64`. `piBPQConfigGen` is still 32-bit, so armhf Qt5 is added only for it |
| CONKY | `conky` virtual package resolves to `conky-std`; cron/desktop dirs created first |
| CQRLOG | Debian `cqrlog` package (Lazarus 2.2 / `lcl-2.2` are gone; Trixie has 4.0) |
| DIREWOLF | Source build kept, with a fallback to Debian's `direwolf` 1.7 and its sample config |
| EES | `php8.2` resolves to `php8.4` |
| GARIM | Build deps added (FLTK, zlib); tarball fetched directly because the whitemesa directory index returns 403; GitHub mirror fallback |
| GPS | gpsd enabled with `systemctl` instead of a hand-made symlink |
| GRIDCALC | `wwl` and `bc` installed from apt before the script (it re-downloads `wwl` from www.db.net on its own) |
| GRIDTRACKER | GridTracker 2 arm64 `.deb` from gridtracker.org. The old NW.js 1.x tarballs needed `libgconf-2-4`, removed in Trixie |
| HAMCLOCK | Clear Sky Institute site is offline (2026). Built from `openhamclock/hamclock` and launched with `-b ohb.hamclock.app:80` |
| HAMRS | Native `linux-arm64` AppImage instead of the armv7l build + armhf multiarch stack |
| JS8 | Debian `js8call` 2.2.0. `files.js8call.com` is dead and upstream releases are x86_64 only |
| M0IAX | JS8CallUtilities_V2 from GitHub in a Python venv (PEP 668). The 2020 32-bit zip is no longer served |
| PAT | GitHub API download of the arm64 `.deb` (works for 1.0.0; the old `v0.x` URL math broke) |
| PIAPRS | Desktop file written under `~/.local` instead of `/run/user/$UID` (missing over SSH) |
| PITERM | Native aarch64 `piQtTermTCP64` + native Qt5 libs |
| QTSOUND | Native aarch64 `piQtSoundModem64` + native Qt5/ALSA/fftw libs |
| REPEAT | SourceForge `/download` URL and `apt-get install ./deb` so dependencies are pulled |
| TQSL | Debian `trustedqsl` (`libdb++-dev` was removed; `libdb5.3++-dev` kept for the source fallback) |
| VARA | Refuses to install on the Pi 5 16K-page kernel; see "Unsupported" |
| VNC | `realvnc-vnc-viewer` from the Raspberry Pi OS repo (the pinned 6.22.826 `.deb` 404s); TigerVNC on plain Debian |
| WSJTX | Finds the `wsjtx-*-linux-aarch64.deb` name used since 3.0 and installs it with apt |
| XASTIR | Debian `xastir` (`libpcre3-dev` removed; set `XASTIR_FROM_SOURCE=1` to build git with `libpcre2-dev`) |
| YAAC | `default-jre` instead of `openjdk-10-dbg`, which no longer exists |

### Works unchanged (upstream installer is fine on Trixie)

| App | Why |
|---|---|
| AX25 | `ax25-tools`, `ax25-apps` exist in Trixie |
| BATT | Downloads `batt-test` from km4ack/pi-scripts (URL still live) |
| DIPOLE | Downloads `dipole` from km4ack/pi-scripts (URL still live) |
| GPREDICT | Debian `gpredict` package |
| GPSUPDATE | Downloads `gpsupdate` from km4ack/pi-scripts (URL still live) |
| PATMENU | `git clone` of patmenu2 plus `yad`/`jq` from apt |
| PIQSO | Debian `pyqso` package |
| SECURITY | km4ack/pi-scripts `security-tools`; its SSE/PTE zip URLs still answer 200 |
| SHOWLOG | Downloads `showlog` from km4ack/pi-scripts (URL still live) |
| XYGRIB | Debian `xygrib` package |
| community/CHECK | km4ack/pi-scripts `checklist-generator` (`yad`, `pandoc` exist) |
| community/DASHBOARD | `git clone` of VA3HDL/hamdashboard; static HTML |
| community/SPOT_POTA | km4ack/pi-scripts `spot-pota` (`yad` exists) |

### Unsupported

| App | Reason |
|---|---|
| PISTATS | W1HKJ's source (`www.w1hkj.com/PI`) is offline and not mirrored. The installer tries the old URLs, then stops with a message. Use `vcgencmd`/`htop` instead. |
| VARA (conditional) | Windows program run via Box86/Box64 + Wine through Pi-Apps. Box86 cannot run on the Pi 5's default 16K-page kernel. Add `kernel=kernel8.img` to `/boot/firmware/config.txt`, reboot, then install. Experimental on Trixie. |

### Still needs armhf multiarch

Only `piBPQConfigGen` (BPQ config generator) is still a 32-bit binary; LinBPQ itself
is the native `pilinbpq64`. If armhf Qt5 libraries cannot be installed, LinBPQ still
runs and `~/linbpq/bpq32.cfg` has to be edited by hand.
