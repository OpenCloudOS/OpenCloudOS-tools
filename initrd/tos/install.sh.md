#!/bin/bash
# Flag
SUCCESS=0

# asset id
ASSETID=$(dmidecode -s chassis-asset-tag)
export ASSET_ID="${ASSETID}"

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
md_b=`ls /dev/ | egrep "md[0-9]{1,}$" | head -n1`
if [ -n $md_b -a -b /dev/$md_b ]; then
    md_flag=1
    for ((i=1; i<5; i++)); do
        sed -i "s/\/dev\/sda${i}/\/dev\/${md_b}p${i}/g" `grep sda -rl /tos | grep -v md | grep -v install.sh`
    done
    sed -i "s/\/dev\/sda/\/dev\/${md_b}/g" `grep sda -rl /tos | grep -v install.sh | grep -v md`
fi

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
    grep -q "tlinux-64bit-v2" /proc/cmdline || grep -q "tlinux-64bit-v3" /proc/cmdline
    if [ $? -eq 0 ]; then
        /tos/configure-70-persistent-net.sh 
    fi
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
fi
SUCCESS=1
#/tos/umountdisk.sh
/sbin/hwclock -w
exit 0
# Post jobs 
