#!/bin/bash

# ===================================================
# Copyright (c) [2022] [Tencent]
# [OpenCloudOS Tools] is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2. 
# You may obtain a copy of Mulan PSL v2 at:
#            http://license.coscl.org.cn/MulanPSL2 
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.  
# See the Mulan PSL v2 for more details.  
# ===================================================

# OpenCloudOS Health Check, 2022
# Minjie HUANG <jackmjhuang@tencent.com>

echo "##########################################################################"
echo "#                                                                        #"
echo "#                       OpenCloudOS Health Check                         #"
echo "#                                                                        #"
echo "##########################################################################"
echo "#                                                                        #"
echo "# WARNING: This check script is based on part 8.1.4 of GB/T 22239-2019,  #"
echo "#          which will ONLY CHECK the system settings and will NOT MODIFY #"
echo "#          any propertities of the system.                               #"
echo "#          The suggestions provided is only for reference, which cannot  #"
echo "#          ensure the system meet the security technical requirements.   #"
echo "#          The suggestions may also impact on your business program.     #"
echo "#          Please modify the settings carefully according to the actual  #"
echo "#          requirements.                                                 #"
echo "#                                                                        #"
echo "##########################################################################"
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>System Basic Info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
hostname=$(uname -n)
tsrelease=$(head /etc/opencloudos-release)
kernel=$(uname -r)
platform=$(uname -p)
address=$(ip addr | grep inet | grep -v "inet6" | grep -v "127.0.0.1" | awk '{ print $2; }' | tr '\n' '\t' )
cpumodel=$(cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq)
cpu=$(cat /proc/cpuinfo | grep 'processor' | sort | uniq | wc -l)
machinemodel=$(dmidecode | grep "Product Name" | sed 's/^[ \t]*//g' | tr '\n' '\t' )
date=$(date)

echo -e "Hostname:\t\t$hostname"
echo -e "OpenCloudOS Release:\t$tsrelease"
echo -e "Kernel Version:\t\t$kernel"
echo -e "Platform:\t\t$platform"
echo -e "IP Address:\t\t$address"
echo -e "CPU Model:\t\t$cpumodel"
echo -e "CPU Cores:\t\t$cpu"
echo -e "Machine Model:\t\t$machinemodel"
echo -e "System Time:\t\t$date"
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Resource Usage<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
summemory=$(free -h |grep "Mem:" | awk '{print $2}')
freememory=$(free -h |grep "Mem:" | awk '{print $4}')
usagememory=$(free -h |grep "Mem:" | awk '{print $3}')
uptime=$(uptime | awk '{print $2" "$3" "$4" "$5}' | sed 's/,$//g')
loadavg=$(uptime | awk '{print $9" "$10" "$11" "$12" "$13}')

echo -e "Mem Total:\t\t$summemory"
echo -e "Mem Usage:\t\t$usagememory"
echo -e "Mem Free:\t\t$freememory"
echo -e "Uptime:\t\t$uptime"
echo -e "Load:\t\t$loadavg"
echo "=========================================================================="
echo "Mem Status:"
vmstat 2 5
echo "=========================================================================="
echo "Zombie Process:"
ps -ef | grep zombie | grep -v grep
if [ $? == 1 ];then
    echo ">>>No zombie process found."
else
    echo ">>>Zombie process found.------[WARN]"
fi
echo "=========================================================================="
echo "Top 5 CPU Usage Processes:"
ps auxf |sort -nr -k 3 |head -5
echo "=========================================================================="
echo "Top 5 Mem Usage Processes:"
ps auxf |sort -nr -k 4 |head -5
echo "=========================================================================="
echo  "ENV:"
env
echo "=========================================================================="
echo  "Route:"
route -n
echo "=========================================================================="
echo  "Ports:"
netstat -tunlp
echo "=========================================================================="
echo  "Connections:"
netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
echo "=========================================================================="
echo "Startup Services:"
systemctl list-unit-files | grep enabled
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>System User Info<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo  "Active Users:"
w | tail -n +2
echo "=========================================================================="
echo  "All Users:"
cut -d: -f1,2,3,4 /etc/passwd
echo "=========================================================================="
echo  "All Groups:"
cut -d: -f1,2,3 /etc/group
echo "=========================================================================="
echo  "Crontab:"
crontab -l
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>Identification Security<<<<<<<<<<<<<<<<<<<<<<<<<<"
grep -i "^password.*requisite.*pam_cracklib.so" /etc/pam.d/system-auth  > /dev/null
if [ $? == 0 ];then
    echo ">>>Password Complexity: Set"
