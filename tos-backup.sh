#!/bin/bash

# ===================================================
# Copyright (c) [2021] [Tencent]
# [OpenCloudOS Tools] is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2. 
# You may obtain a copy of Mulan PSL v2 at:
#            http://license.coscl.org.cn/MulanPSL2 
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.  
# See the Mulan PSL v2 for more details.  
# ===================================================

# Live TencentOS Backup, 2020
# Songqiao Tao <joeytao@tencent.com>

new_dir()
{
    local newdir="$*"
    i=0
    while [ -e $newdir ]; do
        i=`expr $i + 1`
        newdir="$*-$i"
    done
    echo $newdir
}

rebuildtree()
{ 
# Remounting the linux directories effectively excludes removable media, manually mounted devices, windows partitions, virtual files under /proc, /sys, /dev, etc. If your partition scheme is more complicated than listed below, you must add lines to rebuildtree() and destroytree(), otherwise the backup will be partial.
    mkdir /$1
    mount --bind / /$1
    mount --bind /boot /$1/boot
    mount --bind /boot/efi /$1/boot/efi
    mount --bind /home /$1/home
    #mount --bind /tmp /$1/tmp
    #mount --bind /usr /$1/usr
    #mount --bind /var /$1/var
    #mount --bind /srv /$1/srv
    #mount --bind /opt /$1/opt
    mount --bind /usr/local /$1/usr/local
}

destroytree()
{
    umount /$1/usr/local
    #umount /$1/opt
    #umount /$1/srv
    #umount /$1/var
    #umount /$1/usr
    #umount /$1/tmp
    umount /$1/home
    umount /$1/boot/efi
    umount /$1/boot
    umount /$1
    rmdir /$1
}

tos_backup()
{
    if [ -n "$1" ]; then
        back_op=$1
	if [ "$back_op"x == "reboot"x ];then
            /usr/lib/opencloudos-tools/tlinux_super_tool.py -b
	else
	    echo "Please type the correct parameters!"
	    echo "tos -b : backup the system online"
	    echo "tos -b reboot : reboot to backup the system"
	fi
	exit 0
    fi
    if [ ! -x /usr/sbin/mksquashfs ]; then
        echo "Try to install squashfs-tools rpm by yum!"
        yum -y install squashfs-tools > /dev/null 2>&1
    fi
    if [ ! -x /usr/sbin/mksquashfs ]; then
        echo "/usr/sbin/mksquashfs not found, please install squashfs-tools first!"
        exit -1
    fi

    bindingdir=`new_dir /tmp/bind`
    backupdir="/data/tlinux/backup"
    bindingdir="${bindingdir#/}"
    backupdir="${backupdir#/}"
    
    exclude=`new_dir /tmp/exclude`
    echo $backupdir > $exclude
    echo $bindingdir >> $exclude
    echo etc/udev/rules.d/70-persistent-net.rules >> $exclude
    echo etc/machine-id >> $exclude
    echo lost+found >> $exclude
    echo data/lost+found >> $exclude
    echo usr/local/lost+found >> $exclude
    echo var/cache/yum >> $exclude

    for i in `swapon -s | grep file | cut -d " " -f 1`; do
        echo "${i#/}" >> $exclude
    done
    
    for i in `ls /tmp -A`; do
        echo "tmp/$i" >> $exclude
    done

    rebuildtree $bindingdir
    #VER=$(awk '/Tencent/{print $4}' /etc/tlinux-release)
    VER=$(awk '/Tencent/{print $(NF-1)}' /etc/tlinux-release)
    mkdir -p "/$backupdir"
    sqfs=tlinux-64bit-v${VER}-backup.`date +"%Y-%m-%d-%H:%M"`.sqfs
    mksquashfs /$bindingdir "/$backupdir/${sqfs}" -comp xz -b 262144 -ef $exclude
    destroytree $bindingdir
    rm $exclude
    echo "Your backup is ready in /$backupdir/${sqfs}"
}

#tos_backup
