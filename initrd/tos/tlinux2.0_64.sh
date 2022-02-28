#!/bin/bash
# tlinux2.0 64bit img script
# joeytao
SED="sed"
AWK="awk"

MSERIAL=`hwinfo --bios | awk -F ' ' ' { if (( $1 == "System" )&&($2 == "Info:")) a="1" ; if(( a == "1")&&( $1 == "Serial:" )) { print $2;exit;} }' | cut -d '"' -f 2`
ASSETTAG=`hwinfo --bios | grep "Tag: \"" | head -1 | awk -F\" '{print $2}'`

if [ "$MSERIAL" == "" ]; then
   if [ "$ASSETTAG" == "" ]; then
      MSERIAL=`ls /dev/disk/by-uuid/| head -1`
   else
      MSERIAL=$ASSETTAG
   fi
fi

echo SN=$MSERIAL


if [ "$ASSETTAG" == "" ]; then
    ASSETTAG=$MSERIAL
fi

echo AssetTag=$ASSETTAG

CLIIP=`ifconfig | grep inet | head -n 1 | cut -d ":" -f 2 | awk -F " " '{ print $1 }'`


/tos/OSDeployPro.sh

if [ ! -s /tmp/ip.lst ]
then
   echo "ip.lst is empty.Please check."
   exit 0
fi

if [ `awk '{print NF}' /tmp/ip.lst` -eq 3 ] || [ `awk '{print NF}' /tmp/ip.lst` -eq 6 ]
then
   echo "Continue to deploy...."
else
   echo "Format is not right in ip.lst.Please check"
   exit 0
fi


OK=0
ERROR=-1

function replace()
{
        _SOURCE=$1
        _TARGET=$2
        _FILENAME=$3
        if [ $# -ne 3 ]
        then
                echo "ERROR: argc error, use replace <source> <target> <filename>"
        fi

        $SED "s/${_SOURCE}/${_TARGET}/" ${_FILENAME} > /tmp/tmp$$.txt
        cp /tmp/tmp$$.txt ${_FILENAME}
       	rm /tmp/tmp$$.txt
}

#==============================================================================
# Function: prep_tlinux
# Usage:    prep_tlinux <rootdir>
#           release: Tencent Linux 
# Returns:  Nothing
#==============================================================================
prep_tlinux () {
	ROOTDIR="$1"

  
	#if [ ! -f $ROOTDIR/etc/tlinux-release ] ; then
	#	return #ERROR
	#fi

	IF_ETH0="$ROOTDIR/etc/sysconfig/network-scripts/ifcfg-eth0"
	IF_ETH1="$ROOTDIR/etc/sysconfig/network-scripts/ifcfg-eth1"
	IF_REN="$ROOTDIR/etc/udev/rules.d/70-persistent-net.rules"

	if [ "$IF_REN" != "" ] ; then
		echo "" > $IF_REN
	fi

	IPAddress0=""
	if [ -f /tmp/ip.lst ] ; then
		IPAddress0=`cat /tmp/ip.lst | head -1 | awk '{print $1}'`
	fi
	ETH1IP="$IPAddress0"
	if [ "$ETH1IP" != "" ] ; then
		echo ETH1IP=$ETH1IP
		$SED "s/IPADDR=''/IPADDR=\'${ETH1IP}\'/" ${IF_ETH1} > /tmp/tmp$$.txt
		cp /tmp/tmp$$.txt ${IF_ETH1}
		#$SED "s/ListenAddress.*172/ListenAddress      ${ETH1IP}/" $ROOTDIR/etc/ssh/sshd_config > /tmp/tmp$$.txt
		#cp /tmp/tmp$$.txt $ROOTDIR/etc/ssh/sshd_config
		#$SED "s/ListenAddress.*172/ListenAddress      ${ETH1IP}/" $ROOTDIR/etc/ssh/sshd_config.l > /tmp/tmp$$.txt
		#cp /tmp/tmp$$.txt $ROOTDIR/etc/ssh/sshd_config.l
		rm /tmp/tmp$$.txt
	fi

	SubnetMask0=""
	if [ -f /tmp/ip.lst ] ; then
		SubnetMask0=`cat /tmp/ip.lst | head -1 | awk '{print $2}'`
	fi
	MASK1="$SubnetMask0"
	if [ "$MASK1" != "" ] ; then
		echo MASK1=$MASK1
		$SED "s/NETMASK=''/NETMASK=\'${MASK1}\'/" ${IF_ETH1} > /tmp/tmp$$.txt
		cp /tmp/tmp$$.txt ${IF_ETH1}
		rm /tmp/tmp$$.txt
	fi

	DefaultGateway0=""
	if [ -f /tmp/ip.lst ] ; then
		DefaultGateway0=`cat /tmp/ip.lst | head -1 | awk '{print $3}'`
	fi
	GATEWAYL="$DefaultGateway0"
	if [ "GATEWAYL" != "" ] ; then
		echo GATEWAYL=$GATEWAYL
		replace GATEWAY=\'\' GATEWAY=\'${GATEWAYL}\' ${IF_ETH1}
		$SED "s/ONBOOT=''/ONBOOT=\'yes\'/" ${IF_ETH1} > /tmp/tmp$$.txt
		cp /tmp/tmp$$.txt ${IF_ETH1}
		rm /tmp/tmp$$.txt
	fi

	IPAddress1=""
	if [ -f /tmp/ip.lst ] ; then
		IPAddress1=`cat /tmp/ip.lst | head -1 | awk '{print $4}'`
	fi
	ETH0IP="$IPAddress1"
	if [ "$ETH0IP" != "" ] ; then
		echo ETH0IP=$ETH0IP
		$SED "s/IPADDR=''/IPADDR=\'${ETH0IP}\'/" ${IF_ETH0} > /tmp/tmp$$.txt
		cp /tmp/tmp$$.txt ${IF_ETH0}
		rm /tmp/tmp$$.txt
	fi

	SubnetMask1=""
	if [ -f /tmp/ip.lst ] ; then
		SubnetMask1=`cat /tmp/ip.lst | head -1 | awk '{print $5}'`
	fi
	MASK0="$SubnetMask1"
	if [ "$MASK0" != "" ] ; then
		echo MASK0=$MASK0
		$SED "s/NETMASK=''/NETMASK=\'${MASK0}\'/" ${IF_ETH0} > /tmp/tmp$$.txt
		cp /tmp/tmp$$.txt ${IF_ETH0}
		rm /tmp/tmp$$.txt
	fi

	DefaultGateway1=""
	if [ -f /tmp/ip.lst ] ; then
		DefaultGateway1=`cat /tmp/ip.lst | head -1 | awk '{print $6}'`
	fi
	GATEWAY="$DefaultGateway1"
	if [ "$GATEWAY" != "" ] ; then
		echo GATEWAY=$GATEWAY
		replace GATEWAY=\'\' GATEWAY=\'${GATEWAY}\' ${IF_ETH0}
		$SED "s/ONBOOT=''/ONBOOT=\'yes\'/" ${IF_ETH0} > /tmp/tmp$$.txt
		cp /tmp/tmp$$.txt ${IF_ETH0}
		rm /tmp/tmp$$.txt
	fi

	   ##############################################
	    ## add something you want in the ifcfg-ethX ##
	    ##############################################
	return $OK
}
ROOT=/mnt/harddisk/root
prep_tlinux $ROOT