else
    grep -i "pam_pwquality\.so" /etc/pam.d/system-auth > /dev/null
    if [ $? == 0 ];then
	echo ">>>Password Complexity: Set"
    else
	echo ">>>Password Complexity: Not set--------[WARN]"
    fi
fi
echo "=========================================================================="
awk -F":" '{if($2!~/^!|^*/){print ">>>("$1")" " is an unlocked user--------[WARN]"}}' /etc/shadow
echo "=========================================================================="
more /etc/login.defs | grep -E "PASS_MAX_DAYS" | grep -v "#" |awk -F' '  '{if($2!=90){print ">>>Password expiration time is "$2" days, please change to 90 days.------[WARN]"}}'
echo "=========================================================================="
grep -i "^auth.*required.*pam_tally2.so.*$" /etc/pam.d/sshd  > /dev/null
if [ $? == 0 ];then
  echo ">>>Login Failed Policy: On"
else
  echo ">>>Login Failed Policy: Off, please add login failed lock.----------[WARN]"
fi
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>Access Control Security<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo "Non preset users:"
more /etc/passwd |awk -F ":" '{if($3>500){print ">>>/etc/passwd User: "$1 " UID: "$3" is not a preset user, please check.--------[WARN]"}}'
echo "=========================================================================="
echo "Privilege users:"
awk -F: '$3==0 {print $1}' /etc/passwd
echo "=========================================================================="
echo "Empty password users:"
awk -F: '($2=="!!") {print $1" has no password, please check.-------[WARN]"}' /etc/shadow
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Security Audit<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo "History of all logged in users in past 30 days:"
last | head -n 30
echo "=========================================================================="
echo "Check syslog audit service:"
if systemctl status rsyslog | egrep " active \(running";then
  echo ">>>syslog service on"
else
  echo ">>>syslog service off---------[WARN]"
fi
echo "=========================================================================="
echo "Check syslog forwarding:"
if more /etc/rsyslog.conf | egrep "@...\.|@..\.|@.\.|\*.\* @...\.|\*\.\* @..\.|\*\.\* @.\.";then
  echo ">>>syslog forwarding on"
else
  echo ">>>syslog forwarding off---------[WARN]"
fi
echo "=========================================================================="
echo "Audit featrues and logs:"
more /etc/rsyslog.conf  | grep -v "^[$|#]" | grep -v "^$"
echo "=========================================================================="
echo "Key files modified time:"
ls -ltr /bin/ls /bin/login /etc/passwd  /bin/ps /etc/shadow|awk '{print ">>>Filename: "$9"  ""Last modified time: "$6" "$7" "$8}'

echo "=========================================================================="
echo "Check key log files:"
log_secure=/var/log/secure
log_messages=/var/log/messages
log_cron=/var/log/cron
log_boot=/var/log/boot.log
log_dmesg=/var/log/dmesg
if [ -e "$log_secure" ]; then
  echo  ">>>/var/log/secure exists"
else
  echo  ">>>/var/log/secure not exists------[WARN]"
fi
if [ -e "$log_messages" ]; then
  echo  ">>>/var/log/messages exists"
else
  echo  ">>>/var/log/messages not exists------[WARN]"
fi
if [ -e "$log_cron" ]; then
  echo  ">>>/var/log/cron exists"
else
  echo  ">>>/var/log/cron not exists--------[WARN]"
fi
if [ -e "$log_boot" ]; then
  echo  ">>>/var/log/boot.log exists"
else
  echo  ">>>/var/log/boot.log not exists--------[WARN]"
fi
if [ -e "$log_dmesg" ]; then
  echo  ">>>/var/log/dmesg exists"
