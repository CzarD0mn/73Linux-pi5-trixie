# 73Linux Pi 5 / Trixie fork changelog

Unofficial fork of [km4ack/73Linux](https://github.com/km4ack/73Linux) 4.1.13.
First line of `changelog` is `version=4.1.14` so 73.sh can read a version string.

## testing — 2026-09-04 (security hardening, not merged to main)

- `bin/pins.sh` pins km4ack/73Linux to commit `c9a99dafb297387a1713e99dc1e6a3f1963b73fb`.
- `bootstrap.sh` clones that SHA instead of floating master.
- `73.sh` fails closed if `.pi5-trixie-fork` is missing (no `rm -rf` / clone).
- `73.sh` no longer sparse-checkouts `/app` from km4ack master.
- CHIRP uses GitHub Releases API + URL allowlist (needs `jq`).
- HAMLIB downloads the pinned version only; gzip-checked; optional SHA256 file.
- Safer source-dir cleanup (`find` + prefix, not unquoted `grep`/`rm -rf`).
- Optional checksums: `$BAPDIR/data/checksums/<file>.sha256`.

## 4.1.14 — 2026-09-04

### Why this fork exists
- Upstream dropped Raspberry Pi support in 4.1.9 and targets x86_64.
- Goal: run the installer on Raspberry Pi 5 (and CM5 / similar aarch64 boards)
  under Debian 13 / Raspberry Pi OS Trixie.

Original project: Jason Oleham, KM4ACK. This fork is unofficial and
unsupported by KM4ACK.
