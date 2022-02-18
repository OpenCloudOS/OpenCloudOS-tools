#!/bin/bash
# Configure network for tlog
# Preserve network config
#
grep -q "installmethod=net" /proc/cmdline
if [ $? -eq 0 ]
then
    echo "Installation environment network configuration"
    #/sbin/ifconfig eth1 up
    # Wait NIC
    echo "preserve ifcfg-eth*"
    grep -q "rootsize=max" /proc/cmdline
    if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
        rootpart=${INSDISK}2
    else
        rootpart=${INSDISK}1
    fi
    mount -o ro /dev/$rootpart /data
    if [ -d /data/etc/sysconfig/network-scripts ]; then
        cd /data/etc/sysconfig/network-scripts/
        mkdir -p /tmp/ipinfo/
        ls ifcfg-eth* && cp -vf ifcfg-eth* /tmp/ipinfo/
    elif [ -d /data/etc/sysconfig/network/ ];then
        cd /data/etc/sysconfig/network/
        mkdir -p /tmp/ipinfo/
        ls ifcfg-eth* && cp -vf ifcfg-eth* /tmp/ipinfo/
    fi
    cd /tos
    umount /data

    sleep 3
    /sbin/dhclient -timeout 20
    /tos/tlog -m "Installation environment network configuration done"
else
    echo "preserve ifcfg-eth*"
    grep -q "rootsize=max" /proc/cmdline
    # TODO: what if we install kvm under uefi mode
    # for current ISO install grub, the if condition won't be satisfied
    if [ $? -eq 0 -a -d /sys/firmware/efi ]; then
        rootpart=${INSDISK}2
    else
        rootpart=${INSDISK}1
    fi
    # the code is useless, cause no data in /dev/sda now. (if there is an old linux os before,the code will be in use?)
    mount -o ro /dev/$rootpart /data
    if [ -d /data/etc/sysconfig/network-scripts ]; then
        cd /data/etc/sysconfig/network-scripts/
        mkdir -p /tmp/ipinfo/
        ls ifcfg-eth* && cp -vf ifcfg-eth* /tmp/ipinfo/
    elif [ -d /data/etc/sysconfig/network/ ];then
        cd /data/etc/sysconfig/network/
        mkdir -p /tmp/ipinfo/
        ls ifcfg-eth* && cp -vf ifcfg-eth* /tmp/ipinfo/
    fi
    cd /tos
    umount /data
fi
