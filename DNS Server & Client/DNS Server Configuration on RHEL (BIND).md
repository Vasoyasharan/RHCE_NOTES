# 🌐 DNS Server Configuration on RHEL (BIND) — Complete Guide

> **Environment:** Red Hat Enterprise Linux 9 | **DNS Server IP:** `192.168.102.140` | **Domain:** `iforward.in`

---

## 🖥️ Network Overview

| Role       | Hostname              | IP Address         |
| ---------- | --------------------- | ------------------ |
| DNS Server | `server.iforward.in`  | `192.168.102.140`  |
| Client     | `client1.iforward.in` | `192.168.102.142`  |
| Gateway    | —                     | `192.168.102.2`    |
| Subnet     | —                     | `192.168.102.0/24` |
| Domain     | —                     | `iforward.in`      |

> 💡 **Network Adapter changed from Bridge → NAT** so that the VM uses the `192.168.102.x` range.

---

## 📦 Step 1 — Install BIND Packages

BIND (Berkeley Internet Name Domain) is the DNS server software. You need two packages:

| Package      | Purpose                                        |
| ------------ | ---------------------------------------------- |
| `bind`       | The actual DNS server daemon (`named`)         |
| `bind-utils` | DNS query tools like `nslookup`, `dig`, `host` |
|              |                                                |

```bash
# Install both at once
[root@server ~]# dnf install bind bind-utils -y
```

**Expected output (from your lab):**

```
Repository BaseOs-local is listed more than once in the configuration
Last metadata expiration check: 0:02:21 ago on Friday 24 April 2026 07:39:32 AM.
Dependencies resolved.
================================================================================
 Package               Architecture  Version                Repository    Size
================================================================================
Installing:
 bind                  x86_64        32:9.16.23-31.el9_6    Appstream-local  502 k
Installing dependencies:
 bind9.18-libs         x86_64        32:9.18.29-4.el9_6     Appstream-local  1.3 M
Installing weak dependencies:
 bind9.18-dnssec-utils x86_64        32:9.18.29-4.el9_6     Appstream-local  147 k

Transaction Summary
================================================================================
Install  3 Packages
Total size: 1.9 M
Installed size: 5.4 M
Is this ok [y/N]: y
...
Complete!
```

> ✅ `bind-utils` was already installed in the lab — that's why `dnf install bind-utils*` showed **"Nothing to do."**

---

## ▶️ Step 2 — Start & Verify named Service

The DNS daemon is called **`named`**. By default it is **disabled and inactive** after install.

```bash
# Check current status (will show inactive/dead initially)
[root@server ~]# systemctl status named
```

```
○ named.service - Berkeley Internet Name Domain (DNS)
     Loaded: loaded (/usr/lib/systemd/system/named.service; disabled; preset: disabled)
     Active: inactive (dead)
```

```bash
# Start the service
[root@server ~]# systemctl start named

# Verify it is now running
[root@server ~]# systemctl status named
```

```
● named.service - Berkeley Internet Name Domain (DNS)
     Loaded: loaded (/usr/lib/systemd/system/named.service; disabled; preset: disabled)
     Active: active (running) since Fri 2026-04-24 07:43:45 IST; 1s ago
...
Apr 24 07:43:45 server.iforward.in named[33504]: all zones loaded
Apr 24 07:43:45 server.iforward.in named[33504]: running
```

```bash
# Enable named to auto-start on boot
[root@server ~]# systemctl enable named
```

> 💡 **Why `disabled` even after start?** Starting a service ≠ enabling it. `start` runs it now; `enable` makes it survive reboots.

---

## 💾 Step 3 — Backup named.conf

Always back up the main config before editing!

```bash
[root@server ~]# cp /etc/named.conf /root/named.conf

# Confirm backup exists
[root@server ~]# ll /root/
```

```
-rw-r--r--  1 root root   1xxx Apr 24 07:4x named.conf
```

