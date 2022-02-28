#!/bin/bash
/tos/tlog -m "modify fstab start"


set_uuid()
{
    if [ -f "/tos/use_uuid_flag" ]; then
		/tos/tlog -m "use uuid, update fstab with uuid"

		grep -q "rootsize=max" /proc/cmdline
        if [ $? -eq 0 -o $VM -eq 1 ]; then
			if [ -d /sys/firmware/efi ]; then
            	rootpart=${INSDISK}2
				efipart=${INSDISK}1
				efi_line=`grep "^[^#].*\s/boot/efi\s" $ROOT/etc/fstab`
				if [ $? -eq 0 ]; then
					old_dev=`echo $efi_line | awk '{print $1}'`
					sed -i "s/^$old_dev/\/dev\/$efipart/" $ROOT/etc/fstab
				fi
        	else
            	rootpart=${INSDISK}1
			fi
		else
			rootpart=${INSDISK}1
			part2dev=${INSDISK}2
			usrlocalpart=${INSDISK}3
			datapart=${INSDISK}4

			if [ -d /sys/firmware/efi ]; then
            	diskpart2="/boot/efi"
        	else
            	diskpart2="swap"
			fi
		
			part2_line=`grep "^[^#].*\s${diskpart2}\s" $ROOT/etc/fstab`
			if [ $? -eq 0 ]; then
				old_dev=`echo $part2_line | awk '{print $1}'`
				sed -i "s/^$old_dev/\/dev\/$part2dev/" $ROOT/etc/fstab
			fi
			usrlocal_line=`grep "^[^#].*\s/usr/local\s" $ROOT/etc/fstab`
			if [ $? -eq 0 ]; then
				old_dev=`echo $usrlocal_line | awk '{print $1}'`
				sed -i "s/^$old_dev/\/dev\/$usrlocalpart/" $ROOT/etc/fstab
			fi
			data_line=`grep "^[^#].*\s/data\s" $ROOT/etc/fstab`
			if [ $? -eq 0 ]; then
				old_dev=`echo $data_line | awk '{print $1}'`
				sed -i "s/^$old_dev/\/dev\/$datapart/" $ROOT/etc/fstab
			fi
        fi

		root_line=`grep "^[^#].*\s/\s" $ROOT/etc/fstab`
		if [ $? -eq 0 ]; then
			old_dev=`echo $root_line | awk '{print $1}'`
			sed -i "s/^$old_dev/\/dev\/$rootpart/" $ROOT/etc/fstab
		fi

		for i in $(seq 1 5)
		do
			grep -q "/dev/${INSDISK}$i" $ROOT/etc/fstab
			if [ $? -eq 0 ]; then
				UUIDX=`ls -l /dev/disk/by-uuid/ | grep ${INSDISK}$i | awk '{print $9}'`
				sed -i "s/^\/dev\/${INSDISK}$i/UUID=${UUIDX}/" $ROOT/etc/fstab
			fi
		done
	
        sed -i 's/GRUB_DISABLE_LINUX_UUID="true"/GRUB_DISABLE_LINUX_UUID="false"/' $ROOT/etc/default/grub
    fi
}

ROOT=/mnt/harddisk/root
grep -q "rootsize=max" /proc/cmdline
if [ $? -eq 0 -o $VM -eq 1 ]; then
    if [ -d /sys/firmware/efi ]; then
        rootpart=${INSDISK}2
    else
        rootpart=${INSDISK}1
    fi
	mount /dev/$rootpart $ROOT
	# delete dev/sda2 swap partition
	sed -i "/swap/d" $ROOT/etc/fstab
	# delete dev/sda3 /usr/local swap partition
    sed -i "/usr\/local/d" $ROOT/etc/fstab
	if [[ ${INSDISK} =~ nvme.* ]]; then
        sed -i "s/sda/${INSDISK}p/g" $ROOT/etc/fstab
    else
        sed -i "s/sda/${INSDISK}/g" $ROOT/etc/fstab
    fi

	if [ -d /sys/firmware/efi ]; then
		sed -i "s/\/dev\/${INSDISK}1/\/dev\/${INSDISK}2/" $ROOT/etc/fstab
		sed -i "/^\/dev\/${INSDISK}2/a \/dev\/${INSDISK}1\t\t/boot/efi\t\tvfat\tnoatime\t\t1 2" $ROOT/etc/fstab
	fi
	set_uuid
	umount /dev/$rootpart
    /tos/tlog -m "modify fstab done"

