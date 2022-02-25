#!/bin/bash
OSNAME=Unknown
REALNAME=1
get_osname() {
	# depend installmethod
	method=$1
	# find OS name in /proc/cmdline
	grep -q "osname=" /proc/cmdline
	if [ $? -eq 0 ]; then
	    c=$(cat /proc/cmdline);
	    on1=${c##*osname=};
	    OSNAME=${on1%% *};
	
	    if [ -z "$OSNAME" ]; then
		    echo "osname is empty on /proc/cmdline, please check"
		    exit 1
	    fi
	else
	    # the default symlink name to the real sqfs file
	    OSNAME=ts-sqfs
	fi
}

get_realname() {
	file /data/${OSNAME}.sqfs | grep -q "symbolic link"
	if [ $? -eq 0 ]; then
		sqfsname=$(ls -al /data/${OSNAME}.sqfs | awk -F ' ' '{print $NF}')
		REALNAME=${sqfsname%%\.sqfs}
	else
		REALNAME=${OSNAME}
	fi
}

install_from_net() {
    mkdir /tos/img/
	echo "Downloading image"
	/tos/tlog -m "Downloading image"
	wget http://192.168.199.200:8444/img/${OSNAME} -O /tos/img/os.img
	if [ $? -eq 0 ]; then
		/tos/tlog -m "Image download finished"
	else
		/tos/tlog -m "Image download failed"
		exit 1
	fi
}

install_from_hd() {
    mkdir /tos/img/
	if read -n1 -t 6 -p "Do you want to select the data partition with OpenCloudOS image? [Press any key to continue]" answer
  	then
    	while ((1)); do
        	echo -e "\n=========== disk information =============="
        	lsblk
        	echo "==========================================="
        	echo -e "\nWhich disk partition contains OpenCloudOS image (e.g. sda4):"
			echo -e "\nIf the image is under /data in installation disk (sda1/vda1), please press ENTER to continue."
        	read disk_name
        	/tos/tlog -m "you choose $disk_name"
			if [ -z "$disk_name" ]; then
			    grep -q "rootsize=max" /proc/cmdline
            	if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
                	DATA_PART=${INSDISK}2
            	else
                	DATA_PART=${INSDISK}1
            	fi
                /tos/tlog -m  "OpenCloudOS will load image from /data in $DATA_PART"
        	elif [ -b /dev/$disk_name ;then
        	    /tos/tlog -m  "/dev/$disk_name is ok, OpenCloudOS will load image from $disk_name"
        	    DATA_PART=$disk_name
        	    break
        	else
        	    echo "$disk_name is not a suitable disk partition, please type again."
        	fi
    	done
  	else
        # use sda4 first, than choose the first *db(sdb/vdb), than use installation disk
        # this is only for kvm install
        getdisk=$(lsblk | grep db[^1-9] | awk 'NR==1{print $1}')
        if [ -b /dev/${INSDISK}4 ]; then
            DATA_PART="${INSDISK}4"
        elif [ -n "${getdisk}" ]; then
            DATA_PART=${getdisk}1
        else
			grep -q "rootsize=max" /proc/cmdline
            if [ $? -eq 0 -o $VM -eq 1 ] && [ -d /sys/firmware/efi ]; then
            	DATA_PART=${INSDISK}2
            else
            	DATA_PART=${INSDISK}1
            fi
        fi
    	/tos/tlog -m "OpenCloudOS will load image from ${DATA_PART}"
  	fi
	export DATA_PART
	export DATA_PATH="/data"
	echo "$DATA_PART" > "/tmp/datapart.txt"
	grep -q "xvda" /proc/cmdline
	if [ $? -eq 0 ]; then
		mount /dev/sdb1 /tos/img/
		mv /tos/img/${OSNAME}.sqfs /tos/img/os.img
	else
        mount /dev/${DATA_PART} /data
        if [ "$DATA_PART" == "${INSDISK}1" ] || [ "$DATA_PART" == "${INSDISK}2" ]; then
            DATA_PATH="/data/data"
		fi
		get_realname
		/tos/tlog -m "copy ${DATA_PATH}/${REALNAME}.sqfs to /tos/img/os.img"
		cp -vL ${DATA_PATH}/${OSNAME}.sqfs /tos/img/os.img
		grep -q "recovery-mode" /proc/cmdline
		if [ $? -eq 0 ]; then
			cp -v ${DATA_PATH}/hardinstall_iface_hwaddr /tos/img && /tos/tlog -m "copy hardinstall_iface_hwaddr to /tos/img/"
			cp -v ${DATA_PATH}/hardinstall_script /tos/img && /tos/tlog -m "copy hardinstall_script to /tos/img/"
			/tos/tlog -m "recovery-mode, copy done."
		else
			cp -v ${DATA_PATH}/hardinstall_extra.rpm /tos/img && /tos/tlog -m "copy hardinstall_extra.rpm to /tos/img/"
			cp -v ${DATA_PATH}/hardinstall_rc.local /tos/img && /tos/tlog -m "copy hardinstall_rc.local to /tos/img/"
			cp -v ${DATA_PATH}/hardinstall_script /tos/img && /tos/tlog -m "copy hardinstall_script to /tos/img/"
			cp -v ${DATA_PATH}/hardinstall_iface_hwaddr /tos/img && /tos/tlog -m "copy hardinstall_iface_hwaddr to /tos/img/"
		fi
		/tos/tlog -m  "umount /data"
		umount /data
	fi
	grep -q "recovery-mode" /proc/cmdline
	if [ $? -eq 0 ]; then
		python /tos/recovery_check.py
		if [ $? -ne 0 ]; then
			/tos/tlog -m "recovery check failed"
			exit 1
		fi
	else
		python /tos/hardinstall_check.py
		if [ $? -ne 0 ]; then
			/tos/tlog -m "hardinstall check failed"
			exit 1
		fi
	fi
}

install_from_cd() {
    # rmmod usb_storage
	# rmmod mpt3sas
	# rmmod megaraid_sas
	# modprobe megaraid_sas
	# modprobe mpt3sas
	# modprobe usb_storage
	sleep 3
	getrom=$(lsscsi | grep cd/dvd | awk 'NR==1{print $NF}')
	ROM=${getrom}
	mkdir /tos/img/
	echo "mount ${ROM} to /data"
	sleep 5	
	mount ${ROM} /data
	sleep 2
	if [ ! -f /data/${OSNAME}.sqfs ]; then
		umount /data
		echo "mount /dev/sr1 to /data"
		mount /dev/sr1 /data
	fi
		#echo "copy /data/${OSNAME}.sqfs to /tos/img/os.img"
		#cp -v /data/${OSNAME}.sqfs /tos/img/os.img
	get_realname
	echo "rsync -av --progress /data/${REALNAME}.sqfs /tos/img/os.img"
	rsync -avL --progress /data/${OSNAME}.sqfs /tos/img/os.img
	echo "umount /data"
	umount /data
}

install_from_usb() {
    mkdir /tos/img/
	echo "install method usb"
	sleep 10
	USBDEV=$(LANG=C ls -l /dev/disk/by-path/ | grep usb | grep -E "\<sd[a-z][1-9]\>" | head -n 1 | awk -F/ '{print $3}')

	if [ -z "${USBDEV}" ]; then
		USBDEV=$(LANG=C ls -l /dev/disk/by-path/ | grep usb | grep -E "\<sd[a-z]\>" | head -n 1 | awk -F/ '{print $3}')
	fi

	echo "mount /dev/${USBDEV} to /data"
	sleep 2
	mount /dev/${USBDEV} /data
	get_realname
	echo "copy /data/${REALNAME}.sqfs to /tos/img/os.img"
	rsync -avL --progress /data/${OSNAME}.sqfs /tos/img/os.img		
	echo "umount /dev/${USBDEV}"
	umount /data
}



install_from_cd_or_usb() {
    mkdir /tos/img/
	echo "install method cd/usb"
	get_realname

	sleep 5
    #Assume a maximum of 30 devices,traverse them to find the corresponding sqfs file
    for i in {1..30}
    do
        getdev=$(blkid | awk "NR==$i{print $1}")
        #echo $getdev
        if [ "$getdev"x = ""x ]; then
           echo "can't find any sqfs file!!"
           exit 1
        fi
        devname=${getdev%%: *};

        #echo "mount ${devname} to /data"
        sleep 5
        mount ${devname} /data
        sleep 2
        if [ ! -f /data/${OSNAME}.sqfs ]; then
               umount /data
               #echo " ${devname} not match...umount /data"
               continue
        fi
		#here found the sqfs file
        echo "found ${devname}!start copy sqfs...."
        echo "rsync -av --progress /data/${REALNAME}.sqfs /tos/img/os.img"
        rsync -avL --progress /data/${OSNAME}.sqfs /tos/img/os.img
        echo "umount /data"
        umount /data
		break
    done

}

get_osname
for t in $(cat /proc/cmdline); do
    case $t in
        installmethod=net)
			install_from_net
           	break
            ;;
	    installmethod=harddisk)
			install_from_hd
			#/tos/preserve-ifcfg.sh
			break
		    ;;
        installmethod=cdrom)
			install_from_cd
            break
            ;;
        installmethod=usb)
           	install_from_usb	
            break
            ;;
    esac
done

# if /proc/cmdline has no specific words
# assume we are in virt-install command line
grep -qE "rescue|backup|installmethod" /proc/cmdline
if [ $? -ne 0  ]; then
    install_from_cd_or_usb
fi

exit 0
