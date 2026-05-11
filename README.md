# SDN VXLAN Project with Ryu and Open vSwitch

## Project Overview

This project demonstrates a simple Software Defined Networking (SDN) architecture using:

- Ryu SDN Controller
- Open vSwitch (OVS)
- OpenFlow 1.3
- VXLAN Overlay Network
- Dynamic SDN Firewall
- Docker & WSL2

The infrastructure contains:

- 1 Ryu Controller
- 2 OVS Nodes
- VXLAN tunnel between nodes

---

# Architecture

```text
        +-------------------+
        |   Ryu Controller  |
        | OpenFlow + REST   |
        +---------+---------+
                  |
          OpenFlow Control
                  |
    +-------------+-------------+
    |                           |
+---+---+                 +-----+---+
| OVS1  |==== VXLAN ====  |  OVS2   |
|10.0.0.1|               |10.0.0.2 |
+-------+                 +---------+
````

---

# Overlay and VXLAN

VXLAN (Virtual Extensible LAN) is an overlay networking technology.

The physical Docker network uses:

```text
172.33.0.0/24
```

Inside the VXLAN tunnel, the SDN nodes communicate using virtual overlay IP addresses:

* OVS1 → 10.0.0.1
* OVS2 → 10.0.0.2

The VXLAN tunnel encapsulates traffic between both OVS nodes over the Docker network.

This creates a virtual Layer 2 overlay network above the physical infrastructure.

---

# Technologies Used

* Docker
* Docker Compose
* Open vSwitch
* Ryu Controller
* OpenFlow 1.3
* VXLAN
* Python REST API

---

# Project Levels

## Bronze Level

Test OpenFlow connectivity between OVS and Ryu.

Checks:

* OVS connected to controller
* REST API available

Command:

```bash
bash tests/bronze_test.sh
```

---

## Silver Level

Test VXLAN overlay communication.

Checks:

* VXLAN interface exists
* Ping between OVS nodes works

Command:

```bash
bash tests/silver_test.sh
```

---

## Gold Level

Test dynamic SDN firewall.

The Python script installs an OpenFlow DROP rule using REST API.

Result:

* Ping works before firewall
* Ping blocked after firewall

Command:

```bash
bash tests/gold_test.sh
```

---

# Firewall Automation

The firewall is controlled dynamically using Python.

Python script:

```bash
python3 firewall.py
```

The script sends a REST API request to Ryu, which installs OpenFlow rules on OVS.

---

# Important OpenFlow Rules

## NORMAL Flow

```text
actions=NORMAL
```

Allows normal switching and forwarding.

## DROP Flow

```text
actions=drop
```

Blocks ICMP traffic between nodes.

---

# Main Commands

## Start Project

```bash
docker compose up --build -d
```

## Stop Project

```bash
docker compose down -v
```

## Show OVS Configuration

```bash
docker exec ovs1 ovs-vsctl show
```

## Show OpenFlow Rules

```bash
docker exec ovs1 ovs-ofctl -O OpenFlow13 dump-flows br-int
```

## Test Connectivity

```bash
docker exec ovs1 ping 10.0.0.2
```

---

# SDN Principle

Traditional networks are manually configured.

In SDN:

* The controller manages the network centrally
* Switches follow OpenFlow rules
* Network behavior becomes programmable

This project demonstrates:

* Centralized control
* Dynamic firewalling
* Overlay networking with VXLAN
* OpenFlow traffic management

---

# Final Result

✅ OpenFlow communication works
✅ VXLAN overlay works
✅ Dynamic firewall works
✅ Ping blocked dynamically by SDN rules
✅ Full SDN architecture operational


