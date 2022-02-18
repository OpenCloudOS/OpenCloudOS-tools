#!/bin/bash
ROOT=/mnt/harddisk/root
mkdir -p $ROOT
sda="sda"
if [ -b /dev/${sda}1 ] && [ -b /dev/${sda}3 ]; then

        mount /dev/${sda}1 $ROOT
        mount /dev/${sda}3 $ROOT/usr/local
	test -d /sys/firmware/efi && mount /dev/${sda}2 $ROOT/boot/efi

        mount -o bind /dev $ROOT/dev
        mount -t devpts devpts $ROOT/dev/pts
        mount -t proc proc $ROOT/proc
        mount -t sysfs sysfs $ROOT/sys

        echo "/dev/${sda}1 have been mounted on $ROOT, chroot to it :)"
fi

