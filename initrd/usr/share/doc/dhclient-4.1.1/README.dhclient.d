The /etc/dhcp/dhclient.d directory allows other packages and system
administrators to create application-specific option handlers for dhclient.

When dhclient is run, any option listed in the dhcp-options(5) man page can
be requested.  dhclient-script does not handle every option available
because doing so would make the script unmaintainable as the components
using those options might change over time.  The knowledge of how to handle
those options should be under the responsibility of the package maintainer
for that component (e.g., NTP options belong in a handler in the ntp
package).

To make maintenance easier, application specific DHCP options can be handled
by creating a script with two functions and placing it in /etc/dhcp/dhclient.d

The script must follow a specific form:

(1) The script must be named NAME.sh.  NAME can be anything, but it makes
    sense to name it for the service it handles.  e.g., ntp.sh

(2) The script must provide a NAME_config() function to read the options and
    do whatever it takes to put those options in place.

(3) The script must provide a NAME_restore() function to restore original
    configuration state when dhclient stops.

(4) The script must be 'chmod +x' or dhclient-script will ignore it.

The scripts execute in the same environment as dhclient-script.  That means
all of the functions and variables available to it are available to your
NAME.sh script.  Things of note:

    ${SAVEDIR} is where original configuration files are saved.  Save your
    original configuration files here before you take the DHCP provided
    values and generate new files.

    Variables set in /etc/sysconfig/network, /etc/sysconfig/networking/network,
    and /etc/sysconfig/network-scripts/ifcfg-$interface are available to
    you.

See the scripts in /etc/dhcp/dhclient.d for examples.

NOTE:  Do not use functions defined in /sbin/dhclient-script.  Consider
dhclient-script a black box.  This script may change over time, so the
dhclient.d scripts should not be using functions defined in it.

-- 
David Cantrell <dcantrell@redhat.com>
