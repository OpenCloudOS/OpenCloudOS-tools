#!/bin/bash

#
# For the request-based multipath driver, the I/O scheduler runs on the
# multipath device, not the underlying "slave" devices.  This script
# checks the ID_BUS attribute for each of the slave devices.  If it finds
# an ata device, it leaves the I/O scheduler tunings alone.  For any other
# device, we tune the I/O scheduler to try to keep the device busy.
#
PATH=/sbin:$PATH

needs_tuning=1
for slave in /sys${DEVPATH}/slaves/*; do
	bus_type=$(udevadm info --query=property --path=$slave | grep ID_BUS | awk -F= '{print $2}')
	if [ "$bus_type" = "ata" ]; then
		needs_tuning=0
		break
	fi
done

if [ $needs_tuning -eq 1 ]; then
	echo 0 > /sys${DEVPATH}/queue/iosched/slice_idle
	echo 32 > /sys${DEVPATH}/queue/iosched/quantum
fi

exit 0
