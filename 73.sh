#! /bin/bash

# Localization can do weird things.
# See https://github.com/km4ack/73Linux/issues/144 and https://github.com/km4ack/73Linux/issues/71.
export LC_ALL=C

echo "#######################################"
echo "#        Welcome to 73 Linux          #"
echo "#######################################"

#variables
BAPDIR="$(cd "$(dirname "$0")" && pwd)"
BAPSYSINFO=${BAPDIR}/cache/cpu.bap
BAPPVER=$(head -1 "${BAPDIR}/changelog" | sed 's/version=//')
LOGO=${BAPDIR}/data/logo.png
TEMPCRON=/run/user/$UID/tempcron.txt

APPLIST=${BAPDIR}/cache/app-list.bap
APPPATH=${BAPDIR}/app/stable/
BAPINSTALL=${BAPDIR}/cache/install-path.bap
BUILDDIR=$HOME/.bap-source-files

export BUILDDIR
export LOGO
export BAPDIR

if [ -f "${BAPDIR}/bin/pins.sh" ]; then
	# shellcheck disable=SC1091
	source "${BAPDIR}/bin/pins.sh"
fi

# Trixie / Pi 5 package name helpers
if [ -f "${BAPDIR}/bin/trixie-apt.sh" ]; then
	# shellcheck disable=SC1091
	source "${BAPDIR}/bin/trixie-apt.sh"
	export -f bap_pkg_available bap_resolve_pkg bap_apt_install bap_download_w1hkj 2>/dev/null || true
fi

if [ ! -d "${BAPDIR}/cache" ]; then
	mkdir "${BAPDIR}/cache"
fi

echo "#############################"
echo "Checking for 73 Linux Updates"
echo "#############################"
# Never self-replace this fork with unpinned upstream.
if [ ! -f "${BAPDIR}/.pi5-trixie-fork" ]; then
	echo "ERROR: missing .pi5-trixie-fork marker."
	echo "Refusing to fetch or replace the install tree from upstream."
	echo "Restore the marker file from the Pi 5 / Trixie fork and re-run."
	exit 1
fi
echo "Pi 5 / Trixie fork detected — skipping upstream self-replace and /app pull"
LATEST=0
CURRENT=1

echo "73 Linux fork in use. Version ${BAPPVER} (upstream app pull disabled)"

cd "${BAPDIR}"

#####################################
#	Verify not run as root
#####################################
if [ "$(whoami)" = 'root' ]; then
	echo "ROOT DETECTED. Do not run 73.sh as root or with sudo."
	if hash yad 2>/dev/null; then
		yad --form --width=500 --text-align=center --center --title="73 Linux" --text-align=center \
			--image "${LOGO}" --window-icon="${LOGO}" --image-on-top --separator="|" --item-separator="|" \
			--text="<b>ROOT DETECTED</b>\rDon't run this script as root. Restart without sudo" \
			--button=gtk-close
	fi
	exit 1
fi

echo "#######################################"
echo "#  Updating repository & verifying    #"
echo "#  a few needed items needed before   #"
echo "#  we begin.                          #"
echo "#  Package installs may ask for sudo. #"
echo "#  set-enviroment.sh does not use it. #"
echo "#######################################"
if hash sudo 2>/dev/null; then
	sudo apt update
	sudo apt install -y curl wget ca-certificates build-essential cmake pkg-config \
		python3-dev python3-setuptools python3-pip python3-venv fuse3 || true
	if ! hash yad 2>/dev/null; then
		sudo apt install -y yad
	fi
	if ! hash jq 2>/dev/null; then
		sudo apt install -y jq
	fi
	if ! hash bc >/dev/null; then
		sudo apt install -y bc
	fi
	if ! hash git >/dev/null; then
		sudo apt install -y git
	fi
else
	echo "sudo is not available; skipping package installs."
	echo "Install yad jq bc git curl wget yourself if they are missing."
fi

mkdir -p "$HOME/.config"
touch "$HOME/.config/KM4ACK"

