#!/bin/bash
#
# ntp.sh: dhclient-script plugin for NTP settings,
#         place in /etc/dhcp/dhclient.d and 'chmod +x ntp.sh' to enable
#
# Copyright (C) 2008 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author(s): David Cantrell <dcantrell@redhat.com>
#            Miroslav Lichvar <mlichvar@redhat.com>
#

CONF=/etc/ntp.conf
SAVECONF=${SAVEDIR}/${CONF##*/}.predhclient.${interface}

ntp_replace_conf() {
        echo "$1" | diff -q ${CONF} - > /dev/null 2>&1
        if [ $? -eq 1 ]; then
            echo "$1" > ${CONF}
            restorecon ${CONF} >/dev/null 2>&1
            service ntpd condrestart >/dev/null 2>&1
        fi
}

ntp_config() {
    if [ ! "${PEERNTP}" = "no" ] && [ -n "${new_ntp_servers}" ] &&
        [ -e ${CONF} ] && [ -d ${SAVEDIR} ]; then
        local conf=$(egrep -v '^server .*  # added by /sbin/dhclient-script$' < ${CONF})

        conf=$(echo "$conf"
            for s in ${new_ntp_servers}; do
                echo "server ${s}  # added by /sbin/dhclient-script"
            done)

        [ -f ${SAVECONF} ] || touch ${SAVECONF}
        ntp_replace_conf "$conf"
    fi
}

ntp_restore() {
    if [ -e ${CONF} ] && [ -f ${SAVECONF} ]; then
        local conf=$(egrep -v '^server .*  # added by /sbin/dhclient-script$' < ${CONF})

        ntp_replace_conf "$conf"
        rm -f ${SAVECONF}
    fi
}
