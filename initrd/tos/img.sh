#!/bin/bash
ROOT=/mnt/harddisk/root
mkdir -p $ROOT
# test


grep -q "rootsize=max" /proc/cmdline
if [ $? -eq 0 -o $VM -eq 1 ]; then
    if [ -d /sys/firmware/efi ]; then
        mount /dev/${INSDISK}2 $ROOT
		mkdir -p $ROOT/boot/efi
        mount /dev/${INSDISK}1 $ROOT/boot/efi
    else
        mount /dev/${INSDISK}1 $ROOT
    fi
	/tos/tlog -m "Unsquashfs start"
	cores=$((`grep processor /proc/cpuinfo |wc -l`/2+1))
	unsquashfs -f -p $cores -d $ROOT /tos/img/os.img
	/tos/tlog -m "Unsquashfs done"
	sync

	#umount /tos/img
	test -d /sys/firmware/efi && umount $ROOT/boot/efi
	umount $ROOT
else
	mount /dev/${INSDISK}1 $ROOT
	mkdir -p $ROOT/usr/local
	test -d /sys/firmware/efi && mkdir -p $ROOT/boot/efi && mount /dev/${INSDISK}2 $ROOT/boot/efi
	# grep -q "xvda" /proc/cmdline
	if [ $VM -ne 1 ]; then
		mount /dev/${INSDISK}3 $ROOT/usr/local
	fi
	/tos/tlog -m "Unsquashfs start"
	cores=$((`grep processor /proc/cpuinfo |wc -l`/2+1))
	test ! -d /sys/firmware/efi && swapon /dev/${INSDISK}2
	unsquashfs -f -p $cores -d $ROOT /tos/img/os.img
	test ! -d /sys/firmware/efi &&  swapoff /dev/${INSDISK}2
	/tos/tlog -m "Unsquashfs done"
	sync

	#umount /tos/img
	test -d /sys/firmware/efi && umount $ROOT/boot/efi
	umount $ROOT/usr/local
	umount $ROOT
fi
