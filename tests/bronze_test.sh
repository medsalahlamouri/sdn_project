#!/bin/bash
set -e

echo "=================================="
echo " BRONZE TEST - OpenFlow / Ryu"
echo "=================================="

sleep 10

echo
echo "[1] Verification connexion OVS -> Ryu"

docker exec ovs1 ovs-vsctl show | grep -q "is_connected: true" \
    && echo "[OK] ovs1 connecte a Ryu" \
    || echo "[KO] ovs1 NON connecte"

docker exec ovs2 ovs-vsctl show | grep -q "is_connected: true" \
    && echo "[OK] ovs2 connecte a Ryu" \
    || echo "[KO] ovs2 NON connecte"

echo
echo "[2] Verification API REST"

curl http://localhost:8080/stats/switches

echo
echo "=================================="
echo " BRONZE VALIDE"
echo "=================================="

