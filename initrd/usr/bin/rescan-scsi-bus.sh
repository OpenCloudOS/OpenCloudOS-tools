#!/bin/bash
# Skript to rescan SCSI bus, using the 
# scsi add-single-device mechanism
# (c) 1998--2008 Kurt Garloff <kurt@garloff.de>, GNU GPL v2 or later
# (c) 2006--2008 Hannes Reinecke, GNU GPL v2 or later
# $Id: rescan-scsi-bus.sh,v 1.35 2009/11/19 08:54:02 garloff Exp $

setcolor ()
{
  red="\e[0;31m"
  green="\e[0;32m"
  yellow="\e[0;33m"
  bold="\e[0;1m"
  norm="\e[0;0m"
}

unsetcolor () 
{
  red=""; green=""
  yellow=""; norm=""
}

# Return hosts. sysfs must be mounted
findhosts_26 ()
{
  hosts=
  for hostdir in /sys/class/scsi_host/host*; do
    hostno=${hostdir#/sys/class/scsi_host/host}
    if [ -f $hostdir/isp_name ] ; then
	hostname="qla2xxx"
    elif [ -f $hostdir/lpfc_drvr_version ] ; then
	hostname="lpfc"
    else
        hostname=`cat $hostdir/proc_name`
    fi
    hosts="$hosts $hostno"
    echo "Host adapter $hostno ($hostname) found."
  done  
  if [ -z "$hosts" ] ; then
    echo "No SCSI host adapters found in sysfs"
    exit 1;
  fi
  hosts=`echo $hosts | sed 's/ /\n/g' | sort -n`
}

# Return hosts. /proc/scsi/HOSTADAPTER/? must exist
findhosts ()
{
  hosts=
  for driverdir in /proc/scsi/*; do
    driver=${driverdir#/proc/scsi/}
    if test $driver = scsi -o $driver = sg -o $driver = dummy -o $driver = device_info; then continue; fi
    for hostdir in $driverdir/*; do
      name=${hostdir#/proc/scsi/*/}
      if test $name = add_map -o $name = map -o $name = mod_parm; then continue; fi
      num=$name
      driverinfo=$driver
      if test -r $hostdir/status; then
	num=$(printf '%d\n' `sed -n 's/SCSI host number://p' $hostdir/status`)
	driverinfo="$driver:$name"
      fi
      hosts="$hosts $num"
      echo "Host adapter $num ($driverinfo) found."
    done
  done
}

printtype ()
{
    local type=$1

    case "$type" in
	0) echo "Direct-Access    " ;;
	1) echo "Sequential-Access" ;;
	2) echo "Printer          " ;;
	3) echo "Processor        " ;;
	4) echo "WORM             " ;;
	5) echo "CD-ROM           " ;;
	6) echo "Scanner          " ;;
	7) echo "Optical Device   " ;;
	8) echo "Medium Changer   " ;;
	9) echo "Communications   " ;;
	10) echo "Unknown          " ;;
	11) echo "Unknown          " ;;
	12) echo "RAID             " ;;
	13) echo "Enclosure        " ;;
	14) echo "Direct-Access-RBC" ;;
	*) echo "Unknown          " ;;
    esac
}

print02i()
{
    if [ "$1" = "*" ] ; then 
        echo "00"
    else
        printf "%02i" "$1"
    fi
}

# Get /proc/scsi/scsi info for device $host:$channel:$id:$lun
# Optional parameter: Number of lines after first (default = 2), 
# result in SCSISTR, return code 1 means empty.
procscsiscsi ()
{  
  if test -z "$1"; then LN=2; else LN=$1; fi
  CHANNEL=`print02i "$channel"`
  ID=`print02i "$id"`
  LUN=`print02i "$lun"`
  if [ -d /sys/class/scsi_device ]; then
      SCSIPATH="/sys/class/scsi_device/${host}:${channel}:${id}:${lun}"
      if [ -d  "$SCSIPATH" ] ; then
	  SCSISTR="Host: scsi${host} Channel: $CHANNEL Id: $ID Lun: $LUN"
	  if [ "$LN" -gt 0 ] ; then
	      IVEND=$(cat ${SCSIPATH}/device/vendor)
	      IPROD=$(cat ${SCSIPATH}/device/model)
	      IPREV=$(cat ${SCSIPATH}/device/rev)
	      SCSIDEV=$(printf '  Vendor: %-08s Model: %-16s Rev: %-4s' "$IVEND" "$IPROD" "$IPREV")
	      SCSISTR="$SCSISTR
$SCSIDEV"
	  fi
	  if [ "$LN" -gt 1 ] ; then
	      ILVL=$(cat ${SCSIPATH}/device/scsi_level)
	      type=$(cat ${SCSIPATH}/device/type)
	      ITYPE=$(printtype $type)
	      SCSITMP=$(printf '  Type:   %-16s                ANSI SCSI revision: %02d' "$ITYPE" "$((ILVL - 1))")
	      SCSISTR="$SCSISTR
$SCSITMP"
	  fi
	      
      else
	  return 1
      fi
  else
      grepstr="scsi$host Channel: $CHANNEL Id: $ID Lun: $LUN"
      SCSISTR=`cat /proc/scsi/scsi | grep -A$LN -e"$grepstr"`
  fi
  if test -z "$SCSISTR"; then return 1; else return 0; fi
}

