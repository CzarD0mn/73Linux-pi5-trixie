#! /bin/bash
# Arch Linux / Arch Linux ARM / Manjaro ARM package helpers for 73Linux.
# Prefer pacman for official repos; fall back to yay for AUR packages.
# Never calls apt, apt-get, dpkg, or aptitude.

bap_is_arch() {
	[ -f /etc/os-release ] || return 1
	# shellcheck disable=SC1091
	. /etc/os-release
	case "${ID:-}" in
		arch|archarm|manjaro|endeavouros|garuda|artix|cachyos|arco|archcraft) return 0 ;;
	esac
	case " ${ID_LIKE:-} " in
		*" arch "*|*" archlinux "*) return 0 ;;
	esac
	return 1
}

bap_require_arch() {
	if bap_is_arch; then
		return 0
	fi
	echo "##########################################################" >&2
	echo "# 73Linux arch-pacman branch requires an Arch-based OS" >&2
	echo "# (Arch Linux ARM, Manjaro ARM, EndeavourOS, etc.)." >&2
	echo "# Detected: $(grep -E '^(NAME|ID)=' /etc/os-release 2>/dev/null | tr '\n' ' ')" >&2
	echo "# This branch never calls apt. Use the trixie-all-apps" >&2
	echo "# branch for Debian / Raspberry Pi OS." >&2
	echo "##########################################################" >&2
	if hash yad 2>/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
		yad --center --title="Arch required" --button=OK \
			--text="This 73Linux build requires Arch Linux (or Arch ARM / Manjaro ARM).\nIt does not use apt." 2>/dev/null || true
	fi
	return 1
}

# True when a package exists in sync DBs (official) or is already installed.
bap_pkg_available() {
	local p
	command -v pacman >/dev/null 2>&1 || return 1
	for p in "$@"; do
		p=$(bap_resolve_pkg "$p")
		[ -n "$p" ] || return 1
		if pacman -Si -- "$p" >/dev/null 2>&1; then
			continue
		fi
		if pacman -Q -- "$p" >/dev/null 2>&1; then
			continue
		fi
		# AUR: only claim available when yay can see it
		if command -v yay >/dev/null 2>&1 && yay -Si -- "$p" >/dev/null 2>&1; then
			continue
		fi
		return 1
	done
	return 0
}

bap_pkg_installed() {
	local p
	for p in "$@"; do
		p=$(bap_resolve_pkg "$p")
		pacman -Q -- "$p" >/dev/null 2>&1 || return 1
	done
	return 0
}

bap_pkg_version() {
	local p
	p=$(bap_resolve_pkg "$1")
	pacman -Q -- "$p" 2>/dev/null | awk '{print $2}' | sed 's/^[0-9]*://;s/-[0-9.]*$//'
}

