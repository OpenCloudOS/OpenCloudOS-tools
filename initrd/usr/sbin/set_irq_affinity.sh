#!/bin/bash
# setting up irq affinity according to /proc/interrupts
# adapted from the one from intel driver
# version 0.1:  mjqiu <mjqiu@tencent.com> 
#      Initial version, a best effort to set cpu affinity for both intel and bnx2 drivers
# version 0.2:  lynnsong <lynnsong@tencent.com>
#      Added chelsio netcard support
# version 0.3:  lynnsong <lynnsong@tencent.com>
#      Don't kill irqbalance if there is no mutiqueue netcard

version=0.3

set_affinity()
{
    printf "%s mask=%X for /proc/irq/%d/smp_affinity\n" $DEV $MASK $IRQ
    printf "%X" $MASK > /proc/irq/$IRQ/smp_affinity
}

set_intel_broadcom()
{
	#  Intel##########
	#  Assuming a device with two RX and TX queues.
	#  This script will assign: 
	#
	#	eth0-rx-0  CPU0
	#	eth0-rx-1  CPU1
	#	eth0-tx-0  CPU0
	#	eth0-tx-1  CPU1
	# Intel###########
	
	# broadcom########
	# bnx2:
	# eth0-0 eth0-1 eth0-2 eth0-3 eth0-4
	# eth0-0 eth0-1 eth0-2 eth0-3
	# bnx2x:
	# eth0-rx-0 eth0-rx-1 ...
	# eth0-tx-0 eth0-tx-1 ...
	# broadcom########

	local MAX_CPU=$(( $(grep processor /proc/cpuinfo | wc -l) ))
	cd /proc/irq
	ls -d */eth* | sed 's/[^0-9][^0-9]*/ /g' > /tmp/irqaffinity
	while read irq eth queue
	do
		if [ -n "${queue}" ]; then
			queue=$(($[queue%${MAX_CPU}]))
			MASK=$((1<<$((queue))))
			IRQ=$irq
			DEV="eth"$eth
			set_affinity
		fi
	done < /tmp/irqaffinity
}
set_chelsio()
{
	local MAX_CPU=$(( $(grep processor /proc/cpuinfo | wc -l)-1 ))
	cpu=$((1))
	for DEV in $(ifconfig -a | grep 00:07:43 | awk '{print $1}'); do
		for IRQ in $(egrep "rdma|ofld|${DEV}" /proc/interrupts | awk '{printf "%d\n",$1}'); do
			MASK=${cpu}
			set_affinity
			cpu=$((${cpu}<<1))
			if [[ ${cpu} -gt $((1<<${MAX_CPU})) ]]; then
				cpu=$((1))
			fi
		done
		ethtool -K $DEV gro off
	done	
}


if [ "$1" = "--version" -o "$1" = "-V" ]; then
	echo "version: $version"
	exit 0
elif [ -n "$1" ]; then
	echo "Description:"
	echo "    This script attempts to bind each queue of a multi-queue NIC"
	echo "    to the same numbered core, ie tx0|rx0 --> cpu0, tx1|rx1 --> cpu1"
	echo "usage:"
	echo "    $0 "
	exit 0
fi

# Set up the desired devices.
mutiqueue=`ls -d /proc/irq/*/eth* | grep eth.*-.*1`
if [ -n "${mutiqueue}" ]; then
	# check for irqbalance running
	IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
	if [ "$IRQBALANCE_ON" == "0" ] ; then
		echo " WARNING: irqbalance is running and will"
		echo "          likely override this script's affinitization."
		echo "          So I stopped the irqbalance service by"
		echo "          'killall irqbalance'"
		killall irqbalance
	fi

	result=$(ifconfig -a | grep "00:07:43")
	if [ -n "${result}" ]; then
		set_chelsio
	else
		set_intel_broadcom
	fi
fi
