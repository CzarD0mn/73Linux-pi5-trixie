# 73Linux on Raspberry Pi 5 + Debian 13 (Trixie)

Upstream 73Linux (km4ack) dropped Raspberry Pi support in 4.1.9.
This repository is an unofficial patched copy for 64-bit Raspberry Pi OS Trixie on a Pi 5.

## Install on the Pi

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git yad jq bc curl wget
sudo raspi-config   # Advanced Options -> Wayland -> X11, then reboot
sudo usermod -aG dialout,tty,plugdev,gpio,i2c,spi "$USER"
# log out / reboot

git clone https://github.com/CzarD0mn/73Linux-pi5-trixie.git $HOME/73Linux
bash $HOME/73Linux/73.sh
```

Keep `.pi5-trixie-fork` in the tree so 73.sh does not replace itself with upstream.

Original project: Jason Oleham, KM4ACK. This fork is unofficial and unsupported by KM4ACK.
