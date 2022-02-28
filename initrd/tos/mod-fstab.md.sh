#!/bin/bash
/tos/tlog -m "modify fstab start"
ROOT=/mnt/harddisk/root
mdadm --detail-platform | grep -q "Rapid Storage Technology enterprise"
if [ $? -eq 0 ]; then
    mount /dev/md/Volume0_0p1 $ROOT
    sed -i 's/^#\/dev\/${INSDISK}4/\/dev\/${INSDISK}4/g' $ROOT/etc/fstab
    for ((i=1; i<5; i++)); do
        sed -i "s/\/dev\/${INSDISK}${i}/\/dev\/md\/Volume0_0p${i}/g" $ROOT/etc/fstab
    done

    if [ -d /sys/firmware/efi ]; then
        dd if=/dev/zero of=$ROOT/swapfile1 bs=1024 count=2104515
        mkswap $ROOT/swapfile1
        chmod 0600 $ROOT/swapfile1
        sed -i 's/\/dev\/md\/Volume0_0p2/\/swapfile1/' $ROOT/etc/fstab
        sed -i '/^\/dev\/md\/Volume0_0p1/a \/dev\/md\/Volume0_0p2\t\t/boot/efi\t\tvfat\tnoatime\t\t1 2' $ROOT/etc/fstab
    fi

    umount /dev/md/Volume0_0p1
fi
/tos/tlog -m "modify fstab done"
