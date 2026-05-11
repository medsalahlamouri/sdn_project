#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "============================================================"
echo " SILVER TEST - VXLAN Overlay"
echo "============================================================"

echo ""
echo "Waiting for Ryu API to be ready (up to 60s)..."
for i in {1..60}; do
    if curl -s http://localhost:8080/stats/switches >/dev/null 2>&1; then
        echo "  OK: Ryu API is ready"
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "  ERROR: Ryu API did not become ready in time"
        exit 1
    fi
    echo "  Attempt $i/60"
    sleep 1
done

echo ""
echo "[TEST 0] Ryu API and OVS Controller Connectivity"
echo "------------------------------------------------------------"
echo "  Command: curl -s http://localhost:8080/stats/switches"
echo "  Log:"
curl -s http://localhost:8080/stats/switches | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/stats/switches

echo ""
echo "  Command: docker exec ovs1 ovs-vsctl show | grep is_connected"
echo "  Log:"
if docker exec ovs1 ovs-vsctl show | grep -q "is_connected: true"; then
    docker exec ovs1 ovs-vsctl show | grep "is_connected"
    echo "  OK: OVS1 is connected to Ryu"
else
    echo "  ERROR: OVS1 is not connected to Ryu"
    exit 1
fi

echo ""
echo "  Command: docker exec ovs2 ovs-vsctl show | grep is_connected"
echo "  Log:"
if docker exec ovs2 ovs-vsctl show | grep -q "is_connected: true"; then
    docker exec ovs2 ovs-vsctl show | grep "is_connected"
    echo "  OK: OVS2 is connected to Ryu"
else
    echo "  ERROR: OVS2 is not connected to Ryu"
    exit 1
fi

echo ""
echo "[TEST 1] Reset OpenFlow Rules to NORMAL"
echo "------------------------------------------------------------"
echo "  Command: docker exec ovs1 ovs-ofctl -O OpenFlow13 del-flows br-int"
echo "  Log:"
docker exec ovs1 ovs-ofctl -O OpenFlow13 del-flows br-int

echo ""
echo "  Command: docker exec ovs2 ovs-ofctl -O OpenFlow13 del-flows br-int"
echo "  Log:"
docker exec ovs2 ovs-ofctl -O OpenFlow13 del-flows br-int

echo ""
echo "  Command: docker exec ovs1 ovs-ofctl -O OpenFlow13 add-flow br-int actions=NORMAL"
echo "  Log:"
docker exec ovs1 ovs-ofctl -O OpenFlow13 add-flow br-int actions=NORMAL

echo ""
echo "  Command: docker exec ovs2 ovs-ofctl -O OpenFlow13 add-flow br-int actions=NORMAL"
echo "  Log:"
docker exec ovs2 ovs-ofctl -O OpenFlow13 add-flow br-int actions=NORMAL
echo "  OK: OpenFlow flows reset to NORMAL"

sleep 2

echo ""
echo "[TEST 2] VXLAN Tunnel Interfaces"
echo "------------------------------------------------------------"
echo "  Command: docker exec ovs1 ovs-vsctl show | grep vxlan0"
echo "  Log:"
if docker exec ovs1 ovs-vsctl show | grep -q vxlan0; then
    docker exec ovs1 ovs-vsctl show | grep vxlan0
    echo "  OK: VXLAN tunnel interface present on OVS1"
else
    echo "  ERROR: VXLAN tunnel not found on OVS1"
    exit 1
fi

echo ""
echo "  Command: docker exec ovs2 ovs-vsctl show | grep vxlan0"
echo "  Log:"
if docker exec ovs2 ovs-vsctl show | grep -q vxlan0; then
    docker exec ovs2 ovs-vsctl show | grep vxlan0
    echo "  OK: VXLAN tunnel interface present on OVS2"
else
    echo "  ERROR: VXLAN tunnel not found on OVS2"
    exit 1
fi

echo ""
echo "[TEST 3] Ping Connectivity Through VXLAN"
echo "------------------------------------------------------------"
echo "  Test: OVS1 (10.0.0.1) -> OVS2 (10.0.0.2)"
echo "  Command: docker exec ovs1 ping -c 3 -W 2 10.0.0.2"
echo "  Log:"
docker exec ovs1 ping -c 3 -W 2 10.0.0.2

echo ""
echo "  Test: OVS2 (10.0.0.2) -> OVS1 (10.0.0.1)"
echo "  Command: docker exec ovs2 ping -c 3 -W 2 10.0.0.1"
echo "  Log:"
docker exec ovs2 ping -c 3 -W 2 10.0.0.1

echo ""
echo "============================================================"
echo " SILVER TEST PASSED"
echo "============================================================"
echo ""