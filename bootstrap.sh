#!/bin/bash
# Clone official 73Linux and overlay this fork's Pi 5 / Trixie patches.
set -euo pipefail

DEST="${1:-$HOME/73Linux}"
HERE="$(cd "$(dirname "$0")" && pwd)"

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
if [ -f "$DEST/73.sh" ]; then
  chmod +x "$DEST/73.sh"
fi

# Overlay any patched files present in this repo.
# Keep each path on its own line. Do not use backslash continuations.
overlay_files=(
  73.sh
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
  if [ -f "$HERE/$rel" ]; then
    mkdir -p "$DEST/$(dirname "$rel")"
    cp -a "$HERE/$rel" "$DEST/$rel"
    echo "  overlaid $rel"
  fi
done

# If 73.sh from this repo is missing, inject the fork guard + helper source.
if [ -f "$DEST/73.sh" ] && ! grep -q 'pi5-trixie-fork' "$DEST/73.sh"; then
  python3 - "$DEST/73.sh" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
t = p.read_text()

needle = "export BAPDIR\n"
insert = (
    "export BAPDIR\n\n"
    "# Trixie / Pi 5 package name helpers\n"
    'if [ -f "${BAPDIR}/bin/trixie-apt.sh" ]; then\n'
    '\tsource "${BAPDIR}/bin/trixie-apt.sh"\n'
    "\texport -f bap_pkg_available bap_resolve_pkg bap_apt_install bap_download_w1hkj 2>/dev/null || true\n"
    "fi\n"
)
if needle in t:
    t = t.replace(needle, insert, 1)

guard = (
    'echo "Checking for 73 Linux Updates"\n'
    'echo "#############################"\n'
    "LATEST="
)
repl = (
    'echo "Checking for 73 Linux Updates"\n'
    'echo "#############################"\n'
    'if [ -f "${BAPDIR}/.pi5-trixie-fork" ]; then\n'
    '\techo "Pi 5 / Trixie fork detected - skipping upstream self-replace"\n'
    "\tLATEST=0\n"
    "\tCURRENT=1\n"
    "else\n"
    "LATEST="
)
if guard in t:
    t = t.replace(guard, repl, 1)
    old = "CURRENT=$(grep version ${BAPDIR}/changelog | head -1 | sed 's/version=//')\n"
    new = old + "fi\n"
    t = t.replace(old, new, 1)

p.write_text(t)
print("patched 73.sh in place")
PY
fi

echo
echo "Ready. Run:"
echo "  bash $DEST/73.sh"
