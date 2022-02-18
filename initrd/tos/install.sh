#!/bin/bash
# Flag
SUCCESS=0

# asset id
ASSETID=$(dmidecode -s chassis-asset-tag)
export ASSET_ID="${ASSETID}"
INSDISK="sda"
#export INSDISK="sda"
uname -a
cat /etc/motd

# Ok, last
last_word()
{
	if [ $SUCCESS -eq 1 ]; then
		/tos/tlog -m "Installation finished" 
		/tos/tlog -m "Please type 'reboot -f' to reboot from harddisk!"
	else
		/tos/tlog -m "Installation failed"
	fi
}

trap last_word EXIT
md_flag=0
get_disk_flag=0


get_installdisk() {
        # find installdisk in /proc/cmdline
        grep -q "installdisk=" /proc/cmdline
        if [ $? -eq 0 ]; then
            c=$(cat /proc/cmdline);
            on1=${c##*installdisk=};
            IN_DISK=${on1%% *};
            if [ -z "$IN_DISK" ]; then
                IN_DISK=sda
            else
                get_disk_flag=1
            fi
        else
            IN_DISK=sda
        fi

}

get_installdisk

grep -q "use_uuid" /proc/cmdline
if [ $? -eq 0 ]; then
    touch /tos/use_uuid_flag
fi

if [ $get_disk_flag -eq 0 ]; then
  if read -n1 -t 6 -p "Do you want to select the disk to install OpenCloudOS? [Press any key to continue]" answer
  then
    while ((1)); do
        echo -e "\n=========== disk information =============="
        lsblk
        echo "==========================================="
        echo -e "\nWhich disk do you want to install OpenCloudOS (for example:sda):"
        read disk_name
        /tos/tlog -m "you choose $disk_name"
        if [ -b /dev/$disk_name ];then
            /tos/tlog -m  "/dev/$disk_name is ok, OpenCloudOS will be installed on $disk_name"
            IN_DISK=$disk_name
            break
        else
            echo "$disk_name is not a suitable disk,please type again."
        fi
    done
  else
        # choose the first *da(sda/vda) to install, rather than using sda default
        # this is only for kvm install
        getdisk=$(lsblk | grep da[^1-9] | awk 'NR==1{print $1}')
        if [ -n "${getdisk}" ]; then
            IN_DISK=${getdisk}
        fi
    /tos/tlog -m "OpenCloudOS will be installed on ${IN_DISK}"
  fi
fi

if [ ${IN_DISK}x != "sda"x ]; then
    touch /tos/use_uuid_flag
fi
# acutally, the code is useless as there is no such sda[1-9] in *.sh files
if [[ ${IN_DISK} =~ nvme.* ]]; then
    ls /tos/*.sh | grep -v install.sh | xargs sed -i 's/{INSDISK}1/{INSDISK}p1/g'
    ls /tos/*.sh | grep -v install.sh | xargs sed -i 's/{INSDISK}2/{INSDISK}p2/g'
    ls /tos/*.sh | grep -v install.sh | xargs sed -i 's/{INSDISK}3/{INSDISK}p3/g'
    ls /tos/*.sh | grep -v install.sh | xargs sed -i 's/{INSDISK}4/{INSDISK}p4/g'
    ls /tos/*.sh | grep -v install.sh | xargs sed -i 's/{INSDISK}5/{INSDISK}p5/g'
    ls /tos/*.sh | grep -v install.sh | xargs sed -i 's/${INSDISK}$i/${INSDISK}p$i/g'
fi

export INSDISK=$IN_DISK
/tos/tlog -m " "
/tos/tlog -m "OpenCloudOS will be installed on $INSDISK"
# why remove all device mapper
dmsetup  remove_all

grep -q "windows" /proc/cmdline
if [ $? -eq 0 ]; then
    /tos/network-config.sh
    /tos/win.sh
else
    #/tos/udevrename -rules=/etc/udev/rules.d/70-persistent-net.rules
    #test $? -ne 0 && exit 1
    /tos/network-config.sh
    #test $? -ne 0 && exit 1
    /tos/prepare-img.sh
    test $? -ne 0 && exit 1
    /tos/tlog -m "Installation start"
    /tos/parted.sh
    test $? -ne 0 && exit 1
    /tos/mkfs.sh
    test $? -ne 0 && exit 1
    /tos/img.sh
    test $? -ne 0 && exit 1
    if [ $md_flag -eq 0 ]; then
        /tos/mod-fstab.sh
    else
        /tos/mod-fstab.md.sh
    fi
    test $? -ne 0 && exit 1
    /tos/target-network-config.sh
    test $? -ne 0 && exit 1
    # as we always using tl2 or tl3, no need to judge the version
    # grep -q "tlinux-64bit-v2" /proc/cmdline || grep -q "tlinux-64bit-v3" /proc/cmdline
    # if [ $? -eq 0 ]; then
    /tos/configure-70-persistent-net.sh
    # fi
    test $? -ne 0 && exit 1
    /tos/configure-iso-install-network.sh
    test $? -ne 0 && exit 1
    /tos/config-sshd-listen-address.sh
    test $? -ne 0 && exit 1
    /tos/grub.sh
    test $? -ne 0 && exit 1
    # Ok, run post
    #grep -q "installmethod=net" /proc/cmdline
    #if [ $? -eq 0 ]; then
     #   /tos/simplepost -appconf http://192.168.199.200:8444/postapp/conf/app.conf -machconf http://192.168.199.200:8444/postapp/conf/mach.conf
     #   test $? -ne 0 && exit 1
    #else
     #   echo "simplepost done"
    #fi
    
    # work for xenU
    grep -q "xvda" /proc/cmdline
    if [ $? -eq 0 ]; then
        /tos/xenwork.sh
    fi

    /tos/tlog -m "PXE kernel:"
    uname -r
    /tos/tlog -m "lsblk:"
    lsblk
    /tos/tlog -m "lsscsi:"
    lsscsi
    if [ -d /sys/firmware/efi ]; then
        /tos/tlog -m "efibootmgr -v:"
        efibootmgr -v
    fi
fi
SUCCESS=1
#/tos/umountdisk.sh
/sbin/hwclock -w
sync
exit 0
