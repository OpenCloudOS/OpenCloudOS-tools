#!/bin/bash  
# ===============================================================================
#          File: tlinux-lab-init.sh
#   Description: tlinux lab initialization
#        Author: Chapman Ou <chapmanou@tencent.com>
#       Created: 11/19/2012 
#      Revision:  ---
# ===============================================================================

if [ "$1"x != "-f"x ]; then
	echo "Notice!!! This scripts only for in tlinux lab(used by tlinux team), NOT for IDC or other."
	echo "Use \"tlinux-lab-init.sh -f\" if you know what you want."
	exit 1;
fi	

# Iptables
sed -i 's%^/sbin/iptables -A INPUT -i eth0%#&%g; s%^/usr/local%#&%g' /etc/rc.d/boot.local
echo "Notice: iptables will be flush"
iptables -F

# Openssh 
sed -i 's/^[ \t]*ListenAddress 172/#&/g' /etc/ssh/sshd_config{,.l}
service sshd reload


# Route
# In IDC, eth0 == external, eth1 == internal. 
# In Lab, eth0 == internal, eth1 == external. 
sed -i 's%^/sbin/route add -net 192.168.0.0%#&%g' /etc/sysconfig/network-scripts/setdefaultgw-tlinux

# Yum
echo "1.2" > /etc/yum/vars/releasever
sed -i '/tlinux-mirrorlist.tencent-cloud.com/d' /etc/hosts
echo -e "192.168.0.115\ttlinux-mirrorlist.tencent-cloud.com" >> /etc/hosts

# Add srpm and debuginfo repo
cat > /etc/yum.repos.d/tlinux-lab.repo << EOF
[rhel-SRPMS]
name=rhel- rhel-SRPMS
baseurl=http://192.168.0.115/centos/rhel6/SRPMS
enabled=1
gpgcheck=0

[centos-debuginfo]
name=CentOS-$releasever - centos-debuginfo
mirrorlist=https://tlinux-mirrorlist.tencent-cloud.com/?release=\$releasever&arch=\$basearch&repo=debuginfo
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
EOF

# Agent
sed -i 's%^/usr/local/agenttools/agent/startagent.sh%#&%g' /etc/rc.d/boot.local
# sec
sed -i 's%^/usr/local/sa/agent/secu-tcs-agent-mon-safe.sh%#&%g' /etc/rc.d/boot.local

# Crontab
# Remove crontab "#* * * * * /usr/local/sa/agent/secu-tcs-agent-mon-safe.sh" 
/usr/bin/crontab -r

# Kill agent and sa
echo "agent and secu-tcs-agent will be shutdown"
killall -9 base agent secu-tcs-agent tcvmstat agentPlugInD sysddd

# Shutdown atd
echo "Notice: atd will be shutdown"
service atd stop
chkconfig atd off

