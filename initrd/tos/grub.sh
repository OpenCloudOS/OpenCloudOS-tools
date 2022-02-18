#!/bin/bash
/tos/tlog -m "Grub installation start"
ROOT=/mnt/harddisk/root
mkdir -p $ROOT
#umount all /mnt/harddisk mounted if mounted
#mount | grep "$ROOT" | awk '{print $3}' | sort -r | xargs umount
if [ -z "$INSDISK" ];then
	INSDISK="sda"
fi

grep -q "rootsize=max" /proc/cmdline
if [ $? -eq 0 -o $VM -eq 1 ]; then
        if [ -d /sys/firmware/efi ]; then
                mount /dev/${INSDISK}2 $ROOT
                mount /dev/${INSDISK}1 $ROOT/boot/efi
        else
                mount /dev/${INSDISK}1 $ROOT
        fi
else
        mount /dev/${INSDISK}1 $ROOT
        #mount /dev/${INSDISK}3 $ROOT/usr/local
        test -d /sys/firmware/efi && mount /dev/${INSDISK}2 $ROOT/boot/efi
fi


mount -o bind /dev $ROOT/dev
mount -t devpts devpts $ROOT/dev/pts
mount -t proc proc $ROOT/proc 
mount -t sysfs sysfs $ROOT/sys
#change password
#echo -n -e "Dis@init3\nDis@init3\n" | chroot $ROOT passwd
#chroot $ROOT chage -d 0 root