# Find sg device with 2.6 sysfs support
sgdevice26 ()
{
  if test -e /sys/class/scsi_device/$host\:$channel\:$id\:$lun/device/generic; then	
    SGDEV=`readlink /sys/class/scsi_device/$host\:$channel\:$id\:$lun/device/generic`
    SGDEV=`basename $SGDEV`
  else
    for SGDEV in /sys/class/scsi_generic/sg*; do
      DEV=`readlink $SGDEV/device`
      if test "${DEV##*/}" = "$host:$channel:$id:$lun"; then
	SGDEV=`basename $SGDEV`; return
      fi
    done
    SGDEV=""
  fi  
}

# Find sg device with 2.4 report-devs extensions
sgdevice24 ()
{
  if procscsiscsi 3; then
    SGDEV=`echo "$SCSISTR" | grep 'Attached drivers:' | sed 's/^ *Attached drivers: \(sg[0-9]*\).*/\1/'`
  fi
}

# Find sg device that belongs to SCSI device $host $channel $id $lun
sgdevice ()
{
  SGDEV=
  if test -d /sys/class/scsi_device; then
    sgdevice26
  else  
    DRV=`grep 'Attached drivers:' /proc/scsi/scsi 2>/dev/null`
    repdevstat=$((1-$?))
    if [ $repdevstat = 0 ]; then
      echo "scsi report-devs 1" >/proc/scsi/scsi
      DRV=`grep 'Attached drivers:' /proc/scsi/scsi 2>/dev/null`
      if [ $? = 1 ]; then return; fi
    fi
    if ! `echo $DRV | grep 'drivers: sg' >/dev/null`; then
      modprobe sg
    fi
    sgdevice24
    if [ $repdevstat = 0 ]; then
      echo "scsi report-devs 0" >/proc/scsi/scsi
    fi
  fi
}       

# Test if SCSI device is still responding to commands
testonline ()
{
  : testonline
  RC=0
  if test ! -x /usr/bin/sg_turs; then return 0; fi
  sgdevice
  if test -z "$SGDEV"; then return 0; fi
  for t in 1 2 3 4 5; do
    sg_turs /dev/$SGDEV >/dev/null 2>&1
    RC=$?
    [ $RC -ne 6 ] && break
    sleep $t
  done
  # echo -e "\e[A\e[A\e[A${yellow}Test existence of $SGDEV = $RC ${norm} \n\n\n"
  if test $RC = 1; then return $RC; fi
  # OK, device online, compare INQUIRY string
  INQ=`sg_inq $sg_len_arg /dev/$SGDEV 2>/dev/null`
  IVEND=`echo "$INQ" | grep 'Vendor identification:' | sed 's/^[^:]*: \(.*\)$/\1/'`
  IPROD=`echo "$INQ" | grep 'Product identification:' | sed 's/^[^:]*: \(.*\)$/\1/'`
  IPREV=`echo "$INQ" | grep 'Product revision level:' | sed 's/^[^:]*: \(.*\)$/\1/'`
  STR=`printf "  Vendor: %-08s Model: %-16s Rev: %-4s" "$IVEND" "$IPROD" "$IPREV"`
  IPTYPE=`echo "$INQ" | sed -n 's/.* Device_type=\([0-9]*\) .*/\1/p'`
  IPQUAL=`echo "$INQ" | sed -n 's/ *PQual=\([0-9]*\)  Device.*/\1/p'`
  if [ "$IPQUAL" != 0 ] ; then
    echo -e "\e[A\e[A\e[A\e[A${red}$SGDEV changed: ${bold}\nLU not available (PQual $IPQUAL)${norm}\n\n\n"
    return 2
  fi

  TYPE=$(printtype $IPTYPE)
  procscsiscsi
  TMPSTR=`echo "$SCSISTR" | grep 'Vendor:'`
  if [ "$TMPSTR" != "$STR" ]; then
    echo -e "\e[A\e[A\e[A\e[A${red}$SGDEV changed: ${bold}\nfrom:${SCSISTR#* } \nto: $STR ${norm}\n\n\n"
    return 1
  fi
  TMPSTR=`echo "$SCSISTR" | sed -n 's/.*Type: *\(.*\) *ANSI.*/\1/p'`
  if [ $TMPSTR != $TYPE ] ; then
    echo -e "\e[A\e[A\e[A\e[A${red}$SGDEV changed: ${bold}\nfrom:${TMPSTR} \nto: $TYPE ${norm}\n\n\n"
    return 1
  fi
  return $RC
}

