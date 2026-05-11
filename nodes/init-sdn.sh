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
ip link del vxlan0 2>/dev/null || true

ip link add vxlan0 type vxlan \
    id 100 \
    dstport 4789 \
    remote ${REMOTE_IP} \
    dev eth0

ip link set vxlan0 mtu 1450
ip link set vxlan0 up

echo "[OVS] VXLAN kernel created"

# Attach VXLAN to OVS
ovs-vsctl --may-exist add-port br-int vxlan0

# Overlay IP
ip addr add ${LOCAL_IP}/24 dev br-int 2>/dev/null || true

ip link set br-int mtu 1450
ip link set br-int up

# Ryu controller
ovs-vsctl set-controller br-int tcp:${CONTROLLER_IP}:6653

echo "[OVS] Final configuration"

ovs-vsctl show

tail -f /dev/null