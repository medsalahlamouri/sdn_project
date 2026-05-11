#!/bin/bash
set -e

echo "=================================="
echo " GOLD TEST - SDN Firewall"
echo "=================================="

echo
echo "[1] Ping before firewall"

docker exec ovs1 ping -c 2 -W 2 10.0.0.2

echo
echo "[2] Installing DROP ICMP rule"

python3 firewall.py

sleep 2

echo
echo "[3] Ping after firewall"

if docker exec ovs1 ping -c 3 -W 2 10.0.0.2; then
    echo "[ERROR] Firewall failed"
    exit 1
else
    echo "[OK] Ping blocked by SDN firewall"
fi

echo
echo "[4] OpenFlow flows"

docker exec ovs1 ovs-ofctl -O OpenFlow13 dump-flows br-int

echo
echo "=================================="
echo " GOLD VALIDE"
echo "=================================="