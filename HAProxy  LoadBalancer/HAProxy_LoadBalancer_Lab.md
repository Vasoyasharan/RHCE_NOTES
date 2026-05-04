# 🔄 HAProxy Load Balancer Lab — Complete Step-by-Step Guide
### 🖥️ RHEL Lab Setup | Real-World Proxy & Load Balancing

---

## 🏗️ Lab Architecture Overview

```
                        ┌───────────────────────┐
                        │   NON_DNS_Client (NDC) │
                        │   192.168.102.120      │
                        │   (Client Machine)     │
                        └──────────┬────────────┘
                                   │ HTTP Request
                                   ▼
                        ┌───────────────────────┐
                        │    Proxy Server (PS)   │
                        │    192.168.102.110     │
                        │    HAProxy (Port 80)   │
                        │    Load Balancer (LB)  │
                        └──────┬──────────┬─────┘
                               │          │ Round Robin
                  ┌────────────┘          └────────────┐
                  ▼                                     ▼
     ┌────────────────────┐              ┌─────────────────────┐
     │   REDHAT (app1)    │              │   Clone1 (app2)      │
     │   192.168.102.140  │              │   192.168.102.142    │
     │   Web Server :80   │              │   Web Server :80     │
     └────────────────────┘              └─────────────────────┘
```

---

## 📚 What is HAProxy? — Definition

> **HAProxy** (High Availability Proxy) is a **free, open-source, reliable, high-performance TCP/HTTP load balancer and proxy server**.

It distributes incoming network traffic across multiple backend servers so that no single server gets overwhelmed. Think of it like a **traffic cop** standing at the door of a restaurant — it tells each new customer which waiter (server) to go to, so no one waiter is overloaded.

### 🔑 Key Terms

| Term              | Definition                                                       |
| ----------------- | ---------------------------------------------------------------- |
| **Frontend**      | The entry point — where HAProxy listens for incoming connections |
| **Backend**       | The pool of real servers that handle the requests                |
| **Load Balancer** | Distributes traffic across multiple servers                      |
| **Round Robin**   | Sends requests to servers one by one in rotation (1→2→1→2...)    |
| **Proxy**         | Acts as an intermediary between client and server                |
| **Health Check**  | HAProxy pings backend servers to confirm they're alive           |

---

## 🌍 Real-World Use Cases

| Scenario | How HAProxy Helps |
|----------|------------------|
| **E-commerce websites** (Amazon, Flipkart) | Distributes millions of user requests across hundreds of servers |
| **Banking apps** | Ensures high availability — if one server fails, others take over |
| **Netflix / YouTube streaming** | Routes users to nearest/least-loaded server for smooth video |
| **Hospital systems** | Zero downtime — if one server crashes, patients' data is still accessible |
| **Government portals** | Handles peak load during elections, tax filing seasons |
| **Microservices architecture** | Routes API requests to appropriate backend service |

---

## 🗺️ Network Topology

| VM Name | Role | IP Address | Port |
|---------|------|-----------|------|
| **NON_DNS_Client (NDC)** | Client (sends requests) | `192.168.102.120` | — |
| **Proxy Server (PS)** | Load Balancer (HAProxy) | `192.168.102.110` | `80` |
| **REDHAT** | Web Server 1 (app1) | `192.168.102.140` | `80` |
| **Clone1** | Web Server 2 (app2) | `192.168.102.142` | `80` |

---

## 🛠️ Lab Setup — Step by Step

---

### 🔴 STEP 1 — Install Apache Web Server on REDHAT (192.168.102.140)

> ⚠️ **Do this on: REDHAT VM**

```bash
# Install Apache
dnf install httpd -y

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a custom web page so we can identify this server
echo "<h1>Welcome from REDHAT - Server 1 (192.168.102.140)</h1>" > /var/www/html/index.html

# Open firewall for HTTP
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

**Expected Output:**
```
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service
```

**Why?** The client will send HTTP requests. Apache serves those requests on port 80. We add a unique message so we know *which* server responded.

---

### 🟡 STEP 2 — Install Apache Web Server on Clone1 (192.168.102.142)

> ⚠️ **Do this on: Clone1 VM**

```bash
# Install Apache
dnf install httpd -y

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a custom web page to identify this server
echo "<h1>Welcome from Clone1 - Server 2 (192.168.102.142)</h1>" > /var/www/html/index.html

# Open firewall for HTTP
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

**Why?** Same as REDHAT, but this is our second backend server. The different message helps us verify that HAProxy is actually load-balancing (alternating between servers).

---

### 🟢 STEP 3 — Install HAProxy on Proxy Server (192.168.102.110)

> ⚠️ **Do this on: Proxy Server (PS) VM**

```bash
# Install HAProxy
dnf install haproxy -y

# Verify installation
haproxy -v
```

**Expected Output:**
```
HAProxy version 2.4.x
```

---

### ⚙️ STEP 4 — Configure HAProxy (THE MAIN STEP)

> ⚠️ **Do this on: Proxy Server (PS) VM**

