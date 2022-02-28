#!/bin/bash
# create squashfs
#
source /tos/function.sh

ROOT=/mnt/harddisk/root
# umount all /mnt/harddisk mounted if mounted
umountDirs "$ROOT"

VER_DATE=$(getVersionDate $ROOT)
output=/tmp/tlinux-64bit-v${VER_DATE}.sqfs
savelog=${output}_log

# remount /dev/${INSDISK}1 and /dev/${INSDISK}3
mount /dev/${INSDISK}1 $ROOT
mount /dev/${INSDISK}3 $ROOT/usr/local

mkdir -p $savelog
mv $ROOT/tmp/* $ROOT/var/log/anaconda $ROOT/root/anaconda* $savelog

mksquashfs $ROOT $output -comp xz -b 262144 -no-xattrs

umountDirs "$ROOT"

echo "sqfs: $output"
