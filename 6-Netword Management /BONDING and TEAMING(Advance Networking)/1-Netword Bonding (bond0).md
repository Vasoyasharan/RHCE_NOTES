# 🔗 RHEL 9 Network Bonding — Complete Lab Guide

> 📌 **Lab Environment:** VMware Workstation Pro 25H2 | RHEL 9.7 | 5 NICs (ens160, ens161, ens193, ens224, ens256)

---

## 🧪 Lab Overview

In this lab, you will:

| Task | Technology | Purpose |
|------|-----------|---------|
| Add 4 extra NICs to VM | VMware | Simulate multiple physical interfaces |
| Create a bond interface | Linux Bonding | Link aggregation / failover |
| Create a team interface | Linux Teaming | Modern alternative to bonding |
| Test SSH connectivity | SSH | Validate the bond/team IP is reachable |

### 🖧 Network Layout

```
VMware VM (Client 1 - RHEL 9.7)
├── ens160   → Bridged (existing management NIC - 192.168.68.x)
├── ens161   → NAT (slave of bond0 / team0)
├── ens193   → NAT (slave of bond0 / team0)
├── ens224   → NAT (slave of bond0 / team0)
└── ens256   → NAT (slave of bond0 / team0)
         └──> bond0 / team0 → IP: 192.168.102.100/24
```

---

## 🖥️ Step 1 — Add NICs in VMware

> 📸 *Images 1 & 2 from the lab*

In **VMware Workstation → Client 1 VM → Edit Virtual Machine Settings → Add Hardware Wizard**:

1. Select **Network Adapter** → Click **Finish**
2. Repeat **4 times** to get ens161, ens193, ens224, ens256
3. Set each new NIC to **NAT** mode

After adding, your VM settings will show:

```
Network Adapter    → Bridged (Automatic)   ← ens160 (management)
Network Adapter 2  → NAT                   ← ens161
Network Adapter 3  → NAT                   ← ens193
Network Adapter 4  → NAT                   ← ens224
Network Adapter 5  → NAT                   ← ens256
```

> ⚠️ **Note:** USB Controller and Sound Card show "Maximum limit reached" — that's normal, ignore them.

---

## 🔍 Step 2 — Verify NICs in RHEL

> 📸 *Image 3 from the lab*

After booting into RHEL, verify all NICs are detected:

```bash
nmcli dev status
```

**Output:**
```
DEVICE   TYPE      STATE          CONNECTION
ens160   ethernet  connected      ens160
lo       loopback  connected (externally)  lo
ens161   ethernet  disconnected   --
ens193   ethernet  disconnected   --
ens224   ethernet  disconnected   --
ens256   ethernet  disconnected   --
```

✅ **ens160** is connected (your management/internet interface)
🔴 **ens161–ens256** are disconnected — these will become bond/team slaves

Also verify the bonding kernel module is loaded:

```bash
modinfo bonding
```

**Output (partial):**
```
filename:    /lib/modules/5.14.0-611.5.1.el9_7.x86_64/kernel/drivers/net/bonding/bonding.ko.xz
description: Ethernet Channel Bonding Driver
alias:       rtnl-link-bond
rhelversion: 9.7
name:        bonding
```

✅ The bonding driver is available on RHEL 9.7.

---

## 🔗 Part A — Network Bonding (bond0)

> 📸 *Images 4, 5, 6, 7, 8 from the lab*

### What is Bonding?

**Network Bonding** combines multiple NICs into a single logical interface. The **`balance-rr`** (Round Robin) mode we use here sends packets sequentially across all slave interfaces for load balancing.

```
ens161 ─┐
ens193 ─┤
ens224 ─┼──► bond0 (192.168.102.100/24)
ens256 ─┘
```

### Bonding Modes Quick Reference

| Mode | Name | Description |
|------|------|-------------|
| 0 | `balance-rr` | Round robin — load balancing + fault tolerance |
| 1 | `active-backup` | One active, others standby — pure failover |
| 2 | `balance-xor` | XOR-based load balancing |
| 4 | `802.3ad` | IEEE 802.3ad LACP — requires switch support |
| 5 | `balance-tlb` | Adaptive transmit load balancing |
| 6 | `balance-alb` | Adaptive load balancing |

