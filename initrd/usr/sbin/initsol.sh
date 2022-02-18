#!/bin/bash
###########################################################
#
# initialize SOL configuration for Linux OS
# SOL default setting:
#  menu.lst OR grub.conf: console=tty0 console=ttyS0
#  /etc/inittab OR /etc/init/serial.conf: 9600 ttyS0 
#
# 20111122   lynnsong <lynnsong@tencent.com>
# -version 0.3
# -Modified: support suse, tlinux, xen simultaneously
# -Added IBM System x3630M3 console=ttyS1,115200
#
# 20100201
# -Added DELL PowerEdge R410 console=ttyS1
#
# 20090713 
# -Added HuaSai T3500
#
#############################################################

#############################################################
#
# set serial file and grublist according to different OS
# for suse, centos5.5
#  -grublist: /boot/grub/menu.lst
#  -ttySfile: /etc/inittab
#
# for tlinux
#  -grublist: /boot/grub/gurb.conf
#  -ttySfile: /etc/init/serial.conf
#
#############Remove it from boot.local###########################
trap 'sed -i "\/usr\/sbin\/initsol.sh/d" /etc/rc.d/boot.local' EXIT
#############################################################
grublist=/boot/grub/menu.lst
ttySfile=/etc/inittab
if [ -f /etc/tlinux-release ]; then
	grublist=/boot/grub/grub.conf
	ttySfile=/etc/init/serial.conf
fi
TTYS=`cat $grublist | grep "console=ttyS.,"`
if [ "$TTYS" != "" ] ; then
	echo "ttyS0/1 has been initialized , exit..."
	exit 0
fi

#############################################################
#
# Getting Product Info with 'dmidecode' command
# 'dmidecode' exists in all OS what we used
# dmidecode returns null in domU
#
#############################################################
PROMODEL=`dmidecode | grep "Product" | head -1 | awk -F: '{print $2}'`
if [ -z "${PROMODEL}" ]; then
	if [ -f /proc/xen ]; then
		echo -n "There is no Product info, maybe it's domU."
		echo -e "\t\t[\033[34m Warning \033[0m ]"        
		exit 0 
	else
		echo -n "Getting Product Info"
		echo -e "\t\t\t[\033[31m FAILED \033[0m ]"	
		exit 1
	fi
fi

echo "please wait while the system is initializing the SOL"
echo "Initializing......Please do NOT reboot it !"

case $PROMODEL in
	*"950"* | *"X3550"* | *"DCS5110"*)
		BMENU=`cat $grublist | grep  "S1,9600"`
		INITB=`cat $ttySfile | grep "9600" | grep "ttyS1"`
		if [ "$BMENU" = "" ] ; then
			sed -i 's/console=ttyS0/console=ttyS1,9600/g' $grublist
		fi
		if [ "$INITB" = "" ] ; then
			sed -i 's/ttyS0/ttyS1/' $ttySfile
		fi
		echo "It is $RPOMODEL"
		;;
	*"1208"*)
		BMENU=`cat $grublist | grep  "S0,19200"`
		INITB=`cat $ttySfile | grep "19200" | grep  "ttyS0"`
		if [ "$BMENU" = "" ] ; then
			sed -i 's/console=ttyS0/console=ttyS0,19200/g' $grublist
		fi
		if [ "$INITB" = "" ] ; then
			sed -i 's/9600/19200/' $ttySfile
		fi
		echo "It is HP SE1208"
		;;
	*"R410"*)
		BMENU=`cat $grublist | grep  "ttyS1"`
		NITB=`cat $ttySfile | grep "ttyS1"`
		if [ "$BMENU" = "" ] ; then
			sed -i 's/console=ttyS0/console=ttyS1/g' $grublist
		fi
		if [ "$INITB" = "" ] ; then
			sed -i 's/ttyS0/ttyS1/g' $ttySfile
		fi
		echo "It is PowerEdge R410"
		;;
	*"T3500"*)
		BMENU=`cat $grublist | grep  "S1,57600"`
		INITB=`cat $ttySfile | grep "57600" | grep "ttyS1"`
		if [ "$BMENU" = "" ] ; then
			sed -i 's/console=ttyS0/console=ttyS1,57600/g' $grublist
		fi
		if [ "$INITB" = "" ] ; then
			sed -i 's/ttyS0/ttyS1/' $ttySfile
			sed -i 's/9600/57600/' $ttySfile
		fi
		echo "It is HuaSai T3500"
		;;
	*"SD220X4"*)
		BMENU=`cat $grublist | grep  "S1,9600"`
		INITB=`cat $ttySfile | grep "9600" | grep "ttyS1"`
		if [ "$BMENU" = "" ] ; then
			sed -i 's/console=ttyS0/console=ttyS1,9600/g' $grublist
		fi
		if [ "$INITB" = "" ] ; then
			sed -i 's/ttyS0/ttyS1/' $ttySfile
		fi
		echo "It is LENOVO SD220X4"
		;;
	*"3630M3"*)
		BMENU=`cat $grublist | grep  "S1,115200"`
		INITB=`cat $ttySfile | grep "115200" | grep "ttyS1"`
		if [ "$BMENU" = "" ] ; then
			sed -i 's/console=ttyS0/console=ttyS1,115200/g' $grublist
		fi
		if [ "$INITB" = "" ] ; then
			sed -i 's/ttyS0/ttyS1/' $ttySfile
			sed -i 's/9600/115200/' $ttySfile
		fi
		echo "It is IBM System x3630M3"
		;;

	*)
		ttyS=`/usr/sbin/ttyspeed`
		if [ "${ttyS}" == "ttyS1" ]; then
			sed -i 's/console=ttyS0/console=ttyS1/' $grublist
			sed -i 's/ttyS0/ttyS1/' $ttySfile
			echo "Set console to ttyS1 according to the baudrate test!"
		else	
			echo "Other Server Model ,Use default configuration"
		fi
		;;
esac
