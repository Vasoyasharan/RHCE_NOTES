## 7. 🦑 Squid Proxy Server

### 💡 What is a Proxy Server?

```
WITHOUT PROXY:
Client ──────────────────────────► Internet (direct)
Each client exposes their own IP

WITH PROXY:
Client ──► Proxy Server ──────────► Internet
          (192.168.102.140)
All clients share ONE IP on the internet!
```

**Why use a proxy?**

| Reason | Benefit |
|---|---|
| 🌐 Internet Sharing | One IP for the whole office |
| 🚫 Website Blocking | Block YouTube, Facebook, etc. |
| ⚡ Caching | Faster access to frequently visited sites |
| 🔒 Security | Hides internal network from internet |
| 📊 Logging | See exactly which websites users visit |

---

### ⚙️ Squid Profile

| Property | Value |
|---|---|
| 📦 **Package** | `squid` |
| 🔌 **Default Port** | `3128` |
| 📄 **Config File** | `/etc/squid/squid.conf` |
| ⚙️ **Daemon** | `squid` |

**Verify squid is listening:**
```bash
[root@server ~]# ss -tpnl | grep 3128
LISTEN  0  4096  *:3128  *:*  users:(("squid",pid=5804,fd=11))
```
This confirms Squid is running and listening on port 3128 ✅

---

### 🛠️ Step-by-Step Squid Configuration

#### Step 1️⃣ — Install Squid

```bash
[root@server ~]# yum install squid* -y
```

**Sample Output:**
```
Installing:
 squid    x86_64  7:5.5-18.el9   appstream   3.9 M
Installing dependencies:
 libecap  x86_64  1.0.1-10.el9   appstream   28 k
...
Install 4 Packages
```

---

#### Step 2️⃣ — Edit Squid Config

```bash
[root@server ~]# nano /etc/squid/squid.conf
```

Scroll down to the section that says `# INSERT YOUR OWN RULE(S) HERE` and add:

```squid
# Allow access from your local network
acl mynet src 192.168.102.0/24
http_access allow mynet
```

**Full relevant section from Image 7:**
```squid
acl Safe_ports port 80         # http
acl Safe_ports port 21         # ftp
acl Safe_ports port 443        # https
acl Safe_ports port 70         # gopher

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager

# YOUR RULES START HERE:
acl mynet src 192.168.102.0/24
http_access allow mynet

http_access allow localnet
http_access allow localhost
```

---

#### Step 3️⃣ — Start and Enable Squid

```bash
[root@server ~]# systemctl enable --now squid
Created symlink /etc/systemd/system/multi-user.target.wants/squid.service
→ /usr/lib/systemd/system/squid.service
```

---

#### Step 4️⃣ — Allow Squid in Firewall

```bash
[root@server ~]# firewall-cmd --permanent --add-service=squid --zone=public
success
[root@server ~]# firewall-cmd --reload
success
[root@server ~]# firewall-cmd --list-all
  services: cockpit dhcpv6-client dns http https mountd nfs rpc-bind samba squid ssh
  ports: 80/tcp 8080/tcp
```

---

#### Step 5️⃣ — Configure Client Browser (Firefox)

On the **CLIENT machine** (not the server):

1. Open Firefox → Settings → General → Scroll to bottom → **Network Settings** → Click **Settings...**
2. Select **Manual proxy configuration**
3. Fill in:
   - HTTP Proxy: `192.168.102.140` (your proxy server IP)
   - Port: `3128`
   - ✅ Check "Also use this proxy for HTTPS"
4. Click **OK**

**From Image 9:** The Firefox Connection Settings dialog showing proxy IP `192.168.102.140` and port `3128` configured correctly.

---

#### Step 6️⃣ — Check Squid Access Logs

```bash
# Watch live access log
[root@server ~]# tail -f /var/log/squid/access.log

# Search for specific site traffic
[root@server ~]# cat /var/log/squid/access.log | grep server
1777517819.571  67 192.168.102.142 TCP_MISS/304 379 GET http://server.iforward.in/ - HIER_DIRECT/192.168.102.140 -
```

**Log format explained:**
```
1777517819.571    = Timestamp
67                = Response time (ms)
192.168.102.142   = Client IP (who made the request)
TCP_MISS/304      = Cache result / HTTP status
GET               = Request method
http://server...  = URL accessed
HIER_DIRECT/...   = How squid got the content
```

---

## 8. 🚫 Blocking Websites via Squid

### Method 1: Block a Single Site (Direct in squid.conf)

```bash
[root@server ~]# nano /etc/squid/squid.conf
```

Add **before** the `acl mynet` line:
```squid
acl blockurl url_regex server.iforward.in
http_access deny blockurl

acl mynet src 192.168.102.0/24
http_access allow mynet
```

```bash
[root@server ~]# systemctl restart squid.service
```

**Test:** Client tries to access `server.iforward.in` → Gets **403 Forbidden** error ✅

**From Image 13:** The browser shows "The proxy server is refusing connections — Error code: 403 Forbidden" — the block is working!

---

### Method 2: Block Multiple Sites Using an External File

**Step 1:** Create a block list file:
```bash
[root@server ~]# nano /etc/squid/blocklist
```

Add one site per line:
```
hotmail
youtube
facebook
twitter
yahoo
```

