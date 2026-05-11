#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "============================================================"
echo " GOLD TEST - SDN Firewall / Flow Control"
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
echo "[TEST 1] Verify Ryu Connectivity"
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
echo "[TEST 1.5] Reset OpenFlow Rules to NORMAL"
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

echo ""
echo "[TEST 2] Baseline Connectivity (Before Firewall Rule)"
echo "------------------------------------------------------------"
echo "  Pre-rule ping: OVS1 (10.0.0.1) -> OVS2 (10.0.0.2)"
echo "  Command: docker exec ovs1 ping -c 2 -W 2 10.0.0.2"
echo "  Log:"
if docker exec ovs1 ping -c 2 -W 2 10.0.0.2; then
    echo "  OK: Pre-rule ping OVS1 -> OVS2 succeeded"
else
    echo "  ERROR: Pre-rule ping OVS1 -> OVS2 failed"
    exit 1
fi

echo ""
echo "  Pre-rule ping: OVS2 (10.0.0.2) -> OVS1 (10.0.0.1)"
echo "  Command: docker exec ovs2 ping -c 2 -W 2 10.0.0.1"
echo "  Log:"
if docker exec ovs2 ping -c 2 -W 2 10.0.0.1; then
    echo "  OK: Pre-rule ping OVS2 -> OVS1 succeeded"
else
    echo "  ERROR: Pre-rule ping OVS2 -> OVS1 failed"
    exit 1
fi

echo ""
echo "[TEST 3] Install Firewall Rule via Ryu REST API"
echo "------------------------------------------------------------"
echo "  Action: Drop all ICMP packets from 10.0.0.1 to 10.0.0.2"
echo "  Command: python3 firewall.py"
echo "  Log:"
python3 firewall.py

sleep 2

echo ""
echo "[TEST 4] Verify Ping After Firewall Rule"
echo "------------------------------------------------------------"
echo "  Post-rule ping: OVS1 (10.0.0.1) -> OVS2 (10.0.0.2) [EXPECTED: FAIL]"
echo "  Command: docker exec ovs1 ping -c 3 -W 2 10.0.0.2"
echo "  Log:"
if docker exec ovs1 ping -c 3 -W 2 10.0.0.2; then
    echo "  ERROR: Post-rule ping OVS1 -> OVS2 succeeded (should be blocked)"
    exit 1
else
    echo "  OK: Post-rule ping OVS1 -> OVS2 blocked as expected"
fi

echo ""
echo "  Post-rule ping: OVS2 (10.0.0.2) -> OVS1 (10.0.0.1) [EXPECTED: SUCCESS]"
echo "  Command: docker exec ovs2 ping -c 3 -W 2 10.0.0.1"
echo "  Log:"
if docker exec ovs2 ping -c 3 -W 2 10.0.0.1; then
    echo "  OK: Post-rule ping OVS2 -> OVS1 succeeded as expected"
else
    echo "  ERROR: Post-rule ping OVS2 -> OVS1 failed unexpectedly"
    exit 1
fi

echo ""
echo "[TEST 5] Display Installed OpenFlow Rules"
echo "------------------------------------------------------------"
echo "  OpenFlow table on OVS1"
echo "  Command: docker exec ovs1 ovs-ofctl -O OpenFlow13 dump-flows br-int"
echo "  Log:"
docker exec ovs1 ovs-ofctl -O OpenFlow13 dump-flows br-int

echo ""
echo "  OpenFlow table on OVS2"
echo "  Command: docker exec ovs2 ovs-ofctl -O OpenFlow13 dump-flows br-int"
echo "  Log:"
docker exec ovs2 ovs-ofctl -O OpenFlow13 dump-flows br-int

echo ""
echo "============================================================"
echo " GOLD TEST PASSED"
echo "============================================================"
echo ""