```bash
# Open the config file
vi /etc/haproxy/haproxy.cfg
```

#### ❓ Your Question: "Can I delete everything and replace?"

**YES! ✅** You can delete all content and replace it. Here's the complete config:

```bash
# First, backup the original file (good practice!)
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

# Now open and clear the file
> /etc/haproxy/haproxy.cfg

# Then open vi and paste the config
vi /etc/haproxy/haproxy.cfg
```

#### 📄 Complete haproxy.cfg Content (type/paste this):

```
global
    daemon
    maxconn 256

defaults
    mode http
    timeout connect 10s
    timeout client 10s
    timeout server 10s

# my own Proxy server
frontend lb
    bind *:80
    default_backend webservers

backend webservers
    balance roundrobin
    server app1 192.168.102.140:80 check
    server app2 192.168.102.142:80 check
```

**Save in vi:** Press `Esc`, then type `:wq` and press `Enter`

---

## 📝 haproxy.cfg — Full Explanation

Let's break down **every single line**:

### 🔷 `global` Section
```
global
    daemon        ← Run HAProxy as a background process (like a service)
    maxconn 256   ← Allow maximum 256 simultaneous connections
```
> **Why?** Global settings apply to the entire HAProxy process. `daemon` makes it run as a system service. `maxconn` prevents server overload.

---

### 🔷 `defaults` Section
```
defaults
    mode http           ← Work in HTTP mode (Layer 7 — understands web traffic)
    timeout connect 10s ← Wait max 10 seconds to connect to backend
    timeout client 10s  ← Wait max 10 seconds for client to send data
    timeout server 10s  ← Wait max 10 seconds for backend server to respond
```
> **Why?** These apply to all frontends and backends unless overridden. Timeouts prevent "hanging" connections from wasting resources.

---

### 🔷 `frontend lb` Section
```
frontend lb          ← Name this frontend "lb" (load balancer)
    bind *:80        ← Listen on ALL interfaces, port 80 (*)=any IP
    default_backend webservers  ← Send traffic to "webservers" backend
```
> **Why?** The frontend is the "door" — it accepts connections from clients. `bind *:80` means: "Accept connections from anyone on port 80." `default_backend` tells HAProxy where to forward the traffic.

**Real-world analogy:** The frontend is like a hotel receptionist. Anyone who walks in (port 80) gets directed to a room (backend server).

---

### 🔷 `backend webservers` Section
```
backend webservers              ← Name this backend pool "webservers"
    balance roundrobin          ← Use Round Robin algorithm
    server app1 192.168.102.140:80 check  ← Server 1: REDHAT, check if alive
    server app2 192.168.102.142:80 check  ← Server 2: Clone1, check if alive
```

> **Why `check`?** The `check` keyword tells HAProxy to do **health checks** — it periodically sends a request to each server. If a server is down, HAProxy stops sending traffic to it automatically. When it comes back up, HAProxy resumes sending traffic. This is the "High Availability" part!

**Round Robin explained:**
```
Request 1  → app1 (REDHAT 192.168.102.140)
Request 2  → app2 (Clone1  192.168.102.142)
Request 3  → app1 (REDHAT 192.168.102.140)
Request 4  → app2 (Clone1  192.168.102.142)
... and so on
```

---

### STEP 5 — Start & Enable HAProxy

> ⚠️ **Do this on: Proxy Server (PS) VM**

```bash
# Start HAProxy
systemctl start haproxy

# Enable it to start on boot
systemctl enable haproxy

# Check status
systemctl status haproxy
```

**Expected Output:**
```
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled)
   Active: active (running) since Sun 2025-05-03 09:56:53 IST
```

```bash
# Allow port 80 through firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Verify HAProxy is listening on port 80
ss -tlnp | grep 80
```

**Expected Output:**
```
LISTEN  0  128  0.0.0.0:80  0.0.0.0:*  users:(("haproxy",pid=1234,fd=5))
```

---

## ✅ Testing & Verification

---

### 🔵 STEP 6 — Test from NON_DNS_Client (192.168.102.120)

> ⚠️ **Do this on: NON_DNS_Client (NDC) VM**

```bash
# Send request to Load Balancer (NOT directly to web servers)
curl http://192.168.102.110

# Run multiple times to see Round Robin in action
curl http://192.168.102.110
curl http://192.168.102.110
curl http://192.168.102.110
curl http://192.168.102.110
```

**Expected Output (alternating!):**
```
<h1>Welcome from REDHAT - Server 1 (192.168.102.140)</h1>
<h1>Welcome from Clone1 - Server 2 (192.168.102.142)</h1>
<h1>Welcome from REDHAT - Server 1 (192.168.102.140)</h1>
<h1>Welcome from Clone1 - Server 2 (192.168.102.142)</h1>
```

> 🎉 **This proves load balancing is working!** Each request goes to a different server.

---

### 🔵 STEP 7 — Test High Availability (Failure Scenario)

> ⚠️ **Do this on: REDHAT VM** (simulate server failure)