**Step 2:** Reference the file in squid.conf:
```squid
# Block sites listed in file
acl block url_regex "/etc/squid/blocklist"
http_access deny block

acl mynet src 192.168.102.0/24
http_access allow mynet
```

**Step 3:** Reload Squid:
```bash
[root@server ~]# systemctl reload squid.service
```

**Test:** Visit youtube.com → Gets Squid ERROR page: "Access Denied" ✅

---

### 📋 Advanced ACL Options Reference

```squid
############################################################
# PART 1: BASIC SETTINGS
############################################################
http_port 3128

############################################################
# PART 2: CLIENT ACCESS CONTROL (IP BASED)
############################################################
# Allow entire subnet
acl localnet src 192.168.10.0/24

# Allow specific IP only
acl allowed_ip src 192.168.10.142

# Block a specific client IP
acl blocked_ip src 192.168.10.10

############################################################
# PART 3: WEBSITE / DOMAIN CONTROL
############################################################
# Block specific domain
acl blocked_sites dstdomain .facebook.com
http_access deny blocked_sites

# Allow only specific sites (whitelist)
acl allowed_sites dstdomain .google.com .github.com
http_access allow allowed_sites
http_access deny all

############################################################
# PART 4: FILE TYPE FILTERING
############################################################
# Block download of video/exe/zip files
acl block_ext urlpath_regex \.mp4$ \.exe$ \.zip$
http_access deny block_ext

############################################################
# PART 5: TIME-BASED ACCESS
############################################################
# Only allow internet during office hours Mon-Fri 9AM-6PM
acl office_hours time MTWHF 09:00-18:00
http_access allow localnet office_hours
http_access deny localnet   # deny outside office hours

############################################################
# PART 6: CACHE SETTINGS (PERFORMANCE)
############################################################
cache_mem 256 MB
maximum_object_size 50 MB
minimum_object_size 0 KB

############################################################
# PART 7: DISK CACHE
############################################################
cache_dir ufs /var/spool/squid 1000 16 256

############################################################
# PART 8: LOGGING
############################################################
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

############################################################
# PART 9: SECURITY HARDENING
############################################################
visible_hostname squid-server
via off
forwarded_for delete
```

---

## 9. 🏢 Group Policy / Proxy Restriction

### 🎯 Goal: Prevent users from changing proxy settings in Firefox

In enterprise environments, you don't want users to bypass the proxy by changing Firefox settings. Here are methods to lock it down:

---

### Method 1: Firefox AutoConfig / Managed Policy (RHEL/Linux)

**Step 1:** Create Firefox policies directory:
```bash
[root@server ~]# mkdir -p /usr/lib64/firefox/distribution/
[root@server ~]# nano /usr/lib64/firefox/distribution/policies.json
```

**Step 2:** Add this content to lock proxy settings:
```json
{
  "policies": {
    "Proxy": {
      "Mode": "manual",
      "HTTPProxy": "192.168.102.140:3128",
      "UseHTTPProxyForAllProtocols": true,
      "Locked": true
    },
    "DisablePrivateBrowsing": true,
    "BlockAboutConfig": true,
    "BlockAboutProfiles": true
  }
}
```

**What each policy does:**

| Policy | Effect |
|---|---|
| `Proxy → Mode: manual` | Forces manual proxy mode |
| `HTTPProxy` | Sets the proxy to your server |
| `Locked: true` | 🔒 Greys out the proxy settings — user CANNOT change it! |
| `DisablePrivateBrowsing` | Prevents incognito mode (which might bypass proxy) |
| `BlockAboutConfig` | Blocks `about:config` so user can't edit advanced settings |

---

### Method 2: Squid + Transparent Proxy (Force ALL traffic through proxy)

With transparent proxying, clients don't even need to configure anything — all traffic is automatically intercepted.

```bash
# In squid.conf, add:
http_port 3128 transparent
```

```bash
# On the GATEWAY/ROUTER, add iptables rules:
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 \
  -j REDIRECT --to-port 3128
```

> 🧠 **This is what corporate networks do!** Every website you visit goes through the proxy without you even knowing, giving IT full visibility and control.

---

### Method 3: LDAP + Squid Authentication (Active Directory Integration)

For AD/LDAP-based access control in Squid:

```squid
# Add LDAP authentication helper
auth_param basic program /usr/lib64/squid/basic_ldap_auth \
  -b "DC=company,DC=com" \
  -D "CN=squid_service,OU=ServiceAccounts,DC=company,DC=com" \
  -w "ServiceAccountPassword" \
  -f "sAMAccountName=%s" \
  -h 192.168.1.10

# Require authentication
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
```

This means:
- Users must log in with their Windows/AD credentials to use the internet
- Different AD groups can be given different access levels
- All activity is logged per-username, not just per-IP

---

### 🦑 Squid Commands

```bash
# Install
yum install squid* -y

# Start / Enable
systemctl enable --now squid
systemctl restart squid.service
systemctl reload squid.service    # Preferred — no interruption

# Check if running
ss -tpnl | grep 3128
systemctl status squid

# View logs
tail -f /var/log/squid/access.log
cat /var/log/squid/access.log | grep <sitename>

# Firewall
firewall-cmd --permanent --add-service=squid --zone=public
firewall-cmd --reload
```

---
