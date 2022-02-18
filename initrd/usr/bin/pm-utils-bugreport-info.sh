#!/bin/bash
shopt -s nullglob
exec 2>&1
LANG=C

echo SUSPEND LOG
cat /var/log/pm-suspend.log
echo ======
echo SYS POWER
ls -lA /sys/power
echo ======
echo SYS POWER STATE
cat /sys/power/state
echo ======
echo SYS POWER DISK
cat /sys/power/disk
echo ======
echo HAL INFO
lshal | egrep "(system.hardware.(product|vendor|version)|system.firmware.version|power_management.quirk)"
echo ======
echo ETC PM
ls -lAR /etc/pm
for dir in /etc/pm/*
do
    echo DIR ${dir}
    for file in ${dir}/*
    do
        echo FILE $file
        cat ${file}
        echo ======
    done
    echo ======
done
echo UNAME
uname -a
echo ======
echo RPM
rpm --qf '%{name}-%{version}-%{release}\n' -q kernel pm-utils hal hal-info gnome-power-manager vbetool radeontool hdparm
echo ======
echo FEDORA RELEASE
cat /etc/fedora-release
echo ======