> 🛡️ If you break `/etc/named.conf`, just run `cp /root/named.conf /etc/named.conf` to restore.

---

## 🔌 Step 4 — Configure Network (NAT + Static IP)

The network adapter was changed from **Bridge → NAT** so the VM gets the `192.168.102.x` subnet.

```bash
# Add a new static connection on ens160
[root@server ~]# nmcli con add \
  con-name ens160-static \
  type ethernet \
  ifname ens160 \
  ipv4.method manual \
  ipv4.addresses 192.168.102.140/24 \
  ipv4.gateway 192.168.102.2 \
  ipv4.dns 192.168.102.140 \
  ipv6.method disabled \
  connection.autoconnect yes

# Bring the new connection up
[root@server ~]# nmcli con up ens160-static

# Verify
[root@server ~]# ip a show ens160
```

```
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP>
    inet 192.168.102.140/24 brd 192.168.102.255 scope global ens160-static
```

> 🔑 Key options explained:
> 
> - `ipv4.method manual` — static IP (not DHCP)
> - `ipv6.method disabled` — turns off IPv6
> - `ipv4.dns 192.168.102.140` — the server points to **itself** as DNS

---

## ⚙️ Step 5 — Edit /etc/named.conf

This is the **main configuration file** for BIND. Two lines need changing:

```bash
[root@server ~]# nano /etc/named.conf
```

Find and change these two lines:

```diff
- listen-on port 53 { 127.0.0.1; };
+ listen-on port 53 { 127.0.0.1; 192.168.102.140; };

- allow-query     { localhost; };
+ allow-query     { localhost; 192.168.102.0/24; };
```

**What these mean:**

|Directive|Meaning|
|---|---|
|`listen-on`|Which IP addresses BIND listens on. Add the server's own IP so clients can reach it.|
|`allow-query`|Which hosts are allowed to query this DNS. The `/24` means the whole subnet.|

> 💡 The file also includes `include "/etc/named.rfc1912.zones";` near the bottom — that line pulls in our zone definitions (next step).

---

## 📝 Step 6 — Create Zone Entries in named.rfc1912.zones

This file tells BIND which **zones** (domains) it is authoritative for and which zone **files** hold the records.

```bash
[root@server ~]# nano /etc/named.rfc1912.zones
```

**Add these two zone blocks at the bottom** (as seen in Image 1):

```bind
# Forward Lookup Zone — domain name → IP
zone "iforward.in" IN {
    type master;
    file "dns.flz";
    allow-update { none; };
};

# Reverse Lookup Zone — IP → domain name
zone "102.168.192.in-addr.arpa" IN {
    type master;
    file "dns.rlz";
    allow-update { none; };
};
```

> 🔍 **Zone name anatomy for reverse:**
> 
> - Subnet is `192.168.102.x`
> - Reverse zone = write the **first 3 octets backwards** + `.in-addr.arpa`
> - `192.168.102` → `102.168.192.in-addr.arpa` ✅

|Field|Value|Purpose|
|---|---|---|
|`type master`|Primary/authoritative|This server owns this zone|
|`file "dns.flz"`|Zone file name|Stored in `/var/named/`|
|`allow-update { none; }`|No dynamic updates|Static zone, no DHCP writes|

---

## 📄 Step 7 — Create Zone Files (Forward & Reverse)

Zone files live in `/var/named/`. We copy `named.localhost` as a starting template (as seen in Image 2).

```bash
[root@server named]# cd /var/named/

# Copy template for both zone files
[root@server named]# cp named.localhost dns.flz
[root@server named]# cp named.localhost dns.rlz

# Confirm files exist
[root@server named]# ll
```