else
  echo  ">>>/var/log/dmesg not exists--------[WARN]"
fi
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>Residual Information Protection<<<<<<<<<<<<<<<<<<<<<<"
echo "Disk Partitions:"
echo "Please check the utilization rates---------[INFO]"
df -h
echo "=========================================================================="
echo "Block devices:"
lsblk
echo "=========================================================================="
echo "Filesystem info:"
more /etc/fstab  | grep -v "^#" | grep -v "^$"
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>Intrusion Proetction Security<<<<<<<<<<<<<<<<<<<<<<<"
echo "System instrustion log:"
more /var/log/secure |grep refused
if [ $? == 0 ];then
    echo ">>>Instrustion found--------[WARN]"
else
    echo ">>>Instrustion not found"
fi
echo "=========================================================================="
echo "Login failed history:"
lastb | head | grep -v "^$" | grep -v "btmp" > /dev/null
if [ $? == 1 ];then
    echo ">>>No login failed history."
else
    echo ">>>Login failed history found.--------[WARN]"
    lastb | head | grep -v "^$" | grep -v "btmp"
fi
echo "=========================================================================="
echo "SSH Login Failed Info:"
more /var/log/secure | grep  "Failed" > /dev/null
if [ $? == 1 ];then
    echo ">>>No SSH login failed info found."
else
    more /var/log/secure|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print ">>>Failed IP: "$2"="$1"times---------[WARN]";}'
fi
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>Malicious Code Protection<<<<<<<<<<<<<<<<<<<<<<<<<"
echo "Check Anti-Virus Software:"
crontab -l | grep clamscan.sh > /dev/null
if [ $? == 0 ];then
  echo ">>>ClamAV installed."
  crontab -l | grep freshclam.sh > /dev/null
  if [ $? == 0 ];then
    echo ">>>Virus database update crontab set."
  fi
else
  echo ">>>ClamAV not installed, please install anti-virus software.--------[INFO]"
fi
echo " "
echo ">>>>>>>>>>>>>>>>>>>>>>>>>Resource Control Security<<<<<<<<<<<<<<<<<<<<<<<<<"
echo "Check xinetd service:"
if ps -elf |grep xinet |grep -v "grep xinet";then
  echo ">>>xinetd service on, please check whether can turn it off--------[INFO]"
else
  echo ">>>xinetd service off"
fi
echo "=========================================================================="
echo  "Check SSH service:"
if systemctl status sshd | grep -E "listening on|active \(running\)"; then
  echo ">>>SSH service on."
else
  echo ">>>SSH service off--------[WARN]"
fi
echo "=========================================================================="
echo "Check Telnet-Server service:"
if more /etc/xinetd.d/telnetd 2>&1|grep -E "disable=no"; then
  echo ">>>Telnet-Server service on"
else
  echo ">>>Telnet-Server service off--------[INFO]"
fi
echo "=========================================================================="
ps axu | grep iptables | grep -v grep || ps axu | grep firewalld | grep -v grep 
if [ $? == 0 ];then
  echo ">>>Firewall on"
iptables -nvL --line-numbers
else
  echo ">>>Firewall off--------[WARN]"
fi
echo "=========================================================================="
echo  "Check SSH policy (hosts.deny):"
more /etc/hosts.deny | grep -E "sshd"
if [ $? == 0 ]; then
  echo ">>>hosts.deny set"
else
  echo ">>>hosts.deny not set--------[WARN]"
fi
echo "=========================================================================="
echo "Check SSH policy (hosts.allow):"
more /etc/hosts.allow | grep -E "sshd"
if [ $? == 0 ]; then
  echo ">>>hosts.allow set"
else
  echo ">>>hosts.allow not set--------[WARN]"
fi
echo "=========================================================================="
echo "Use hosts.allow by default when hosts.allow conflicts with host.deny."
echo "=========================================================================="
grep -i "TMOUT" /etc/profile /etc/bashrc
if [ $? == 0 ];then
    echo ">>>Login timeout set."
else
    echo ">>>Login timeout not set. Please add TMOUT=600 in /etc/profile or /etc/bashrc--------[WARN]"
fi
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>end<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"