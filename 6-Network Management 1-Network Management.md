# 🖧 Red Hat Linux — Network Management Complete Guide

> 📘 A beginner-friendly, command-by-command guide to Linux networking using `nmcli`, `ip`, `hostname`, and NetworkManager on RHEL/CentOS/AlmaLinux.

---

## 🏷️ Hostname — Show & Change

The **hostname** is your machine's identity on the network. In the screenshots, the machine is named `client1.iforward.in`.

### 📌 Show Current Hostname

```bash
[admin@client1 ~]$ hostname
client1.iforward.in
```

### 📌 Show All Hostname Types

```bash
hostnamectl
```

Output shows:
- **Static hostname** — set by admin, survives reboot
- **Transient hostname** — temporary, set by DHCP/mDNS
- **Pretty hostname** — human-friendly display name

### 📌 Change the Hostname

```bash
sudo hostnamectl set-hostname newname.domain.com
```

> ⚠️ After changing, open a new terminal session to see the updated prompt.

---

## 📁 /etc/hosts — Local DNS Mapping

This file maps **IP addresses to hostnames** locally, without needing a DNS server.

### 📌 View the File

```bash
cat /etc/hosts
```

### 📌 Edit the File (as seen in Image 2)

```bash
sudo nano /etc/hosts
```

**Contents after editing:**

```
127.0.0.1    localhost localhost.localdomain localhost4 localhost4.localdomain4
::1          localhost localhost.localdomain localhost6 localhost6.localdomain6

##
192.168.68.128   client1.iforward.in
```

> 💡 The line `192.168.68.128   client1.iforward.in` tells the system: when you ping `client1.iforward.in`, go to `192.168.68.128`. This is **local DNS resolution**.

### 📌 Test It Works

```bash
[admin@client1 ~]$ ping 192.168.68.128
64 bytes from 192.168.68.128: icmp_seq=1 ttl=64 time=0.210 ms

[admin@client1 ~]$ ping client1.iforward.in
64 bytes from client1.iforward.in (192.168.68.128): icmp_seq=1 ttl=64 time=0.211 ms
```

Both commands reach the same IP — `/etc/hosts` resolved the name! ✅

---

## 🔌 NIC Naming Conventions

In modern Linux, network cards are **NOT** named `eth0`, `eth1`. They use **predictable names** based on hardware location.

| 🏷️ Prefix | 📖 Meaning | 📝 Example |
|-----------|-----------|-----------|
| `en` | Ethernet (wired) | `ens160`, `enp3s0` |
| `wl` | Wireless LAN (Wi-Fi) | `wlan0`, `wlp2s0` |
| `ww` | WWAN (mobile broadband) | `wwp0s20f0u2` |
| `lo` | Loopback (virtual, always 127.0.0.1) | `lo` |

### 📌 Second Part of Name (Location Code)

| 🔤 Letter | 📖 Meaning |
|-----------|-----------|
| `s` | Slot (PCI slot number) — e.g., `ens160` = ethernet, slot 160 |
| `p` | PCI bus position — e.g., `enp3s0` = PCI bus 3, slot 0 |
| `o` | Onboard — e.g., `eno1` = onboard ethernet 1 |
| `u` | USB port — e.g., `enusb0` |

> 💡 In the screenshots, the NIC is `ens160` (ethernet, slot 160) and also appears as `enp3s0` (its alternate name via `altname`).

---

## 🛠️ ip Utility — Exploring Network Details

The `ip` command is the modern replacement for `ifconfig`, `route`, and `arp`.

### 📌 Show All Interfaces (Brief)

```bash
[admin@client1 ~]$ ip li
# or
ip link
```

**Output:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 ...
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    link/ether 00:0c:29:07:29:97 brd ff:ff:ff:ff:ff:ff
    altname enp3s0
```

### 📌 Show IP Addresses

```bash
[admin@client1 ~]$ ip a
# or
ip addr
```

**Output (from Image 4):**
```
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    inet 192.168.68.128/24 brd 192.168.68.255 scope global dynamic ens160
    inet6 fe80::20c:29ff:fe07:2997/64 scope link
```

> 📌 `inet` = IPv4 address | `inet6` = IPv6 address | `/24` = subnet mask (255.255.255.0)

### 📌 Show Routing Table

```bash
[admin@client1 ~]$ ip r
# or
ip route
```

**Output:**
```
default via 192.168.68.1 dev ens160 proto dhcp src 192.168.68.128 metric 100
192.168.68.0/24 dev ens160 proto kernel scope link src 192.168.68.128 metric 100
```

> 💡 `default via 192.168.68.1` = **Gateway** — all unknown traffic goes here (your router).

### 📌 Show Interface Statistics (Packets/Errors)

```bash
[admin@client1 ~]$ ip -s link
```

**Output (from Image 3):**
```
2: ens160: ...
    RX:  bytes   packets  errors  dropped  missed  mcast
         311477  500      0       11       0       56
    TX:  bytes   packets  errors  dropped  carrier collsns
         22638   273      0       0        0       0
