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

# fix_dns
RESOLV_CONF="/etc/resolv.conf"
RESOLV_CONF_BAK="/etc/resolv.conf_bak"
RESOLV_CONF_TMP="/etc/resolv.conf_tmp"
CURL_BIN="/usr/bin/curl --connect-timeout 5 -m 10 -s -H 'Host: cachedns-api'"
SERVER_URL="http://9.148.192.52/get_cachedns_ip"
SERVER_URL_BAK1="http://100.119.202.103/get_cachedns_ip"
SERVER_URL_BAK2="http://100.119.152.103/get_cachedns_ip"
TEST_DOMAIN="cachecheck.fortest.qzoneapp.com."
DIG_BIN="/usr/bin/dig"
RETRY_TIMES=2
URL_NUM=3

#check the user, we need root
check_root() 
{
        if [ `id -u` -ne 0 ];then
                echo "Please check the user, we need root"
                exit -1
        fi
}

#check the resolv.conf if has other configure
check_resolv_conf()
{
        if [ ! -f "$RESOLV_CONF" ];then
                echo "The configure file $RESOLV_CONF doesn't exist"
                return 1
        fi
        TEST_VALUE="nameserver"
        while read line
        do
                #the line is annotation in the resolv.conf
                if [[ "$line" =~ ^#.* ]];then
                        flag=true
                else
                        #have nameserver in the resolv.conf
                        if [[ "$line" == $TEST_VALUE* ]];then
                                echo "Already have configure '$line' in $RESOLV_CONF"
                                return 0
                        else
                                flag=false
                        fi
                fi
        done < $RESOLV_CONF
	return 1
}

#check the dns server is available
check_serverip_available()
{
        name_server_conf=$1
        name_servers=$(echo "$name_server_conf" | cut -d ' ' -f 2)

        for server_ip in $name_servers
        do
                #test the server_ip 
                dig_result=`$DIG_BIN $TEST_DOMAIN @$server_ip`

                #if we have answer section
                answer_section=$(echo $dig_result | grep "ANSWER SECTION:")

                #if we have answer section
                if [ "$answer_section" == "" ];then
                        echo "The server $server_ip is not available"
                        return -1
                fi
        done

        echo "Check all the DNS nameserver available"
}

#write the result value to resolv.conf
write_to_resolv_conf()
{
    value=$1
    if [ -f "$RESOLV_CONF" ];then
       cp "$RESOLV_CONF" "$RESOLV_CONF_BAK"
    fi

    echo "$value" > $RESOLV_CONF_TMP
    if [ $? -ne 0 ];then
        echo "Write to $RESOLV_CONF_TMP failed"
        exit -1
    fi

    mv "$RESOLV_CONF_TMP" "$RESOLV_CONF"
    if [ $? -ne 0  ];then
        echo "Write to $RESOLV_CONF failed"
        exit -1
    fi

    rm -f $RESOLV_CONF_TMP
}

#do last dig action
check_final()
{
        dig_result=`$DIG_BIN $TEST_DOMAIN`
        #if we have answer section
        answer_section=$(echo $dig_result | grep "ANSWER SECTION:")

        #if we have answer section
        if [ "$answer_section" = "" ];then
                echo "The server is not available"
                exit -1
        fi
        echo "The CacheDNS server is available, Set success"
}

set_resolv_conf()
{
    #check when write to the resolv.conf
        local_server_url=$1
        find_flag=false
        retry_time=1
        server_number=1
        #echo "url is $local_server_url"

        while(( $retry_time <= $RETRY_TIMES ))
        do
                #Get the value from cache server
                resolv_value=$($CURL_BIN $local_server_url)
                if [ ! -n "$resolv_value" ];then
                        echo "do not have value, retry the ${retry_time}th times"
                        let "retry_time++"
                else
                        #if we have value, check the value right or not
                        result=$(echo "$resolv_value" | grep "nameserver")

                        if [[ "$result" != "" ]];then

                                #check the server available or not
                                check_serverip_available "$result"

                                write_to_resolv_conf "$resolv_value"
                		#set the flag as true
                		find_flag=true
                		break
                        else
                                echo "The value \"$resolv_value\" is not what we expected, retry the ${retry_time}th times"
                                let "retry_time++"
                        fi
                fi
                sleep 1
        done

        #check success, we exit normal
        if [ "$find_flag" == true ];then
                check_final
                exit 0
        fi
}

get_resolv_from_server()
{
        url_id=1
        while(( $url_id <= $URL_NUM ))
        do
                case $url_id in
                1)
                        local_server_url=$SERVER_URL
                        ;;
                2)
                        local_server_url=$SERVER_URL_BAK1
                        ;;
                3)
                        local_server_url=$SERVER_URL_BAK2
                        ;;
                *)
                        echo "The server is not exist"
                        exit -1
                        ;;
                esac
                set_resolv_conf $local_server_url
                let "url_id++"
        done
}

tos_fix_dns()
{
    check_root
    check_resolv_conf
    result=$?
    if [ $result -ne 0 ]; then
        get_resolv_from_server
    fi
}
tos_set_dns()
{
    check_root
    get_resolv_from_server
}

