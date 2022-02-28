#!/bin/bash
grep -q "installmethod=net" /proc/cmdline
if [ $? -eq 0 ];then
exit 0
fi
echo  "network and 70-rules configure start"
grep -q "rootsize=max" /proc/cmdline
if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
        rootpart=${INSDISK}2
else
        rootpart=${INSDISK}1
fi
mntdir="/mnt/harddisk/root"
mount /dev/$rootpart $mntdir
if [ -f /tos/img/hardinstall_iface_hwaddr ];then
        grep -q "eth0" /tos/img/hardinstall_iface_hwaddr
        if [ $? -eq 0 ];then
		ETH0MAC=$(cat /tos/img/hardinstall_iface_hwaddr | grep eth0 | head -1 | awk -F '=' '{print $2}')
	fi
	grep -q "eth1" /tos/img/hardinstall_iface_hwaddr
        if [ $? -eq 0 ];then
                ETH1MAC=$(cat /tos/img/hardinstall_iface_hwaddr | grep eth1 | head -1 | awk -F '=' '{print $2}')
        fi
	grep -q "eth2" /tos/img/hardinstall_iface_hwaddr
        if [ $? -eq 0 ];then
                ETH2MAC=$(cat /tos/img/hardinstall_iface_hwaddr | grep eth2 | head -1 | awk -F '=' '{print $2}')
        fi
        grep -q "eth3" /tos/img/hardinstall_iface_hwaddr
        if [ $? -eq 0 ];then
                ETH3MAC=$(cat /tos/img/hardinstall_iface_hwaddr | grep eth3 | head -1 | awk -F '=' '{print $2}')
        fi
fi

NIC_NUM=$(ifconfig -a | grep HWaddr | awk '{print $5}' | sort  | uniq | wc -l)

IF_ETH0="$mntdir/etc/sysconfig/network-scripts/ifcfg-eth0"
IF_ETH1="$mntdir/etc/sysconfig/network-scripts/ifcfg-eth1"

[ -z "$ETH0MAC" ] && ETH0MAC=$(ifconfig -a | grep HWaddr | head -1 | awk '{print $5}' )
echo "eth0mac:$ETH0MAC"
[ -z "$ETH1MAC" ] && ETH1MAC=$(ifconfig -a | grep HWaddr | grep -v $ETH0MAC | head -1 | awk '{print $5}')
echo "eth1mac:$ETH1MAC"

ETH1MAC=$(echo $ETH1MAC | tr A-Z a-z)
ETH0MAC=$(echo $ETH0MAC | tr A-Z a-z)

sed -i "s/HWADDR=[^ ]*/HWADDR=${ETH1MAC}/" ${IF_ETH1}
sed -i "s/HWADDR=[^ ]*/HWADDR=${ETH0MAC}/" ${IF_ETH0}


echo "This Server has $NIC_NUM NIC"
ifconfig -a | grep HWaddr > /tmp/HWaddr.tmp
cat /tmp/HWaddr.tmp | egrep -i -v "${ETH1MAC}|${ETH0MAC}" > /tmp/HWaddr.tmp2
RULE_FILE="$mntdir/etc/udev/rules.d/70-persistent-net.rules"
rm -rf ${RULE_FILE}
if [ "$ETH0MAC" != "" ] ; then
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETH0MAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth0\"" >> $RULE_FILE
fi

if [ "$ETH1MAC" != "" ] ; then
	echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETH1MAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth1\"" >> $RULE_FILE
fi

j=2
eth="eth"
IFCFG_PRE="$mntdir/etc/sysconfig/network-scripts/ifcfg-"
while [ $j -lt "$NIC_NUM" ]
do
	ethnumb=${eth}"$j"
        ETHMAC=`cat /tmp/HWaddr.tmp2 | awk '{print $5}' | head -1`
	ETHMAC=$(echo $ETHMAC | tr A-Z a-z)
	IFCFG_FILE=${IFCFG_PRE}${ethnumb}
	rm -rf ${IFCFG_FILE} 
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETHMAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$ethnumb\"" >> $RULE_FILE
	echo "DEVICE='${ethnumb}'" >> ${IFCFG_FILE}
	echo "HWADDR='${ETHMAC}'" >> ${IFCFG_FILE}
	echo "NM_CONTROLLED='yes'" >> ${IFCFG_FILE}
	echo "ONBOOT='no'" >> ${IFCFG_FILE}
	echo "IPADDR=''" >> ${IFCFG_FILE}
	echo "NETMASK=''" >> ${IFCFG_FILE}
	echo "GATEWAY=''" >> ${IFCFG_FILE}
	cat /tmp/HWaddr.tmp2 | egrep -i -v "${ETHMAC}" > /tmp/HWaddr.tmp
        cat /tmp/HWaddr.tmp > /tmp/HWaddr.tmp2
	j=$(($j+1))
done
rm -rf /tmp/HWaddr.tmp*
umount $mntdir
echo "configure network done"
