#!/bin/bash

#
#send message to jobserver
#
#

nfsServer="192.168.0.1"
nfsDir="/data/nfsDisk/log"
mntDir="/tmp/nfsDir"
sleepTime=30

log="/tmp/sms.log"

#CLIIP=$(/sbin/ifconfig | grep inet | grep -v ":127" | head -n 1 | cut -d ":" -f 2 | awk -F " " '{ print $1}')

#hwInfo="/tmp/${CLIIP}"
getInfo="/bin/hwinfo_formini.sh"

procNu="`ps -ef | grep sendMessage.sh | grep -v grep | wc -l`"
if [ ${procNu} -ge 3 ]
then
   echo "sendMessage.sh is exist.exit now" >> ${log}
   exit 0
fi


while [ 1 == 1 ]
do
   CLIIP=$(/sbin/ifconfig | grep inet | grep -v ":127" | head -n 1 | cut -d ":" -f 2 | awk -F " " '{ print $1}')
   hwInfo="/tmp/${CLIIP}"
   if [ -z ${CLIIP} ]
   then
      echo "No IP to Connect the Server" | tee -a ${log}
      service network reload
   else 
      sh ${getInfo} xxx | tee -a ${log}
      nfsStat="`/usr/sbin/showmount -e ${nfsServer} | grep "${nfsDir}" | wc -l`"
      if [ ${nfsStat} -eq 1 ]
      then
         [ -d ${mntDir} ] || mkdir ${mntDir}
         #mount -t nfs ${nfsServer}:${nfsDir} ${mntDir} >> ${log}
         mount -o nolock,vers=3 -t nfs ${nfsServer}:${nfsDir} ${mntDir} >> ${log}
         ok="`df -h | grep ${nfsServer} | wc -l`"
         if [ ${ok} -eq 1 ]
         then
            echo "NFS mount OK"  | tee -a ${log}
            echo "cp ${hwInfo} ${mntDir}"  | tee -a ${log}
            cp ${hwInfo} ${mntDir}
            echo "umount ${mntDir}" | tee -a ${log}
            umount ${mntDir} >> ${log}
         else
            echo "NFS mount failed" | tee -a ${log}
         fi
      else
         echo "NFS Server(${nfsServer}),Can not connected" | tee -a ${log}
      fi
   fi
   sleep ${sleepTime}
   logSize=`du ${log} | awk '{print $1}'`
   if [ ${logSize} -ge 512 ]
   then
      > ${log}
   fi
done
