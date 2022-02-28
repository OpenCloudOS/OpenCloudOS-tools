#!/bin/bash
#
# make Novell zenwork image.
#
# Chapman Ou <chapmanou@tencent.com>
# Wed Aug 13 10:30:58 CST 2014
#
source /tos/function.sh

ZMG_ROOT=/tmp/novell-root
mkdir -p $ZMG_ROOT
mkdir -p $ZMG_ROOT/zmg

# umount all /mnt/harddisk mounted if mounted
umountDirs "harddisk"

echo "Network configuration, please wait..."
dhclient eth0

# download
echo "Download Novell root image..."
curl http://192.168.0.156:8444/img/novell-root -o $ZMG_ROOT/root

# mount disk for filename
DISK_MNT=/mnt/harddisk/root
VER_DATE=$(getVersionDate $DISK_MNT)

# mount direcotry
mkdir -p $ZMG_ROOT/root.d
mount -o loop $ZMG_ROOT/root $ZMG_ROOT/root.d
mountChrootSysDevProc "$ZMG_ROOT/root.d"
mkdir -p $ZMG_ROOT/root.d/zmg
mount -o bind $ZMG_ROOT/zmg $ZMG_ROOT/root.d/zmg

ZMG_FILE=tlinux-64bit-v${VER_DATE}.zmg
chroot $ZMG_ROOT/root.d bin/img -make -local /zmg/$ZMG_FILE -comp=9

echo "Zenwork image: $ZMG_ROOT/zmg/$ZMG_FILE"

# Clean
# umount all mounted if mounted
umountDirs "$ZMG_ROOT"
