#! /bin/bash

tlog(){
    /tos/tlog -m "$1"
}

check(){
    if [ $? -eq 0 ]; then
        tlog "done"
    else
        tlog "fail"
        exit 1
    fi
}

OSNAME=Unknown

get_osname() {
	# depend installmethod
	method=$1
	# find OS name in /proc/cmdline
	
	c=$(cat /proc/cmdline); 
	on1=${c##*osname=};
	OSNAME=${on1%% *};
	
	if [ -z "$OSNAME" ]; then
		echo "osname is empty on /proc/cmdline, please check"
		exit 1
	fi

}

get_osname
if [ -d /sys/firmware/efi ]; then
	if [[ ${OSNAME} =~ "2008" ]]; then
	  gpt="windows2008sp1_x64_v1.2_uefi.gpt"
	  part1="windows2008sp1_x64_v1.2_uefi.part1"
          part2="windows2008sp1_x64_v1.2_uefi.part2"
          part3="${OSNAME}.gz"
	elif [[ ${OSNAME} =~ "2012" ]];then
	  gpt="windows2012r2_x64_v1.0_uefi.gpt"
	  part1="windows2012r2_x64_v1.0_uefi.part1"
          part2="windows2012r2_x64_v1.0_uefi.part2"
          part3="windows2012r2_x64_v1.0_uefi.part3"
	  part4="${OSNAME}.gz"
	else
	  gpt="windows2016dc_x64_v1.0_uefi.gpt"
          part1="windows2016dc_x64_v1.0_uefi.part1"
          part2="windows2016dc_x64_v1.0_uefi.part2"
          part3="windows2016dc_x64_v1.0_uefi.part3"
          part4="${OSNAME}.gz"

	fi
else
	if [[ ${OSNAME} =~ "2008" ]]; then
	  mbr="windows2008sp1_x64_v1.2.mbr"
	  part1="windows2008sp1_x64_v1.2.part1"
          part2="${OSNAME}.gz"
	elif [[ ${OSNAME} =~ "2012" ]];then
	  mbr="windows2012r2_x64_v1.0.mbr"
	  part1="windows2012r2_x64_v1.0.part1"
	  part2="${OSNAME}.gz"
	else
	  mbr="windows2016dc_x64_v1.0.mbr"
          part1="windows2016dc_x64_v1.0.part1"
          part2="${OSNAME}.gz"

	fi
fi

for t in $(cat /proc/cmdline); do
    case $t in
        installmethod=net)
                        echo "Downloading image"
                        /tos/tlog -m "Downloading image"

			if [ -d /sys/firmware/efi ]; then
                        	wget http://192.168.199.200:8444/img/$gpt -P /data
                        	wget http://192.168.199.200:8444/img/$part1 -P /data
                        	wget http://192.168.199.200:8444/img/$part2 -P /data
                        	wget http://192.168.199.200:8444/img/$part3 -P /data
				if [[ ${OSNAME} =~ 2012 ]] || [[ ${OSNAME} =~ 2016 ]]; then
				  wget http://192.168.199.200:8444/img/$part4 -P /data
				fi
			else

                        	wget http://192.168.199.200:8444/img/$mbr -P /data
                        	wget http://192.168.199.200:8444/img/$part1 -P /data
                        	wget http://192.168.199.200:8444/img/$part2 -P /data

			fi

                        if [ $? -eq 0 ]; then
                                /tos/tlog -m "Image download finished"
                        else
                                /tos/tlog -m "Image download failed"
                                exit 1
                        fi
            break
            ;;
        installmethod=cdrom)
            echo "mount /dev/cdrom to /data"
            sleep 10
            mount /dev/cdrom /data
            break;
            ;;
        installmethod=usb) ##add by zgpeng 20161012 
	    echo "install method usb"
            USBDEV=$(LANG=C ls -l /dev/disk/by-path/ | grep usb | grep -E "\<sd[a-z][1-9]\>" | head -n 1 | awk -F/ '{print $3}')
            echo "mount /dev/${USBDEV} to /data"
            sleep 10
            mount /dev/${USBDEV} /data
            break;
            ;;
    esac
done

if [ -d /sys/firmware/efi ]; then
        tlog "recovery gpt"
	dd if=/dev/zero of=/dev/${INSDISK} bs=1M count=1
        dd if=/data/$gpt of=/dev/${INSDISK}
	sgdisk -e /dev/${INSDISK}
else
	tlog "recovery mbr"
	dd if=/data/$mbr of=/dev/${INSDISK} bs=1M count=1
fi

umount -l /dev/${INSDISK}{1..4}

partprobe /dev/${INSDISK} 
check

if [ -d /sys/firmware/efi ]; then
	tlog "recovery partition 1"
	dd if=/data/$part1 of=/dev/${INSDISK}1
	check
	tlog "recovery partition 2"
	dd if=/data/$part2 of=/dev/${INSDISK}2
	check
	tlog "recovery partition 3"
	if [[ ${OSNAME} =~ 2008 ]]; then 
	  gunzip -c /data/$part3 | ntfsclone -r -O /dev/${INSDISK}3 -
       	  check
	else
	  dd if=/data/$part3 of=/dev/${INSDISK}3
	  check
	  tlog "recovery partition 4"
	  gunzip -c /data/$part4 | ntfsclone -r -O /dev/${INSDISK}4 -
	  check
	fi
else
	tlog "recovery partition 1"
	ntfsclone -r -O /dev/${INSDISK}1 /data/$part1
	check
	tlog "recovery partition 2"
	gunzip -c /data/$part2 | ntfsclone -r -O /dev/${INSDISK}2 -
	check
fi

#add by zgpeng. add win_init.bat when install by usb or cdrom 
if [ -d /sys/firmware/efi ]; then
	if [[ ${OSNAME} =~ 2008 ]]; then 
		mount /dev/${INSDISK}3 /mnt
	else
		mount /dev/${INSDISK}4 /mnt
	fi
else
	mount /dev/${INSDISK}2 /mnt
fi

echo "copy win_init.bat"
cp /data/win_init.bat /mnt
umount /mnt

sleep 1
tlog "umount /data"
umount /data

sleep 1
# make partition  if there is enough space left
#size=$(parted /dev/${INSDISK} p | grep /dev/${INSDISK}: | cut -d ' ' -f 3)
size=$(parted /dev/${INSDISK} print | grep /dev/${INSDISK}: | cut -d ' ' -f 3 | cut -d 'G' -f 1)
if [ $(echo "$size>80" | bc) -eq 1 ]; then
    if [ -d /sys/firmware/efi ]; then

          tlog "EFI"          
    else
          tlog "MBR"          
    fi
fi

tlog "all done"
