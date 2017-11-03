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


echo "Configuring doas"
cp ./etc/doas.conf /etc/doas.conf


echo "Configuring sysctl"
# Configures sysctl toggles necessary to allow IP traffic to be routed
# through the system. Also enables GRE packets, which are necessary
# for VPN traffic.
cp ./etc/sysctl.conf /etc/sysctl.conf
cat /etc/sysctl | xargs sysctl


echo "Configuring PF rules"
# Configures the PF firewall rules for this router. This includes NAT
# for IPv4 traffic and port forwarding for all internal services
cp ./etc/pf.conf /etc/pf.conf
pfctl -ef /etc/pf.conf


echo "Configuring network interfaces"
# Sets up configuration for network interfaces, both internal and
# external
cp ./etc/myname /etc/myname
rm -f /etc/mygate
cp ./etc/hostname.wan /etc/hostname.$WAN_IF
cp ./etc/hostname.lan /etc/hostname.$LAN_IF
/bin/sh /etc/netstart


echo "Configuring DHCPv6 Client"
# Comcast doesn't support full IPv6 autoconfiguration, so we have
# to use separate utility to configure IPv6 for this host and the
# internal network
pkg_add dhcpcd
cp ./etc/dhcpcd.conf /etc/dhcpcd.conf
rcctl enable dhcpcd
rcctl start dhcpcd


echo "Configuring rtadvd"
# This enables true IPv6 autoconfiguration within the LAN.
rcctl enable rtadvd
rcctl set rtadvd flags $LAN_IF
rcctl start rtadvd


echo "Configuring unbound"
# This gives us a caching DNS resolver for the local network. In my
# case, this improves most DNS query time from >50ms to ~5ms.
cp ./var/etc/unbount/etc/unbound.conf /var/unbound/etc/unbound.conf
rcctl enable unbound
rcctl start unbound


echo "Configuring dhcpd"
pkg_add dhcpd
cp ./etc/dhcpd.conf /etc/dhcpd.conf
rcctl enable dhcpd
rcctl set dhcpd flags $LAN_IF
rcctl start dhcpd


echo "Installation complete."

