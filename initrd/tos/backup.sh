#!/bin/bash
SUCCESS=0
# asset id
#ASSETID=$(dmidecode -s chassis-asset-tag)
#export ASSET_ID="${ASSETID}"

# Ok, last
last_word()
{
	if [ $SUCCESS -eq 1 ]; then
		/tos/tlog -m "Backup Tlinux OS finished!" 
		/tos/tlog -m "Please type 'reboot -f' to reboot from harddisk!"
	else
		/tos/tlog -m "Backup failed"
	fi
}

trap last_word EXIT
/tos/tlog -m "Backup Tlinux OS start, please wait for a few minitues."
/tos/backup-tlinux.sh
test $? -ne 0 && exit 1
SUCCESS=1
#/tos/umountdisk.sh
/sbin/hwclock -w
exit 0
# Post jobs 
