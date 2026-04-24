
## 🤝 Part B — Network Teaming (team0)

> 📸 *Images 9 & 10 from the lab*

### What is Teaming?

**Network Teaming** is the **modern replacement** for bonding in RHEL. It uses a small kernel driver + a userspace daemon (`teamd`) for more flexibility.

| Feature | Bonding | Teaming |
|---------|---------|---------|
| Kernel module | `bonding` | `team` |
| Userspace daemon | None | `teamd` |
| Configuration | `/proc/net/bonding/` | JSON runner config |
| RHEL support | Legacy | Preferred in RHEL 8/9 |

```
ens161 ─┐
ens193 ─┤
ens224 ─┼──► team0 (DHCP or static IP)
ens256 ─┘
```

---

### 1. Create the Team Master (team0)

```bash
nmcli connection add \
  con-name team0 \
  type team \
  ifname team0 \
  ipv4.method auto \
  ipv6.method disabled
```

**Output:**
```
Connection 'team0' (4135a3e4-c8c4-4f6e-8173-8488899eb970) successfully added.
```

Inspect the config:

```bash
cat /etc/NetworkManager/system-connections/team0.nmconnection
```

**Output:**
```ini
[connection]
id=team0
uuid=4135a3e4-c8c4-4f6e-8173-8488899eb970
type=team
interface-name=team0

[team]

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=disabled

[proxy]
```

> 💡 `ipv4.method auto` = DHCP. The `[team]` section is empty here (uses default `activebackup` runner). You can add a JSON runner config for advanced modes.

---

### 2. Create Port Members for team0

```bash
# Port 1 — ens161
nmcli connection add type ethernet ifname 161 con-name team0-port1 slave-type team master team0

# Port 2 — ens193
nmcli connection add type ethernet ifname 193 con-name team0-port2 slave-type team master team0

# Port 3 — ens224
nmcli connection add type ethernet ifname 224 con-name team0-port3 slave-type team master team0

# Port 4 — ens256
nmcli connection add type ethernet ifname 256 con-name team0-port4 slave-type team master team0
```

> ⚠️ **Note:** In the lab, short ifnames like `161`, `193` etc. were used as shorthand — in your environment use `ens161`, `ens193`, etc. if those are the actual device names.

**Output:**
```
Connection 'team0-port1' (782b1dd7-a958-4acd-b017-2d62b1921488) successfully added.
Connection 'team0-port2' (21b35961-04a4-46ce-93ca-985dce57413f) successfully added.
Connection 'team0-port3' (2a425846-6a4b-46ce-a954-b3ccc0a4acf7) successfully added.
Connection 'team0-port4' (ac2c72af-ce7f-4d2a-a039-074cb1c20053) successfully added.
```

Verify all config files:

```bash
ll /etc/NetworkManager/system-connections/
```

**Output:**
```
total 24
-rw-------. 1 root root 229 Mar 17 07:59 ens160.nmconnection
-rw-------. 1 root root 178 Apr 16 08:07 team0.nmconnection
-rw-------. 1 root root 160 Apr 16 08:09 team0-port1.nmconnection
-rw-------. 1 root root 160 Apr 16 08:10 team0-port2.nmconnection
-rw-------. 1 root root 160 Apr 16 08:10 team0-port3.nmconnection
-rw-------. 1 root root 160 Apr 16 08:10 team0-port4.nmconnection
```

---

### 3. Bring team0 Up & Test Connectivity

```bash
nmcli connection up team0
```

**Output:**
```
Connection successfully activated (controller waiting for ports)
```

Bring up all ports:

```bash
nmcli connection up team0-port1
nmcli connection up team0-port2
nmcli connection up team0-port3
nmcli connection up team0-port4
```

#### Optional: Switch from ens160 to team0

To test team0 is fully working independently:

```bash
# Bring down the original management interface
nmcli connection down ens160

# Bring up team0 (should get DHCP IP)
nmcli connection up team0
```

Test internet connectivity:

```bash
ping google.com
```

