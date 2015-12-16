#!/bin/bash
# vim: set tabstop=4 shiftwidth=4 expandtab cindent:
#
# The script simply conducts such an experiment, that two separate networks
# could be connected with a router. We would model each of the network nodes
# as a network namespace, each of the networks as a network bridge:
#
# brA ==> network A (with subnet 172.16.0.0/24)
# brB ==> network B (with subnet 192.168.0.0/24)
#
# ns1 ==> node 1 (in network A)
# ns2 ==> node 2 (in network B)
# ns3 ==> node 3 (in network A)
# ns4 ==> node 4 (in network B)
# nsr ==> router (in network A and B)
#
# vethN-a ==> one of the veth pair ends, in the global namespace
# vethN-b ==> one of the veth pair ends, in the nsN/nsr namespace
#

# settings
addrs=("172.16.0.10/24" "192.168.0.10/24" "172.16.0.20/24" "192.168.0.20/24" "172.16.0.1/24" "192.168.0.1/24")
gws=("172.16.0.1" "192.168.0.1" "172.16.0.1" "192.168.0.1")

# create stuff
for i in "A" "B"; do
    echo "creating bridge br${i} ..."
    brctl addbr "br${i}"
    ip link set "br${i}" up
done

for i in {1..4} "r"; do
    echo "creating namespace ns${i} ..."
    ip netns add "ns${i}"
done

for i in {1..6}; do
    echo "creating veth${i} ..."

    ip link add "veth${i}-a" type veth peer name "veth${i}-b"
    ip link set "veth${i}-a" up

    if [ $(( ${i} % 2 )) -eq 1 ]; then
        brctl addif "brA" "veth${i}-a"
    else
        brctl addif "brB" "veth${i}-a"
    fi

    if [ ${i} -le 4 ]; then
        ip link set "veth${i}-b" netns "ns${i}"
        ip netns exec "ns${i}" ip link set "veth${i}-b" up
        ip netns exec "ns${i}" ip addr add "${addrs[$((i-1))]}" dev "veth${i}-b"

        ip netns exec "ns${i}" ip link set lo up

        ip netns exec "ns${i}" ip route add default via "${gws[$((i-1))]}" dev "veth${i}-b"
    else
        ip link set "veth${i}-b" netns "nsr"
        ip netns exec "nsr" ip link set "veth${i}-b" up
        ip netns exec "nsr" ip addr add "${addrs[$((i-1))]}" dev "veth${i}-b"

        ip netns exec "nsr" ip link set lo up
    fi
done
