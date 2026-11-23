# 73Linux on Raspberry Pi 5 + Debian 13 (Trixie)

Upstream 73Linux (KM4ACK) dropped Raspberry Pi support in 4.1.9.
This repository is an unofficial patched copy for 64-bit Raspberry Pi OS Trixie
on a Raspberry Pi 5 (or CM5).

For full install steps, see the [README](README.md#install).

## Quick install

Run these as your normal user, **not as root**.

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git yad jq bc curl wget
sudo raspi-config   # Advanced Options -> Wayland -> X11, then reboot
sudo usermod -aG dialout,tty,plugdev,gpio "$USER"
# log out / reboot

git clone https://github.com/CzarD0mn/73Linux-pi5-trixie.git $HOME/73Linux-pi5-trixie
bash $HOME/73Linux-pi5-trixie/bootstrap.sh
bash $HOME/73Linux/73.sh
```

## How the install is laid out

| Folder | What it is |
|---|---|
| `~/73Linux-pi5-trixie` | This fork: the patched files |
| `~/73Linux` | Official 73Linux, with this fork's patches copied over it by `bootstrap.sh`. Run 73Linux from here. |

## Keep `.pi5-trixie-fork`

Don't delete `.pi5-trixie-fork`. `73.sh` looks for it and skips replacing itself
with the upstream version, which would remove Pi support.

## More information

See [CHANGELOG.fork.md](CHANGELOG.fork.md) for what this fork changes and why.

Original project: Jason Oleham, KM4ACK. This fork is unofficial and unsupported by KM4ACK.
