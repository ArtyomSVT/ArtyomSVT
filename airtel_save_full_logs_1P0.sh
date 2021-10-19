#!/bin/bash

# Artyom Serhiienko and Michael Lerman
# Version: 1P0 Logs Airtel Host and UBMC

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"
YLW="\033[1;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
PN=`dmidecode -t system | grep "Product Name" | awk '{print $3;}'`
SN=`dmidecode -t system | grep "Serial Number" | awk '{print $3;}'`
DATE=`date "+%d%m%y_%H%M"`


#HELP

help () {      
        echo -e "\n\t$GREEN Version: 1P0 Logs Airtel Host and UBMC$NC";
		echo -e "\n$PURPLE Before starting, make sure that you do not have a cable connected to the management port.$NC";
        echo -e "\n$YLW Enter the serial number of the device being tested.$NC";
        echo -e "\n$YLW Wait until all commands are executed.$NC";
        echo -e "\n$YLW At the end you will receive a file named SN.log\n$NC";
}
if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
    help
    exit
fi

#********Start Set IP***********

clear
ip=192.168.0.250
host=192.168.0.1
ip_bmc=192.168.0.10

i210=enp`eeupdate64e |grep -i i21 | awk '{print $2}'`s0
ifconfig $i210 0.0.0.0
SN=`dmidecode -t system | grep "Serial Number" | awk '{print $3;}'`
if [[ $SN == "123456789" ]] ; then
 echo -e "${RED}Wrong serial number" 
 echo -e "${GREEN}Please rum DMI Update programm and restart"
 exit

fi


echo -e "${YLW}Checking connection to internet,host $host"
ping $host -c 2 -W 1 &> /dev/null

status=$?
#echo "status=$status"

if [ "$status" == "0" ]; then
echo -e "${RED}System  connected to internet ...${NC}" 
echo -e "${PURPLE}Please  disconect  cable from managment port and restart${NC}"
exit
else
echo -e "${GREEN}System  did not connected to internet , so we start ...${NC}"
sleep 3
fi

systemctl stop  NetworkManager.service 
echo "Configuring managment port, please wait 5 sec"
ifconfig $i210 $ip

route add -host 192.168.0.10 dev $i210
route

sleep 5

#********End Set IP***********


#********Start Command functions**********

create_file () {
 log="$DATE"_"$SN"_"$PN".log
 echo `date +"%d/%m/%Y %H:%M"` > $log
 echo
 echo "---------------" |tee -a $log
 echo "HW information:" |tee -a $log
 echo "---------------" |tee -a $log
}


PN=`dmidecode -t system | grep "Product Name" | awk '{print $3;}'`
SN=`dmidecode -t system | grep "Serial Number" | awk '{print $3;}'`
DATE=`date "+%d%m%y_%H%M"`
FILE_NAME="$DATE"_"$SN"_"$PN".log

command_dmidecode () {

echo
echo ------------------------ |tee -a $log;
echo "Command dmidecode" |tee -a $log;
echo ------------------------ |tee -a $log;
dmidecode |tee -a $log
}

command_lsblk () {
echo
echo ------------------------ |tee -a $log
echo "Command lsblk" |tee -a $log
echo ------------------------ |tee -a $log
lsblk |tee -a $log
}

command_ifconfig () {
echo
echo ------------------------ |tee -a $log
echo "Command ifconfig -a" |tee -a $log
echo ------------------------ |tee -a $log
ifconfig -a |tee -a $log
}

command_free () {
echo
echo ------------------------ |tee -a $log
echo "Command free -m" |tee -a $log
echo ------------------------ |tee -a $log
free -m |tee -a $log
}

command_lspci () {
echo
echo ------------------------ |tee -a $log
echo "Command lspci" |tee -a $log
echo ------------------------ |tee -a $log
lspci |tee -a $log
}

command_lspcivx () {
echo
echo ------------------------ |tee -a $log
echo "Command lspcivx" |tee -a $log
echo ------------------------ |tee -a $log
lspci -vvvxxx |tee -a $log
}

