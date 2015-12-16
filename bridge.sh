#!/bin/bash
# vim: set tabstop=4 shiftwidth=4 expandtab cindent:
#
# The script will find the routing device (say, eth0) and create a bridge with
# the same suffix number (br0) that enslaves the original routing device.
#

dev=$(ip route show match 0.0.0.0 | awk '{print $5}')
suf_num=$(expr "${dev}" : '[a-z]*\([0-9]\+\)')
brdg="br${suf_num}"
eval $(ip route show | grep "dev ${dev}.*src" | awk '{print "cidr="$1, "addr="$9}')
nmask=$(echo "${cidr}" | cut -d '/' -f 2)
gw=$(ip route show match 0.0.0.0 | awk '{print $3}')

echo "Original settings:"
ip addr show dev "${dev}"
ip route show

# flush addresses from the slave device
ip addr flush dev "${dev}"

# create the bridge
brctl addbr "${brdg}"
ip link set "${brdg}" up
ip addr add "${addr}/${nmask}" dev "${brdg}"
brctl addif "${brdg}" "${dev}"
ip route add default via "${gw}" dev "${brdg}"

echo "New settings:"
brctl show "${brdg}"
ip addr show dev "${brdg}"
ip route show
