#!/bin/sh

# This script sets up a fresh OpenBSD system with the configuration
# outlined in the accompanying Readme.md document. In particular, it
# copies configuration files to the appropriate locations, installs
# any necessary packages, and interacts with rc to enable and
# configure services.
#
# NOTES:
# * This must be run as the root user
# * This script is idempotent, meaning it can be run at any time (or
#   multiple times) and the end result will always be correct


# You may need to change some or all of these variables, depending on
# hardware configuration
WAN_IF=em0
LAN_IF=em1
BAK_IF=em3 # TODO: not sure what this will be until after installed


echo "Configuring sysctl"
cp ./etc/sysctl.conf /etc/sysctl.conf
cat /etc/sysctl.conf | xargs -L 1 sysctl


echo "Configuring network interfaces"
cp ./etc/hostname.wan /etc/hostname.$WAN_IF
cp ./etc/hostname.lan /etc/hostname.$LAN_IF
cp ./etc/hostname.bak /etc/hostname.$BAK_IF
/bin/sh /etc/netstart


echo "Configuring unbound"
cp ./var/etc/unbount/etc/unbound.conf /var/unbound/etc/unbound.conf
rcctl enable unbound
rcctl start unbound


echo "Configuring dhcpd"
pkg_add dhcpd
cp ./etc/dhcpd.conf /etc/dhcpd.conf
rcctl set dhcpd flags $LAN_IF $BAK_IF
rcctl enable dhcpd
rcctl start dhcpd


echo "Configuring and enabling PF"
cp ./etc/pf.conf /etc/pf.conf
pfctl -ef /etc/pf.conf


echo "Installation complete."

