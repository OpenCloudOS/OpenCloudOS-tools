#!/bin/bash

######################################
# o
##

> /tmp/ip.lst

checkGW() {
   IP=$1
   GateWay=$2
   oIP="`echo ${IP} | awk -F "." '{print $NF}'`"
   oGateWay="`echo ${GateWay} | awk -F "." '{print $NF}'`"
   if [ ${oIP} -le ${oGateWay} ]
   then
      echo -e "Please check IP [\033[31;49;7m${IP}\033[39;49;0m] and GateWay [\033[31;49;7m${GateWay}\033[39;49;0m]"
      echo ""
      echo ""
      echo "-----------------"
      echo "If you want to deploy this host.Please enter the shell (sles32.sh...) again."
      exit 0
   fi
}

checkSN(){
   eSN=$1
   SN=`/usr/sbin/hwinfo --bios | awk -F ' ' ' { if (( $1 == "System" )&&($2 == "Info:")) a="1" ; if(( a == "1")&&( $1 == "Serial:" )) { print $2;exit;} }' | cut -d '"' -f 2`
   if [ "X${eSN}" != "X${SN}" ]
   then
      echo -e "Please check SN [\033[31;49;7m${eSN}\033[39;49;0m]. In BIOS is [\033[32;49;1m${SN}\033[39;49;0m]"
      exit 0
   fi
}

checkIP(){
  eLanIp=$1 
  rootdisk=`fdisk -l | grep \* | grep Linux | head -1 | awk '{print $1}'`
  mp="/tmp/${INSDISK}1"
  sLanIp=""
  Flag="0"
  if [ -z ${rootdisk} ]
  then
     echo "No system partion exist.(has no /dev/${INSDISK}1 or /dev/cciss/c0d0p1)."
     Flag="1"
  else
     mkdir ${mp}
     mount ${rootdisk} ${mp}
     if [ -f ${mp}/etc/SuSE-release ]
     then
        sLanIp="`awk -F "=" /^IPADDR/'{print $2}' ${mp}/etc/sysconfig/network/ifcfg-eth1 | sed s/\'//g`"
     elif [ -f ${mp}/etc/slackware-version ] 
     then
        ver="`awk '{print $2} /tmp/${INSDISK}1/etc/slackware-version'`"
        if [ "X${ver}" == "X8.1" ]
        then
           sLanIp="`grep ^"IPADDR\[1\]" ${mp}/etc/rc.d/rc.inet1 | awk -F "=" '{print $2}' | sed s/'"'//g`"
        elif [ ! -z `echo $ver|grep -E "^10"` ] 
        then
           sLanIp="`grep ^"IPADDR\[1\]" ${mp}/etc/rc.d/rc.inet1.conf | awk -F "=" '{print $2}' | sed s/'"'//g`"
        else 
           sLanIp=""
        fi
     else
        sLanIp=""
     fi
     
     umount ${mp}
     rm -rf ${mp}
     
     if [ -z ${sLanIp} ] || [ ${eLanIp} != ${sLanIp} ]
     then
        echo -e "OS LanIp[\033[32;49;1m${sLanIp}\033[39;49;0m],Your enter LanIp [\033[31;49;7m${eLanIp}\033[39;49;0m]."
        Flag="1"
     fi
  fi
  if [ "X${Flag}" == "X1" ]
  then
     echo -e "Please enter (\033[32;49;1my\033[39;49;0m or \033[32;49;1mn\033[39;49;0m) to select continue or stop."
     read KEY
     case ${KEY} in
     "y")
        echo "Deploy continue now..."
        ;;
     "n")
        echo "Deploy stop.Please check again."
        exit 0
        ;;
     "*")
        echo "Deploy stop.Please check again."
        exit 0
        ;;
     esac
  fi 
}

echo -e "Please enter the [\033[32;49;1mSN\033[39;49;0m] of this host:"
read SN
echo -e "Please enter the [\033[32;49;1mLAN IP\033[39;49;0m] of this host:"
read LanIp 
echo -e "Please enter the [\033[32;49;1mLAN NetMask\033[39;49;0m] of this host:"
read LanNM
echo -e "Please enter the [\033[32;49;1mLAN GateWay\033[39;49;0m] of this host:"
read LanGW

if [ -z ${SN} ] || [ -z ${LanIp} ] || [ -z ${LanNM} ] || [ -z ${LanGW} ]
then
   echo -e "[\033[32;49;1mSN\033[39;49;0m] [\033[32;49;1mLAN IP\033[39;49;0m] [\033[32;49;1mLAN NetMask\033[39;49;0m] [\033[32;49;1mLAN GateWay\033[39;49;0m] must not empty"
   exit 0
fi

checkSN ${SN}
checkIP ${LanIp}

echo -e "Please enter the [\033[32;49;1mWAN IP\033[39;49;0m] of this host(if no WAN.Please enter now):"
read WanIp
if [ ${WanIp} ]
then
   echo -e "Please enter the [\033[32;49;1mWAN NetMask\033[39;49;0m] of this host:"
   read WanNM 
   echo -e "Please enter the [\033[32;49;1mWAN GateWay\033[39;49;0m] of this host:"
   read WanGW 
   if [ -z ${WanGW} ] || [ -z ${WanNM} ] 
   then
      echo -e "Because of WanIp is not empty,[\033[32;49;1mWAN NetMask\033[39;49;0m] [\033[32;49;1mWAN GateWay\033[39;49;0m] must not empty"
   exit 0
   fi
   
   checkGW ${LanIp} ${LanGW}
   checkGW ${WanIp} ${WanGW}  
   
   echo "${LanIp} ${LanNM} ${LanGW} ${WanIp} ${WanNM} ${WanGW}" > /tmp/ip.lst

else
   checkGW ${LanIp} ${LanGW}
   echo "${LanIp} ${LanNM} ${LanGW}" > /tmp/ip.lst
fi

