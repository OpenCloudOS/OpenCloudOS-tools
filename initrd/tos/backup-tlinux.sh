#!/bin/bash
# create squashfs
#
source /tos/function.sh

ROOT=/mnt/harddisk/root
function get_free_space_mb
{
	test -d "$1" || mkdir -p "$1"
	hdread=""
	df -P "$1" | while read fs bl us av rest; do
		test "$hdread" && expr $av / 1024
		hdread="$fs"
	done
}
# umount all /mnt/harddisk mounted if mounted
umountDirs "$ROOT"

VER=$(getVersion $ROOT)
output=/tmp/tlinux-64bit-v${VER}-backup.`date +"%Y-%m-%d-%H:%M"`.sqfs
md5sum=/tmp/tlinux-64bit-v${VER}-backup.`date +"%Y-%m-%d-%H:%M"`.sqfs.md5sum
savelog=${output}_log

# remount /dev/${INSDISK}1 and /dev/${INSDISK}3
mount /dev/${INSDISK}1 $ROOT
mount /dev/${INSDISK}3 $ROOT/usr/local
test -d /sys/firmware/efi && mount /dev/${INSDISK}2 $ROOT/boot/efi

mount /dev/${INSDISK}4 $ROOT/data
restsize=$(get_free_space_mb "$ROOT/data")
/tos/tlog -m "restsize: $restsize MB"
needsize=5120
if [ $restsize -lt $needsize ]; then
	/tos/tlog -m  "No enough space left on backup device (restsize: $restsize MB)"
	exit 1
fi
umount $ROOT/data

grep -q "2." $ROOT/etc/tlinux-release
if [ $? -eq 0 ]; then
	grubfile="$ROOT/boot/grub2/grub.cfg"
fi
grep -q "1." $ROOT/etc/tlinux-release
if [ $? -eq 0 ]; then
	if [ -d /sys/firmware/efi -a -f $ROOT/boot/efi/EFI/tencent/grub.efi ]; then
        	grubfile="$ROOT/boot/efi/EFI/tencent/grub.conf"
        else
		grubfile="$ROOT/boot/grub/grub.conf"
	fi
fi

#mkdir -p $savelog
#mv $ROOT/tmp/* $ROOT/var/log/anaconda $ROOT/root/anaconda* $savelog

#backup-mode remove /boot/*backup-recovery*
grep -q "backup-mode" /proc/cmdline
if [ $? -eq 0 ]; then
        /tos/tlog -m "backup-mode, remove /boot/*backup-recovery*"
        rm -fv $ROOT/boot/*backup-recovery*
	/tos/tlog -m "recovery the grub_conf"
	cp -fv ${grubfile}.bak ${grubfile}
	#/tos/tlog -m "remove backup-recovery title from grub"
	#[ -n "$grubfile1" ] && sed -i '0,/title.*\(Backup\)/{//d;b};0,/initrd.*backup/d' $grubfile1
	#[ -n "$grubfile2" ] && sed -i '0,/menuentry.*backup-recovery/{//d;b};0,/}/d' $grubfile2
fi

mksquashfs $ROOT $output -comp xz -b 262144 2>&1 

mount /dev/${INSDISK}4 $ROOT/data
test -d $ROOT/data/tlinux/backup/ ||  mkdir -p $ROOT/data/tlinux/backup

/tos/tlog -m "Copy backup sqfs to /data/tlinux/backup/$output"
cp -fv $output $ROOT/data/tlinux/backup/
/tos/tlog -m "Copy done"
/usr/bin/md5sum $output > $md5sum
cp -fv $md5sum $ROOT/data/tlinux/backup/
/tos/tlog -m "Write md5sum to /data/tlinux/backup/$output.md5sum"

umountDirs "$ROOT"

/tos/tlog -m  "sqfs: $output"