```
total 36
drwxrwx---. 2 named named 4096 Apr 24 07:43 data
-rw-r-----. 1 root  root   245 Apr 24 08:16 dns.flz   ← forward zone file
-rw-r-----. 1 root  root   264 Apr 24 08:25 dns.rlz   ← reverse zone file
drwxrwx---. 2 named named 4096 Apr 24 07:44 dynamic
-rw-r-----. 1 root  named 2112 Jul 10  2025 named.ca
-rw-r-----. 1 root  named  152 Jul 10  2025 named.empty
-rw-r-----. 1 root  named  152 Jul 10  2025 named.localhost
-rw-r-----. 1 root  named  168 Jul 10  2025 named.loopback
drwxrwx---. 2 named named 4096 Jul 10  2025 slaves
```

---

### ✏️ Edit the Forward Zone File (dns.flz)

```bash
[root@server named]# nano dns.flz
```

```bind
$TTL 86400
@   IN  SOA  ns1.iforward.in.  root.iforward.in. (
                2026042401  ; Serial (YYYYMMDDnn format)
                3600        ; Refresh — slave checks for updates every 1 hour
                1800        ; Retry — slave retries after 30 min on failure
                604800      ; Expire — slave gives up after 1 week
                86400 )     ; Minimum TTL — negative cache = 1 day

; Name Servers
        IN  NS      server.iforward.in.

; A Records (hostname → IP)

server  IN  A       192.168.102.140
client1 IN  A       192.168.102.142
```

> 📌 **Key records explained:**
> 
> - `SOA` — Start of Authority: who owns this zone and timing parameters
> - `NS` — Name Server record: which server is authoritative
> - `A` — Address record: maps hostname to IPv4 address
> - The trailing **dot** (`.`) on FQDNs like `ns1.iforward.in.` is **critical** — without it BIND appends the domain name again!

---

### ✏️ Edit the Reverse Zone File (dns.rlz)

```bash
[root@server named]# nano dns.rlz
```

```bind
$TTL 86400
@   IN  SOA  ns1.iforward.in.  root.iforward.in. (
                2026042401  ; Serial
                3600        ; Refresh
                1800        ; Retry
                604800      ; Expire
                86400 )     ; Minimum TTL

; Name Servers
@       IN  NS      ns1.iforward.in.

; PTR Records (last octet of IP → FQDN)
140     IN  PTR     server.iforward.in.
142     IN  PTR     client1.iforward.in.
```

> 📌 **PTR record logic:**
> 
> - Zone is `102.168.192.in-addr.arpa` (covers `192.168.102.x`)
> - For `192.168.102.140` → just put the last octet `140` as the name
> - BIND combines it: `140.102.168.192.in-addr.arpa` → `server.iforward.in.`

---

## 🔐 Step 8 — Set Permissions on Zone Files

BIND runs as the `named` user. Zone files owned by `root` with group `root` won't be readable by BIND!

```bash
# Change group ownership to 'named'
[root@server named]# chgrp named dns.flz
[root@server named]# chgrp named dns.rlz

# Verify permissions
[root@server named]# ll
```

```
-rw-r-----. 1 root  named  245 Apr 24 08:16 dns.flz   ← group is now named ✅
-rw-r-----. 1 root  named  264 Apr 24 08:25 dns.rlz   ← group is now named ✅
```

> ⚠️ If you skip this step, `named` will fail to load the zones and you'll see **permission denied** errors in the logs.

---

## ✅ Step 9 — Validate Configuration

Before restarting the service, always check for syntax errors!

```bash
# Check named.conf syntax
[root@server ~]# named-checkconf
# (no output = no errors ✅)

# Check forward zone file
[root@server ~]# named-checkzone iforward.in /var/named/dns.flz
```

```
zone iforward.in/IN: loaded serial 2026042401
OK
```

```bash
# Check reverse zone file
[root@server ~]# named-checkzone 102.168.192.in-addr.arpa /var/named/dns.rlz
```

```
zone 102.168.192.in-addr.arpa/IN: loaded serial 2026042401
OK
```

> 🚨 **Common errors to watch for:**
> 
> - `missing '.' at end of name` — forgot trailing dot on FQDN
> - `not at top of zone` — SOA record indentation issue
> - `serial number must be ≤ XXXXXXXX` — serial not incremented

