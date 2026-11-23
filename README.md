# 73Linux — Raspberry Pi 5 / Debian Trixie fork

An **unofficial** fork of [km4ack/73Linux](https://github.com/km4ack/73Linux) that restores Raspberry Pi support for the **Raspberry Pi 5 (and CM5) running Debian 13 / Raspberry Pi OS Trixie**. Official 73Linux dropped Pi support in 4.1.9.

> [!IMPORTANT]
> I am in no way, shape, or form a programmer. This fork was generated with Grok AI by pulling KM4ACK's 73Linux repo and updating the scripts to work on CM5 / Debian Trixie. **Please scrutinize it as much as possible** before relying on it.

## Contents

- [Why this fork](#why-this-fork)
- [Requirements](#requirements)
- [Install](#install)
- [Updating](#updating)
- [Important notes](#important-notes)
- [Further reading](#further-reading)
- [Contributing](#contributing)
- [Credits](#credits)

## Why this fork

KM4ACK moved 73Linux's focus to x86_64 systems and dropped Raspberry Pi support. 73Linux is still great on ARM, though:

- A portable station on the **ClockworkPi uConsole**, paired with a **Xiegu X6200** or **QRP-Labs QMX**
- Quick deployment on any portable ARM device or Pi-based radio go-bag

73Linux lets you choose which ham radio applications to install. It supports Raspberry Pi (aarch64 / armv7l) and x86_64 Debian-based systems.

## Requirements

- Raspberry Pi 5 or CM5 (or a similar aarch64 board)
- 64-bit Raspberry Pi OS Trixie / Debian 13
- A normal user account. **Do not run the installer as root.**

## Install

**1. Update the system and install dependencies**

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git yad jq bc curl wget
```

**2. Switch from Wayland to X11**

```bash
sudo raspi-config   # Advanced Options -> Wayland -> X11, then reboot
```

**3. Add your user to the hardware groups**

```bash
sudo usermod -aG dialout,tty,plugdev,gpio "$USER"
```

Log out or reboot so the group changes take effect.

**4. Clone this fork and run the bootstrap**

```bash
git clone https://github.com/CzarD0mn/73Linux-pi5-trixie.git $HOME/73Linux-pi5-trixie
bash $HOME/73Linux-pi5-trixie/bootstrap.sh
```

`bootstrap.sh` clones official 73Linux into `$HOME/73Linux` (e.g. `/home/pi/73Linux`) and copies this fork's patched files over it.

**5. Run 73Linux**

```bash
bash $HOME/73Linux/73.sh
```

## Updating

```bash
cd ~/73Linux-pi5-trixie
git pull
bash ~/73Linux-pi5-trixie/bootstrap.sh
bash ~/73Linux/73.sh
```

## Important notes

- **Keep `.pi5-trixie-fork` in the tree.** `73.sh` looks for it and skips replacing itself with the upstream version, which would wipe out Pi support.
- Trixie renamed several packages (for example `libfuse2` → `libfuse2t64`). `bin/trixie-apt.sh` handles these fallbacks automatically.

## Further reading

- [PI5_TRIXIE.md](PI5_TRIXIE.md) — Pi 5 / Trixie notes
- [CHANGELOG.fork.md](CHANGELOG.fork.md) — what this fork changes and why

## Contributing

Please fork, optimize, and take this further for yourself and for others building Raspberry Pi–based radio go-bags.

## Credits

Original project: [73Linux](https://github.com/km4ack/73Linux) by Jason Oleham, KM4ACK, and the 73Linux contributors.

This Trixie / Pi 5 compatibility work is unofficial and **not supported by KM4ACK**.
