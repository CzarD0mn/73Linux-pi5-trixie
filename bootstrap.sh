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

DEST="$HOME/73Linux"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "Install directory: $DEST"
mkdir -p "$DEST"

if [ ! -d "$DEST/.git" ] && [ ! -f "$DEST/73.sh" ]; then
  echo "Cloning km4ack/73Linux into $DEST"
  git clone https://github.com/km4ack/73Linux.git "$DEST"
fi

echo "Applying Pi 5 / Trixie patches"
mkdir -p "$DEST/bin" "$DEST/app/stable/pi"
cp -a "$HERE/.pi5-trixie-fork" "$DEST/"
cp -a "$HERE/PI5_TRIXIE.md" "$DEST/"
cp -a "$HERE/bin/trixie-apt.sh" "$DEST/bin/"
chmod +x "$DEST/bin/trixie-apt.sh"

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
