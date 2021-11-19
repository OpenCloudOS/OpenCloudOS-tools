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

# tos -a : analyze system performance
# joeytao@tencent.com

ana_uptime()
{
    echo "========== Uptime ==============="
    echo "# uptime"
    uptime
    echo "================================="
}
ana_vmstat()
{
    echo "========== VMSTAT ==============="
    echo "# vmstat 1 3"
    vmstat 1 3
    echo "================================="
}
ana_cpu()
{
    echo "========== CPU =================="
    echo "# mpstat 1 3"
    mpstat 1 3
    echo "================================="
}
ana_mem()
{
    echo "========== Memory ==============="
    echo "# free -m"
    free -m
    echo "================================="
}
ana_net()
{
    echo "========= Network ==============="
    echo "# sar -n DEV 1 3"
    sar -n DEV 1 3
    echo "================================="
}
ana_io()
{
    echo "========= I/O ==================="
    echo "# iostat -dx 1 3"
    iostat -dx 1 3
    echo "================================="
}
ana_pidstat()
{
    echo "========= pidstat ==================="
    echo "# pidstat 1 3"
    pidstat 1 3
    echo "================================="
}
ana_dmesg()
{
    echo "========= dmesg ==================="
    echo "# dmesg | tail"
    dmesg | tail
    echo "================================="
}

ana_performance()
{
    ana_uptime
    ana_vmstat
    ana_cpu
    ana_mem
    ana_net
    ana_io
    ana_pidstat
    ana_dmesg
}


tos_analyze()
{
    if [ -n "$1" ]; then
        ana_op=$1
	if [ "$ana_op"x == "cpu"x ];then
	    ana_cpu
        elif [ "$ana_op"x == "io"x ];then
            ana_io
        elif [ "$ana_op"x == "mem"x ];then
	    ana_mem
	elif [ "$ana_op"x == "net"x ];then
            ana_net
	else
	    ana_performance
	fi
    else
        ana_performance
    fi
}
#tos_analyze $1
