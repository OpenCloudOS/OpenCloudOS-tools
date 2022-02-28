#!/bin/bash
###AUTHOR: zgpeng 20160824

RULE_FILE="/etc/udev/rules.d/70-persistent-net.rules"
grep -q "tlinux 2.2\|tlinux 2.0" /etc/motd
if [ $? -eq 1 ];then
exit 1
fi

#if 70-persistent-net.rules file is exist 
if [  -f "$RULE_FILE" ]; then 
	echo "70-persistent-net.rules is already exist"
	exit 1
fi

echo "configure 70 rules start"
NIC_NUM=$(ifconfig -a | grep eth[0-9]: | wc -l)

j=0
eth="eth"
while [ $j -lt "$NIC_NUM" ]
do
	ethnumb=${eth}"$j"
	ifconfig $ethnumb |grep ether >> /tmp/HWaddr.tmp2
	j=$(($j+1))
done

rm -rf ${RULE_FILE}
j=0
IFCFG_PRE="/etc/sysconfig/network-scripts/ifcfg-"
while [ $j -lt "$NIC_NUM" ]
do
	ethnumb=${eth}"$j"
        ETHMAC=`cat /tmp/HWaddr.tmp2 | awk '{print $2}' | head -1`
	ETHMAC=$(echo $ETHMAC | tr A-Z a-z)
	IFCFG_FILE=${IFCFG_PRE}${ethnumb}
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$ETHMAC\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$ethnumb\"" >> $RULE_FILE
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
yum -y update initscripts
echo "configure 70 rules done"
