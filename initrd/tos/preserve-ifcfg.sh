#!/bin/bash
# Preserver network config
#
etc/sysconfig/network-scripts
/tos/tlog -m "preserve ifcfg-eth*"
mount -o ro /dev/${INSDISK}1 /data
if [ -d /data/etc/sysconfig/network-scripts/ ];then
    cd /data/etc/sysconfig/network-scripts/
    mkdir -p /tmp/ipinfo/
    ls ifcfg-eth* && cp -vf ifcfg-eth* /tmp/ipinfo/
    cd /tos
elif [ -d /data/etc/sysconfig/network/ ];then
    cd /data/etc/sysconfig/network/
    mkdir -p /tmp/ipinfo/
    ls ifcfg-eth* && cp -vf ifcfg-eth* /tmp/ipinfo/
    cd /tos
fi
umount /data