else
	mount /dev/${INSDISK}1 $ROOT

	if [[ ${INSDISK} =~ nvme.* ]]; then
        sed -i "s/sda/${INSDISK}p/g" $ROOT/etc/fstab
    else
    	sed -i "s/sda/${INSDISK}/g" $ROOT/etc/fstab
    fi

	sed -i "s/^#\/dev\/${INSDISK}4/\/dev\/${INSDISK}4/g" $ROOT/etc/fstab
	if [ -d /sys/firmware/efi ]; then
        dd if=/dev/zero of=$ROOT/swapfile1 bs=1024 count=2104515
		mkswap $ROOT/swapfile1
        chmod 0600 $ROOT/swapfile1
		grep -q "\/boot\/efi" $ROOT/etc/fstab
		if [ $? -eq 0 ]; then
			/tos/tlog -m "recovery mode, EFI to EFI, no need to change"
		else
        	sed -i "s/\/dev\/${INSDISK}2/\/swapfile1/" $ROOT/etc/fstab
			sed -i "/^\/dev\/${INSDISK}1/a \/dev\/${INSDISK}2\t\t/boot/efi\t\tvfat\tnoatime\t\t1 2" $ROOT/etc/fstab
		fi
	else
		grep -q "\/boot\/efi" $ROOT/etc/fstab
        if [ $? -eq 0 ]; then
            /tos/tlog -m "recovery mode, EFI to Legacy, need to change"
			sed -i "/\/boot\/efi/d" $ROOT/etc/fstab
			sed -i "s/\/swapfile1/\/dev\/${INSDISK}2/" $ROOT/etc/fstab
		fi
	fi

	#grep -q "recovery-mode" /proc/cmdline
	#if [ $? -eq 0 ]; then
	data_f=$(parted /dev/${INSDISK}4 print | grep -A 1 Number | awk 'NR==2 {print $5}')
	grep -q "tlinux-.*v1" /proc/cmdline	
	if [ $? -eq 0 -a ${data_f} == "ext4" ]; then
		sed -i "/^\/dev\/${INSDISK}4/{s/ext3/ext4/}" $ROOT/etc/fstab
	fi
	grep -q "tlinux-.*v2" /proc/cmdline || grep -q "tlinux-.*v3" /proc/cmdline    
	if [ $? -eq 0 -a ${data_f} == "ext3" ]; then 
        sed -i "/^\/dev\/${INSDISK}4/{s/ext4/ext3/}" $ROOT/etc/fstab
	fi
	#fi

	# if ${INSDISK} is big than 8T and is tlinux1.2-tkernel system ,use ext4 to mkfs,so we should modify fstab. add by zgpeng 20160921
	DISK_BIG_THAN_8T=1
	#disk_size=`fdisk -l /dev/${INSDISK} | grep 'Disk /dev/' | cut -d ' ' -f 5`
	#if [ $disk_size -gt 8796093022208 ]; then # 8TB = 8*1024*1024*1024*1024
       # 	DISK_BIG_THAN_8T=1
        #fi

	TLINUX1_2_TKERNEL2=0
	grep -q "tlinux-tkernel2-64bit-v1" /proc/cmdline
	if [ $? -eq 0 ]
	then
        TLINUX1_2_TKERNEL2=1
	fi

	if [ $DISK_BIG_THAN_8T -eq 1 -a $TLINUX1_2_TKERNEL2 -eq 1 ]; then
		sed -i "/\/dev\/${INSDISK}/s/ext3/ext4/g" $ROOT/etc/fstab
	fi

	set_uuid
	umount /dev/${INSDISK}1
	/tos/tlog -m "modify fstab done"
fi
