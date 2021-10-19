#!/bin/bash

# Artyom Serhiienko
# Ver : R001

#### Introduction ####
# This script intended to create a bin file based on ONIE standard according to "ID_info_vecpe_xs_R007" document.
# Part of the output bin file data is taken from the DMI data , So this script cannot run on unit with blank DMI data.
# This script implemented & tested ( and all the instruction are related to ) on Debian 9.6 , Kernel Ver : 4.14.39

#### Instructions ####
# Verify that the 'cksfv' SW installed.
# If not , install 'cksfv' from the Internet by command : apt-get install cksfv
# The 'cksfv' SW is for CRC-32 calculatation
# Make this script executable by : chmod 777 onie_eeprom.sh
# Run the script : ./onie_eeprom.sh
# The script will create a file ( on its folder ) called : juniper_eeprom.bin

RED="\033[0;31m"
GREEN="\033[0;32m"
YLW="\033[1;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
NC="\033[0m"

type_logo () {
clear	
echo '                                                    '
echo ' ███████╗██╗██╗     ██╗ ██████╗ ██████╗ ███╗   ███╗ '
echo ' ██╔════╝██║██║     ██║██╔════╝██╔═══██╗████╗ ████║ '
echo ' ███████╗██║██║     ██║██║     ██║   ██║██╔████╔██║ '
echo ' ╚════██║██║██║     ██║██║     ██║   ██║██║╚██╔╝██║ '
echo ' ███████║██║███████╗██║╚██████╗╚██████╔╝██║ ╚═╝ ██║ '
echo ' ╚══════╝╚═╝╚══════╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝ '
}


write_byte_hex () {
		printf "\x${1}" >> juniper_eeprom.bin
}

write_string_ascii () {
		echo -n $1 >> juniper_eeprom.bin
}

hex2bigend () {
	case $1 in
					1)
						BYTE_LSB=$2
						BYTE_MSB=00
					;;
					2)
						BYTE_LSB=$2
						BYTE_MSB=00
					;;
					3)
						BYTE_LSB=${2:1:2}
						BYTE_MSB=${2:0:1}
					;;
					4)
						BYTE_LSB=${2:2:2}
						BYTE_MSB=${2:0:2}
					;;
	esac
}

rm -f juniper_eeprom.bin

