#!/bin/bash
# configure 70-persistent-net.rules for tlinux2.x joeytao 20160524
grep -q "installmethod=net" /proc/cmdline
if [ $? -ne 0 ];then
exit 0
fi
/tos/tlog -m "configure 70-persistent-net.rules start"
grep -q "rootsize=max" /proc/cmdline
if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
    rootpart=${INSDISK}2
else
    rootpart=${INSDISK}1
fi

mntdir="/mnt/harddisk/root"
mount /dev/$rootpart $mntdir

NIC_NUM=$(ifconfig -a | grep HWaddr | awk '{print $5}' | sort  | uniq | wc -l)

IF_ETH0="$mntdir/etc/sysconfig/network-scripts/ifcfg-eth0"
IF_ETH1="$mntdir/etc/sysconfig/network-scripts/ifcfg-eth1"

ETH0MAC=$(ifconfig | egrep "inet addr:10|inet addr:192" -B1 | grep HWaddr | head -1 | awk '{print $5}' )
echo "eth0mac:$ETH0MAC"
ETH1MAC=$(ifconfig -a | grep HWaddr | grep -v $ETH0MAC | head -1 | awk '{print $5}')
echo "eth1mac:$ETH1MAC"

#weather eth1 is 10000M NIC
`ethtool eth1 | grep "Advertised link modes" -A3 | grep "10000" &> /dev/null`
if [ $? -eq 1 ];then
	i=2
	eth="eth"
	while [ "$i" -lt "$NIC_NUM" ]	
	do
		ethnumb=${eth}"$i"
		`ethtool ${ethnumb} | grep "Advertised link modes" -A3 | grep "10000" &> /dev/null`
		if [ $? -eq 0 ];then
        		ETH1MAC=$(ifconfig -a | grep HWaddr | egrep "$ethnumb" | grep -v $ETH1MAC | head -1 | awk '{print $5}')
			break
		fi
		i=$(($i+1))
	done
fi
ETH1MAC=$(echo $ETH1MAC | tr A-Z a-z)
ETH0MAC=$(echo $ETH0MAC | tr A-Z a-z)

sed -i "s/HWADDR=[^ ]*/HWADDR=${ETH1MAC}/" ${IF_ETH1}
sed -i "s/HWADDR=[^ ]*/HWADDR=${ETH0MAC}/" ${IF_ETH0}

/tos/tlog -m "This Server has $NIC_NUM NIC"
ifconfig -a | grep HWaddr > /tmp/HWaddr.tmp
cat /tmp/HWaddr.tmp | egrep -i -v "${ETH1MAC}|${ETH0MAC}" > /tmp/HWaddr.tmp2
RULE_FILE="$mntdir/etc/udev/rules.d/70-persistent-net.rules"

if [ "$ETH1MAC" != "" ] ; then
	echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETH1MAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth1\"" >> $RULE_FILE
fi

if [ "$ETH0MAC" != "" ] ; then
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETH0MAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth0\"" >> $RULE_FILE
fi

j=2
eth="eth"
while [ $j -lt "$NIC_NUM" ]
do
	ethnumb=${eth}"$j"
        ETHMAC=`cat /tmp/HWaddr.tmp2 | awk '{print $5}' | head -1`
	ETHMAC=$(echo $ETHMAC | tr A-Z a-z)
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETHMAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$ethnumb\"" >> $RULE_FILE
	cat /tmp/HWaddr.tmp2 | egrep -i -v "${ETHMAC}" > /tmp/HWaddr.tmp
	cat /tmp/HWaddr.tmp > /tmp/HWaddr.tmp2
	j=$(($j+1))
done
rm -rf /tmp/HWaddr.tmp*
umount $mntdir
/tos/tlog -m "configure 70-persistent-net.rules done"
