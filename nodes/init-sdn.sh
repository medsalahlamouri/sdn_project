#!/bin/bash

echo "[OVS] Initialisation userspace..."

mkdir -p /var/run/openvswitch /etc/openvswitch

if [ ! -f /etc/openvswitch/conf.db ]; then
    ovsdb-tool create /etc/openvswitch/conf.db \
        /usr/share/openvswitch/vswitch.ovsschema
fi

ovsdb-server \
    --remote=punix:/var/run/openvswitch/db.sock \
    --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
    --pidfile --detach --log-file

sleep 1

ovs-vsctl --no-wait init

ovs-vswitchd --pidfile --detach --log-file

sleep 2

# Reset bridge
ovs-vsctl --if-exists del-br br-int

# Bridge OVS userspace
ovs-vsctl add-br br-int \
    -- set bridge br-int datapath_type=netdev

# OpenFlow 1.3
ovs-vsctl set bridge br-int protocols=OpenFlow13

# DPID
DPID=$(printf "%016d" "${NODE_ID}")
ovs-vsctl set bridge br-int other-config:datapath-id=$DPID

echo "[OVS] DPID = $DPID"

# VXLAN kernel Linux
echo "[OVS] Creating VXLAN tunnel to ${REMOTE_IP}..."

if [ -z "${REMOTE_IP}" ]; then
    echo "[ERROR] REMOTE_IP not set"
    exit 1
fi

ip link del vxlan0 2>/dev/null || true

if ! ip link add vxlan0 type vxlan id 100 dstport 4789 remote "${REMOTE_IP}" dev eth0; then
    echo "[ERROR] Failed to create VXLAN interface"
    exit 1
fi

ip link set vxlan0 mtu 1450
ip link set vxlan0 up

if ! ip link show vxlan0 | grep -q "UP"; then
    echo "[ERROR] VXLAN interface failed to come up"
    exit 1
fi

echo "[OVS] VXLAN tunnel created successfully"

# Attach VXLAN to OVS
echo "[OVS] Attaching VXLAN interface to bridge..."
if ! ovs-vsctl --may-exist add-port br-int vxlan0; then
    echo "[ERROR] Failed to attach VXLAN port to br-int"
    exit 1
fi

# Overlay IP
echo "[OVS] Configuring overlay IP ${LOCAL_IP}/24..."
ip addr add ${LOCAL_IP}/24 dev br-int 2>/dev/null || true

ip link set br-int mtu 1450
if ! ip link set br-int up; then
    echo "[ERROR] Failed to bring up br-int interface"
    exit 1
fi

# Ryu controller
echo "[OVS] Connecting to Ryu controller at ${CONTROLLER_IP}:6653..."
if ! ovs-vsctl set-controller br-int tcp:${CONTROLLER_IP}:6653; then
    echo "[ERROR] Failed to set controller"
    exit 1
fi

echo "[OVS] Final configuration"

ovs-vsctl show

tail -f /dev/null