#first run? welcome!
if [ ! -f "$BAPSYSINFO" ]; then
    
    if [ ! -f "${BAPDIR}/app/stable/autohotspot" ]; then
        echo -e "\n Missing important stuff. Can't continue. "
        echo "Run bootstrap.sh from the fork so the pinned km4ack tree is present."
        exit 1
    fi

    mkdir -p "${HOME}/.bap-source-files"

    N0CALL=$(yad --form --width=420 --text-align=center --title="73 Linux" --center \
        --title="Amature Radio Callsign Required" --center --image="$LOGO" \
        --field="Call Sign" \
        --field="<b>Required</b>":LBL)

    TMPCALL=$(echo "${N0CALL^^}" | sed 's/||//' | awk '{gsub(/[^[:alnum:][:space:]]/,"?")} 1')

    if echo "$TMPCALL" | grep -q "?";then
        echo -e "\n ERROR: CRITICAL: valid call to operate (no SSID) $TMPCALL QRZ?"
        exit 1
    fi

    if [ "$N0CALL" = "||" ] || [ -z "$N0CALL" ]; then
        echo -e "\n ERROR: CRITICAL: need a radio call to operate, nothing heard QRZ?"
        exit 1
    else
        MYCALL=$TMPCALL
        BAPCALL=$TMPCALL
        touch "${BAPDIR}/MYCALL.${MYCALL}"
        touch "${BAPDIR}/cache/MYCALL.${MYCALL}"
        echo "###################################"
        echo "#Registered $MYCALL to this host"
        echo "###################################"
        wait
    fi

    if [ -f "${BAPDIR}/bin/set-enviroment.sh" ]; then
        echo "###################################"
        echo "#Detected New System for Install"
        echo "###################################"
        echo -e "Hostname - $(hostname -s)"
        "${BAPDIR}/bin/set-enviroment.sh"
    else
            echo -e "\n ERROR: CRITICAL: check integrity of package."
            exit 1
    fi

    yad --form --width=420 --height=200 --fixed --center --title="Welcome ${MYCALL}!" --image="$LOGO"  \
    --image-on-top --text-align=fill --button=gtk-ok --text="\n          <b>${MYCALL} DE KM4ACK!</b>\r        Welcome to\r
                    <b>73 Linux</b>\n
        Build a Pi on Steroids!\n
            -A full build can take up to 4 hours!
	    -Possibly more on a Pi 3
	    -Press ok to scan the system
	     and begin the build process"

    wait

else
	"${BAPDIR}/bin/config.sh"
fi

COMMUNITY_CK=$(ls -a "${BAPDIR}/cache/" | grep -F .community || true)
if [ -z "$COMMUNITY_CK" ]; then
	echo "Community apps excluded"
else
	echo "Community Apps included"
	rm -f "${BAPDIR}/cache/.community"
fi

BAPARCH=$(sed '1q;d' "$BAPSYSINFO")
BAPCORE=$(sed '2q;d' "$BAPSYSINFO")
BAPCPU=$(sed '3q;d' "$BAPSYSINFO")
BAPDIST=$(sed '4q;d' "$BAPSYSINFO")
BAPSRC="${HOME}/.bap-source-files"
echo "$BAPDIR" > "$BAPINSTALL"
BAPCALL=$(ls "${BAPDIR}/cache" | grep MYCALL.* | sed 's/MYCALL.//' | head -1)
MYCALL=$BAPCALL
CALL=$BAPCALL

LOAD_FILES=$(lscpu | awk '/Architecture:/ {print $2}')

case $LOAD_FILES in
	armv7l)
		if [ -n "$COMMUNITY_CK" ]; then
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp ${BAPDIR}/app/community/pi/*.bapp"
		else
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp"
		fi;;
	aarch64)
		if [ -n "$COMMUNITY_CK" ]; then
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp ${BAPDIR}/app/community/pi/*.bapp"
		else
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp"
		fi;;
	x86_64)
		if [ -n "$COMMUNITY_CK" ]; then
			APPSFILES="${BAPDIR}/app/stable/x86_64/*.bapp ${BAPDIR}/app/community/x86_64/*.bapp"
		else
			APPSFILES="${BAPDIR}/app/stable/x86_64/*.bapp"
		fi;;

esac

export BAPCPU
export BAPCORE
export BAPARCH
export BAPDIST
export BAPCALL
export MYCALL
export CALL
export BAPSRC
export BAPSYSINFO
export BAPPVER
export APPSFILES
export TEMPCRON
export LOGO

"${BAPDIR}/bin/app-check.sh"
wait

UNINSTALL_CK=$(ls -a "${BAPDIR}/cache/" | grep -F .remove || true)
if [ -n "$UNINSTALL_CK" ]; then
	rm -f "${BAPDIR}/cache/.remove"
	"${BAPDIR}/bin/remove.sh"
	wait
	exit
fi

"${BAPDIR}/bin/menu.sh"
wait