---

### 1. Create the Bond Master (bond0)

```bash
nmcli connection add \
  con-name bond0 \
  type bond \
  ifname bond0 \
  mode balance-rr \
  ipv4.method manual \
  ipv4.addresses 192.168.102.100/24 \
  ipv4.gateway 192.168.102.2 \
  ipv4.dns 8.8.8.8 \
  ipv6.method disabled
```

**Output:**
```
Connection 'bond0' (8cb010b5-e7f1-41e2-b54a-74c800b0a284) successfully added.
```

Verify it was created:

```bash
nmcli connection show
```

**Output:**
```
NAME    UUID                                   TYPE      DEVICE
ens160  ae862be8-af8e-3163-8360-f2e852298b73  ethernet  ens160
bond0   8cb010b5-e7f1-41e2-b54a-74c800b0a284  bond      bond0
lo      434e72f1-9824-4dc7-aff5-2c7c284416a1  loopback  lo
```

Inspect the config file:

```bash
cd /etc/NetworkManager/system-connections/
cat bond0.nmconnection
```

**Output:**
```ini
[connection]
id=bond0
uuid=8cb010b5-e7f1-41e2-b54a-74c800b0a284
type=bond
interface-name=bond0

[bond]
mode=balance-rr

[ipv4]
address1=192.168.102.100/24
dns=8.8.8.8;
gateway=192.168.102.2
method=manual

[ipv6]
addr-gen-mode=default
method=disabled

[proxy]
```

---

### 2. Create Slave Ports for bond0

Each slave binds one physical NIC to the bond master:

```bash
# Slave 1 — ens161
nmcli connection add con-name bond0-port1 type ethernet slave-type bond master bond0 ifname ens161

# Slave 2 — ens193
nmcli connection add con-name bond0-port2 type ethernet slave-type bond master bond0 ifname ens193

# Slave 3 — ens224
nmcli connection add con-name bond0-port3 type ethernet slave-type bond master bond0 ifname ens224

# Slave 4 — ens256
nmcli connection add con-name bond0-port4 type ethernet slave-type bond master bond0 ifname ens256
```

**Output:**
```
Connection 'bond0-port1' (53d847be-8645-4bbf-9693-712faf7a01c1) successfully added.
Connection 'bond0-port2' (a9596ed4-8613-4f74-8102-2013ce710c9f) successfully added.
Connection 'bond0-port3' (f255012d-768e-4929-bcea-39ee3d74940f) successfully added.
Connection 'bond0-port4' (769dc41f-6a8b-4c25-9df6-3bf1117e7f48) successfully added.
```

Verify slave config file:

```bash
cat bond0-port1.nmconnection
```

**Output:**
```ini
[connection]
id=bond0-port1
uuid=53d847be-8645-4bbf-9693-712faf7a01c1
type=ethernet
controller=bond0
interface-name=ens161
port-type=bond

[ethernet]
```

✅ `controller=bond0` confirms this NIC is enslaved to bond0.

Verify all files:

```bash
ll /etc/NetworkManager/system-connections/
```

**Output:**
```
-rw-------. 1 root root 259 Apr 16 07:35 bond0.nmconnection
-rw-------. 1 root root 163 Apr 16 07:41 bond0-port1.nmconnection
-rw-------. 1 root root 163 Apr 16 07:41 bond0-port2.nmconnection
-rw-------. 1 root root 163 Apr 16 07:42 bond0-port3.nmconnection
-rw-------. 1 root root 163 Apr 16 07:42 bond0-port4.nmconnection
-rw-------. 1 root root 229 Mar 17 07:59 ens160.nmconnection
```

---

### 3. Bring bond0 Up & Test Connectivity

```bash
nmcli connection up bond0
```

**Output:**
```
Connection successfully activated (controller waiting for ports)
(D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/9)
```

Check interface status:

```bash
ip a
```

