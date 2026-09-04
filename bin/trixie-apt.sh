#! /bin/bash
# Install packages with Debian 13 (Trixie) name fallbacks.
bap_pkg_available() {
	apt-cache show "$1" >/dev/null 2>&1
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
		swig4.0)
			if bap_pkg_available swig; then echo swig
			else echo swig4.0
			fi
			;;
		*)
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
