#! /bin/bash

ROOT=/mnt/root
mkdir -p $ROOT
mount /dev/${INSDISK}1 $ROOT

# modify fstab
echo "modify fstab"
sed -i 's/${INSDISK}1/xvda1/' $ROOT/etc/fstab
sed -i 's/${INSDISK}4/xvdb1/' $ROOT/etc/fstab
sed -i 's/ext3/ext4/' $ROOT/etc/fstab
sed -i '/${INSDISK}[2-3]/d' $ROOT/etc/fstab

# add swapfile
echo "create swapfile"
dd if=/dev/zero of=$ROOT/swapfile1 bs=1024 count=2104515
mkswap $ROOT/swapfile1
sed -i '/xvda1/a /swapfile1 swap swap defaults 0 0' $ROOT/etc/fstab
cat $ROOT/etc/fstab

# update grub
echo "update grub"
sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="showopts i8042.noaux sysfs.deprecated=1 console=tty0 console=ttyS0"/' $ROOT/etc/default/grub
mount --bind /dev $ROOT/dev
chroot $ROOT grub2-mkconfig
sed -i 's/${INSDISK}/xvda/g' $ROOT/boot/grub2/grub.cfg

umount $ROOT/dev
umount $ROOT
rmdir $ROOT
