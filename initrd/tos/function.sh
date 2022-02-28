#!/bin/bash -
# ===============================================================================
#          File: function.sh
#   Description: Deploy System base function.
#        Author: Chapman Ou <chapmanou@tencent.com>
#       Created: 09/01/2014
#      Revision:  ---
# ===============================================================================

#
# Umount chroot mounted directories.
#
umountDirs()
{
	root=$1
	mount | grep "$root" | awk '{print $3}' | sort -r | while read line; do 
		if [ -n "$line" ]; then
			echo "umount $line"
			umount $line
		fi
	done
}

#
# mount chroot sysfs dev proc
#
mountChrootSysDevProc()
{
	dest=$1
	mount -o bind /dev $dest/dev
	mount -t sysfs sysfs $dest/sys
	mount -t proc proc $dest/proc
}

#
# Get target system information, for generated filename
#
getVersionDate()
{
	mnt=$1
	mount /dev/${INSDISK}1 $mnt
	VER=$(awk '/Version/{print $2}' $mnt/etc/motd)
	DATE=$(awk '/Version/{print $NF}' $mnt/etc/motd)
	umount $mnt
	echo "$VER.$DATE"
}

getVersion()
{
        mnt=$1
        mount /dev/${INSDISK}1 $mnt
        VER=$(awk '/Version/{print $2}' $mnt/etc/motd)
        umount $mnt
        echo "$VER"
}