**Output (relevant parts):**
```
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    inet 192.168.68.114/24 brd 192.168.68.255 scope global dynamic ens160

3: ens161: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 ... master bond0 ...
4: ens193: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 ... master bond0 ...
5: ens224: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 ... master bond0 ...
6: ens256: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 ... master bond0 ...

7: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 ...
    inet 192.168.102.100/24 brd 192.168.102.255 scope global noprefixroute bond0
```

> 🔑 Key flags: `SLAVE` on ens161–ens256 and `MASTER` on bond0

Verify device status:

```bash
nmcli dev status
```

**Output:**
```
DEVICE   TYPE      STATE     CONNECTION
ens160   ethernet  connected ens160
bond0    bond      connected bond0
lo       loopback  connected (externally) lo
ens161   ethernet  connected bond0-port1
ens193   ethernet  connected bond0-port2
ens224   ethernet  connected bond0-port3
ens256   ethernet  connected bond0-port4
```

#### 🔐 SSH Test from Host Machine

From your admin PC (host), test connectivity to bond0's IP:

```bash
ping 192.168.102.100
```

**Output:**
```
PING 192.168.102.100 (192.168.102.100) 56(84) bytes of data.
64 bytes from 192.168.102.100: icmp_seq=1 ttl=64 time=1.59 ms
--- 192.168.102.100 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss
```

```bash
ssh root@192.168.102.100
```

**Output:**
```
The authenticity of host '192.168.102.100' can't be established.
Are you sure you want to continue connecting (yes/no)? yes
root@192.168.102.100's password: ****

Last login: Thu Apr 16 07:16:34 2026
[root@client1 ~]#
```

✅ **SSH via bond0 IP works!**

Check who is logged in:

```bash
who
```

**Output:**
```
admin  seat0  2026-04-16 07:16 (login screen)
admin  tty2   2026-04-16 07:16 (tty2)
root   pts/1  2026-04-16 07:47 (192.168.102.1)
```

> 📌 `192.168.102.1` is the NAT gateway — root is SSHed in through the bond interface.

---

### 4. Cleanup — Delete bond0 and All Slaves

> 📸 *Image 8 from the lab*

First, bring bond0 down:

```bash
nmcli connection down bond0
```

**Output:**
```
Connection 'bond0' successfully deactivated
(D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/9)
```

Delete the bond master:

```bash
nmcli connection delete bond0
```

**Output:**
```
Connection 'bond0' (8cb010b5-e7f1-41e2-b54a-74c800b0a284) successfully deleted.
```

Delete all slaves in one command:

```bash
nmcli connection delete bond0-port1 bond0-port2 bond0-port3 bond0-port4
```

**Output:**
```
Connection 'bond0-port1' (53d847be-8645-4bbf-9693-712faf7a01c1) successfully deleted.
Connection 'bond0-port2' (a9596ed4-8613-4f74-8102-2013ce710c9f) successfully deleted.
Connection 'bond0-port3' (f255012d-768e-4929-bcea-39ee3d74940f) successfully deleted.
Connection 'bond0-port4' (769dc41f-6a8b-4c25-9df6-3bf1117e7f48) successfully deleted.
```

Verify cleanup:

```bash
ll /etc/NetworkManager/system-connections/
```

**Output:**
```
total 8
-rw-------. 1 root root 229 Mar 17 07:59 ens160.nmconnection
```

✅ Only the original `ens160` connection remains.

Check routes — you should see 2 routes (ens160's network + default):

```bash
ip r
```

**Output:**
```
default via 192.168.68.2 dev ens160 proto dhcp src 192.168.68.114 metric 100
192.168.68.0/24 dev ens160 proto kernel scope link src 192.168.68.114 metric 100
```

> 📌 The bond0 route `192.168.102.0/24` is now gone since we deleted bond0.

---
 
### Part B — Network Teaming (team0)

![LIKE](https://github.com/Vasoyasharan/RHCE_NOTES/blob/main/6-Netword%20Management%20/BONDING%20and%20TEAMING(Advance%20Networking)/2-Network%20Teaming%20(team0).md)
