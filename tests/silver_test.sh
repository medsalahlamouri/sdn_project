#!/bin/bash
set -e

echo "=================================="
echo " SILVER TEST - VXLAN Overlay"
echo "=================================="

echo
echo "[0] Reset OpenFlow rules"

docker exec ovs1 ovs-ofctl -O OpenFlow13 del-flows br-int
docker exec ovs2 ovs-ofctl -O OpenFlow13 del-flows br-int

docker exec ovs1 ovs-ofctl -O OpenFlow13 add-flow br-int actions=NORMAL
docker exec ovs2 ovs-ofctl -O OpenFlow13 add-flow br-int actions=NORMAL

echo "[OK] Default NORMAL flows restored"

sleep 2

echo
echo "[1] Verification tunnel VXLAN"

docker exec ovs1 ovs-vsctl show | grep -q vxlan0 \
    && echo "[OK] VXLAN present ovs1" \
    || exit 1

docker exec ovs2 ovs-vsctl show | grep -q vxlan0 \
    && echo "[OK] VXLAN present ovs2" \
    || exit 1

echo
echo "[2] Ping through VXLAN"

docker exec ovs1 ping -c 3 -W 2 10.0.0.2
docker exec ovs2 ping -c 3 -W 2 10.0.0.1

echo
echo "=================================="
echo " SILVER VALIDE"
echo "=================================="