get_passwd() {
        # find passwd in /proc/cmdline
	grep -q "passwd=" /proc/cmdline
	if [ $? -eq 0 ]; then
        	c=$(cat /proc/cmdline);
        	on1=${c##*passwd=};
        	PASSWD=${on1%% *};
        	if [ -z "$PASSWD" ]; then
                	PASSWD=0
        	fi
	else
		PASSWD=0
	fi

}

# set passwd for root
set_passwd() {
        echo -e "================= set root password ==================="
        if read -n1 -t 15 -p "Do you want to set root password? [Press any key to set or waiting 15 seconds]: " answer
        then
                while ((1)); do
                        echo -e "================= set your root password ==================="
                        read -sp "input root password:" first_passwd
                        echo -e " "
                        if [ -z first_passwd ]; then
                        continue
                        fi

                        pwd_count=0
                        while ((1)); do
                        pwd_count=$((pwd_count+1))
                        read -sp "confirm your root password:" second_passwd
                        echo -e " "
                        if [ $first_passwd = $second_passwd ]; then
                                need_input=0
                                break
                        else
                                if [ $pwd_count -gt 2 ];then
                                need_input=1
                                break
                                fi
                                echo -e "\e[33mWarning\e[0m: not matched!"
                                continue
                        fi
                        done

                        if [ $need_input -eq 1 ]; then
                        echo -e "\e[31mError\e[0m: password retry over 3 times, please try again!"
                        continue
                        else
                        echo -n -e "$first_passwd\n$first_passwd\n" | chroot $ROOT passwd
                        if [ $? -eq 0 ]; then
                                echo -e "set root password $first_passwd succuss"
                                break
                        else
                                echo -e "\e[31mBAD PASSWORD\e[0m: Your password cannot be use!"
                                continue
                        fi
                        fi
                done
        else
                echo -n -e "TencentOS2021++\nTencentOS2021++\n" | chroot $ROOT passwd
                /tos/tlog -m "set default root passwd: TencentOS2021++" 
        fi
}

#recovery-mode remove /boot/*backup-recovery*
grep -q "recovery-mode" /proc/cmdline
if [ $? -eq 0 ]; then
	get_passwd
	if [ ${PASSWD} == "0" ]; then
		/tos/tlog -m "recovery-mode, and don't change passwd"
	else 
		/tos/tlog -m "recovery-mode, and change passwd"
		echo -n -e "${PASSWD}\n${PASSWD}\n" | chroot $ROOT passwd
	fi
	/tos/tlog -m "recovery-mode, remove /boot/*backup-recovery*"
	rm -fv $ROOT/boot/*backup-recovery*
else
	get_passwd
        if [ ${PASSWD} == "0" ]; then
            set_passwd
            #change password
            #/tos/tlog -m "change passwd to Tlinux2019++"
            #echo -n -e "Tlinux2019++\nTlinux2019++\n" | chroot $ROOT passwd
            /tos/tlog -m "change passwd for root"
        else
            set_passwd
            /tos/tlog -m "change passwd"
                #echo -n -e "${PASSWD}\n${PASSWD}\n" | chroot $ROOT passwd
        fi
	if [ -z ${PASSWD} ]; then
            set_passwd
	    #change password
	    #/tos/tlog -m "change passwd to Tlinux2019++"
	    #echo -n -e "Tlinux2019++\nTlinux2019++\n" | chroot $ROOT passwd
            /tos/tlog -m "change passwd for root"
        fi
fi

grep -q "tlinux-64bit-v2" /proc/cmdline || grep -q "tlinux-64bit-v3" /proc/cmdline
if [ $? -eq 0 ]
then
       #chroot $ROOT chage -d 0 root
	true
fi
#to get the right os name
#GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' $ROOT/etc/system-release)"
GRUBDIS_STR=$(sed -n '/^GRUB_DISTRIBUTOR=/p' $ROOT/etc/default/grub)
GRUB_DISTRIBUTOR=$(echo ${GRUBDIS_STR#*=})
eval GRUB_DISTRIBUTOR="$GRUB_DISTRIBUTOR"

GRUB_DISTRIBUTOR_L=$(echo ${GRUB_DISTRIBUTOR} | tr 'A-Z' 'a-z' | cut -d' ' -f1|LC_ALL=C sed 's,[^[:alnum:]_],_,g')
echo "GRUB_DISTRIBUTOR is "$GRUB_DISTRIBUTOR_L
if [ "$GRUB_DISTRIBUTOR_L"x = "tencentos"x ]; then
        GRUB_DISTRIBUTOR_L="tencent"
fi

if [ -f $ROOT/boot/grub2/grub.cfg ]; then
        # grub2
        #mdadm --detail-platform | grep -q "Rapid Storage Technology enterprise"
        #if [ $? -eq 0 ]; then
        #        echo "modify /etc/default/grub!"
        #        chroot $ROOT mdadm --detail --scan --verbose > $ROOT/etc/mdadm.conf
        #        for i in `cat $ROOT/etc/mdadm.conf | egrep -o [:0-9a-zA-Z]{35}`;do
        #                sed -i "s/console=tty0/console=tty0 rd.md.uuid=${i}/" $ROOT/etc/default/grub
        #        done
        #fi
        if [ $VM -eq 1 ]; then
                sed -i "s/console=tty0/console=tty0 console=ttyS0,115200/" $ROOT/etc/default/grub
        fi
        chroot $ROOT rm -rf /boot/initramfs*
        chroot $ROOT cp -f /etc/dracut.conf /etc/dracut.conf.bak
        /tos/tlog -m "mkinitrd, waiting"
        kern_ver=`ls $ROOT/boot/vmlinuz* | tail -n1 | cut -d "-" -f 2-`
        result=`chroot $ROOT dracut -f /boot/initramfs-${kern_ver}.img ${kern_ver} 2>&1`
        /tos/tlog -m "$result"
        err=`echo "$result" | grep "ERROR"`
        if [ $? -eq 0 ]; then
                for i in {1..5}; do
                        /tos/tlog -m "mkinitrd failed, retry ${i}..."
                        err_driver=${err#*"'"}
                        err_driver=${err_driver%*"'"}
                        sed -i "s/$err_driver//g" $ROOT/etc/dracut.conf
                        result=`chroot $ROOT dracut -f /boot/initramfs-${kern_ver}.img ${kern_ver} 2>&1`
                        /tos/tlog -m "$result"
                        err=`echo "$result" | grep "ERROR"`
                        if [ $? -ne 0 ]; then
                                break
                        fi
                        if [ $i -eq 5 ]; then
                                /tos/tlog -m "mkinitrd failed, initramfs may be incomplete."
                        fi
                done
        fi
        /tos/tlog -m "mkinitrd done!"

        if [ -d /sys/firmware/efi ]; then
                if [ ! -d $ROOT/boot/efi/EFI/$GRUB_DISTRIBUTOR_L ]; then
                        mkdir -p $ROOT/boot/efi/EFI/$GRUB_DISTRIBUTOR_L/
                        cp $ROOT/boot/efi/EFI/centos/grubx64.efi  $ROOT/boot/efi/EFI/$GRUB_DISTRIBUTOR_L/
cat > $ROOT/boot/efi/EFI/$GRUB_DISTRIBUTOR_L/grub.cfg <<EOF 
search --no-floppy --set prefix --file /boot/grub2/grub.cfg
set prefix=(\$prefix)/boot/grub2
configfile \$prefix/grub.cfg
EOF
                fi
                grep -q "rootsize=max" /proc/cmdline
                if [ $? -eq 0 -o $VM -eq 1 ]; then
                        chroot $ROOT efibootmgr -c -d /dev/${INSDISK} -p 1 -l \\EFI\\tencent\\grubx64.efi -L $GRUB_DISTRIBUTOR_L
                else
                        chroot $ROOT efibootmgr -c -d /dev/${INSDISK} -p 2 -l \\EFI\\tencent\\grubx64.efi -L $GRUB_DISTRIBUTOR_L
                fi
                chroot $ROOT /usr/sbin/grub2-set-default 0
                chroot $ROOT /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
        else
                chroot $ROOT /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
                chroot $ROOT /usr/sbin/grub2-install /dev/${INSDISK}
                chroot $ROOT /usr/sbin/grub2-set-default 0
        fi

	# for secureboot
        #if [ -d /sys/firmware/efi -a -f $ROOT/boot/efi/EFI/tencent/grubx64.efi ]; then
        #       cp /tos/grubx64.efi.signed $ROOT/boot/efi/EFI/tencent/grubx64.efi
	#	chmod 755 $ROOT/boot/efi/EFI/tencent/grubx64.efi
        #fi
	# end for secureboot

        #defkernel=$(grep -iR "\$menuentry_id_option" $ROOT/boot/grub2/grub.cfg | awk -F\' '/menuentry/{print $2}' | head -n1);
else
        chroot $ROOT grub-install /dev/${INSDISK}
        if [ -d /sys/firmware/efi -a -f $ROOT/boot/efi/EFI/$GRUB_DISTRIBUTOR_L/grub.efi ]; then
                chroot $ROOT efibootmgr -c -d /dev/${INSDISK} -p 2 -l \\EFI\\tencent\\grub.efi -L $GRUB_DISTRIBUTOR_L
        fi
fi

if [ -f /tos/img/hardinstall_extra.rpm ]; then
	/tos/tlog -m "Install extra rpm"
	cp /tos/img/hardinstall_extra.rpm $ROOT
        chroot $ROOT /bin/rpm -Uvh hardinstall_extra.rpm
	rm $ROOT/hardinstall_extra.rpm
fi

if [ -f /tos/img/hardinstall_rc.local ]; then
	/tos/tlog -m "Append extra rc.local"
        cat /tos/img/hardinstall_rc.local >> $ROOT/etc/rc.d/rc.local
fi
if [ -f /tos/img/hardinstall_script ]; then
	/tos/tlog -m "run extra script in side chroot"
	cp /tos/img/hardinstall_script $ROOT
	chmod +x $ROOT/hardinstall_script
	chroot $ROOT /hardinstall_script
	rm $ROOT/hardinstall_script
	fuser -k -9 $ROOT
fi

# umount all /mnt/harddisk mounted if mounted
mount | grep "$ROOT" | awk '{print $3}' | sort -r | xargs umount

/tos/tlog -m "Grub installation done"
