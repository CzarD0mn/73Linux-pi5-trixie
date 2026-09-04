Patched files live in this directory so they are never executed from `/` or the repo root.

`bootstrap.sh` copies `overlay/73.sh` into `$HOME/73Linux/73.sh`.
Run the installer from that home directory only:

    bash "$HOME/73Linux/73.sh"