command_eeupdate64e () {
echo
echo ------------------------ |tee -a $log
echo "Command eeupdate64e" |tee -a $log
echo ------------------------ |tee -a $log
eeupdate64e |tee -a $log
}

command_eeupdate64e_mac () {
echo
echo ------------------------ |tee -a $log
echo "Command eeupdate64e /all /mac_dump" |tee -a $log
echo ------------------------ |tee -a $log
eeupdate64e /all /mac_dump |tee -a $log
}

command_adapterinfo () {
echo
echo ------------------------ |tee -a $log
echo "Command eeupdate64e /all /adapterinfo" |tee -a $log
echo ------------------------ |tee -a $log
eeupdate64e /all /adapterinfo |tee -a $log
}

command_i2cdetect_bus () {
echo
echo ------------------------ |tee -a $log
echo "Command i2cdetect -l" |tee -a $log
echo ------------------------ |tee -a $log
i2cdetect -l |tee -a $log
}

command_i2cdetect_device () {
echo
echo ------------------------ |tee -a $log
echo "Command i2cdetect -y 0" |tee -a $log
echo ------------------------ |tee -a $log
i2cdetect -y 0 |tee -a $log
}

command_i2cdump () {
echo
echo ------------------------ |tee -a $log
echo "Command i2cdump -y 0 0x56" |tee -a $log
echo ------------------------ |tee -a $log
i2cdump -y 0 0x56 |tee -a $log
}

command_fdisk () {
echo
echo ------------------------ |tee -a $log
echo "Command fdisk -l" |tee -a $log
echo ------------------------ |tee -a $log
fdisk -l |tee -a $log
}
command_dmesg () {
echo
echo ------------------------ |tee -a $log
echo "Command dmesg" |tee -a $log
echo ------------------------ |tee -a $log
dmesg |tee -a $log
}

command_timedatectl () {
echo
echo ------------------------ |tee -a $log
echo "Command timedatectl" |tee -a $log
echo ------------------------ |tee -a $log
timedatectl |tee -a $log
}
#********END Command functions**********

#MAIN


create_file
command_dmidecode
command_lsblk
command_ifconfig
command_free
command_lspci
command_lspcivx
command_eeupdate64e
command_eeupdate64e_mac
command_adapterinfo
command_i2cdetect_bus
command_i2cdetect_device
command_i2cdump
command_fdisk
command_dmesg
command_timedatectl

#UBMC LOGS EXPECT

echo ------------------------ |tee -a $log
echo "Start UMBC LOGS" |tee -a $log
echo ------------------------ |tee -a $log

ubmc_expect="

#Time expect
set timeout 1

#Connect ssh:
spawn ssh  -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" is_admin@192.168.0.10
expect \"*assword: \"
send \"1qaz2wsX\r\"

expect \"ubmc>\"
send \"enable\r\"

expect \"ubmc#\"
send \"configure\r\"

expect \"ubmc(config)#\"
send \"show health\r\"

expect \"ubmc(config)#\"
send \"show version\r\"

expect \"ubmc(config)#\"
send \"show device\r\"

expect \"ubmc(config)#\"
send \"debug shell\r\"

expect \"*assword: \"
send \"She11#local\r\"

expect \"$ \"
send \"lsmod\r\"

expect \"$ \"
send \"sudo ifconfig -a\r\"

expect \"$ \"
send \"free -m\r\"

expect \"$ \"
send \"lsblk\r\"

expect \"$ \"
send \"sudo fdisk -l\r\"

expect \"$ \"
send \"sudo i2cdetect -l\r\"

expect \"$ \"
send \"sudo i2cdetect -y 1\r\"

expect \"$ \"
send \"sudo i2cdump -y -f 1 0x50\r\"

expect \"$ \"
send \"sudo eeprom_op -v\r\"

expect \"$ \"
send \"dmesg\r\"

send \"exit\r\"

expect \"ubmc(config)#\"
send \"exit\r\"

expect \"ubmc#\"
send \"exit\r\"

#Exit expect:
expect eof
"
output=$(expect -c "$ubmc_expect") 
echo -e $output |tee -a $log
ifconfig $i210 0.0.0.0