```bash
# Stop Apache on REDHAT to simulate a crash
systemctl stop httpd
```

> ⚠️ **Now go back to NON_DNS_Client and test:**

```bash
curl http://192.168.102.110
curl http://192.168.102.110
curl http://192.168.102.110
```

**Expected Output (all responses from Clone1!):**
```
<h1>Welcome from Clone1 - Server 2 (192.168.102.142)</h1>
<h1>Welcome from Clone1 - Server 2 (192.168.102.142)</h1>
<h1>Welcome from Clone1 - Server 2 (192.168.102.142)</h1>
```

> 💡 HAProxy detected that REDHAT is down (health check failed) and automatically sends all traffic to Clone1. **Zero downtime for the client!**

> ⚠️ **Restore REDHAT:**

```bash
# On REDHAT VM — bring it back up
systemctl start httpd
```

```bash
# On NDC — test again (Round Robin resumes)
curl http://192.168.102.110
curl http://192.168.102.110
```

---

### 🔵 STEP 8 — Check HAProxy Logs

> ⚠️ **Do this on: Proxy Server (PS) VM**

```bash
# View HAProxy logs
tail -f /var/log/haproxy.log

# Or check system journal
journalctl -u haproxy -f
```

---

## ⚠️ Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Address already in use :80` | Another service is using port 80 | `systemctl stop httpd` on PS |
| `502 Bad Gateway` | Backend servers are down | Start httpd on REDHAT and Clone1 |
| `Connection refused` | HAProxy not started | `systemctl start haproxy` |
| `Permission denied` on port 80 | SELinux blocking | `setsebool -P haproxy_connect_any 1` |
| Config syntax error | Wrong config format | `haproxy -c -f /etc/haproxy/haproxy.cfg` |

### 🔧 Validate Config Before Starting
```bash
# Always validate config first!
haproxy -c -f /etc/haproxy/haproxy.cfg
```

**Good Output:**
```
Configuration file is valid
```

### 🔧 SELinux Fix (if backends are blocked)
```bash
# Allow HAProxy to connect to any port
setsebool -P haproxy_connect_any 1
```

---

## 📋 Quick Reference Cheatsheet

### Commands Summary by VM

#### 🖥️ On REDHAT (192.168.102.140) & Clone1 (192.168.102.142):
```bash
dnf install httpd -y
systemctl start httpd && systemctl enable httpd
echo "<h1>Server X</h1>" > /var/www/html/index.html
firewall-cmd --permanent --add-service=http && firewall-cmd --reload
```

#### 🖥️ On Proxy Server / PS (192.168.102.110):
```bash
dnf install haproxy -y
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
vi /etc/haproxy/haproxy.cfg                        # paste config
haproxy -c -f /etc/haproxy/haproxy.cfg             # validate
systemctl start haproxy && systemctl enable haproxy
firewall-cmd --permanent --add-service=http && firewall-cmd --reload
ss -tlnp | grep 80                                  # verify listening
```

#### 🖥️ On NON_DNS_Client (192.168.102.120):
```bash
curl http://192.168.102.110    # test load balancer
# Run multiple times — should alternate between servers
```

---

## 🧠 Why Use Load Balancing? — Summary

```
WITHOUT Load Balancer:          WITH Load Balancer (HAProxy):
─────────────────────          ─────────────────────────────
Client → Server1 (overloaded)  Client → HAProxy → Server1
                               Client → HAProxy → Server2
                               Client → HAProxy → Server1
                               (if Server1 dies → all go to Server2)
```

| Feature | Without LB | With HAProxy |
|---------|-----------|-------------|
| Single point of failure | ✅ Yes | ❌ No |
| Handles high traffic | ❌ No | ✅ Yes |
| Auto failover | ❌ No | ✅ Yes |
| Scalable | ❌ No | ✅ Yes |
| Health monitoring | ❌ No | ✅ Yes |

---

## 🔒 Final haproxy.cfg (Clean Version)

```
global
    daemon
    maxconn 256

defaults
    mode http
    timeout connect 10s
    timeout client 10s
    timeout server 10s

frontend lb
    bind *:80
    default_backend webservers

backend webservers
    balance roundrobin
    server app1 192.168.102.140:80 check
    server app2 192.168.102.142:80 check
```

> ✅ **Answer to your question:** YES, you can delete everything in the original haproxy.cfg and replace it with the above. The original file has many commented-out examples that are not needed. Your config is **correct and complete** for this lab.

---

## 📌 Key Concepts Recap

- 🔄 **Round Robin** = Requests distributed evenly, one by one
- 💓 **Health Check (`check`)** = HAProxy monitors if servers are alive
- 🌐 **Frontend** = Where clients connect (port 80 on PS)
- ⚙️ **Backend** = Where HAProxy forwards traffic (REDHAT + Clone1)
- 🛡️ **High Availability** = If one server fails, service continues
- 🔁 **Proxy** = Intermediary that hides backend servers from clients

---

*Lab configured on RHEL with VMware Workstation | HAProxy 2.x | May 2025*
