#!/bin/bash
# configure 70-persistent-net.rules for tlinux2.x joeytao 20160524
grep -q "installmethod=net" /proc/cmdline
if [ $? -ne 0 ];then
exit 0
fi
/tos/tlog -m "configure 70-persistent-net.rules start"
mntdir="/mnt/harddisk/root"
mount /dev/${INSDISK}1 $mntdir

NIC_NUM=$(ifconfig -a | grep HWaddr | awk '{print $5}' | sort  | uniq | wc -l)

ETH1MAC=$(ifconfig | egrep "inet addr:192.168.199" -B1 | grep HWaddr | head -1 | awk '{print $5}' )
echo "eth1mac:$ETH1MAC"
ETH0MAC=$(ifconfig -a | grep HWaddr | grep -v $ETH1MAC | head -1 | awk '{print $5}')
echo "eth0mac:$ETH0MAC"

ETH0NAME=$(ifconfig -a | grep ${ETH0MAC} | awk '{print $1}')
`ethtool ${ETH0NAME} | grep "Advertised link modes" -A3 | grep "10000" &> /dev/null`
if [ $? -eq 1 ];then
	i=0
	eth="eth"
	while [ "$i" -lt "$NIC_NUM" ]	
	do
		ethnumb=${eth}"$i"
		`ethtool ${ethnumb} | grep "Advertised link modes" -A3 | grep "10000" &> /dev/null`
		if [ $? -eq 0 ];then
        		MACADDR=$(ifconfig -a | grep HWaddr | egrep "$ethnumb" | grep -v $ETH1MAC | head -1 | awk '{print $5}')
			if [ "$MACADDR" != "" ] ; then
				ETH0MAC=${MACADDR}
				ETH0NAME=$(ifconfig -a | grep ${ETH0MAC} | awk '{print $1}')
				break
			fi
		fi
		i=$(($i+1))
	done
fi

/tos/tlog -m "This Server has $NIC_NUM NIC"
rm -rf /tmp/HWaddr.tmp*
ifconfig -a | grep HWaddr > /tmp/HWaddr.tmp
ifconfig -a | grep ${ETH0MAC} >> /tmp/HWaddr.tmp2
ifconfig -a | grep ${ETH1MAC} >> /tmp/HWaddr.tmp2
cat /tmp/HWaddr.tmp | egrep -i -v "${ETH1MAC}|${ETH0MAC}" >> /tmp/HWaddr.tmp2
RULE_FILE="${mntdir}/etc/udev/rules.d/70-persistent-net.rules"
rm -rf ${RULE_FILE}

j=0
IFCFG_PRE="${mntdir}/etc/sysconfig/network-scripts/ifcfg-"
while [ $j -lt "$NIC_NUM" ]
do
        ethnumb=${eth}"$j"
        ETHMAC=`cat /tmp/HWaddr.tmp2 | awk '{print $5}' | head -1`
        ETHMAC=$(echo $ETHMAC | tr A-Z a-z)
        IFCFG_FILE=${IFCFG_PRE}${ethnumb}
	if [ "$ETHMAC" != "" ] ; then
        	echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETHMAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$ethnumb\"" >> $RULE_FILE
	fi
        if [  -f "$IFCFG_FILE" ]; then
                sed -i "s/HWADDR=[^ ]*/HWADDR=${ETHMAC}/" ${IFCFG_FILE}
        else
                echo "DEVICE='${ethnumb}'" >> ${IFCFG_FILE}
                echo "HWADDR='${ETHMAC}'" >> ${IFCFG_FILE}
                echo "NM_CONTROLLED='yes'" >> ${IFCFG_FILE}
                echo "ONBOOT='no'" >> ${IFCFG_FILE}
                echo "IPADDR=''" >> ${IFCFG_FILE}
                echo "NETMASK=''" >> ${IFCFG_FILE}
                echo "GATEWAY=''" >> ${IFCFG_FILE}
        fi
        cat /tmp/HWaddr.tmp2 | egrep -i -v "${ETHMAC}" > /tmp/HWaddr.tmp
        cat /tmp/HWaddr.tmp > /tmp/HWaddr.tmp2
        j=$(($j+1))
done
rm -rf /tmp/HWaddr.tmp*
umount $mntdir
/tos/tlog -m "configure 70-persistent-net.rules done"
