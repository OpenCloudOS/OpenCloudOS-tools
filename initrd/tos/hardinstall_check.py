#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import os
os.environ["PATH"] = "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
import sys
import subprocess
import hashlib
import socket
import glob
import time
import shutil

SQFS_WHITELIST = {
    "tlinux-tkernel2-64bit-v1.2.20150311.sqfs" :'2daa58748ca34dc301e577a9e5d19084',
    "tlinux-64bit-v2.0.20150311.sqfs" : 'e9977cdcfe6fd584c553ace9c115e3a2',
    "tlinux-64bit-v2.2.20161122.sqfs" : '74ed42b0c1a9a8ef5ab1958c7011a54b'
}

def exit_script(msg=''):
    if msg:
        print msg
    sys.exit(3)

def check_img(img):
    if not img:
        exit_script("-i option is not given")
    if not os.path.isfile(img):
        exit_script('%s does not exist or is not a regular file.' % img)
    if not img.endswith('.sqfs'):
        exit_script('Support .sqfs file only.')
    basename = os.path.basename(img)
    if basename not in SQFS_WHITELIST:
        exit_script("%s is not supported by this tool" % basename)
    f = open(img)
    m = hashlib.md5()
    while True:
        buf = f.read(4096)
        if buf:
            m.update(buf)
        else:
            break
    if m.hexdigest() != SQFS_WHITELIST[basename]:
        exit_script("%s md5sum [%s] not match with expected[%s]" % (basename,
                                                                    m.hexdigest(),
                                                                    SQFS_WHITELIST[basename]))

def remove_grub_entry(root):
    grub_conf = os.path.join(root, 'boot/grub/grub.conf')
    if not os.path.isfile(grub_conf):
        grub_conf = os.path.join(root, 'boot/grub/menu.lst')
    os.rename(grub_conf + ".bak", grub_conf)

def add_hwaddr(iface, hwaddr, ifcfg_path):
    if not os.path.exists(ifcfg_path):
        f = file(ifcfg_path, "w")
        content = """#IP Config for %s:
DEVICE='%s'
HWADDR='%s'
NM_CONTROLLED='yes'
ONBOOT='no'
IPADDR=''
NETMASK=''
GATEWAY=''
""" % (iface, iface, hwaddr)
        print("content for %s [%s]" % (iface, ifcfg_path))
        print(content)
        f.write(content)
        f.close()
        return
    HAS_IP_PT = re.compile(r"^IPADDR=.?\d+")
    #HAS_HWADDR_PT = re.compile(r"^HWADDR=.?[0-9a-fA-F]+")
    content = file(ifcfg_path).read()
    m = HAS_IP_PT.search(content)
    if m and "ONBOOT=" not in content:
        content += "\n" + "ONBOOT='yes'"
    #m = HAS_HWADDR_PT.search(content)
    print("%s has hwaddr %s" % (iface, hwaddr))
    if "HWADDR" in content:
        HWADDR_PT = re.compile(r"^.*HWADDR=.+", re.MULTILINE)
        content = HWADDR_PT.sub("HWADDR=" + hwaddr, content)
    else:
        content += "\n" + "HWADDR=" + hwaddr + "\n"
    f = file(ifcfg_path, "w")
    f.write(content)
    f.close()
    print("content for %s [%s]" % (iface, ifcfg_path))
    print(content)

def derive_network_config(iface, hwaddr, ifcfg):
    network_script = "/etc/sysconfig/network-scripts/ifcfg-%s" % iface
    if os.path.isfile(ifcfg):
        shutil.copy(ifcfg, network_script)
        if "network-scripts" not in ifcfg:
            f = open(network_script, "a")
            f.write("DEVICE='%s'\n" % iface)
            f.close()
    add_hwaddr(iface, hwaddr, network_script)
    add_hwaddr(iface, hwaddr, ifcfg)

