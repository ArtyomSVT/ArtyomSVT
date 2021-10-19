#!/bin/bash
# Ver: 1P1 - Added Num of bytes that written.
# Ver: 2P0 - Read , Write or verify - I2C device content.
# Ver: 2P1 - Added 5 ms delay between write to write.
# Ver: 2P2 - Bug Fixed. Bug - in case that the bin file ends in the last of the `hexdump -C` ROW the script continue write 00 to the eeprom.
# Ver: 3P0 - Changed the method of retreiving size of a file and binary file parsing.
#			 Added informative notes to the user.

# Yuval Badichi

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

usage () {
	echo "Usage:"
	echo -e "\t For writing to I2C device :\n"
	echo -e "\t ./wr_eeprom_i2c_2P2.sh [w] [I2C BUS] [I2C_ADDR] [FILE_NAME]\n\n"
	echo -e "\t For verify I2C device compared with a file :\n"
	echo -e "\t ./wr_eeprom_i2c_2P2.sh [v] [I2C BUS] [I2C_ADDR] [FILE_NAME] [NUM BYTES TO READ]\n\n"
	echo -e "\t For dumping I2C device to file :\n"
	echo -e "\t ./wr_eeprom_i2c_2P2.sh [r] [I2C BUS] [I2C_ADDR] [FILE_NAME] [NUM BYTES TO READ]\n\n"
	echo -e "\t For dumping I2C device to file up to 0xff value:\n"
	echo -e "\t ./wr_eeprom_i2c_2P2.sh [r] [I2C BUS] [I2C_ADDR] [FILE_NAME]\n\n"
}

# write_i2c <i2c_bus> <i2c_addr> <file_name.bin>
write_i2c () {

# i2c_write <i2c_bus> <i2c_addr> <reg_num_value>
i2c_write () {
    i2cset -y $1 $2 $3 0x$4
}

i=0
echo -ne "\t Start Writing $3 to I2C Device , Address : $2 , Bus Num: $1\n$NC"
echo -ne "$GREEN|$NC"
while true ; do
	DATA_HEX=`hexdump -C -s $i $3 | head -1 | awk '{print $2;}'`
	if [ $i -eq `stat --printf="%s" $3` ] ; then
		echo -ne "$GREEN*| 100% Complete.$NC\n"
		echo -e "`stat --printf="%s" $3` bytes had been written.\n"
		break
	else
		i2c_write $1 $2 $i $DATA_HEX
		sleep 0.005
		echo -ne "$GREEN*$NC"
		let "i++"
	fi
done
}

# read_i2c <i2c_bus> <i2c_addr> <num_bytes_to_read>
# if there is no <num_bytes_to_read> , the function read until value of 0xff or till 256 bytes.
read_i2c () {
rm -f $3
if [ -z $4 ] ; then
	NUM2READ=256
	echo -ne "\t Start dumping [ 256 Bytes or till 0xff ] I2C Device , Address : $2 , Bus Num: $1\n$NC"
else
	NUM2READ=$4
	echo -ne "\t Start dumping [ $4 Bytes ] I2C Device , Address : $2 , Bus Num: $1\n$NC"
fi
REG_NUM=0
echo -ne "$GREEN|$NC"
while [ $REG_NUM -lt $NUM2READ ] ; do
	a=`i2cget -y $1 $2 $REG_NUM`
	DATA_HEX_R=`echo ${a:2:2}`
	if [ -z $4 ] && [ $DATA_HEX_R = ff ] ; then
		echo -ne "\n\t Dump was stopped because 0xff value\n$NC"
		break
	fi
	printf "\x${DATA_HEX_R}" >> $3
	echo -ne "$GREEN*$NC"
	let "REG_NUM++"
done
echo -ne "$GREEN*| 100% Complete.$NC\n"
echo -e "\t Dump Finished! total of $REG_NUM bytes.$NC\n"
}


if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] || [ -z $4 ] ; then
	echo -e "\nInput is missing\n"
	usage
	exit
fi

modprobe i2c_i801
modprobe i2c-dev
sleep 2

a=`i2cdetect -l`
if [ -z "$a" ] ; then
    echo -e "$RED Pls Install i2c-tools $NC : 1) apt-get update"
	echo -e "				  2) apt-get install i2c-tools$NC"
	exit
fi

STATE=$1
BYTES_TO_READ=$5
while true ; do
	case $STATE in
			w)
				write_i2c $2 $3 $4
				STATE=v
				BYTES_TO_READ=`stat --printf="%s" $4`
			;;
			v)
				echo -e "\t Start Verify :\n"
				read_i2c $2 $3 temp.bin $BYTES_TO_READ
				a=`diff temp.bin $4`
				if [ -z "$a" ] ; then
					echo -e "$GREEN --- Verification Pass ---$NC\n"
				else
					echo -e "$RED --- Verification Fail ---$NC\n"
				fi
				rm -f temp.bin
				exit
			;;
			r)
				read_i2c $2 $3 $4 $BYTES_TO_READ
				exit
			;;
			*)
				echo -e "\nInput is illegal\n"
				usage
				exit
			;;
	esac
done
