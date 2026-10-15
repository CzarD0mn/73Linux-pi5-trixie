#!/bin/bash
# Build the 73Linux install tree in the default user directory: $HOME/73Linux
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run bootstrap.sh as root. Use your normal user account."
  exit 1
fi

if [ -z "${HOME:-}" ] || [ "$HOME" = "/" ] || [ "$HOME" = "/root" ]; then
  echo "HOME is '$HOME'. Refusing to install there."
  echo "Log in as a normal user so HOME is /home/<you>"
  exit 1
fi

# Arch-only branch: refuse Debian / apt systems up front.
if ! grep -qE '^(ID=("?)(arch|archarm|manjaro|manjaro-arm|endeavouros|garuda|artix|cachyos)("?)$|ID_LIKE=.*arch)' /etc/os-release 2>/dev/null; then
  echo "This is the arch-pacman branch of 73Linux-pi5-trixie."
  echo "It only supports Arch-based systems (Arch Linux ARM, Manjaro ARM, ...)"
  echo "and installs with pacman/yay, never apt."
  echo "For Debian / Raspberry Pi OS use the trixie-all-apps branch."
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  echo "git is missing. Install it with: sudo pacman -S --needed git"
  exit 1
fi

DEST="$HOME/73Linux"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "Install directory: $DEST"
mkdir -p "$DEST"

if [ ! -d "$DEST/.git" ] && [ ! -f "$DEST/73.sh" ]; then
  echo "Cloning km4ack/73Linux into $DEST"
  git clone https://github.com/km4ack/73Linux.git "$DEST"
fi

echo "Applying Arch (pacman/yay) patches"
mkdir -p "$DEST/bin" "$DEST/app/stable/pi" "$DEST/app/community/pi"
cp -a "$HERE/.pi5-trixie-fork" "$DEST/"
cp -a "$HERE/ARCH.md" "$DEST/"
cp -a "$HERE/bin/arch-pkg.sh" "$DEST/bin/"
chmod +x "$DEST/bin/arch-pkg.sh"
# Remove the old Debian helper if an earlier Trixie bootstrap left it behind
rm -f "$DEST/bin/trixie-apt.sh"

if [ -f "$HERE/73.sh" ]; then
  cp -a "$HERE/73.sh" "$DEST/73.sh"
  echo "  installed $DEST/73.sh"
fi
chmod +x "$DEST/73.sh"

patch_files=(
  changelog
  bin/set-enviroment.sh
  app/stable/pi/HAMLIB.bapp
  app/stable/pi/CHIRP.bapp
  app/stable/pi/FLDIGI.bapp
  app/stable/pi/FLRIG.bapp
  app/stable/pi/FLAMP.bapp
  app/stable/pi/FLMSG.bapp
  app/stable/pi/FLNET.bapp
  app/stable/pi/FLWRAP.bapp
  app/stable/pi/EES.bapp
  app/stable/pi/PITERM.bapp
  app/stable/pi/QTSOUND.bapp
  app/stable/pi/HAMRS.bapp
  app/stable/pi/ARDOP.bapp
  app/stable/pi/ARDOPGUI.bapp
  app/stable/pi/BPQ.bapp
  app/stable/pi/CONKY.bapp
  app/stable/pi/CQRLOG.bapp
  app/stable/pi/DIREWOLF.bapp
  app/stable/pi/GARIM.bapp
  app/stable/pi/GPS.bapp
  app/stable/pi/GRIDCALC.bapp
  app/stable/pi/GRIDTRACKER.bapp
  app/stable/pi/HAMCLOCK.bapp
  app/stable/pi/JS8.bapp
  app/stable/pi/M0IAX.bapp
  app/stable/pi/PAT.bapp
  app/stable/pi/PIAPRS.bapp
  app/stable/pi/PISTATS.bapp
  app/stable/pi/REPEAT.bapp
  app/stable/pi/TQSL.bapp
  app/stable/pi/VARA.bapp
  app/stable/pi/VNC.bapp
  app/stable/pi/WSJTX.bapp
  app/stable/pi/XASTIR.bapp
  app/stable/pi/YAAC.bapp
)

for rel in "${patch_files[@]}"; do
  if [ -f "$HERE/$rel" ]; then
    mkdir -p "$DEST/$(dirname "$rel")"
    cp -a "$HERE/$rel" "$DEST/$rel"
    echo "  patched $rel"
  fi
done

echo
echo "73Linux is in your user directory:"
echo "  $DEST"
echo "Run (not as root):"
echo "  bash $DEST/73.sh"
