#!/bin/bash

# Artyom Serhiienko
# Ver. 1P4
# Revision History:
# 1P0 - Initial Version
# 1P1 - Add checks Power Supply
# 1P2 - Add checks ipmitool
# 1P3 - Add Power Supply Controller Sensor + bug fix
# 1P4 - Add allPower Supply Sequencer Sensors


RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"
YLW="\033[1;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"

#Help
help () {      
        echo -e "\n\t$GREEN VERSION: 1P4$NC";
        echo -e "\n\nJust run the script for monitoring sensors, to stop press Ctrl-C";
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
    help
    exit
fi

#Check ipmitool
if ! [ -x "$(command -v ipmitool)" ]; then
  clear
  echo -e "\n\t$RED Error: ipmitool is not installed.$NC \n" >&2
  exit 1
fi

#Setup time
human_time ()
{
day=$(( $1/86400 ))
hour=$(( $(( $1-$day*86400 ))/3600 ))
min=$(( $(( $1-$day*86400-$hour*3600 ))/60 ))
sec=$(( $1-$day*86400-$hour*3600-$min*60 )) 
}

#Setup mux
ipmitool i2c bus=3 0xe4 0x00 0x08 >/dev/null

ipmitool i2c bus=3 0xe0 0x00 0x01 >/dev/null

#Time
time_start=`date +%s`

#Resolution
TEMP_resolution=64
INVOLT_resolution=125
OUTVOLT_resolution=$(bc <<< 'scale=1; 0.003125')
OUTVOLT_CURRENT_resolution=$(bc <<< 'scale=2; 0.25')
VPCIE_resolution=$(bc <<< 'scale=1; 0.00097656 ')
res12207_resolution=$(bc <<< 'scale=1; 0.00012207 ')
res24414_resolution=$(bc <<< 'scale=1; 0.00024414 ')
res06104_resolution=$(bc <<< 'scale=1; 0.00006104 ')
VREF_1_0V6_resolution=$(bc <<< 'scale=1; 0.00003052 ')


#test1=$(bc <<< 'scale=3; 3.125')
#test1=$(bc <<< 'scale=3; 3.125')
#Loop_sensors 

while true ; do
#eASIC East Temperature Sensor
TEMP1_HEX=`ipmitool i2c bus=3 0x5C 0x01 0x25 |head -c 3 |sed 's/^[[:space:]]*//g'`
#Local Temperature Sensor 
TEMP2_HEX=`ipmitool i2c bus=3 0x5C 0x01 0x26 |head -c 3 |sed 's/^[[:space:]]*//g'`  
#eASIC West Temperature Sensor
TEMP3_HEX=`ipmitool i2c bus=3 0x5C 0x01 0x27 |head -c 3 |sed 's/^[[:space:]]*//g'`

#Input Voltage
INPUT_VOLTAGE_HEX=`ipmitool i2c bus=3 0x48 0x01 0x88 |head -c 3 |sed 's/^[[:space:]]*//g'`

#Power Supply Temperature 
POWERS_TEMP_HEX=`ipmitool i2c bus=3 0x48 0x01 0x8d |head -c 3 |sed 's/^[[:space:]]*//g'`

#Power Supply Output Voltage

OUTPUT_VOLTAGE_HEX=`ipmitool i2c bus=3 0x48 0x02 0x8B | tr -d '[:space:]'`
OUTPUT_VOLTAGE_BIT1=`echo ${OUTPUT_VOLTAGE_HEX:4} |head -c8`
OUTPUT_VOLTAGE_BIT2=`echo ${OUTPUT_VOLTAGE_HEX:4} |cut -c 16`
SUM_BIT_VOLT=$OUTPUT_VOLTAGE_BIT2$OUTPUT_VOLTAGE_BIT1
OUTPUT_VOLTAGE_DEC=$(echo "obase=10; ibase=2; $SUM_BIT_VOLT" | bc )

#SUM_OUTPUT_VOLTAGE_DEC=$(($OUTPUT_VOLTAGE_DEC*$OUTVOLT_resolution))
SUM_OUTPUT_VOLTAGE_DEC=`echo "scale=5; ($OUTPUT_VOLTAGE_DEC*$OUTVOLT_resolution)" | bc`


#Power Supply Output Current
OUTPUT_CURRENT_HEX=`ipmitool i2c bus=3 0x48 0x02 0x8C | tr -d '[:space:]'`
OUTPUT_CURRENT_BIT1=`echo ${OUTPUT_CURRENT_HEX:4} |head -c8`
OUTPUT_CURRENT_BIT2=`echo ${OUTPUT_CURRENT_HEX:4} |cut -c 15-16`
SUM_BIT_CURRENT=$OUTPUT_CURRENT_BIT2$OUTPUT_CURRENT_BIT1

OUTPUT_CURRENT_DEC=$(echo "obase=10; ibase=2; $SUM_BIT_CURRENT" | bc )
SUM_OUTPUT_CURRENT_DEC=`echo "scale=3; ($OUTPUT_CURRENT_DEC*$OUTVOLT_CURRENT_resolution)" | bc`



#Sensor 12VPCIE
ipmitool i2c bus=3 0x6c 0x00 0x00 0x00 >/dev/null
VPCIE_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VPCIE_BIT1=`echo ${VPCIE_HEX:4} |head -c8`
VPCIE_BIT2=`echo ${VPCIE_HEX:4} |cut -c 9-16`
SUM_12VPCIE_BIT=$VPCIE_BIT2$VPCIE_BIT1
VPCIE_DEC=$(echo "obase=10; ibase=2; $SUM_12VPCIE_BIT" | bc )
SUM_VPCIE_DEC=`echo "scale=3; ($VPCIE_DEC*$VPCIE_resolution)" | bc | cut -c1-5` 


#Sensor eF_IMON
ipmitool i2c bus=3 0x6c 0x00 0x00 0x01 >/dev/null
EF_IMON_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
EF_IMON_BIT1=`echo ${EF_IMON_HEX:4} |head -c8`
EF_IMON_BIT2=`echo ${EF_IMON_HEX:4} |cut -c 9-16`
SUM_EF_IMON_BIT=$EF_IMON_BIT2$EF_IMON_BIT1
EF_IMON_DEC=$(echo "obase=10; ibase=2; $SUM_EF_IMON_BIT" | bc )
SUM_EF_IMON_DEC=`echo "scale=1; ($EF_IMON_DEC*$res12207_resolution)" | bc | cut -c1-4`

#Sensor 3V3_PRE
ipmitool i2c bus=3 0x6c 0x00 0x00 0x02 >/dev/null
V3_PRE_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
V3_PRE_BIT1=`echo ${V3_PRE_HEX:4} |head -c8`
V3_PRE_BIT2=`echo ${V3_PRE_HEX:4} |cut -c 9-16`
SUM_V3_PRE_BIT=$V3_PRE_BIT2$V3_PRE_BIT1
V3_PRE_DEC=$(echo "obase=10; ibase=2; $SUM_V3_PRE_BIT" | bc )
SUM_V3_PRE_DEC=`echo "scale=1; ($V3_PRE_DEC*$res24414_resolution)" | bc | cut -c1-4`


#Sensor VCC_1V2
ipmitool i2c bus=3 0x6c 0x00 0x00 0x03 >/dev/null
VCC_1V2_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VCC_1V2_BIT1=`echo ${VCC_1V2_HEX:4} |head -c8`
VCC_1V2_BIT2=`echo ${VCC_1V2_HEX:4} |cut -c 9-16`
SUM_VCC_1V2_BIT=$VCC_1V2_BIT2$VCC_1V2_BIT1
VCC_1V2_DEC=$(echo "obase=10; ibase=2; $SUM_VCC_1V2_BIT" | bc )
SUM_VCC_1V2_DEC=`echo "scale=1; ($VCC_1V2_DEC*$res06104_resolution)" | bc | cut -c1-4`


#Sensor VCCIO_P3V3
ipmitool i2c bus=3 0x6c 0x00 0x00 0x04 >/dev/null
VCCIO_P3V3_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VCCIO_P3V3_BIT1=`echo ${VCCIO_P3V3_HEX:4} |head -c8`
VCCIO_P3V3_BIT2=`echo ${VCCIO_P3V3_HEX:4} |cut -c 9-16`
SUM_VCCIO_P3V3_BIT=$VCCIO_P3V3_BIT2$VCCIO_P3V3_BIT1
VCCIO_P3V3_DEC=$(echo "obase=10; ibase=2; $SUM_VCCIO_P3V3_BIT" | bc )
SUM_VCCIO_P3V3_DEC=`echo "scale=1; ($VCCIO_P3V3_DEC*$res24414_resolution)" | bc | cut -c1-4`

#Sensor VPP
ipmitool i2c bus=3 0x6c 0x00 0x00 0x05 >/dev/null
VPP_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VPP_BIT1=`echo ${VPP_HEX:4} |head -c8`
VPP_BIT2=`echo ${VPP_HEX:4} |cut -c 9-16`
SUM_VPP_BIT=$VPP_BIT2$VPP_BIT1
VPP_DEC=$(echo "obase=10; ibase=2; $SUM_VPP_BIT" | bc )
SUM_VPP_DEC=`echo "scale=1; ($VPP_DEC*$res12207_resolution)" | bc | cut -c1-4`

#Sensor 3V3_IDM
ipmitool i2c bus=3 0x6c 0x00 0x00 0x06 >/dev/null
V3_IDM_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
V3_IDM_BIT1=`echo ${V3_IDM_HEX:4} |head -c8`
V3_IDM_BIT2=`echo ${V3_IDM_HEX:4} |cut -c 9-16`
SUM_V3_IDM_BIT=$V3_IDM_BIT2$V3_IDM_BIT1
V3_IDM_DEC=$(echo "obase=10; ibase=2; $SUM_V3_IDM_BIT" | bc )
SUM_V3_IDM_DEC=`echo "scale=1; ($V3_IDM_DEC*$res24414_resolution)" | bc | cut -c1-4`

#Sensor VDD_V085
ipmitool i2c bus=3 0x6c 0x00 0x00 0x07 >/dev/null
VDD_V085_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VDD_V085_BIT1=`echo ${VDD_V085_HEX:4} |head -c8`
VDD_V085_BIT2=`echo ${VDD_V085_HEX:4} |cut -c 9-16`
SUM_VDD_V085_BIT=$VDD_V085_BIT2$VDD_V085_BIT1
VDD_V085_DEC=$(echo "obase=10; ibase=2; $SUM_VDD_V085_BIT" | bc )
SUM_VDD_V085_DEC=`echo "scale=1; ($VDD_V085_DEC*$res06104_resolution)" | bc | cut -c1-4`

#Sensor VCCPD_1V8 
ipmitool i2c bus=3 0x6c 0x00 0x00 0x08 >/dev/null
VCCPD_1V8_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VCCPD_1V8_BIT1=`echo ${VCCPD_1V8_HEX:4} |head -c8`
VCCPD_1V8_BIT2=`echo ${VCCPD_1V8_HEX:4} |cut -c 9-16`
SUM_VCCPD_1V8_BIT=$VCCPD_1V8_BIT2$VCCPD_1V8_BIT1
VCCPD_1V8_DEC=$(echo "obase=10; ibase=2; $SUM_VCCPD_1V8_BIT" | bc )
SUM_VCCPD_1V8_DEC=`echo "scale=1; ($VCCPD_1V8_DEC*$res12207_resolution)" | bc | cut -c1-4`

#Sensor VCCIO_1V8
ipmitool i2c bus=3 0x6c 0x00 0x00 0x09 >/dev/null
VCCIO_1V8_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VCCIO_1V8_BIT1=`echo ${VCCIO_1V8_HEX:4} |head -c8`
VCCIO_1V8_BIT2=`echo ${VCCIO_1V8_HEX:4} |cut -c 9-16`
SUM_VCCIO_1V8_BIT=$VCCIO_1V8_BIT2$VCCIO_1V8_BIT1
VCCIO_1V8_DEC=$(echo "obase=10; ibase=2; $SUM_VCCIO_1V8_BIT" | bc )
SUM_VCCIO_1V8_DEC=`echo "scale=1; ($VCCIO_1V8_DEC*$res12207_resolution)" | bc | cut -c1-4`

#Sensor VDDA_16G_0V85
ipmitool i2c bus=3 0x6c 0x00 0x00 0x0a >/dev/null
VDDA_16G_0V85_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VDDA_16G_0V85_BIT1=`echo ${VDDA_16G_0V85_HEX:4} |head -c8`
VDDA_16G_0V85_BIT2=`echo ${VDDA_16G_0V85_HEX:4} |cut -c 9-16`
SUM_VDDA_16G_0V85_BIT=$VDDA_16G_0V85_BIT2$VDDA_16G_0V85_BIT1
VDDA_16G_0V85_DEC=$(echo "obase=10; ibase=2; $SUM_VDDA_16G_0V85_BIT" | bc )
SUM_VDDA_16G_0V85_DEC=`echo "scale=1; ($VDDA_16G_0V85_DEC*$res06104_resolution)" | bc | cut -c1-4`


#Sensor VDDA_CK_0V85
ipmitool i2c bus=3 0x6c 0x00 0x00 0x0b >/dev/null
VDDA_CK_0V85_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VDDA_CK_0V85_BIT1=`echo ${VDDA_CK_0V85_HEX:4} |head -c8`
VDDA_CK_0V85_BIT2=`echo ${VDDA_CK_0V85_HEX:4} |cut -c 9-16`
SUM_VDDA_CK_0V85_BIT=$VDDA_CK_0V85_BIT2$VDDA_CK_0V85_BIT1
VDDA_CK_0V85_DEC=$(echo "obase=10; ibase=2; $SUM_VDDA_CK_0V85_BIT" | bc )
SUM_VDDA_CK_0V85_DEC=`echo "scale=1; ($VDDA_CK_0V85_DEC*$res06104_resolution)" | bc | cut -c1-4`

#Sensor VDDP_16G_1V2
ipmitool i2c bus=3 0x6c 0x00 0x00 0x0c >/dev/null
VDDP_16G_1V2_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VDDP_16G_1V2_BIT1=`echo ${VDDP_16G_1V2_HEX:4} |head -c8`
VDDP_16G_1V2_BIT2=`echo ${VDDP_16G_1V2_HEX:4} |cut -c 9-16`
SUM_VDDP_16G_1V2_BIT=$VDDP_16G_1V2_BIT2$VDDP_16G_1V2_BIT1
VDDP_16G_1V2_DEC=$(echo "obase=10; ibase=2; $SUM_VDDP_16G_1V2_BIT" | bc )
SUM_VDDP_16G_1V2_DEC=`echo "scale=1; ($VDDP_16G_1V2_DEC*$res06104_resolution)" | bc | cut -c1-4`


#Sensor VDDR_16G_0V85
ipmitool i2c bus=3 0x6c 0x00 0x00 0x0d >/dev/null
VDDR_16G_0V85_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VDDR_16G_0V85_BIT1=`echo ${VDDR_16G_0V85_HEX:4} |head -c8`
VDDR_16G_0V85_BIT2=`echo ${VDDR_16G_0V85_HEX:4} |cut -c 9-16`
SUM_VDDR_16G_0V85_BIT=$VDDR_16G_0V85_BIT2$VDDR_16G_0V85_BIT1
VDDR_16G_0V85_DEC=$(echo "obase=10; ibase=2; $SUM_VDDR_16G_0V85_BIT" | bc )
SUM_VDDR_16G_0V85_DEC=`echo "scale=1; ($VDDR_16G_0V85_DEC*$res06104_resolution)" | bc | cut -c1-4`

#Sensor VDDIO_16G_1V2
ipmitool i2c bus=3 0x6c 0x00 0x00 0x0e >/dev/null
VDDIO_16G_1V2_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VDDIO_16G_1V2_BIT1=`echo ${VDDIO_16G_1V2_HEX:4} |head -c8`
VDDIO_16G_1V2_BIT2=`echo ${VDDIO_16G_1V2_HEX:4} |cut -c 9-16`
SUM_VDDIO_16G_1V2_BIT=$VDDIO_16G_1V2_BIT2$VDDIO_16G_1V2_BIT1
VDDIO_16G_1V2_DEC=$(echo "obase=10; ibase=2; $SUM_VDDIO_16G_1V2_BIT" | bc )
SUM_VDDIO_16G_1V2_DEC=`echo "scale=1; ($VDDIO_16G_1V2_DEC*$res06104_resolution)" | bc | cut -c1-4`

#Sensor VREF_1_0V6
ipmitool i2c bus=3 0x6c 0x00 0x00 0x0f >/dev/null
VREF_1_0V6_HEX=`ipmitool i2c bus=3 0x6c 0x02 0x8b | tr -d '[:space:]'`
VREF_1_0V6_BIT1=`echo ${VREF_1_0V6_HEX:4} |head -c8`
VREF_1_0V6_BIT2=`echo ${VREF_1_0V6_HEX:4} |cut -c 9-16`
SUM_VREF_1_0V6_BIT=$VREF_1_0V6_BIT2$VREF_1_0V6_BIT1
VREF_1_0V6_DEC=$(echo "obase=10; ibase=2; $SUM_VREF_1_0V6_BIT" | bc )
SUM_VREF_1_0V6_DEC=`echo "scale=1; ($VREF_1_0V6_DEC*$VREF_1_0V6_resolution)" | bc | cut -c1-4`

printf -v TEMP1_DEC "%d" "0x$TEMP1_HEX" #Hex to Decimal
printf -v TEMP2_DEC "%d" "0x$TEMP2_HEX" #Hex to Decimal
printf -v TEMP3_DEC "%d" "0x$TEMP3_HEX" #Hex to Decimal
printf -v INPUT_VOLTAGE_DEC "%d" "0x$INPUT_VOLTAGE_HEX" #Hex to Decimal
printf -v POWERS_TEMP_DEC "%d" "0x$POWERS_TEMP_HEX" #Hex to Decimal

SUM_TEMP1_DEC=$((TEMP1_DEC-TEMP_resolution))
SUM_TEMP2_DEC=$((TEMP2_DEC-TEMP_resolution))
SUM_TEMP3_DEC=$((TEMP3_DEC-TEMP_resolution))

SUM_INPUT_VOLTAGE_DEC=$((INPUT_VOLTAGE_DEC*INVOLT_resolution/1000))

echo -e "\n\t$GREEN ****Reading temperature:****$NC";

echo -e "\n\t$YLW Local Temperature Sensor  = $NC $SUM_TEMP2_DEC [C]$NC"

echo -e "\n\t$YLW eASIC East Temperature Sensor  = $NC $SUM_TEMP1_DEC [C]$NC"

echo -e "\n\t$YLW eASIC West Temperature Sensor = $NC $SUM_TEMP3_DEC [C]$NC"

echo -e "\n\t$YLW eASIC West Temperature Sensor = $NC $SUM_TEMP3_DEC [C]$NC"

echo -e "\n\t$GREEN ****VDD Core Power Supply Controller MP2940B:****$NC";

echo -e "\n\t$YLW Input Voltage = $NC $SUM_INPUT_VOLTAGE_DEC [V]$NC"

echo -e "\n\t$YLW Output Voltage = $NC 0$SUM_OUTPUT_VOLTAGE_DEC [V]$NC"

echo -e "\n\t$YLW Output Current = $NC $SUM_OUTPUT_CURRENT_DEC [A]$NC"

echo -e "\n\t$YLW Power Supply Temperature = $NC $POWERS_TEMP_DEC [C]$NC"

echo -e "\n\t$GREEN ****Sensors Power Supply Sequencer :****$NC";

echo -e "\n\t$YLW Voltage on +12V_EDGE = $NC $SUM_VPCIE_DEC [V]$NC"

echo -e "\n\t$YLW Current on +12V_EDGE = $NC $SUM_EF_IMON_DEC [A]$NC"

echo -e "\n\t$YLW Voltage on 3V3_PRE = $NC $SUM_V3_PRE_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VCC_1V2 = $NC $SUM_VCC_1V2_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VCCIO_P3V3 = $NC $SUM_VCCIO_P3V3_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VPP = $NC $SUM_VPP_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on 3V3_IDM = $NC $SUM_V3_IDM_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VDD_V085 = $NC 0$SUM_VDD_V085_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VCCPD_1V8 = $NC $SUM_VCCPD_1V8_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VCCIO_1V8 = $NC $SUM_VCCIO_1V8_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VDDA_16G_0V85 = $NC 0$SUM_VDDA_16G_0V85_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VDDA_CK_0V85 = $NC 0$SUM_VDDA_CK_0V85_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VDDP_16G_1V2 = $NC $SUM_VDDP_16G_1V2_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VDDR_16G_0V85 = $NC 0$SUM_VDDR_16G_0V85_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VDDIO_16G_1V2 = $NC $SUM_VDDIO_16G_1V2_DEC [V]$NC"

echo -e "\n\t$YLW Voltage on VREF_1_0V6 = $NC 0$SUM_VREF_1_0V6_DEC [V]$NC"
#TIME
time_now=`date +%s`
time_remain=`expr $time_now - $time_start`
human_time $time_remain

echo -e "\n\t$CYAN TIME TEST: ${day}d:${hour}h:${min}m:${sec}s$NC"

sleep 2
clear

done
}

#printf -v OUTPUT_VOLTAGE_DEC "%d" "0x$OUTPUT_VOLTAGE_HEX" #Hex to Decimal
#SUM_OUTPUT_VOLTAGE_DEC=$((OUTPUT_VOLTAGE_DEC*OUTVOLT_resolution))
#test=$($OUTPUT_VOLTAGE_DEC * $OUTVOLT_resolution |bc)
#echo $test
#test=`echo $test1*$OUTPUT_VOLTAGE_DEC| bc`
#test2=$(bc <<< 'scale=9; 16803.125')
#echo $test2 | awk '{printf "%.5f \n", $1}'
