#!/bin/bash
# Configure network of target installed system
ROOT=/mnt/harddisk/root
/tos/tlog -m "Mount installed system disk before network configuration"
grep -q "rootsize=max" /proc/cmdline
if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
    rootpart=${INSDISK}2
else
    rootpart=${INSDISK}1
fi
mount /dev/$rootpart $ROOT

grep -q "installmethod=net" /proc/cmdline
if [ $? -eq 0 ]; then
	/tos/tlog -m "Network configuration start"
	ls /tmp/ipinfo/ifcfg-eth* > /dev/null
	if [ $? -eq 0 ]; then
    	eth1ip=$(cat /tmp/ipinfo/ifcfg-eth1* |grep IPADDR|sed -E 's/IPADDR=['"'"'"]?([0-9.]*)['"'"'"]?/\1/')
    	if [ $eth1ip ]; then
        	/tos/tlog -m "use the old configuration of IP"
        	cp -vf /tmp/ipinfo/ifcfg-eth* $ROOT/etc/sysconfig/network-scripts/
			/tos/tlog -m "Network configuragtion done"
    	fi
	else
    	/tos/netconf -ochttp=http://192.168.199.200:8444/postapp/conf/ip.txt -root $ROOT
    	if [ $? -eq 0 ]; then 
			/tos/tlog -m "Network configuragtion done"
    	else 
			/tos/tlog -m "Network configuragtion failed"
    	fi
	fi
else
	ls /etc/sysconfig/network-scripts/ifcfg-eth* >/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		rm -v $ROOT/etc/sysconfig/network-scripts/ifcfg-eth*
		cp -pv /etc/sysconfig/network-scripts/ifcfg-eth* $ROOT/etc/sysconfig/network-scripts/
	else
		ls /tmp/ipinfo/ifcfg-eth* > /dev/null
		if [ $? -eq 0 ]; then
			eth1ip=$(cat /tmp/ipinfo/ifcfg-eth1* |grep IPADDR|sed -E 's/IPADDR=['"'"'"]?([0-9.]*)['"'"'"]?/\1/')
			if [ $eth1ip ]; then
				/tos/tlog -m  "use the old configuration of IP"
				cp -vf /tmp/ipinfo/ifcfg-eth* $ROOT/etc/sysconfig/network-scripts/
			#else
				#    /tos/tlinux2.0_64.sh
			fi
			#else
		#    /tos/tlinux2.0_64.sh
		fi
	fi
fi
umount $ROOT