---

## 🔥 Step 10 — Firewall & Restart

```bash
# Allow DNS through the firewall (port 53 UDP/TCP)
[root@server ~]# firewall-cmd --add-service=dns --permanent
[root@server ~]# firewall-cmd --reload

# Restart named to apply all config changes
[root@server ~]# systemctl restart named

# Enable on boot
[root@server ~]# systemctl enable named

# Final status check
[root@server ~]# systemctl status named
```

```
● named.service - Berkeley Internet Name Domain (DNS)
     Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; preset: disabled)
     Active: active (running)
...
Apr 24 xx:xx:xx server.iforward.in named[xxxxx]: zone iforward.in/IN: loaded serial 2026042401
Apr 24 xx:xx:xx server.iforward.in named[xxxxx]: zone 102.168.192.in-addr.arpa/IN: loaded serial 2026042401
Apr 24 xx:xx:xx server.iforward.in named[xxxxx]: all zones loaded
Apr 24 xx:xx:xx server.iforward.in named[xxxxx]: running
```

---

### 🧪 Test DNS Resolution

```bash
# From the DNS server itself — forward lookup
[root@server ~]# nslookup server.iforward.in
```

```
Server:         192.168.102.140
Address:        192.168.102.140#53

Name:   server.iforward.in
Address: 192.168.102.140
```

```bash
# Reverse lookup
[root@server ~]# nslookup 192.168.102.140
```

```
140.102.168.192.in-addr.arpa    name = server.iforward.in.
```

```bash
# From the client machine — point it to our DNS server first
[root@client1 ~]# nmcli con mod ens160 ipv4.dns 192.168.102.140
[root@client1 ~]# nmcli con up ens160
[root@client1 ~]# nslookup client1.iforward.in
```

---

## 📌 Quick Reference Cheatsheet

```
┌─────────────────────────────────────────────────────────────┐
│               DNS BIND Quick Reference                      │
├─────────────────────┬───────────────────────────────────────┤
│ Install             │ dnf install bind bind-utils -y        │
│ Start service       │ systemctl start named                 │
│ Enable on boot      │ systemctl enable named                │
│ Main config         │ /etc/named.conf                       │
│ Zone declarations   │ /etc/named.rfc1912.zones              │
│ Zone files dir      │ /var/named/                           │
│ Forward zone file   │ /var/named/dns.flz                    │
│ Reverse zone file   │ /var/named/dns.rlz                    │
│ Check conf syntax   │ named-checkconf                       │
│ Check zone syntax   │ named-checkzone <zone> <file>         │
│ Open firewall       │ firewall-cmd --add-service=dns --perm │
│ Reload firewall     │ firewall-cmd --reload                 │
│ View logs           │ journalctl -u named -n 50             │
└─────────────────────┴───────────────────────────────────────┘
```

---

## 🗂️ File Structure Summary

```
/etc/
├── named.conf                    ← Main BIND config (listen IP, allow-query)
└── named.rfc1912.zones           ← Zone declarations (which domains this server owns)

/var/named/
├── dns.flz                       ← Forward zone: hostname → IP (A records)
├── dns.rlz                       ← Reverse zone: IP → hostname (PTR records)
├── named.localhost               ← Template file (used as base for zone files)
└── named.loopback                ← Loopback zone
```

---

## 🧠 Concept Map

```
Client Query: "What is the IP of client1.iforward.in?"
         │
         ▼
   DNS Server (192.168.102.140)
         │
         ├─→ Checks /etc/named.conf  ──→  allowed? yes (192.168.102.0/24)
         │
         ├─→ Checks named.rfc1912.zones ──→ zone "iforward.in" → file "dns.flz"
         │
         └─→ Reads /var/named/dns.flz ──→ client1 IN A 192.168.102.142
                                                │
                                                ▼
                                    Returns: 192.168.102.142 ✅
```

---

_Guide created based on lab session — RHEL 9, BIND 9.16, April 2026_