# Test if SCSI device $host $channen $id $lun exists
# Outputs description from /proc/scsi/scsi, returns SCSISTR 
testexist ()
{
  : testexist
  SCSISTR=
  if procscsiscsi && test -z "$1"; then
    echo "$SCSISTR" | head -n1
    echo "$SCSISTR" | tail -n2 | pr -o4 -l1
  fi
}

# Returns the list of existing channels per host
chanlist ()
{
  local hcil
  local cil
  local chan
  local tmpchan

  for dev in /sys/class/scsi_device/${host}:* ; do
    [ -d $dev ] || continue;
    hcil=${dev##*/}
    cil=${hcil#*:}
    chan=${cil%%:*}
    for tmpchan in $channelsearch ; do
      if test "$chan" -eq $tmpchan ; then
	chan=
      fi
    done
    if test -n "$chan" ; then
      channelsearch="$channelsearch $chan"
    fi
  done
}

# Returns the list of existing targets per host
idlist ()
{
  local hcil
  local cil
  local il
  local target
  local tmpid

  for dev in /sys/class/scsi_device/${host}:${channel}:* ; do
    [ -d $dev ] || continue;
    hcil=${dev##*/}
    cil=${hcil#*:}
    il=${cil#*:}
    target=${il%%:*}
    for tmpid in $idsearch ; do
      if test "$target" -eq $tmpid ; then
	target=
	break
      fi
    done
    if test -n "$target" ; then
      idsearch="$idsearch $target"
    fi
  done
}

# Returns the list of existing LUNs
getluns ()
{
  sgdevice
  if test -z "$SGDEV"; then return; fi
  if test ! -x /usr/bin/sg_luns; then echo 0; return; fi
  LLUN=`sg_luns -d /dev/$SGDEV 2>/dev/null`
  if test $? != 0; then echo 0; return; fi
  echo "$LLUN" | sed -n 's/.*lun=\(.*\)/\1/p'
}

# Perform scan on a single lun
dolunscan()
{
  SCSISTR=
  devnr="$host $channel $id $lun"
  echo "Scanning for device $devnr ..."
  printf "${yellow}OLD: $norm"
  testexist
  : f $remove s $SCSISTR
  if test "$remove" -a "$SCSISTR"; then
    # Device exists: Test whether it's still online
    # (testonline returns 1 if it's gone or has changed)
    testonline
    RC=$?
    if test $RC != 0 -o ! -z "$forceremove"; then
      echo -en "\r\e[A\e[A\e[A${red}REM: "
      echo "$SCSISTR" | head -n1
      echo -e "${norm}\e[B\e[B"
      if test -e /sys/class/scsi_device/${host}:${channel}:${id}:${lun}/device; then
        echo 1 > /sys/class/scsi_device/${host}:${channel}:${id}:${lun}/device/delete
	if test $RC -eq 1 -o $lun -eq 0 ; then
          # Try readding, should fail if device is gone
          echo "$channel $id $lun" > /sys/class/scsi_host/host${host}/scan
	fi
      else
        echo "scsi remove-single-device $devnr" > /proc/scsi/scsi
	if test $RC -eq 1 -o $lun -eq 0 ; then
          # Try readding, should fail if device is gone
          echo "scsi add-single-device $devnr" > /proc/scsi/scsi
	fi
      fi
    fi
    if test $RC = 0 -o "$forcerescan" ; then
      if test -e /sys/class/scsi_device/${host}:${channel}:${id}:${lun}/device; then
        echo 1 > /sys/class/scsi_device/${host}:${channel}:${id}:${lun}/device/rescan
      fi
    fi
    printf "\r\x1b[A\x1b[A\x1b[A${yellow}OLD: $norm"
    testexist
    if test -z "$SCSISTR"; then
      printf "\r${red}DEL: $norm\r\n\n"
      let rmvd+=1;
      return 1
    fi
  fi
  if test -z "$SCSISTR"; then
    # Device does not exist, try to add
    printf "\r${green}NEW: $norm"
    if test -e /sys/class/scsi_host/host${host}/scan; then
      echo "$channel $id $lun" > /sys/class/scsi_host/host${host}/scan 2> /dev/null
    else
      echo "scsi add-single-device $devnr" > /proc/scsi/scsi
    fi
    testexist
    if test -z "$SCSISTR"; then
      # Device not present
      printf "\r\x1b[A";
      # Optimization: if lun==0, stop here (only if in non-remove mode)
      if test $lun = 0 -a -z "$remove" -a $optscan = 1; then 
        break;
      fi
    else 
      let found+=1; 
    fi
  fi
}

# Perform report lun scan
doreportlun()
{
  lun=
  SCSISTR=
  for dev in /sys/class/scsi_device/${host}:${channel}:${id}:*; do
        if [ -d "$dev" ]; then
                lun=${dev##*:}
                break
        else
                continue
        fi
  done
  #If not a single LUN is present then assign lun=0
  if [ -z $lun ]; then
    lun=0
    devnr="$host $channel $id $lun"
    echo "Scanning for device $devnr ..."
    printf "${yellow}OLD: $norm"
    testexist -1
    if test -z "$SCSISTR"; then
      # Device does not exist, try to add
      printf "\r${green}NEW: $norm"
      if test -e /sys/class/scsi_host/host${host}/scan; then
        echo "$channel $id $lun" > /sys/class/scsi_host/host${host}/scan 2> /dev/null
      else
        echo "scsi add-single-device $devnr" > /proc/scsi/scsi
      fi
      testexist
      if test -z "$SCSISTR"; then
        # Device not present
        printf "\r\x1b[A";
        lunsearch=
        return
      fi
    fi
    #testonline
  fi
  flag=0
  lun_search=" `getluns`"
  # Set flag=1 if all the LUNs are removed
  if [ "${#lun_search}" = "1" ]; then
    flag=1
  fi
  lunremove=
  # Check existing luns
  for dev in /sys/class/scsi_device/${host}:${channel}:${id}:*; do
    [ -d "$dev" ] || continue
    lun=${dev##*:}
    if [ "$flag" = "1" ]; then
      lunremove="$lunremove $lun"
    fi
    newsearch=
    oldsearch="$lun_search"
    for tmplun in $lun_search; do
      if test $tmplun -eq $lun ; then
	dolunscan
      else
	newsearch="$newsearch $tmplun"
      fi
    done
    if [ "${#oldsearch}" = "${#newsearch}" ] ; then
	# Stale lun
	lunremove="$lunremove $lun"
    fi
    lun_search="$newsearch"
  done
  # Add new ones and check stale ones
  for lun in $lun_search $lunremove; do
    dolunscan
  done
}
  
# Perform search (scan $host)
dosearch ()
{
  if test -z "$channelsearch" ; then
    chanlist
  fi
  for channel in $channelsearch; do
    if test -z "$idsearch" ; then
      idlist
    fi
    for id in $idsearch; do
      if test -z "$lunsearch" ; then
	doreportlun
      else
	for lun in $lunsearch; do
          dolunscan
        done
      fi
    done
  done
}
 
expandlist ()
{
    list=$1
    result=""
    first=${list%%,*}
    rest=${list#*,}
    while test ! -z "$first"; do 
	beg=${first%%-*};
	if test "$beg" = "$first"; then
	    result="$result $beg";
    	else
    	    end=${first#*-}
	    result="$result `seq $beg $end`"
	fi
	test "$rest" = "$first" && rest=""
	first=${rest%%,*}
	rest=${rest#*,}
    done
    echo $result
}

# main
if test @$1 = @--help -o @$1 = @-h -o @$1 = @-?; then
    echo "Usage: rescan-scsi-bus.sh [options] [host [host ...]]"
    echo "Options:"
    echo " -l      activates scanning for LUNs 0-7    [default: 0]"
    echo " -L NUM  activates scanning for LUNs 0--NUM [default: 0]"
    echo " -w      scan for target device IDs 0 .. 15 [default: 0-7]"
    echo " -c      enables scanning of channels 0 1   [default: 0]"
    echo " -r      enables removing of devices        [default: disabled]"
    echo " -i      issue a FibreChannel LIP reset     [default: disabled]"
    echo "--remove:        same as -r"
    echo "--issue-lip:     same as -i"
    echo "--forcerescan:   Rescan existing devices"
    echo "--forceremove:   Remove and readd every device (DANGEROUS)"
    echo "--nooptscan:     don't stop looking for LUNs is 0 is not found"
    echo "--color:         use coloured prefixes OLD/NEW/DEL"
    echo "--hosts=LIST:    Scan only host(s) in LIST"
    echo "--channels=LIST: Scan only channel(s) in LIST"
    echo "--ids=LIST:      Scan only target ID(s) in LIST"
    echo "--luns=LIST:     Scan only lun(s) in LIST"  
    echo " Host numbers may thus be specified either directly on cmd line (deprecated) or"
    echo " or with the --hosts=LIST parameter (recommended)."
    echo "LIST: A[-B][,C[-D]]... is a comma separated list of single values and ranges"
    echo " (No spaces allowed.)"
    exit 0
fi

if test ! -d /sys/class/scsi_host/ -a ! -d /proc/scsi/; then
  echo "Error: SCSI subsystem not active"
  exit 1
fi	

# Make sure sg is there
modprobe sg >/dev/null 2>&1

if test -x /usr/bin/sg_inq; then
    sg_version=$(sg_inq -V 2>&1 | cut -d " " -f 3)
    sg_version=${sg_version##0.}
    #echo "\"$sg_version\""
    if [ -z "$sg_version" -o "$sg_version" -lt 70 ] ; then
        sg_len_arg="-36"
    else
        sg_len_arg="--len=36"
    fi
fi    

# defaults
unsetcolor
lunsearch=""
idsearch=`seq 0 7`
channelsearch=""
remove=
forceremove=
optscan=1
if test -d /sys/class/scsi_host; then 
  findhosts_26
else  
  findhosts
fi  

# Scan options
opt="$1"
while test ! -z "$opt" -a -z "${opt##-*}"; do
  opt=${opt#-}
  case "$opt" in
    l) lunsearch=`seq 0 7` ;;
    L) lunsearch=`seq 0 $2`; shift ;;
    w) idsearch=`seq 0 15` ;;
    c) channelsearch="0 1" ;;
    r) remove=1 ;;
    i) lipreset=1 ;;
    -remove)      remove=1 ;;
    -forcerescan) remove=1; forcerescan=1 ;;
    -forceremove) remove=1; forceremove=1 ;;
    -hosts=*)     arg=${opt#-hosts=};   hosts=`expandlist $arg` ;;
    -channels=*)  arg=${opt#-channels=};channelsearch=`expandlist $arg` ;; 
    -ids=*)   arg=${opt#-ids=};         idsearch=`expandlist $arg` ;; 
    -luns=*)  arg=${opt#-luns=};        lunsearch=`expandlist $arg` ;; 
    -color) setcolor ;;
    -nooptscan) optscan=0 ;;
    -issue-lip) lipreset=1 ;;
    *) echo "Unknown option -$opt !" ;;
  esac
  shift
  opt="$1"
