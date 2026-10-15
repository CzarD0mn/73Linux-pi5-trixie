#! /bin/bash
# Environment detection for 73Linux.
# User-space only. Do not run this script with sudo.

BAPSYSINFO=${BAPDIR}/cache/cpu.bap
CACHEDIR=${BAPDIR}/cache
mkdir -p "$CACHEDIR"

set +e
MYCALL=$(ls "${BAPDIR}"/MYCALL.* 2>/dev/null | head -1 | sed 's/.*MYCALL.//')
if [ -z "$MYCALL" ]; then
	MYCALL=$(ls MYCALL.* 2>/dev/null | head -1 | sed 's/MYCALL.//')
fi
CALL=$MYCALL
export CALL
export MYCALL

pi_check() {
	if [ "$(getconf LONG_BIT)" = 32 ]; then
		CPU=32
	else
		CPU=64
	fi
}

LSCPU_OUT="${CACHEDIR}/bap-env-lscpu"
lscpu > "$LSCPU_OUT"
eval "$(sed -n 's/^ID=/distribution=/p' /etc/os-release)"
eval "$(sed -n 's/^VERSION_ID=/version=/p' /etc/os-release | tr -d '"')"
arch=$(awk '/^Architecture:/ {print $2}' "$LSCPU_OUT")
cpu=$(grep -c ^processor /proc/cpuinfo)

case "$arch" in
	armv7l|aarch64) pi_check ;;
	x86_64) CPU=64 ;;
	x86) CPU=32 ;;
	*)
		echo "Unknown: $arch with $cpu cores"
		CPU=64
		;;
esac

ID_LIKE_VAL=$(sed -n 's/^ID_LIKE=//p' /etc/os-release | tr -d '"')
case "$distribution" in
	arch|archarm|manjaro|manjaro-arm|endeavouros|garuda|artix|cachyos)
		echo "Distribution $distribution $version accepted (Arch-based)"
		;;
	*)
		case " $ID_LIKE_VAL " in
			*" arch "*) echo "Distribution $distribution (ID_LIKE=$ID_LIKE_VAL) accepted (Arch-based)" ;;
			*)
				echo "Unsupported: $distribution $version on $arch."
				echo "This 73Linux branch only supports Arch-based systems (pacman/yay)."
				exit 1
				;;
		esac
		;;
esac

if [ -f /proc/device-tree/model ]; then
	MODEL=$(tr -d '\0' </proc/device-tree/model)
	echo "Board: $MODEL"
	if echo "$MODEL" | grep -qi "Raspberry Pi"; then
		distribution="arch-rpi"
	fi
fi

echo -e "$CPU\n$cpu\n$arch\n$distribution\n$MYCALL\n$(hostname -s)" > "$BAPSYSINFO"
echo "enviroment $CPU $arch $distribution"
exit 0
