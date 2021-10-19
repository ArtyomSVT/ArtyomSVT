#!/bin/ash
# Artyom Serhiienko
# Ver: 1P0

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

#Help

help () {      
        echo -e "\n\t$GREEN VERSION: 1P0$NC";
        echo -e "\n\n$RED Example: ./script_name.sh 10$NC";
		echo -e "\n\n$RED !!!!!Input Fans Speeds!!!!$NC";
		echo -e "\n\n$RED Input#  = Speeds Fan %$NC";
}

start_fan () {      
		cd /sys/class/hwmon/hwmon0
        echo $1 |sudo tee pwm1;
		echo $1 |sudo tee pwm2;
		echo $1 |sudo tee pwm3;
		echo $1 |sudo tee pwm4;
		echo $1 |sudo tee pwm5;
		echo -e "\n\t$GREEN Speed Fans: $1%$NC";
}

# Check Script Inputs
if [ -z "$1" ] ; then
	clear
    echo -e "\n\t $RED!!! Pls Enter Fan Speeds$NC"
	clear
	help
    exit
fi
start_fan $1