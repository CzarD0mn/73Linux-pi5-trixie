# 73Linux on Raspberry Pi (aarch64) with Arch Linux ARM / Manjaro ARM

This is the **arch-pacman** branch of the unofficial 73Linux Pi fork. It targets
**Arch-based aarch64** systems (Arch Linux ARM, Manjaro ARM, EndeavourOS ARM, ...)
on a Raspberry Pi 5 / CM5 or similar board, and installs every package with
**pacman** (official repos) or **yay** (AUR). It never calls `apt`, `apt-get`,
`apt-cache`, `dpkg` or `aptitude`.

It is **not** for Debian 13 / Raspberry Pi OS Trixie. For that, use the
`trixie-all-apps` branch. `bootstrap.sh`, `73.sh` and `bin/set-enviroment.sh`
read `/etc/os-release` and stop with a message on non-Arch systems
(accepted: `ID=arch, archarm, manjaro, manjaro-arm, endeavouros, garuda, artix,
cachyos`, or `ID_LIKE` containing `arch`).

## Install

```bash
sudo pacman -Syu
sudo pacman -S --needed git base-devel yad jq bc curl wget
# AUR helper (needed for js8call, trustedqsl, direwolf, xastir, cqrlog, ...)
git clone https://aur.archlinux.org/yay.git /tmp/yay && (cd /tmp/yay && makepkg -si --noconfirm)
sudo usermod -aG uucp,lock,audio "$USER"   # serial (uucp) and audio access on Arch
# log out / reboot

git clone -b arch-pacman https://github.com/CzarD0mn/73Linux-pi5-trixie.git $HOME/73Linux-pi5-trixie
bash $HOME/73Linux-pi5-trixie/bootstrap.sh
bash $HOME/73Linux/73.sh
```

Keep `.pi5-trixie-fork` in the tree so 73.sh does not replace itself with upstream.

## Package helper: `bin/arch-pkg.sh`

Replaces `bin/trixie-apt.sh` (deleted; bootstrap removes a leftover copy).

| Function | Purpose |
|---|---|
| `bap_is_arch` / `bap_require_arch` | `/etc/os-release` check; refuse with a message on apt systems |
| `bap_resolve_pkg` | Debian/Trixie name → Arch name (strips `:armhf` and `t64`) |
| `bap_pkg_available` | in sync DB, installed, or visible to `yay -Si` |
| `bap_pkg_install` | `sudo pacman -S --needed --noconfirm` for repo packages, then `yay -S --needed --noconfirm` for the rest. If yay is missing it prints how to install it and fails |
| `bap_pkg_install_available` | same, but skips packages that don't exist |
| `bap_pkg_installed` / `bap_pkg_version` / `bap_pkg_candidate` / `bap_pkg_remove` | `pacman -Q`, `-Si`, `-R` wrappers used by VERSION/REMOVE |
| `bap_download_w1hkj` | W1HKJ source tarball download (w1hkj.org, then SourceForge) |
| `bap_gh_asset_url` / `bap_install_gh_binary` | GitHub release asset download into `/usr/local/bin` |
| `bap_unsupported` | clean "not supported on Arch" message (and yad dialog) |

### Main Debian → Arch mappings