```

> 📌 `RX` = Received | `TX` = Transmitted | `dropped=11` means some packets were lost

### 📌 Show NIC Hardware Details

```bash
[admin@client1 ~]$ ethtool ens160
```

**Output (from Image 3):**
```
Speed: 10000Mb/s
Duplex: Full
Port: Twisted Pair
Link detected: yes
```

> 💡 This shows your NIC is running at 10Gbps Full Duplex — very fast!

---

## 🌐 NetworkManager — The Brain of Networking

**NetworkManager** is the service that manages all network connections in Red Hat-based systems.

### 📌 Check its Status

```bash
[admin@client1 ~]$ systemctl status NetworkManager
```

**Output (from Image 3):**
```
● NetworkManager.service - Network Manager
   Loaded: loaded (/usr/lib/systemd/system/NetworkManager.service; enabled)
   Active: active (running) since Tue 2026-04-14 08:01:15 IST; 7min ago
   Main PID: 1104 (NetworkManager)
```

> ✅ `active (running)` = NetworkManager is working fine.

### 📌 Start / Stop / Enable

```bash
sudo systemctl start NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable NetworkManager   # Auto-start on boot
```

---

## 🔗 Devices vs Connections — Key Concept!

> 🧠 This is the most important concept — don't confuse these two!

| 🔧 Term        | 📖 What It Is                              | 📝 Example                                  |
| -------------- | ------------------------------------------ | ------------------------------------------- |
| **Device**     | Physical/virtual NIC hardware              | `ens160` (the actual network card)          |
| **Connection** | Configuration profile (like a config file) | `ens160-static` (IP settings, DNS, gateway) |

Think of it like this:
- 🖥️ **Device** = your pen drive (hardware)
- 📄 **Connection** = the files/settings stored on it

> 💡 One device can have **multiple connections**, but only **one can be active** at a time. You can switch between them!

---

## 📋 nmcli — Managing Network with CLI

`nmcli` = **NetworkManager Command Line Interface**

### 📌 Show All Connections

```bash
[admin@client1 ~]$ nmcli connection
# or
nmcli con
```

**Output (from Image 4):**
```
NAME            UUID                                  TYPE      DEVICE
ens160          ae862be8-af8e-3163-8360-f2e852298b73  ethernet  ens160
lo              c5bd1ee5-5fad-4b5c-a804-d9c15950e35d  loopback  lo
```

### 📌 Show Device Status

```bash
[admin@client1 ~]$ nmcli dev status
# or
nmcli dev sta
```

**Output:**
```
DEVICE   TYPE      STATE     CONNECTION
ens160   ethernet  connected ens160
lo       loopback  connected (externally) lo
```

> 💡 `STATE: connected` = this device has an active connection profile attached.

---

## ➕ Adding a Static IP Connection

Instead of DHCP (automatic IP), you can set a **fixed/static IP**.

### 📌 The Command (from Image 6)

```bash
nmcli connection add \
  con-name ens160-static \
  type ethernet \
  ifname ens160 \
  ipv4.addresses 192.168.68.243/24 \
  gw4 192.168.68.1 \
  ipv4.method manual \
  ipv6.method disabled \
  ipv4.dns 192.168.68.1
```

**Output:**
```
Connection 'ens160-static' (d20a268f-7195-46ea-8f89-a3877c517145) successfully added.
```

### 📖 What Each Option Means

| 🔤 Option | 📖 Meaning |
|----------|-----------|
| `con-name ens160-static` | Name for this connection profile |
| `type ethernet` | Type of connection |
| `ifname ens160` | Which device (NIC) to attach to |
| `ipv4.addresses 192.168.68.243/24` | Static IP with subnet |
| `gw4 192.168.68.1` | Gateway (router IP) |
| `ipv4.method manual` | Manual = static IP (not DHCP) |
| `ipv6.method disabled` | Disable IPv6 |
| `ipv4.dns 192.168.68.1` | DNS server to use |

### 📌 Verify the New Connection Was Created

```bash
[admin@client1 ~]$ nmcli connection
```

**Output (from Image 7):**
```
NAME            UUID                                  TYPE      DEVICE
ens160          ae862be8-...                          ethernet  ens160
lo              c5bd1ee5-...                          loopback  lo
ens160-static   d20a268f-...                          ethernet  --
```

> 📌 Notice `ens160-static` shows `--` under DEVICE — it's created but **not yet active**.

---

## 🔄 Switching Connections (Down Old, Up New)

### 📌 Step 1: Bring Down the Old Connection

```bash
[admin@client1 system-connections]$ nmcli connection down ens160
Connection 'ens160' successfully deactivated
```

> ⚡ When you deactivate `ens160`, NetworkManager **automatically activates** `ens160-static` if it's the next available profile for that device.

### 📌 Step 2: Verify the IP Changed

```bash
ip a
```

**Output (from Image 8):**
```
2: ens160:
    inet 192.168.68.243/24 brd 192.168.68.255 scope global ens160