def get_iface_hwaddr_map():
    tmp_map = {}
    for path in glob.glob("/sys/class/net/eth*"):
        iface = os.path.basename(path)
        hwaddr = file(os.path.join(path, "address")).read().strip()
        tmp_map[iface] = hwaddr
    if "eth0" not in tmp_map or "eth1" not in tmp_map:
        exit_script("machine must have eth0 and eth1")
    return tmp_map

def iface_rename(new_map):
    curr_map = get_iface_hwaddr_map()
    print(new_map)
    print(curr_map)
    if set(new_map.keys()) != set(curr_map.keys()):
        #exit_script("recorded iface names dosn't match with current status")
	print("recorded iface names dosn't match with current status")
    if set(new_map.values()) != set(curr_map.values()):
        #exit_script("recorded iface hwaddr dosn't match with current status")
	print("recorded iface hwaddr dosn't match with current status")
    if curr_map == new_map:
        print("recorded iface_hwaddr_map match with current status")
    else:
        curr_hwaddr_iface_map = dict((v, k) for k, v in curr_map.iteritems())
        for iface in curr_map:
            subprocess.check_call(["ip", "link", "set", iface, "name",
                                   iface + "_fake"])
            time.sleep(1)
        for iface in new_map:
            curr_iface = curr_hwaddr_iface_map[new_map[iface]]
            subprocess.check_call(["ip", "link", "set", curr_iface + "_fake",
                                   "name", iface])

def copy_config(root):
    basedir = os.path.join(root, "etc/sysconfig/network-scripts")
    if not os.path.isdir(basedir):
        basedir = os.path.join(root, "etc/sysconfig/network")
    f = file("/tos/img/hardinstall_iface_hwaddr")
    iface_hwaddr_map = {}
    for line in f:
        (iface, hwaddr) = line.strip().split("=")
        iface_hwaddr_map[iface] = hwaddr
    f.close()
    #iface_rename(iface_hwaddr_map)
    for iface in iface_hwaddr_map:
        hwaddr = iface_hwaddr_map[iface]
        ifcfg = os.path.join(basedir, "ifcfg-" + iface)
        derive_network_config(iface, hwaddr, ifcfg)
    return True

def check_telnet(ip, port):
    if ip and port:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            sock.connect((ip, int(port)))
            sock.close()
        except Exception, err:
            exit_script('network test failed: %s' % err)

def main():
    root = "/mnt/harddisk/root"
    try:
        os.makedirs(root)
    except:
        pass

    root_disk = os.getenv("INSDISK")
    if "nvme" in root_disk:
        root_disk = root_disk + "p"

    is_vm = os.getenv("VM")
    OSNAME_PT = re.compile(r"osname=(\S+)")
    CHECK_PT = re.compile(r"check=([\d.]+):(\d+)")
    sshd_PT = re.compile(r"sshd=([\d.]+)")
    ROOTMAX_PT = re.compile(r"rootsize=max")
    cmdline = file("/proc/cmdline").read()

    m = ROOTMAX_PT.search(cmdline)
    if (m or is_vm) and os.path.exists('sys/firmware/efi'):
        root_part = os.path.join("/dev/", root_disk + "2")
    else:
        root_part = os.path.join("/dev/", root_disk + "1")
    subprocess.check_call(["mount", root_part, root])

    remove_grub_entry(root)

    data_part = os.getenv("DATA_PART")
    data_path = os.getenv("DATA_PATH")
    m = OSNAME_PT.search(cmdline)
    if m:
        osname = m.group(1)
        subprocess.check_call(["mount", "/dev/" + data_part, "/data"])
        sqfs = "%s/%s.sqfs" % (data_path, osname)
        check_img(sqfs)
        subprocess.check_call(["umount", "/data"])
    else:
        exit_script("osname is not found in cmdline")

    copy_config(root)
    m = CHECK_PT.search(cmdline)
    if m:
        subprocess.check_call(["/etc/init.d/network", "start"])
        subprocess.call(["ip", "a"])
        subprocess.call(["ip", "r"])
        ip_addr = m.group(1)
        port = m.group(2)
        #check_telnet(ip_addr, port)
    subprocess.check_call(["umount", root_part])

if __name__ == "__main__":
    main()
