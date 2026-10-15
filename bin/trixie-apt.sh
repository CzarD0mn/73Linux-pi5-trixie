#! /bin/bash
# Install packages with Debian 13 (Trixie) name fallbacks.
bap_pkg_available() {
	local p
	for p in "$@"; do
		apt-cache show "$p" >/dev/null 2>&1 || return 1
	done
}

bap_resolve_pkg() {
	local pkg="$1"
	case "$pkg" in
		libfuse2)
			if bap_pkg_available libfuse2t64; then echo libfuse2t64
			elif bap_pkg_available libfuse2; then echo libfuse2
			else echo libfuse2
			fi
			;;
		libasound2)
			if bap_pkg_available libasound2t64; then echo libasound2t64
			else echo libasound2
			fi
			;;
		libasound2:armhf)
			if bap_pkg_available libasound2t64:armhf; then echo libasound2t64:armhf
			else echo libasound2:armhf
			fi
			;;
		libgtk-3-0)
			if bap_pkg_available libgtk-3-0t64; then echo libgtk-3-0t64
			else echo libgtk-3-0
			fi
			;;
		libgtk-3-0:armhf)
			if bap_pkg_available libgtk-3-0t64:armhf; then echo libgtk-3-0t64:armhf
			else echo libgtk-3-0:armhf
			fi
			;;
		libglib2.0-0)
			if bap_pkg_available libglib2.0-0t64; then echo libglib2.0-0t64
			else echo libglib2.0-0
			fi
			;;
		libglib2.0-0:armhf)
			if bap_pkg_available libglib2.0-0t64:armhf; then echo libglib2.0-0t64:armhf
			else echo libglib2.0-0:armhf
			fi
			;;
		php8.2)
			if bap_pkg_available php8.4; then echo php8.4
			elif bap_pkg_available php8.3; then echo php8.3
			elif bap_pkg_available php8.2; then echo php8.2
			else echo php
			fi
			;;
		libqt5core5a|libqt5core5a:armhf)
			if bap_pkg_available "libqt5core5t64${pkg#libqt5core5a}"; then echo "libqt5core5t64${pkg#libqt5core5a}"
			else echo "$pkg"
			fi
			;;
		swig4.0)
			if bap_pkg_available swig; then echo swig
			else echo swig4.0
			fi
			;;
		conky)
			# conky is a virtual package on Trixie (conky-std / conky-cli / conky-all)
			if bap_pkg_available conky-std; then echo conky-std
			else echo conky
			fi
			;;
		libpcre3-dev)
			if bap_pkg_available libpcre3-dev; then echo libpcre3-dev
			else echo libpcre2-dev
			fi
			;;
		libdb++-dev)
			if bap_pkg_available libdb++-dev; then echo libdb++-dev
			else echo libdb5.3++-dev
			fi
			;;
		*)
			# openjdk-N-jre/jdk/dbg: Trixie has 21/25; fall back to default-jre.
			case "$pkg" in
				openjdk-*-jre|openjdk-*-jdk|openjdk-*-dbg)
					if bap_pkg_available "$pkg"; then echo "$pkg"
					else echo default-jre
					fi
					return
					;;
			esac
			# Generic 64-bit time_t rename (libfooN -> libfooNt64), keeps :arch suffix.
			if ! bap_pkg_available "$pkg"; then
				local base="${pkg%%:*}" arch=""
				[ "$base" != "$pkg" ] && arch=":${pkg#*:}"
				if bap_pkg_available "${base}t64${arch}"; then
					echo "${base}t64${arch}"
					return
				fi
			fi
			echo "$pkg"
			;;
	esac
}

bap_apt_install() {
	local resolved=()
	local p
	for p in "$@"; do
		resolved+=("$(bap_resolve_pkg "$p")")
	done
	sudo apt-get install -y "${resolved[@]}"
}