```

> ✅ IP changed from `192.168.68.128` (DHCP) → `192.168.68.243` (Static)!

### 📌 Manually Bring Up a Specific Connection

```bash
nmcli connection up ens160-static
```

### 📌 Manually Bring Up Old DHCP Connection

```bash
nmcli connection up ens160
```

---

## 🧪 Verifying Connectivity

After switching to static IP, always verify internet still works:

```bash
[admin@client1 ~]$ ping 8.8.8.8
64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=60.6 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=116 time=42.1 ms
✅ Internet via IP works!

[admin@client1 ~]$ ping google.com
64 bytes from del11s22-in-f14.1e100.net (142.250.206.174): icmp_seq=1 ttl=117 time=27.8 ms
✅ DNS resolution + internet works!
```

---

## 📂 NetworkManager Config Files

All connection profiles are stored as files in:

```
/etc/NetworkManager/system-connections/
```

### 📌 Navigate and List Files

```bash
[admin@client1 ~]$ cd /etc/NetworkManager/
[admin@client1 NetworkManager]$ ll
```

**Output (from Image 5):**
```
drwxr-xr-x  conf.d
drwxr-xr-x  dispatcher.d
drwxr-xr-x  dnsmasq.d
drwxr-xr-x  dnsmasq-shared.d
-rw-r--r--  NetworkManager.conf
drwxr-xr-x  system-connections    ← connection files live here
```

```bash
[admin@client1 NetworkManager]$ cd system-connections/
[admin@client1 system-connections]$ ll
```

```
-rw-------  ens160.nmconnection           ← original DHCP profile
-rw-------  ens160-static.nmconnection    ← your static IP profile
```

### 📌 View the Static Connection File

```bash
[admin@client1 system-connections]$ sudo cat ens160-static.nmconnection
```

**Output (from Image 5):**
```ini
[connection]
id=ens160-static
uuid=d20a268f-7195-46ea-8f89-a3877c517145
type=ethernet
interface-name=ens160

[ethernet]

[ipv4]
address1=192.168.68.243/24
dns=192.168.68.1;
gateway=192.168.68.1
method=manual

[ipv6]
addr-gen-mode=default
method=disabled

[proxy]
```

> 🔐 Files in `system-connections/` are `root:root` with `600` permissions — only root can read them (security).

---

## 🖥️ nmtui — GUI in Terminal

For those who prefer a **text-based graphical interface** instead of typing commands:

```bash
nmtui
```

This opens a menu-driven interface where you can:
- ✏️ **Edit a connection** — change IP, gateway, DNS
- ➕ **Activate a connection** — enable/disable
- 🏷️ **Set system hostname**

> 💡 Great for beginners or when you forget the exact `nmcli` syntax!

---

## 🧠 Quick Cheatsheet

| 🎯 Task | ⚡ Command |
|--------|----------|
| Show hostname | `hostname` |
| Change hostname | `sudo hostnamectl set-hostname NAME` |
| Edit local DNS | `sudo nano /etc/hosts` |
| Show IP addresses | `ip a` |
| Show routing table | `ip r` |
| Show link stats | `ip -s link` |
| Show NIC hardware info | `ethtool ens160` |
| Check NetworkManager status | `systemctl status NetworkManager` |
| List all connections | `nmcli con` |
| List device status | `nmcli dev sta` |
| Add static IP connection | `nmcli con add con-name NAME type ethernet ifname DEV ipv4.addresses IP/PREFIX gw4 GW ipv4.method manual ipv4.dns DNS ipv6.method disabled` |
| Activate a connection | `nmcli con up CONNECTION_NAME` |
| Deactivate a connection | `nmcli con down CONNECTION_NAME` |
| Delete a connection | `nmcli con delete CONNECTION_NAME` |
| Open TUI network manager | `nmtui` |
| View connection config file | `sudo cat /etc/NetworkManager/system-connections/NAME.nmconnection` |

---

## 🔁 Full Workflow Recap

```
1. Check current IP           →  ip a
2. Check current connections  →  nmcli con
3. Add a static connection    →  nmcli con add con-name ens160-static ...
4. Verify it's created        →  nmcli con  (see DEVICE = --)
5. Down the old connection    →  nmcli con down ens160
6. New connection auto-ups    →  ip a  (verify new IP applied)
7. Manually bring up if needed→  nmcli con up ens160-static
8. Test internet              →  ping 8.8.8.8 && ping google.com
```

---

> 📝 **Notes:**
> - All changes made via `nmcli` are **persistent** (survive reboot) — they're saved to `/etc/NetworkManager/system-connections/`
> - Changes made via `ip` command directly are **temporary** (lost on reboot)
> - Always test internet (`ping 8.8.8.8`) after changing network settings!

---

*Guide based on hands-on lab session — Red Hat Enterprise Linux / AlmaLinux 9* 🐧