| Debian / Trixie | Arch |
|---|---|
| build-essential | base-devel |
| pkg-config | pkgconf |
| g++ | gcc |
| python3, python3-dev, python3-venv | python |
| python3-pip / python3-setuptools | python-pip / python-setuptools |
| python3-gi(-cairo) | python-gobject |
| python3-gps, gpsd-clients, gpsd-tools, libgps-dev | gpsd |
| python3-tk | tk |
| libfuse2 / libfuse2t64 / fuse | fuse2 |
| libfltk1.3-dev | fltk |
| libjpeg62-turbo-dev / libjpeg-dev | libjpeg-turbo |
| libusb-1.0-0(-dev) | libusb |
| libasound2(t64), libasound2-dev | alsa-lib |
| libudev-dev | systemd-libs |
| portaudio19-dev | portaudio |
| libsndfile1-dev / libsamplerate0-dev / libpulse-dev | libsndfile / libsamplerate / libpulse |
| libqt5core5a, libqt5gui5, libqt5network5, libqt5widgets5 | qt5-base |
| libqt5serialport5 / libqt5multimedia5 | qt5-serialport / qt5-multimedia |
| libfftw3-single3 | fftw |
| libdb++-dev / libdb5.3++-dev | db |
| libwxgtk3.2-dev | wxwidgets-gtk3 |
| libssl-dev / libcurl4-openssl-dev / libexpat1-dev | openssl / curl / expat |
| libpcre3-dev / libpcre2-dev | pcre2 |
| libmotif-dev | openmotif |
| php8.2 / php8.4 | php |
| default-jre / openjdk-*-jre | jre-openjdk |
| librxtx-java | java-rxtx |
| conky / conky-std | conky |
| tigervnc-viewer / realvnc-vnc-viewer | tigervnc |
| lazarus, lcl-gtk2, fpc | lazarus |
| default-mysql-* / libmariadb-dev-compat | mariadb |
| gir1.2-osmgpsmap-1.0 | osm-gps-map |

## App status on Arch aarch64

Not yet run on real hardware. Package names checked against Arch / Arch Linux ARM
and the AUR as of 2026-10-15; whether a package is in the ALARM repos or only the
AUR can change, and `bap_pkg_install` handles both.

| App | How it installs on Arch |
|---|---|
| HAMLIB | `pacman -S hamlib`; source build fallback (`HAMLIB_FROM_SOURCE=1`) |
| FLDIGI, FLAMP, FLMSG, FLNET, FLWRAP | W1HKJ source build, pacman build deps |
| FLRIG | W1HKJ source build; falls back to `flrig` (AUR via yay) |
| WSJTX | `wsjtx` (official repo if built for aarch64, otherwise AUR) — the upstream ARM `.deb` is no longer used |
| JS8 | `js8call` from the AUR (yay) |
| TQSL | `trustedqsl` from the AUR (yay); ARRL source build fallback |
| CQRLOG | `cqrlog` from the AUR; git build with pacman Lazarus fallback |
| XASTIR | `xastir` from the AUR; `XASTIR_FROM_SOURCE=1` builds git |
| DIREWOLF | git source build; falls back to AUR `direwolf` |
| GRIDTRACKER | GridTracker2's official **aarch64 `.pacman`** package via `pacman -U` |
| PAT | `pat_*_linux_arm64.tar.gz` from GitHub into `/usr/local/bin`, writes `pat@.service`; AUR `pat` fallback |
| REPEAT | Arch-independent Python package; deps from pacman, payload unpacked with `bsdtar` (no dpkg), file list kept for REMOVE |
| CHIRP, HAMRS | aarch64 AppImages + `fuse2` |
| CONKY, GPS, EES, YAAC, VNC, GRIDCALC, M0IAX, PIAPRS, GARIM, HAMCLOCK | official-repo packages (conky, gpsd/chrony, php/ghostwriter, jre-openjdk/java-rxtx, tigervnc, ...) |
| ARDOP, ARDOPGUI, PITERM, QTSOUND, BPQ | native aarch64 G8BPQ / pflarue binaries + `qt5-*` |
| GRIDCALC | `wwl` only installed if a package exists; otherwise grid-calc downloads it itself |

### Unsupported on Arch

| App | Reason |
|---|---|
| VARA | Needs Pi-Apps (Box86/Box64 + Wine), which only supports Debian-based systems |
| PISTATS | W1HKJ's source is no longer published (same as the Trixie branch) |
| BPQ Config Generator (`piBPQConfigGen`) | 32-bit armhf only, and Arch ARM aarch64 has no armhf multiarch. LinBPQ itself works; edit `~/linbpq/bpq32.cfg` by hand |

Original project: Jason Oleham, KM4ACK. This fork is unofficial and unsupported by KM4ACK.
