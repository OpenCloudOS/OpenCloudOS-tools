#!/bin/bash
#
# Hardware Information Collection Script
# 
# 20100126 v1.0 Barondai
#
#
if [  -f /tmp/deploy/log/hwinfo.log ] ; then
	mkdir /tmp/deploy/log/ -p
        > /tmp/deploy/log/hwinfo.log
fi 

MSERIAL=$(hwinfo --bios | awk -F ' ' ' { if (( $1 == "System" )&&($2 == "Info:")) a="1" ; \
        if(( a == "1")&&( $1 == "Serial:" )) { print $2;exit;} }' | cut -d '"' -f 2)
echo SN=$MSERIAL | tee -a /tmp/deploy/log/hwinfo.log

ASSETTAG=$(hwinfo --bios | grep "Tag: \"" | grep "[^A-z]\{2,4\}[0-9]\{4,12\}" | head -1 | awk -F\" '{print $2}')
echo TAG=$ASSETTAG | tee -a /tmp/deploy/log/hwinfo.log

SMODEL=$(hwinfo --bios | grep "Product:" | head -1 | awk -F "\"" '{print $2}' | cut -b 1-20) 
echo SMODEL=$SMODEL | tee -a /tmp/deploy/log/hwinfo.log

CLIIP=$(ifconfig | grep inet | head -n 1 | cut -d ":" -f 2 | awk -F " " '{ print $1}')
echo CLIIP=$CLIIP | tee -a /tmp/deploy/log/hwinfo.log

ETH1MAC=$(ifconfig | grep HWaddr | head -1 | awk '{print $5}' | tr A-Z a-z)
echo ETH1MAC=$ETH1MAC | tee -a /tmp/deploy/log/hwinfo.log

ETH0MAC=$(ifconfig -a | grep HWaddr | grep -v -i "$ETH1MAC" | head -1 | awk '{print $5}' | tr A-Z a-z)
echo ETH0MAC=$ETH0MAC | tee -a /tmp/deploy/log/hwinfo.log

HDISK=$(fdisk -l | grep Disk | awk -F"/" '{print $3 $4}')
echo HDISK=$HDISK | tee -a /tmp/deploy/log/hwinfo.log
HDISK2=$(fdisk -l | grep Disk | head -1 | awk -F: '{print $2}' | awk '{print $1}')

MEM=$(hwinfo --mem | grep "Memory Size" | awk -F":" '{print $2}')
echo MEM=$MEM | tee -a /tmp/deploy/log/hwinfo.log

#set error number to /tmp/deploy/log/status.log
if [ "$MSERIAL" != "" -a "$HDISK2" != "" -a "$ETH0MAC" != "" -a "$ETH1MAC" != "" ] ; then
        echo 80010000 | tee -a /tmp/deploy/log/status.log
        echo "$(date) [${MSERIAL}] Successfully complete hardware detection" | tee -a /tmp/deploy/log/install.log
fi

if [ "$MSERIAL" = "" ] ; then
        echo 80010001 | tee -a /tmp/deploy/log/status.log
        echo "$(date) [${MSERIAL}] SN is epmty , we DO NOT allow it , EXIT installation" | tee -a /tmp/deploy/log/install.log
fi

if [ "$HDISK2" = "" -o "$HDISK2" = "0" ] ; then
        echo 80010002 | tee -a /tmp/deploy/log/status.log
        echo "$(date) [${MSERIAL}] ERROR : No available harddisk to place operation system" | tee -a /tmp/deploy/log/install.log
fi

if [ "$ETH0MAC" = "" ] ; then
        echo 80010003 | tee -a /tmp/deploy/log/status.log
        echo "$(date) [${MSERIAL}] Can not detec ETH0MAC" | tee -a /tmp/deploy/log/install.log
fi

if [ "$ETH1MAC" = "" ] ; then
        echo 80010004 | tee -a /tmp/deploy/log/status.log
        echo "$(date) [${MSERIAL}] Can not detec ETH1MAC" | tee -a /tmp/deploy/log/install.log
fi
