#!/bin/bash
# Collection Hardware Information for pxe
#

CLIIP=$(/sbin/ifconfig | grep inet | grep -v ":127" | head -n 1 | cut -d ":" -f 2 | awk -F " " '{ print $1}')

FS_hw="??"

if [ ${CLIIP} ]
then
   if [ -z $1 ]
   then
      log=/tmp/hwinfo.log
   else
      log=/tmp/${CLIIP}
   fi
   echo -n ${CLIIP} > ${log}
   echo -n "$FS_hw" >> ${log} 
else 
   if [ -z $1 ]
   then
      log=/tmp/hwinfo.log
   else
      log=/tmp/No_IP
   fi
   echo -n No_IP > ${log}
   echo -n "$FS_hw" >> ${log}
fi

BIN_DMI="/usr/sbin/dmidecode"

#Gather Serial Number
SN=$($BIN_DMI | awk '{ if (( $1 == "System" )&&($2 == "Information")) a="1" ; if(( a == "1")&&($1 == "Serial")) { print $3;exit;} }' | awk '{print $1}')
if [ -z ${SN} ]
then
   SN="No_SN"
fi
echo -n ${SN} >> ${log}
echo -n "$FS_hw" >> ${log}

#Gather AssetTag
ASSETTAG=`$BIN_DMI | grep "Asset Tag:" | grep SV | head -1 | tr -s ' ' | awk -F "Tag:"  '{print \$2}'`
if [ -z ${ASSETTAG} ]
then
   ASSETTAG="No_Asset"
fi
echo -n ${ASSETTAG} >> ${log}
echo -n "$FS_hw" >> ${log}

#Gather NetCard Info
ETH="No_ETH"
ETHIP="No_IP"
MAC="No_Mac"
SPEED="No_Speed"
/sbin/ifconfig -a | grep eth | while read line
do
   ETH=`echo $line | awk '{print $1}'`
   ETHIP=`/sbin/ifconfig $ETH | grep inet | head -n 1 | cut -d ":" -f 2 | awk -F " " '{ print $1}'`
   if [ -z $ETHIP ]
   then
      ETHIP="No_IP"
   fi
   MAC=`echo $line | awk '{print $NF}'`
   SPEED=`/sbin/ethtool ${ETH} | grep "Speed:" | awk '{print $2}'`
   echo -n "$ETH,$ETHIP,$MAC,$SPEED;" >> ${log}
#   echo -n "$FS_hw" >> ${log}
done
echo -n "$FS_hw" >> ${log}

#Gather DISK Info
HDISK=$(fdisk -l | grep Disk | grep -v dm | awk -F"/" '{print $3 $4}' | awk -F"," '{print $1","}')
HDISK1="`echo $HDISK | sed s/,$//g`"
if [ -z "${HDISK1}" ]
then
   HDISK1="No_Disk"
fi
echo -n "${HDISK1}"  >> ${log}
echo -n "$FS_hw" >> ${log}

#Gather Mem Info
#MEM=$($BIN_DMI -t memory | grep "Size:" | grep MB | awk '{print $2}')
>/tmp/mem
$BIN_DMI -t memory | grep "Size:" | grep MB | awk '{print $2/1024}' | while read line
do
   echo -n "${line}+" >> /tmp/mem
done
MEM="`sed s/+$//g /tmp/mem`"
MEM1="`echo ${MEM} | bc`"
echo -n "${MEM1} GB" >> ${log}

#Gather CPU Info
#CPU=$($BIN_DMI -t processor | grep Version | grep Hz | awk -F 'Version: ' '{print $2","}' | sed -e s/'   '//g  -e s/'  '/' '/g )
CPU=$(grep "model name" /proc/cpuinfo |  awk -F ': ' '{print $NF}' | sed -e s/'   '//g  -e s/'  '/' '/g | head -1)
CPU_No=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
if [ ${CPU_No} -gt 1 ]
then
   CPU="(${CPU})*${CPU_No}"
fi

echo -n "$FS_hw" >> ${log}
echo -n "${CPU}"  >> ${log} 

echo "" >> ${log}
cat ${log}
