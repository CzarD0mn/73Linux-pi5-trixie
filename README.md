#73Linux (Pi 5 / Trixie fork)

**This copy restores Raspberry Pi support for Raspberry Pi 5 running Debian 13 / Raspberry Pi OS Trixie.** Official 73Linux dropped Pi support in 4.1.9. Read PI5_TRIXIE.md first.

## Description

73 Linux supports Raspberry Pi (aarch64 / armv7l) and x86_64 Debian based systems. You choose which ham radio applications to install.

This is an **unofficial fork**. Original project: [km4ack/73Linux](https://github.com/km4ack/73Linux) by Jason Oleham, KM4ACK.

# Install on a Pi 5 (Trixie)

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git yad jq bc curl wget
sudo raspi-config   # Advanced Options -> Wayland -> X11, then reboot
sudo usermod -aG dialout,tty,plugdev,gpio "$USER"
# log out / reboot

git clone https://github.com/CzarD0mn/73Linux-pi5-trixie.git $HOME/73Linux
bash $HOME/73Linux/73.sh
```

Keep `.pi5-trixie-fork` in the tree so 73.sh does not replace itself with upstream.

# Credits

KM4ACK and 73Linux contributors. This Trixie/Pi 5 compatibility work is unofficial and unsupported by KM4ACK.
