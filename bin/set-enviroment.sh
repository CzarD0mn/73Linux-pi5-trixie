#! /bin/bash
# envioment checking

#for first run
BAPSYSINFO=${BAPDIR}/cache/cpu.bap
set +e
MYCALL=$(ls MYCALL.* | sed 's/MYCALL.//')
CALL=$MYCALL

export CALL
export MYCALL

trap 'catch' ERR
catch() {
echo -e "\nCRITICAL: parsing error on:"
}

pi_check(){
	if [ `getconf LONG_BIT` = 32 ]; then
		CPU=32
	elif [ `getconf LONG_BIT` = 64 ]; then
		CPU=64
	fi
}

rm -f /tmp/bap-env-*
lscpu > /tmp/bap-env-lscpu
eval "$(sed -n 's/^ID=/distribution=/p' /etc/os-release)"
eval "$(sed -n 's/^VERSION_ID=/version=/p' /etc/os-release | tr -d '"')"
arch=$(cat /tmp/bap-env-lscpu | grep Architecture: | awk '{print $2}')
cpu=$(grep processor /proc/cpuinfo | wc -l)

case "$arch" in
    armv7l)
        pi_check
        ;;
    aarch64)
        pi_check
        ;;
    x86_64)
        CPU=64
        ;;
    x86)
        CPU=32
        ;;
    *)
        echo -e "Unknown: $arch with $cpu cores"
        ;;
esac

case "$distribution" in
    raspbian|debian|linuxmint|ubuntu|raspios)
        echo "Distribution $distribution $version accepted"
        ;;
    *)
        echo "Possibly unsupported: $distribution $version on $arch with $cpu cores"
        echo "Continuing anyway (Pi 5 / Debian Trixie fork)"
        ;;
esac

if [ -f /proc/device-tree/model ]; then
	MODEL=$(tr -d '\0' </proc/device-tree/model)
	echo "Board: $MODEL"
	if echo "$MODEL" | grep -qi "Raspberry Pi"; then
		distribution="debian-rpi"
	fi
fi

echo -e "$CPU\n$cpu\n$arch\n$distribution\n$MYCALL\n$(hostname -s)" > $BAPSYSINFO
echo -e "enviroment $CPU $arch $distribution"
exit 0