**Expected Output:**
```
PING google.com (142.250.x.x) 56(84) bytes of data.
64 bytes from 142.250.x.x: icmp_seq=1 ttl=57 time=3.2 ms
64 bytes from 142.250.x.x: icmp_seq=2 ttl=57 time=2.9 ms
^C
--- google.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss
```

✅ **Ping to google.com works through team0!**

Check IP assignment:

```bash
ip a show team0
```

**Expected Output:**
```
8: team0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 ...
    inet 192.168.x.x/24 brd 192.168.x.255 scope global dynamic team0
```

Check teamd status:

```bash
teamdctl team0 state
```

**Expected Output:**
```json
{
  "setup": {
    "runner_name": "activebackup"
  },
  "ports": {
    "ens161": { "link": { "up": true } },
    "ens193": { "link": { "up": true } },
    "ens224": { "link": { "up": true } },
    "ens256": { "link": { "up": true } }
  },
  "runner": {
    "active_port": "ens161"
  }
}
```

SSH test from admin PC:

```bash
ssh root@<team0-ip>
```

---

## 📊 Concept Summary

### Bonding vs Teaming

```
┌─────────────────────────────────────────────────────────────┐
│                     BONDING (bond0)                         │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│  │ ens161 │  │ ens193 │  │ ens224 │  │ ens256 │  (slaves) │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘           │
│      └───────────┴───────────┴───────────┘                 │
│                         ▼                                   │
│               ┌──────────────────┐                         │
│               │  bond0 (MASTER)  │  192.168.102.100/24     │
│               │   mode=balance-rr│                         │
│               └──────────────────┘                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     TEAMING (team0)                         │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│  │ ens161 │  │ ens193 │  │ ens224 │  │ ens256 │  (ports)  │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘           │
│      └───────────┴───────────┴───────────┘                 │
│                         ▼                                   │
│               ┌──────────────────┐                         │
│               │  team0 (MASTER)  │  DHCP IP                │
│               │ runner=activebackup                        │
│               └──────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Quick Reference Cheatsheet

### 🔗 Bonding Commands

```bash
# Create bond master with static IP
nmcli con add con-name bond0 type bond ifname bond0 mode balance-rr \
  ipv4.method manual ipv4.addresses 192.168.102.100/24 \
  ipv4.gateway 192.168.102.2 ipv4.dns 8.8.8.8 ipv6.method disabled

# Add slave
nmcli con add con-name bond0-port1 type ethernet slave-type bond master bond0 ifname ens161

# Activate
nmcli con up bond0

# Status
cat /proc/net/bonding/bond0

# Delete all
nmcli con down bond0
nmcli con delete bond0 bond0-port1 bond0-port2 bond0-port3 bond0-port4
```

### 🤝 Teaming Commands

```bash
# Create team master with DHCP
nmcli con add con-name team0 type team ifname team0 \
  ipv4.method auto ipv6.method disabled

# Add port
nmcli con add type ethernet ifname ens161 con-name team0-port1 slave-type team master team0

# Activate
nmcli con up team0

# Status
teamdctl team0 state

# Delete all
nmcli con down team0
nmcli con delete team0 team0-port1 team0-port2 team0-port3 team0-port4
```

### 🔍 Verification Commands

```bash
nmcli dev status          # Show all device states
nmcli con show            # List all connections
ip a                      # Show IP addresses
ip r                      # Show routing table
ping <ip>                 # Test connectivity
ssh root@<ip>             # Test SSH
who                       # See logged-in users
```

---

## ⚠️ Common Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| `bond0` shows "controller waiting for ports" | Slaves not up yet | Run `nmcli con up bond0-port1` etc. |
| SSH permission denied | Root SSH disabled by default | Use correct password or enable `PermitRootLogin` in `/etc/ssh/sshd_config` |
| `ping google.com` fails on team0 | ens160 still has the default route | Run `nmcli con down ens160` first |
| Team/bond gets no IP | DHCP server not reachable on NAT network | Switch to static IP or check VMware NAT settings |
| Routes missing after delete | Normal — bond/team routes auto-removed | Verify with `ip r` — ens160 route should remain |

---

