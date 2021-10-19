#!/bin/bash

# Yuval Badichi
# Ver: 1P0

# This script intended to run on Madrid system
# This script tested on Fedora 27
# Make sure "killall" is installed

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

SERIAL_DEV_NAME=ttyACM0

send_serial () {
	printf ''$1'\xD' > /dev/$SERIAL_DEV_NAME
	sleep $2
}

# Check Script Inputs
#if [ -z "$1" ] ; then
#	echo -e "\n\t $RED!!! Pls Enter ttyUSB# <0/1/2/3/4/5...>$NC"
#	exit
#fi

ps aux | grep "cat /dev/$SERIAL_DEV_NAME" | grep -v "grep" > /dev/null
if [ $? -eq 0 ] ; then
	killall cat
fi
rm -f gps.log
cat /dev/$SERIAL_DEV_NAME > gps.log &
while true ; do
	TIME=`cat gps.log | grep -a GNGLL | head -1 | tail -c 18 | head -c 6`
	DATE=`cat gps.log | grep -a GNRMC | head -1 | tail -c 17 | head -c 6`
	echo -e "\n\nDate = $DATE | Time = $TIME"
	echo > gps.log
	sleep 1
done
killall cat