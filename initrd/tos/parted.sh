#/bin/bash
:<<!
In uefi mode, rootsize=max or in virtual machine, disk will be parted
into two partitions: efi part(sda1) and root part(sda2). otherwise, 
there will have four partitions, root part(sda1), efi part(sda2), sda3-4.

In legacy mode, rootsize=max or in virtual machine, disk only has
one partition, the root part(sda1). otherwise four part, sda2 will
be swap partition.
!
#recovery-mode, and not found format_data=1 don't partition the disk
grep -q "recovery-mode" /proc/cmdline
if [ $? -eq 0 ]; then
	grep -q "format_data=1" /proc/cmdline
	if [ $? -ne 0 ]; then
        /tos/tlog -m "recovery-mode, and format_data=0 don't partition the disk"
		exit 0
	fi
elif [ -b /dev/${INSDISK}4 ];then
        #/tos/tlog -m "By default we will not format ${INSDISK}4"
#        touch /tlinux_not_part
#        exit 0
	echo "${INSDISK}4 exist"
fi

grep -q "not_part" /proc/cmdline
if [ $? -eq 0 ]; then
	touch /tlinux_not_part
	/tos/tlog -m "not_part, don't partition the disk"
	exit 0
fi



get_rootsize() {
	grep -q "rootsize=" /proc/cmdline
	if [ $? -eq 0 ]; then
		c=$(cat /proc/cmdline);
		on1=${c##*rootsize=};
		ROOTSIZE=${on1%% *};
		if [ -z "$ROOTSIZE" ]; then
				ROOTSIZE=20
		fi
	    if [ ${ROOTSIZE}x = "max"x ]; then
			ROOTSIZE=max
		else
			if [ "$ROOTSIZE" -gt 0 ] 2>/dev/null ;then
				echo "rootsize=$ROOTSIZE"
			else
				ROOTSIZE=20
			fi
		fi
	else
		ROOTSIZE=20
	fi
}

get_rootsize
#if [ ${ROOTSIZE}x != "20"x ]; then
        a1=$((${ROOTSIZE} * 1024 + 1529))
        a2=$(($a1 + 512))
        a3=$(($a2 + 20480))
cat > /tos/parted-efi.s <<EOF
select /dev/${INSDISK}
mklabel gpt
unit MiB
mkpart primary ext2 1 $a1
mkpart primary fat32 $a1 $a2
mkpart primary ext2 $a2 $a3
mkpart primary ext2 $a3 -1
set 2 boot on
quit
EOF





        a1=$((${ROOTSIZE} * 1024 + 1))
        a2=$(($a1 + 2040))
        a3=$(($a2 + 20480))
cat > /tos/parted-tlinux2.s <<EOF
select /dev/${INSDISK}
mklabel msdos
unit MiB
mkpart primary ext2 1 $a1
mkpart primary linux-swap $a1 $a2
mkpart primary ext2 $a2 $a3
mkpart primary ext2 $a3 -1
set 1 boot on
quit
EOF
cp /tos/parted-tlinux2.s /tos/parted.s

        a1=$((${ROOTSIZE} * 1024 + 1))
        a2=$(($a1 + 2040))
        a3=$(($a2 + 20480))
cat > /tos/parted-tlinux2-gpt.s <<EOF
select /dev/${INSDISK}
mklabel gpt
unit MiB
mkpart primary ext2 1 $a1
mkpart primary linux-swap $a1 $a2
mkpart primary ext2 $a2 $a3
mkpart primary ext2 $a3 -5
mkpart primary ext2 -5 -1
set 1 boot on
set 5 bios_grub on
quit
EOF

#fi



for ((i=1; i<5; i++)); do
    grep -q ${INSDISK}${i} /proc/mounts && /bin/umount /dev/${INSDISK}${i}
done

/tos/tlog -m "Clean /dev/${INSDISK}"
dd if=/dev/zero of=/dev/${INSDISK} bs=1M count=10
/tos/tlog -m "Part start"
sed -i "s/sda/${INSDISK}/g" /tos/parted-one-efi.s
sed -i "s/sda/${INSDISK}/g" /tos/parted-one.s

if [ -d /sys/firmware/efi ]; then
	/tos/tlog -m "efi mode"
	# if set rootsize to max or in the vm, just part disk into two partitions
	echo ${ROOTSIZE} | grep -qi max
	if [ $? -eq 0 -o $VM -eq 1 ]; then
		/sbin/parted < /tos/parted-one-efi.s
	else
		/sbin/parted < /tos/parted-efi.s
	fi
else
	# use gpt label if disk size is greater than 2TB, otherwise use msdos
	disk_size=`fdisk -l /dev/${INSDISK} | grep 'Disk /dev/' | cut -d ' ' -f 5`
	if [ "$disk_size" -gt 2199023255552 ]; then # 2TB = 2*1024*1024*1024*1024
		sed -i 's/mklabel.*/mklabel gpt/' /tos/parted*.s
	else
		sed -i 's/mklabel.*/mklabel msdos/' /tos/parted*.s
	fi

	# as we only need to support linux v2.x v3.x, so the else part can be comment.
	# grep -q "tlinux-64bit-v2" /proc/cmdline || grep -q "tlinux-64bit-v3" /proc/cmdline
	# if [ $? -eq 0 ]
	# then
	if [ ${ROOTSIZE}x = "max"x -o $VM -eq 1 ]; then
		/sbin/parted < /tos/parted-one.s
	else
		# grep -q "xvda" /proc/cmdline
		# if [ $? -eq 0 ]; then
		# 	/tos/tlog -m "use parted-xenU2.s"
		# 	/sbin/parted < /tos/parted-xenU2.s
		if [ "$disk_size" -gt 2199023255552 ]; then
			/sbin/parted < /tos/parted-tlinux2-gpt.s
		else
			/sbin/parted < /tos/parted-tlinux2.s
		fi
	fi
	# else
	# 	grep -q "xvda" /proc/cmdline
	# 	if [ $? -eq 0 ]; then
	# 		/sbin/parted < /tos/parted-xenU.s
	# 	else
	# 		/sbin/parted < /tos/parted.s
	# 	fi
	# fi
fi
/tos/tlog -m "Part done"

/sbin/partprobe /dev/${INSDISK}
if [ $? -eq 0 ]; then
	/tos/tlog -m "partprobe done"
else
	/tos/tlog -m "partprobe failed"
	exit 1
fi
sleep 2
