#!/usr/bin/python2
# -*- coding: utf-8 -*-

# ===================================================
# Copyright (c) [2022] [Tencent]
# [OpenCloudOS Tools] is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2. 
# You may obtain a copy of Mulan PSL v2 at:
#            http://license.coscl.org.cn/MulanPSL2 
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.  
# See the Mulan PSL v2 for more details.  
# ===================================================

# ====================================
# Created By  : Songqiao Tao
# Email       : joeytao@tencent.com
# Created Date: Fri Mar 24 2017
# Update Date : Wed Feb 18 2022
# Description : Backup and Recover system for OpenCloudOS
# Version     : 3.0.1
# ====================================

import shutil
import os
os.environ["PATH"] = "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
import sys
import getopt
import time
import subprocess
import re
import socket
import glob

def usage():
    print '''Usage: tos -b | -r [ -f ] [ -p password ] [-s script] -i SQFS_FILE  | -h

    Options:
    -b                  Backup tlinux system
    -r                  Recover tlinux system
    -i  SQFS_FILE       The path to the sqfs file
    -f                  Format data, e.g. /dev/sda4 in physical machine, /dev/vdb1 in VM, /data in VM without data disk
    -p  PASSWORD        Set the new password
    -s  SCRIPT          An executable file, e.g. a script with shebang to run within the installed new system
    -u  RPM             An rpm file, e.g. kernel-xxx.rpm to update within the installed new system
    -h                  Print this short help text and exit
'''

def exit_script(msg=''):
    if msg:
        print msg
        print
    usage()
    sys.exit(3)

def check_img(img):
    if not img:
        exit_script("-i option is not given")
    if not os.path.isfile(img):
        exit_script('%s does not exist or is not a regular file.' % img)
    if not img.endswith('.sqfs'):
        exit_script('Support .sqfs file only.')

def check_data_disk():
    f = open("/etc/mtab", "r")
    for line in f:
        dev = line.split()[0]
        mnt = line.split()[1]
        if dev == "/dev/sda4" or dev == "/dev/vdb1":
            f.close()
            return mnt
    f.close()

    if os.path.exists("/data"):
        return "/data"
    else:
        try:
            os.mkdir("/data")
            return "/data"
        except:
            exit_script("/data create failed.")

def is_oc8():
    if os.path.isfile("/etc/opencloudos-release"):
        f = open("/etc/opencloudos-release")
        for line in f:
            if "8." in line:
                f.close()
                return True
        f.close()
    return False

def is_vm():
    if os.path.isfile("/proc/cmdline"):
        f = open("/proc/cmdline")
        for line in f:
            if "xvda" in line:
                f.close()
                return True
        f.close()
    
    p = subprocess.Popen(["dmidecode"], stdout=subprocess.PIPE)
    vm_desktop_pt = re.compile(r"Manufacturer: innotek GmbH|Vendor: Parallels|Manufacturer: VMware")
    vm_cloud_pt = re.compile(r"Product Name: KVM|Product Name: CVM|Manufacturer: QEMU")
    vm_desktop_flag = False
    vm_cloud_flag = False
    for line in p.stdout:
        m1 = vm_desktop_pt.search(line)
        m2 = vm_cloud_pt.search(line)
        if m1:
            vm_desktop_flag = True
        if m2:
            vm_cloud_flag = True
    if vm_desktop_flag == False and vm_cloud_flag == True:
        return True
    
    return False

def is_rootsize_max():
    if os.path.isfile("/proc/cmdline"):
        f = open("/proc/cmdline")
        for line in f:
            if "rootsize=max" in line:
                f.close()
                return True
        f.close()
    return False

def check_os():
    if not (is_oc8()):
        exit_script("only OpenCloudOS is supported")
    if os.uname()[-1] != 'x86_64':
        exit_script("only x86_64 is supported")

def get_iface_hwaddr_map():
    tmp_map = {}
    for path in glob.glob("/sys/class/net/eth*"):
        iface = os.path.basename(path)
        hwaddr = file(os.path.join(path, "address")).read().strip()
        tmp_map[iface] = hwaddr
    if "eth0" not in tmp_map and "eth1" not in tmp_map:
        exit_script("machine must have eth0 or eth1")
    return tmp_map

def copy_files(option, img, sqfs_dir, script, rpm_file):
    shutil.copy("/usr/lib/opencloudos-tools/initrd-2.0-backup-recovery.img", "/boot/initrd-2.0-backup-recovery.img")
    shutil.copy("/usr/lib/opencloudos-tools/vmlinuz-2.0-backup-recovery", "/boot/vmlinuz-2.0-backup-recovery")
    if option == "recovery":
        img_basename = os.path.basename(img)
        if not os.path.isfile(sqfs_dir + '/' + img_basename):
            shutil.copy(img, sqfs_dir)
        if script:
            shutil.copy(script, os.path.join(sqfs_dir, "hardinstall_script"))
        if rpm_file:
            shutil.copy(rpm_file, os.path.join(sqfs_dir, "hardinstall_extra.rpm"))
        iface_hwaddr_map = get_iface_hwaddr_map()
        f = file(os.path.join(sqfs_dir, "hardinstall_iface_hwaddr"), "w")
        for key in iface_hwaddr_map:
            f.write("%s=%s\n" % (key, iface_hwaddr_map[key]))
        f.close()