# Map Debian-ish / Trixie package names to Arch package names.
# Prints empty string when the Debian name has no Arch equivalent (caller should skip).
bap_resolve_pkg() {
	local pkg="$1"
	# Drop Debian multiarch suffixes (:armhf, :arm64, :amd64)
	pkg="${pkg%%:*}"
	# Drop t64 time_t renames used on Trixie
	pkg="${pkg%t64}"

	case "$pkg" in
		# Meta / build
		build-essential) echo base-devel ;;
		pkg-config) echo pkgconf ;;
		ca-certificates) echo ca-certificates ;;
		autoconf|automake|cmake|make|git|curl|wget|unzip|texinfo|bc|jq|yad|ruby|swig|chrony)
			echo "$pkg" ;;
		g++) echo gcc ;;
		python3) echo python ;;
		python3-dev|python3-devel) echo python ;;
		python3-setuptools) echo python-setuptools ;;
		python3-pip) echo python-pip ;;
		python3-venv) echo python ;;
		python3-tk) echo tk ;;
		python3-gi|python3-gi-cairo) echo python-gobject ;;
		python3-gps) echo gpsd ;;

		# FUSE / AppImage
		libfuse2|fuse) echo fuse2 ;;
		fuse3) echo fuse3 ;;

		# Core libs (runtime and -dev collapse on Arch)
		libusb-1.0-0|libusb-1.0-0-dev) echo libusb ;;
		libxml2-dev) echo libxml2 ;;
		zlib1g|zlib1g-dev) echo zlib ;;
		libfltk1.3-dev|libfltk1.3) echo fltk ;;
		libjpeg62-turbo-dev|libjpeg62-dev|libjpeg9-dev|libjpeg-dev) echo libjpeg-turbo ;;
		libxft-dev) echo libxft ;;
		libxinerama-dev) echo libxinerama ;;
		libxcursor-dev) echo libxcursor ;;
		libx11-dev) echo libx11 ;;
		libsndfile1-dev) echo libsndfile ;;
		libsamplerate0-dev) echo libsamplerate ;;
		portaudio19-dev) echo portaudio ;;
		libpulse-dev) echo libpulse ;;
		libudev-dev) echo systemd-libs ;;
		libasound2|libasound2-dev) echo alsa-lib ;;
		libavahi-client-dev) echo avahi ;;
		libexpat1-dev) echo expat ;;
		libssl-dev) echo openssl ;;
		libdb++-dev|libdb5.3++-dev) echo db ;;
		libcurl4-openssl-dev) echo curl ;;
		libwxgtk3.2-dev|libwxgtk3.0-gtk3-dev) echo wxwidgets-gtk3 ;;
		libsqlite3-dev|sqlite3) echo sqlite ;;
		libgtk-3-0) echo gtk3 ;;
		libglib2.0-0) echo glib2 ;;
		libnss3) echo nss ;;
		libgbm1) echo mesa ;;
		libxss1) echo libxss ;;
		libxtst6) echo libxtst ;;
		libnotify4) echo libnotify ;;
		libdbus-1-3) echo dbus ;;
		libgps-dev) echo gpsd ;;
		libpcre3-dev|libpcre2-dev) echo pcre2 ;;
		libmotif-dev) echo openmotif ;;
		graphicsmagick) echo graphicsmagick ;;
		xorg-dev) echo xorg-server-devel ;;

		# Qt5
		libqt5core5a|libqt5gui5|libqt5network5|libqt5widgets5) echo qt5-base ;;
		libqt5serialport5) echo qt5-serialport ;;
		libqt5multimedia5-plugins) echo qt5-multimedia ;;
		libasound2-plugins) echo alsa-plugins ;;
		libpulse0) echo libpulse ;;
		libshp-dev|shapelib) echo shapelib ;;
		libproj-dev) echo proj ;;
		libdb-dev) echo db ;;
		python-dev-is-python3) echo python ;;
		libax25-dev) echo libax25 ;;
		libwebp-dev) echo libwebp ;;
		libgraphicsmagick1-dev) echo graphicsmagick ;;
		festival-dev) echo festival ;;
		libqt5multimedia5) echo qt5-multimedia ;;
		libfftw3-single3|libfftw3-dev) echo fftw ;;

		# PHP / Java
		php8.2|php8.3|php8.4|php) echo php ;;
		default-jre|openjdk-*-jre|openjdk-*-jdk|openjdk-*-dbg) echo jre-openjdk ;;
		librxtx-java) echo java-rxtx ;;

		# Apps / ham
		conky|conky-std|conky-all|conky-cli) echo conky ;;
		gpsd-tools|gpsd-clients) echo gpsd ;;
		gpsd) echo gpsd ;;
		ghostwriter) echo ghostwriter ;;
		hamlib) echo hamlib ;;
		direwolf) echo direwolf ;;
		js8call) echo js8call ;;
		trustedqsl|tqsl) echo trustedqsl ;;
		xastir) echo xastir ;;
		cqrlog) echo cqrlog ;;
		flrig) echo flrig ;;
		wsjtx) echo wsjtx ;;
		wwl) echo wwl ;;
		tigervnc-viewer|tigervnc) echo tigervnc ;;
		realvnc-vnc-viewer) echo tigervnc ;;
		swig4.0) echo swig ;;

		# Lazarus / FPC (CQRLOG source path)
		lazarus|lcl-gtk2|fpc|fp-units-misc) echo lazarus ;;
		libmariadb-dev-compat|default-mysql-client-core|default-mysql-server|default-mysql-server-core)
			echo mariadb ;;
		libnetpbm11) echo netpbm ;;

		# Python GIS / maps (REPEAT)
		gir1.2-osmgpsmap-1.0|libosmgpsmap-1.0-1) echo osm-gps-map ;;
		gir1.2-geoclue-2.0) echo geoclue ;;
		xdg-utils) echo xdg-utils ;;

		# Repeater-start has no Arch package
		repeater-start) echo "" ;;


		# Anything else: strip common Debian -dev suffix and hope
		*-dev)
			local base="${pkg%-dev}"
			base="${base#lib}"
			echo "$base"
			;;
		*)
			echo "$pkg"
			;;
	esac
}