#Help
help () {      
        echo -e "\n\t$GREEN VERSION: juniper_eeprom_R001$NC";
        echo -e "\n\nExample: ./juniper_eeprom_R001.sh Write 256 bits";
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
    help
    exit
fi

#main
#Logo
type_logo

#hex2bigend ${#TOTAL_LENGTH_H} $TOTAL_LENGTH_H
#TL_LSB=$BYTE_LSB
#TL_MSB=$BYTE_MSB

read_label_revision () {
	echo -e "\n\n$GREEN Enter Label Revision that is on the external label\n(Format: RDDD - R followed by 3 decimal digits):\n> $NC"
	read LABEL_REVISION
	while [[ ! $LABEL_REVISION =~ ^(X|R|x|r)([0-9]{3})$ ]]; do
		echo -e "\n$RED Label revision inserted is incorrect, please type R followed by 3 decimal digits:\n> $NC"
		read LABEL_REVISION
	done
}

read_serial_number () {
	echo -e "\n\n$GREEN Enter Serial Number that is on the external label\n(Format: DDDDDDDDDD - 10 decimal digits):\n> $NC"
	read SERIAL_NUMBER
	while [[ ! $SERIAL_NUMBER =~ ^([0-9]{10})$ ]]; do
		echo -e "\n$RED Serial Number inserted is incorrect, please type 10 decimal digits:\n> $NC"
		read SERIAL_NUMBER
	done
}

read_LTE_IMEI () {
	echo -e "\n$GREEN Enter LTE IMEI as shown on LTE device\n(Format: XXXXXXXXXXXXXXXX - 15 digits):\n> $NC"
	read LTE_IMEI
	while [[ ! $LTE_IMEI =~ ^([0-9a-fA-F]{15})$ ]]; do
		echo -e "\n$RED LTE IMEI should be 16 hexadecimal digits  XXXXXXXXXXXXXXXX:\n> $NC"
		read LTE_IMEI
	done
	
	LTE_IMEI=$LTE_IMEI"0"
}

UUID=`uuidgen -r`
UUID1=`echo $UUID | sed 's/-//g'`

########### VERSION ############
write_byte_hex 00
write_byte_hex 01					
############ VENDOR ############
Manuf="Juniper Network, Inc."
write_string_ascii "$Manuf"
############ PRODUCT ###########
prname="SSR120-AE-TAA"
write_string_ascii "$prname"
########### REVISION ###########
read_label_revision
write_string_ascii $LABEL_REVISION
########## PART NUMBER #########
write_string_ascii "650-142267"
########## SERIAL NUMBER #########
read_serial_number
write_string_ascii $SERIAL_NUMBER
########### LTE IMEI ############
read_LTE_IMEI

for i in {2,4,6,8,10,12,14,16} ; do
	IMEI_BYTE_H=`echo $LTE_IMEI | head -c $i | tail -c 2`
	printf "\x${IMEI_BYTE_H}" >> juniper_eeprom.bin
done

########### CLEI ############
write_string_ascii "PROTOXCLEI"
########### REGISTRATION CODE ############
for (( i=1; i <= 100; i++ ))
do
write_byte_hex 00
done
########### UUID ############
for i in {2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32} ; do
	UUID_BYTE_H=`echo $UUID1 | head -c $i | tail -c 2`
	printf "\x${UUID_BYTE_H}" >> juniper_eeprom.bin
done
########### RESERVED ############
for (( i=1; i <= 57; i++ ))
do
write_byte_hex 00
done
########### CRC-32 ############
CRC32=`cksfv -b juniper_eeprom.bin | tail -1 | awk '{print $2;}'` # 4 Bytes Hex
for i in {2,4,6,8} ; do
	CRC32_BYTE_H=`echo $CRC32 | head -c $i | tail -c 2`
	printf "\x${CRC32_BYTE_H}" >> juniper_eeprom.bin
done
########### END vendor-reserved ############
write_byte_hex FF

########### START ONIE WRITE ############

I2C_BUS=`i2cdetect -l | grep -i i801 | awk '{print $1;}' | tail -c 2`

./wr_eeprom_i2c_3P0.sh w $I2C_BUS 0x54 juniper_eeprom.bin

echo -e "\n\n$GREEN ONIE write completed. $NC"

########### ONIE WRITE END############


########### CHECK DMI############
echo -e "\n\n$CYAN Check the data that will be write in the DMI.$NC"
echo -e "\n\n$YLW Manufacturer:$NC $Manuf"
echo -e "\n\n$YLW System-product-name:$NC $prname"
echo -e "\n\n$YLW System-version:$NC $LABEL_REVISION"
echo -e "\n\n$YLW System-serial-number:$NC $SERIAL_NUMBER"
echo -e "\n\n$YLW System-uuid:$NC $UUID"
echo -e "\n\n$YLW System-family:$NC Session Smart Router"
echo -e "\n\n$YLW Board-manufacturer:$NC $Manuf"
echo -e "\n\n$YLW Board-product-name:$NC Session Smart Router"
echo -e "\n\n$YLW Board-version:$NC $LABEL_REVISION"
echo -e "\n\n$YLW Board-serial-number:$NC $SERIAL_NUMBER"

echo -e "\n\n$PURPLE Please put Enter to start write DMI. $NC"

read DMI

########### START DMI WRITE ############
./adi_smbios_util -w --system-manufacturer="$Manuf" --system-product-name="$prname" --system-version="$LABEL_REVISION" --system-serial-number="$SERIAL_NUMBER" --system-uuid=$UUID --system-family="Session Smart Router" --board-manufacturer="$Manuf" --board-product-name="Session Smart Router" --board-version="$LABEL_REVISION" --board-serial-number="$SERIAL_NUMBER"
clear
echo -e "\n\n$GREEN DMI write completed. $NC"