def grub_add_entry(option, img, format_data, passwd, vm):
    if format_data:
        format_value = 1
    else:
        format_value = 0
    if passwd:
        pw_value = passwd
    else:
        pw_value = 0
    if is_tlinux1():
        grub_conf = '/boot/grub/grub.conf'
        if os.path.exists("/sys/firmware/efi") and os.path.isfile("/boot/efi/EFI/tencent/grub.efi") :
            grub_conf = '/boot/efi/EFI/tencent/grub.conf'
    else:
        grub_conf = '/boot/grub2/grub.cfg'
        #if os.path.exists("/sys/firmware/efi") and os.path.isfile("/boot/efi/EFI/centos/grubenv") :
        #    os.remove("/boot/grub2/grubenv")
        #    shutil.copy("/boot/efi/EFI/centos/grubenv", "/boot/grub2/grubenv") 
    if vm:
        console = "tty0,115200"
    else:
        console = "tty0"
    img_name = ''
    if option == "recovery":
        basename = os.path.basename(img)
        img_name = basename.replace(".sqfs", "")
    
    print('backup the grub_conf')
    shutil.copy(grub_conf, grub_conf + ".bak")
    if is_oc8():
        print('add new boot entry!')
        if os.system('grubby --add-kernel=/boot/vmlinuz-2.0-backup-recovery --title="OpenCloudOS backup and revovery" --initrd=/boot/initrd-2.0-backup-recovery.img --copy-default'):
            exit_script("setup grub failed !")
        if option == 'backup':
            os.system('sed -i "/^options/ s/$/ panic=5 backup-mode/" /boot/loader/entries/*backup-recovery.conf')
        else:
            os.system('sed -i "/^options/ s/$/ osname=%s installmethod=harddisk panic=5 recovery-mode format_data=%d passwd=%s/" /boot/loader/entries/*backup-recovery.conf ' % (img_name, format_value, pw_value ))
        os.system('grub2-reboot "OpenCloudOS backup and revovery"')

def get_sshd_ip():
    p = subprocess.Popen(["netstat", "-ntpl"], stdout=subprocess.PIPE)
    netstat_pt = re.compile(r"(\d+\.\d+\.\d+.\d+):.+\/sshd")
    for line in p.stdout:
        m = netstat_pt.search(line)
        if m:
            ssh_ip = m.group(1)
            p.stdout.close()
            p.wait()
            return ssh_ip
    p.wait()
    exit_script("sshd not running or not bound to a specified ipv4 address")

def check_memory_size_M(size):
    MEM_PT = re.compile(r"Mem:\s+(\d+)")
    p = subprocess.Popen(["free", "-m"], stdout=subprocess.PIPE)
    for line in p.stdout:
        m = MEM_PT.search(line)
        if m:
            p.stdout.close()
            p.wait()
            total_size = int(m.group(1))
            if total_size < size:
                exit_script("%d MiB total memory is required" % size)
            return
    exit_script("Fail to get total memory")

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'brfi:p:s:u:nh', ["help"])
    except getopt.GetoptError, err:
        print str(err)
        usage()
        sys.exit(1)

    img = ''
    option = ''
    passwd = ''
    format_data = False
    script = ''
    rpm_file = ''
    for o, a in opts:
        if o in ('-h', '--help'):
            usage()
            sys.exit(0)
        if o == '-b':
            option = 'backup'
        if o == '-r':
            option = 'recovery'
        if o == '-f':
            format_data = True
        if o == '-i':
            img = os.path.abspath(a)
        if o == '-p':
            passwd = a
        if o == '-s':
            script = os.path.abspath(a)
            if not os.path.isfile(script):
                exit_script("wrong -s option, %s does not exist or is not a regular file" % script)
        if o == '-u':
            rpm_file = os.path.abspath(a)
            if not os.path.isfile(rpm_file):
                exit_script("wrong -u option, %s does not exist or is not a regular file" % rpm_file)
        if o == '-n':
            print("Backup OpenCloudOS system and no need to reboot")
            if os.system('/usr/lib/opencloudos-tools/tos-backup.sh'):
                exit_script("setup grub failed !")
            else:
                print("Backup OpenCloudOS system successfully!")
                sys.exit(0)
    if option == '':
        print("-b or -r parameter is required!")
        usage()
        sys.exit(1)
    if option == 'recovery':
        check_img(img)
        
    vm = is_vm()
    data_dir = check_data_disk()
    check_memory_size_M(3000)
    check_os()
    copy_files(option, img, data_dir, script, rpm_file)
    grub_add_entry(option, img, format_data, passwd, vm)
    
    if option == 'backup':
        print("\n!! Please reboot to backup the system as soon as possible !!")
        os.system('sync')
    elif option == 'recovery': 
        print("\n!! Please reboot to recover or reinstall the system as soon as possible !!")
        os.system('sync')
    
if __name__ == "__main__":
    main()
