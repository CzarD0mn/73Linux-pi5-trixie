#!/bin/bash
# Clone official 73Linux into $HOME/73Linux and overlay this fork's patches.
# Never install or run from / (root of the filesystem).
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run bootstrap.sh as root. Use your normal user account."
  exit 1
fi

DEST="${1:-$HOME/73Linux}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OVERLAY="$HERE/overlay"

case "$DEST" in
  /|/.|//|/root|/root/*)
    echo "Refusing destination $DEST"
    echo "Install into a user directory such as $HOME/73Linux"
    exit 1
    ;;
esac

# Keep the install tree under the user's home.
if [ "${DEST#"$HOME"/}" = "$DEST" ] && [ "$DEST" != "$HOME/73Linux" ]; then
  echo "Destination must be inside your home directory."
  echo "Using $HOME/73Linux instead of $DEST"
  DEST="$HOME/73Linux"
fi

mkdir -p "$DEST"

if [ ! -d "$DEST/.git" ] && [ ! -f "$DEST/73.sh" ]; then
  echo "Cloning km4ack/73Linux into $DEST"
  git clone https://github.com/km4ack/73Linux.git "$DEST"
fi

echo "Copying Trixie / Pi 5 overlay from $HERE"
mkdir -p "$DEST/bin" "$DEST/app/stable/pi"
cp -a "$HERE/.pi5-trixie-fork" "$DEST/"
cp -a "$HERE/PI5_TRIXIE.md" "$DEST/"
cp -a "$HERE/bin/trixie-apt.sh" "$DEST/bin/"
chmod +x "$DEST/bin/trixie-apt.sh"

if [ -f "$OVERLAY/73.sh" ]; then
  cp -a "$OVERLAY/73.sh" "$DEST/73.sh"
  echo "  overlaid overlay/73.sh -> $DEST/73.sh"
fi
chmod +x "$DEST/73.sh"

overlay_files=(
  changelog
  bin/set-enviroment.sh
  app/stable/pi/HAMLIB.bapp
  app/stable/pi/CHIRP.bapp
  app/stable/pi/FLDIGI.bapp
  app/stable/pi/FLRIG.bapp
  app/stable/pi/EES.bapp
  app/stable/pi/PITERM.bapp
  app/stable/pi/QTSOUND.bapp
  app/stable/pi/HAMRS.bapp
)

for rel in "${overlay_files[@]}"; do
  if [ -f "$OVERLAY/$rel" ]; then
    mkdir -p "$DEST/$(dirname "$rel")"
    cp -a "$OVERLAY/$rel" "$DEST/$rel"
    echo "  overlaid $rel"
  elif [ -f "$HERE/$rel" ]; then
    mkdir -p "$DEST/$(dirname "$rel")"
    cp -a "$HERE/$rel" "$DEST/$rel"
    echo "  overlaid $rel"
  fi
done

echo
echo "Install tree is $DEST"
echo "Run (not as root):"
echo "  bash $DEST/73.sh"