bap_w1hkj_tarball_name() {
	local name="$1"
	local page host tarball
	for host in \
		"https://www.w1hkj.org/files/${name}/" \
		"https://www.w1hkj.com/files/${name}/"
	do
		page=$(curl -fsSL --max-time 20 "$host" 2>/dev/null || true)
		tarball=$(echo "$page" | grep -oE "${name}-[0-9]+(\.[0-9]+)*\.tar\.gz" | sort -V | tail -1)
		if [ -n "$tarball" ]; then
			echo "${host}${tarball} ${tarball}"
			return 0
		fi
	done
	tarball=$(curl -fsSL --max-time 20 "https://sourceforge.net/projects/fldigi/files/${name}/" 2>/dev/null \
		| grep -oE "${name}-[0-9]+(\.[0-9]+)*\.tar\.gz" | sort -V | tail -1)
	if [ -n "$tarball" ]; then
		echo "https://sourceforge.net/projects/fldigi/files/${name}/${tarball}/download ${tarball}"
		return 0
	fi
	return 1
}

bap_download_w1hkj() {
	local name="$1"
	local dest="${2:-.}"
	local info url tarball
	mkdir -p "$dest"
	info=$(bap_w1hkj_tarball_name "$name") || {
		echo "ERROR: could not locate source for $name" >&2
		return 1
	}
	url=${info% *}
	tarball=${info##* }
	# Only the filename goes to stdout. wget noise stays on stderr.
	if ! wget -q --tries 2 --connect-timeout=60 -O "${dest}/${tarball}" "$url"; then
		echo "ERROR: download failed for $url" >&2
		rm -f "${dest}/${tarball}"
		return 1
	fi
	if ! gzip -t "${dest}/${tarball}" 2>/dev/null; then
		echo "ERROR: ${tarball} is not a valid gzip archive" >&2
		rm -f "${dest}/${tarball}"
		return 1
	fi
	echo "$tarball"
}

# Like bap_apt_install, but drops packages that do not exist in the
# configured repositories (with a warning) instead of failing the whole set.
bap_apt_install_available() {
	local resolved=() p r
	for p in "$@"; do
		r=$(bap_resolve_pkg "$p")
		if apt-cache show "$r" >/dev/null 2>&1; then
			resolved+=("$r")
		else
			echo "WARNING: package $p ($r) not available on this release; skipping" >&2
		fi
	done
	[ ${#resolved[@]} -eq 0 ] && return 0
	sudo apt-get install -y "${resolved[@]}"
}

# True on a 64-bit ARM userland (Pi 5 / CM5 running arm64 Raspberry Pi OS).
bap_is_arm64() {
	[ "$(dpkg --print-architecture 2>/dev/null || uname -m)" = arm64 ] || [ "$(uname -m)" = aarch64 ] \
		&& [ "$(getconf LONG_BIT)" = 64 ]
}

# Enable armhf multiarch once (for the few 32-bit-only binaries left).
bap_enable_armhf() {
	if ! dpkg --print-foreign-architectures | grep -qx armhf; then
		sudo dpkg --add-architecture armhf
		sudo apt-get update
	fi
}

# Install a local .deb and pull its dependencies in one step.
bap_install_deb() {
	local deb="$1"
	case "$deb" in /*) ;; *) deb="$(pwd)/$deb" ;; esac
	sudo apt-get install -y "$deb"
}

# Print the download URL of the newest GitHub release asset matching an ERE.
# Usage: bap_gh_asset_url owner/repo 'linux_arm64\.deb$'
bap_gh_asset_url() {
	curl -fsSL --max-time 30 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
		| grep -oE '"browser_download_url": *"[^"]+"' | sed 's/.*: *"//;s/"$//' \
		| grep -E "$2" | head -1
}

# Explain why an app cannot be installed on this system and fail cleanly.
bap_unsupported() {
	local app="$1"; shift
	echo "##########################################################" >&2
	echo "# $app is not supported on Raspberry Pi 5 / Trixie (arm64)" >&2
	local line
	for line in "$@"; do echo "# $line" >&2; done
	echo "# See PI5_TRIXIE.md in the 73Linux-pi5-trixie fork." >&2
	echo "##########################################################" >&2
	if hash yad 2>/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
		yad --center --title="$app not supported" --button=OK \
			--text="$app is not supported on Raspberry Pi 5 / Trixie.\n\n$(printf '%s\n' "$@")" 2>/dev/null || true
	fi
	return 1
}