done    

# Hosts given ?
if test "@$1" != "@"; then 
  hosts=$*; 
fi

if [ -d /sys/class/scsi_host -a ! -w /sys/class/scsi_host ]; then
  echo "You need to run scsi-rescan-bus.sh as root"
  exit 2
fi  
echo "Scanning SCSI subsystem for new devices"
test -z "$remove" || echo " and remove devices that have disappeared"
declare -i found=0
declare -i rmvd=0
for host in $hosts; do
  echo -n "Scanning host $host "
  if test -e /sys/class/fc_host/host$host -o -e /sys/class/iscsi_host/host$host ; then
    if test -e /sys/class/fc_host/host$host -a -n "$lipreset" ; then
      echo 1 > /sys/class/fc_host/host$host/issue_lip 2> /dev/null;
    fi
    # always do a scan on FC or iSCSI
    echo "- - -" > /sys/class/scsi_host/host$host/scan 2> /dev/null;
    [ -z $forcerescan ] && channelsearch=""
    idsearch=""
  fi
  [ -n "$channelsearch" ] && echo -n "channels $channelsearch "
  echo -n "for "
  if [ -n "$idsearch" ] ; then
      echo -n " SCSI target IDs " $idsearch
  else
      echo -n " all SCSI target IDs"
  fi
  if [ -n "$lunsearch" ] ; then
      echo ", LUNs " $lunsearch
  else
      echo ", all LUNs"
  fi
  dosearch; 
done
echo "$found new device(s) found.               "
echo "$rmvd device(s) removed.                 "

