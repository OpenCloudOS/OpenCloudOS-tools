#!/bin/bash


/tos/tlog -m "Disk format start"


# if ${INSDISK} is big than 8T and is tlinux1.2-tkernel system ,use ext4 to mkfs.  add by zpeng 20160921
DISK_BIG_THAN_8T=1
#disk_size=`fdisk -l /dev/${INSDISK} | grep 'Disk /dev/' | cut -d ' ' -f 5`
#if [ "$disk_size" -gt 8796093022208 ]; then # 8TB = 8*1024*1024*1024*1024
#	DISK_BIG_THAN_8T=1
#fi

# TLINUX1_2_TKERNEL2=0
# grep -q "tlinux-tkernel2-64bit-v1" /proc/cmdline
# if [ $? -eq 0 ]
# then
# 	TLINUX1_2_TKERNEL2=1
# fi

# TLINUX2=0
# grep -q "tlinux-64bit-v2" /proc/cmdline || grep -q "tlinux-64bit-v3" /proc/cmdline
# if [ $? -eq 0 ]
# then
# 	TLINUX2=1
# fi
# set the default parted format is ext4, so comment upper code
MKFS_CMD=mkfs.ext4
grep -q "CentOS-5.5-64bit" /proc/cmdline
if [ $? -eq 0 ]
then
    MKFS_CMD="mkfs.ext3 -I 128"
fi
grep -q "tlinux-sles10sp2-64bit" /proc/cmdline
if [ $? -eq 0 ]
then
    MKFS_CMD="mkfs.ext3 -I 128"
fi
# if [ $TLINUX2 -eq 1 ]
# then
# 	MKFS_CMD=mkfs.ext4
# fi

# # if ${INSDISK} is big than 8T and is tlinux1.2-tkernel system ,use ext4 to mkfs . add by zgpeng 20160921
# if [ $DISK_BIG_THAN_8T -eq 1 -a $TLINUX1_2_TKERNEL2 -eq 1 ]
# then
# 	MKFS_CMD=mkfs.ext4
# fi

# the uefi mode mkfs part, in uefi mode, we need part sda1 as efi partition
# no matter whether we are in kvm or not
uefi_mkfs() {
	/tos/tlog -m "Make /dev/${INSDISK}1 as efi system partition"
	mkdosfs -F 32 -n efi-boot /dev/${INSDISK}1
	[ $? -eq 0 ] && /tos/tlog -m "Disk format /dev/${INSDISK}1 done"
	$MKFS_CMD /dev/${INSDISK}2
	if [ $? -eq 0 ]; then
		/tos/tlog -m "efi mode, Disk format /dev/${INSDISK}2 done"
	else
		/tos/tlog -m "efi mode, Disk format /dev/${INSDISK}2 failed"
		exit 1
	fi
	
	e2label /dev/${INSDISK}2 /
	/tos/tlog -m "Label done"
}

grep -q "rootsize=max" /proc/cmdline
# in this section, we part the whole disk as one partition
if [ $? -eq 0 -o $VM -eq 1 ]; then
    if [ -d /sys/firmware/efi ]; then
		uefi_mkfs
	else
		$MKFS_CMD /dev/${INSDISK}1
		if [ $? -eq 0 ]; then
        	/tos/tlog -m "Disk format /dev/${INSDISK}1 done"
		else
        	/tos/tlog -m "Disk format /dev/${INSDISK}1 failed"
        	exit 1
		fi
		e2label /dev/${INSDISK}1 /
		/tos/tlog -m "Label done"
	fi
# only physical machine can go to the else part
else
	$MKFS_CMD /dev/${INSDISK}1
	if [ $? -eq 0 ]; then
		/tos/tlog -m "Disk format /dev/${INSDISK}1 done"
	else
		/tos/tlog -m "Disk format /dev/${INSDISK}1 failed"
		exit 1
	fi

	# do the rest partiton for physical machine
	# as vm is judged in former if condition, so delete this if
	# if [ $VM -eq 0 ]; then
		if [ -d /sys/firmware/efi ]; then
    		/tos/tlog -m "Make /dev/${INSDISK}2 as efi system partition"
    		mkdosfs -F 32 -n efi-boot /dev/${INSDISK}2
    		[ $? -eq 0 ] && /tos/tlog -m "Disk format /dev/${INSDISK}2 done"
		else
    		/tos/tlog -m "Make /dev/${INSDISK}2 as swap"
    		mkswap -L swap /dev/${INSDISK}2
		fi

		/tos/tlog -m "Disk format /dev/${INSDISK}3 start"
		$MKFS_CMD /dev/${INSDISK}3
		if [ $? -eq 0 ]; then
			/tos/tlog -m "Disk format /dev/${INSDISK}3 done"
		else
			/tos/tlog -m "Disk format /dev/${INSDISK}3 failed"
			exit 1
		fi

	#recovery-mode,and not find format_data=1, don't format data disk
		grep -q "recovery-mode" /proc/cmdline
		r_flag=$?
		DATA_PART="${INSDISK}4"
		read DATA_PART < "/tmp/datapart.txt"
		grep -q "format_data=1" /proc/cmdline
		if [ $? -ne 0 -a $r_flag -eq 0 ]; then
        	/tos/tlog -m "recovery-mode, and format_data=0, don't format /dev/${DATA_PART}"
		else
        	if [ -f /tlinux_not_part ]; then
				/tos/tlog -m "by default, don't format /dev/${DATA_PART}"
			elif [ "$DATA_PART" == "${INSDISK}1" ] || [ "$DATA_PART" == "${INSDISK}2" ]; then
				/tos/tlog -m "/data is under ${INSDISK}, should not format again."
			else
				/tos/tlog -m "Disk format /dev/${DATA_PART} start"
			#$MKFS_CMD -E lazy_itable_init=1 /dev/${INSDISK}4
				$MKFS_CMD /dev/${DATA_PART}
				if [ $? -eq 0 ]; then
					/tos/tlog -m "Disk format /dev/${DATA_PART} done"
				else
					/tos/tlog -m "Disk format /dev/${DATA_PART} failed"
					exit 1
				fi
			fi
		fi
	# fi # VM == 0

	/tos/tlog -m "Label start"
	e2label /dev/${INSDISK}1 /
	# if [ $VM -eq 0 ]; then # for physical machine only
	e2label /dev/${INSDISK}3 usrlocal
	e2label /dev/${INSDISK}4 data
	# fi
	/tos/tlog -m "Label done"
fi
