#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "============================================================"
echo " BRONZE TEST - OpenFlow / Ryu Connectivity"
echo "============================================================"

echo ""
echo "[TEST 0] Ryu REST API Reachability"
echo "------------------------------------------------------------"
echo "  Command: curl -s http://localhost:8080/stats/switches"
echo "  Log:"
curl -s http://localhost:8080/stats/switches | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/stats/switches

echo ""
echo "Waiting for Ryu API to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8080/stats/switches >/dev/null 2>&1; then
        echo "  OK: Ryu API is ready"
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "  ERROR: Ryu API did not become ready in time"
        exit 1
    fi

    echo "  Attempt $i/30"
    sleep 1
done

echo ""
echo "[TEST 1] OVS Controller Connections"
echo "------------------------------------------------------------"
echo "  Command: docker exec ovs1 ovs-vsctl show"
echo "  Log:"
if docker exec ovs1 ovs-vsctl show | grep -q "is_connected: true"; then
    docker exec ovs1 ovs-vsctl show | head -20
    echo "  OK: OVS1 is connected to Ryu controller"
else
    echo "  ERROR: OVS1 is not connected"
    exit 1
fi

echo ""
echo "  Command: docker exec ovs2 ovs-vsctl show"
echo "  Log:"
if docker exec ovs2 ovs-vsctl show | grep -q "is_connected: true"; then
    docker exec ovs2 ovs-vsctl show | head -20
    echo "  OK: OVS2 is connected to Ryu controller"
else
    echo "  ERROR: OVS2 is not connected"
    exit 1
fi

echo ""
echo "[TEST 2] Ryu API Connected Switches"
echo "------------------------------------------------------------"
echo "  Command: curl -s http://localhost:8080/stats/switches"
echo "  Log:"
curl -s http://localhost:8080/stats/switches | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/stats/switches

echo ""
echo "============================================================"
echo " BRONZE TEST PASSED"
echo "============================================================"
echo ""

