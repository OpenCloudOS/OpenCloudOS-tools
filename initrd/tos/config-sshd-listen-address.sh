#!/bin/bash
# configure installed system sshd listen address to eth1
# configure after network configuration
# Chapman Ou <chapmanou@tencent.com>
# 2013-12-19

NAME=ConfigSshdListenAddress
LOG_PREFIX="PostApp.${NAME}"
/tos/tlog -m "sshd ListenAddress start"


prepare()
{
	local mntdir=$1
	grep -q "rootsize=max" /proc/cmdline
    if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
        rootpart=${INSDISK}2
    else
        rootpart=${INSDISK}1
    fi
    mount /dev/$rootpart $mntdir
}


ConfigSshd()
{
	local mntdir=$1
	local eth1ip=$2
	if [ -f $mntdir/etc/tlinux-release ]; then
		sshdconf=$mntdir/etc/ssh/sshd_config
	elif [ -f $mntdir/etc/SuSE-release ]; then
		sshdconf=$mntdir/etc/ssh2/sshd2_config
	else 
		/tos/tlog -m "Unknown system"
		exit -1
	fi
	/tos/tlog -m "Configure sshd ListenAddress start"
	# Port 36000
	sed -i  "s/^ListenAddress.*$/ListenAddress $eth1ip/"  $sshdconf
	# Port 56000
	sed -i  "s/^ListenAddress.*$/ListenAddress $eth1ip/"  ${sshdconf}.l
}

GetEth1Ip()
{
	local mntdir=$1	
        if grep -q sshd= /proc/cmdline >/dev/null; then
		eth1ip=`sed -E 's/.*sshd=(\S+).*/\1/' /proc/cmdline`
	else
        if [ -z "$eth1ip" ]; then
		eth1ip=$(cat $mntdir/etc/sysconfig/network-scripts/ifcfg-eth1* |grep IPADDR| sed -E 's/IPADDR=['"'"'"]?([0-9.]*)['"'"'"]?/\1/')
	#if [ -z $eth1ip ]; then
	#	/tos/tlog -m "eth1 ip addr is not configure yet!"
	#fi
	fi
	fi
	echo "$eth1ip"
}

main()
{
	local mntdir="/mnt/harddisk/root"
	local eth1ip=""
	
	prepare $mntdir
	eth1ip=$(GetEth1Ip $mntdir)
        sleep 5 
	if [ -z "$eth1ip" ]; then
		umount $mntdir
		/tos/tlog -m "eth1ip is null, configure sshd done"
		return		
	fi
	ConfigSshd $mntdir $eth1ip

	if [ $? -eq 0 ]; then
		/tos/tlog -m "Configure sshd ListenAddress finished"
	else 
		/tos/tlog -m "Configure sshd ListenAddress failed"
	fi

	umount $mntdir
}

main