bap_need_yay_msg() {
	echo "##########################################################" >&2
	echo "# Package(s) need the AUR helper 'yay', which is missing." >&2
	echo "# Install yay once, then re-run 73Linux:" >&2
	echo "#   sudo pacman -S --needed --noconfirm base-devel git" >&2
	echo "#   git clone https://aur.archlinux.org/yay.git /tmp/yay" >&2
	echo "#   cd /tmp/yay && makepkg -si --noconfirm" >&2
	echo "# Or: sudo pacman -S --needed yay   # if your repo ships it" >&2
	echo "##########################################################" >&2
}

# Install packages: pacman for official, yay for AUR. Skips empties.
bap_pkg_install() {
	local official=() aur=() p r
	bap_require_arch || return 1
	for p in "$@"; do
		[ -n "$p" ] || continue
		r=$(bap_resolve_pkg "$p")
		[ -n "$r" ] || { echo "WARNING: no Arch mapping for $p; skipping" >&2; continue; }
		if pacman -Q -- "$r" >/dev/null 2>&1; then
			continue
		fi
		if pacman -Si -- "$r" >/dev/null 2>&1; then
			official+=("$r")
		else
			aur+=("$r")
		fi
	done
	# Deduplicate
	if [ ${#official[@]} -gt 0 ]; then
		# shellcheck disable=SC2207
		official=($(printf '%s\n' "${official[@]}" | awk '!a[$0]++'))
		sudo pacman -S --needed --noconfirm "${official[@]}" || return 1
	fi
	if [ ${#aur[@]} -gt 0 ]; then
		# shellcheck disable=SC2207
		aur=($(printf '%s\n' "${aur[@]}" | awk '!a[$0]++'))
		if ! command -v yay >/dev/null 2>&1; then
			bap_need_yay_msg
			echo "Needed AUR packages: ${aur[*]}" >&2
			return 1
		fi
		yay -S --needed --noconfirm "${aur[@]}" || return 1
	fi
	return 0
}

# Like bap_pkg_install, but never fails the whole set for missing packages.
bap_pkg_install_available() {
	local keep=() p r
	bap_require_arch || return 1
	for p in "$@"; do
		r=$(bap_resolve_pkg "$p")
		[ -n "$r" ] || continue
		if pacman -Si -- "$r" >/dev/null 2>&1 || pacman -Q -- "$r" >/dev/null 2>&1; then
			keep+=("$r")
		elif command -v yay >/dev/null 2>&1 && yay -Si -- "$r" >/dev/null 2>&1; then
			keep+=("$r")
		else
			echo "WARNING: package $p ($r) not available; skipping" >&2
		fi
	done
	[ ${#keep[@]} -eq 0 ] && return 0
	bap_pkg_install "${keep[@]}"
}

bap_pkg_remove() {
	local p r
	for p in "$@"; do
		r=$(bap_resolve_pkg "$p")
		[ -n "$r" ] || continue
		if pacman -Q -- "$r" >/dev/null 2>&1; then
			sudo pacman -R --noconfirm "$r" 2>/dev/null || \
				sudo pacman -Rns --noconfirm "$r" 2>/dev/null || true
		fi
	done
	return 0
}



# Newest version in the sync DB / AUR (no pkgrel).
bap_pkg_candidate() {
	local p v
	p=$(bap_resolve_pkg "$1")
	v=$(pacman -Si -- "$p" 2>/dev/null | awk '/^Version/{print $3; exit}')
	if [ -z "$v" ] && command -v yay >/dev/null 2>&1; then
		v=$(yay -Si --aur -- "$p" 2>/dev/null | awk '/^Version/{print $3; exit}')
	fi
	echo "$v" | sed 's/^[0-9]*://;s/-[0-9.]*$//'
}

bap_is_arm64() {
	local m
	m=$(uname -m)
	[ "$m" = aarch64 ] || [ "$m" = arm64 ]
}

# Multiarch armhf is a Debian concept; no-op on Arch with a warning.
bap_enable_armhf() {
	echo "WARNING: armhf multiarch is not supported on Arch; skipping" >&2
	return 1
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

bap_gh_asset_url() {
	curl -fsSL --max-time 30 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
		| grep -oE '"browser_download_url": *"[^"]+"' | sed 's/.*: *"//;s/"$//' \
		| grep -E "$2" | head -1
}

bap_unsupported() {
	local app="$1"; shift
	echo "##########################################################" >&2
	echo "# $app is not supported on Arch Linux ARM (aarch64)" >&2
	local line
	for line in "$@"; do echo "# $line" >&2; done
	echo "# See ARCH.md in the 73Linux-pi5-trixie arch-pacman branch." >&2
	echo "##########################################################" >&2
	if hash yad 2>/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
		yad --center --title="$app not supported" --button=OK \
			--text="$app is not supported on Arch Linux ARM.\n\n$(printf '%s\n' "$@")" 2>/dev/null || true
	fi
	return 1
}

# Install a GitHub release binary (tar.gz / zip / plain binary) into /usr/local/bin.
# Usage: bap_install_gh_binary owner/repo 'linux_arm64\.tar\.gz$' [binname]
bap_install_gh_binary() {
	local repo="$1" pattern="$2" binname="${3:-}"
	local url file dest
	url=$(bap_gh_asset_url "$repo" "$pattern") || true
	[ -n "$url" ] || return 1
	dest="${BUILDDIR:-/tmp}/bap-gh-$$"
	mkdir -p "$dest"
	file="${url##*/}"
	wget -q --tries 2 --connect-timeout=60 -O "${dest}/${file}" "$url" || { rm -rf "$dest"; return 1; }
	case "$file" in
		*.tar.gz|*.tgz)
			tar -xzf "${dest}/${file}" -C "$dest" || { rm -rf "$dest"; return 1; }
			;;
		*.zip)
			unzip -q "${dest}/${file}" -d "$dest" || { rm -rf "$dest"; return 1; }
			;;
		*)
			chmod +x "${dest}/${file}"
			[ -n "$binname" ] || binname=$(echo "$file" | sed 's/_linux.*//;s/-linux.*//;s/\.AppImage//')
			sudo install -m 755 "${dest}/${file}" "/usr/local/bin/${binname}"
			rm -rf "$dest"
			return 0
			;;
	esac
	local found=""
	[ -n "$binname" ] && found=$(find "$dest" -type f -name "$binname" | head -1)
	if [ -n "$found" ]; then
		sudo install -m 755 "$found" "/usr/local/bin/${binname}"
	else
		# Install first executable found
		local exe
		exe=$(find "$dest" -type f -executable ! -name '*.sh' | head -1)
		[ -n "$exe" ] || { rm -rf "$dest"; return 1; }
		[ -n "$binname" ] || binname=$(basename "$exe")
		sudo install -m 755 "$exe" "/usr/local/bin/${binname}"
	fi
	rm -rf "$dest"
	return 0
}
