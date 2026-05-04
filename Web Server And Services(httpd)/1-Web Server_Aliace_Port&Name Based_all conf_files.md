# 🐧 Module 17: Apache Web Server (httpd) — Complete RHEL Guide

> 📘 **By:** iForward IT Academy | Trainer Notes + Lab Screenshots  
> 🎯 **Goal:** Learn Apache, HTTPS, Virtual Hosting & Squid Proxy from scratch — with real commands, real outputs, and zero confusion!

---

## 1. 🌐 What is a Web Server?

### 💡 Simple Definition

A **web server** is both:
- 🖥️ **Hardware** — The physical computer that stores website files and is always connected to the internet
- 💿 **Software** — The program (like Apache) running on that computer that delivers web pages

> **Think of it like this:** A web server is like a pizza shop. The building is the hardware, and the staff (Apache) takes your order and delivers your pizza (webpage) to you!

---

### 🔄 How Does a Web Server Work? (Request-Response Flow)

```
You (Browser)  ──────────────────────────────────────►  Web Server
               Step 1: Type URL → browser splits it into parts
               Step 2: DNS translates domain → IP address
               Step 3: Browser picks protocol (HTTP/HTTPS/FTP)
               Step 4: Browser sends GET request to server
               Step 5: Server finds files, runs scripts, sends back HTML
               Step 6: Browser renders HTML → you see the webpage!
```

**Step-by-Step Example:**
1. You type `http://www.example.com/page.html` in Firefox
2. Firefox asks DNS: *"What is the IP of example.com?"*
3. DNS replies: `93.184.216.34`
4. Firefox sends: `GET /page.html` to that IP
5. Server responds with the HTML content
6. Firefox shows you the webpage ✅

---

## 2. ⚙️ Apache (httpd) Profile on RHEL

| Property | Value |
|---|---|
| 📦 **Package** | `httpd` |
| 🔌 **HTTP Port** | `80` |
| 🔐 **HTTPS Port** | `443` |
| 📄 **Main Config File** | `/etc/httpd/conf/httpd.conf` |
| 📂 **Config Directory** | `/etc/httpd/conf.d/` |
| 🔒 **SSL Config File** | `/etc/httpd/conf.d/ssl.conf` |
| 📁 **Document Root** | `/var/www/html` |
| ⚙️ **Daemon** | `httpd` |
| 📋 **Sample Vhost Config** | `/usr/share/doc/httpd-core/httpd-vhosts.conf` (RHEL 9) |

> 💡 **Document Root** = The folder where your website files live. When someone visits your site, Apache looks here first!

---

## 3. 🚀 Basic Apache Setup — Single Website

### Step 1️⃣ — Install the Package

```bash
[root@server ~]# dnf install httpd* -y
```

**What this does:** Installs Apache web server and all related packages (httpd, httpd-core, httpd-tools, etc.)

**Sample Output:**
```
Installing:
 httpd          x86_64  2.4.62-4.el9   appstream   51 k
 httpd-core     x86_64  2.4.62-4.el9   appstream   1.5 M
 httpd-tools    x86_64  2.4.62-4.el9   appstream   86 k
...
Complete!
```

---

### Step 2️⃣ — Copy Sample Config File

```bash
# For RHEL 9:
[root@server ~]# cp /usr/share/doc/httpd-core/httpd-vhosts.conf /etc/httpd/conf.d/myweb.conf

# For RHEL 7/8:
[root@server ~]# cp /usr/share/doc/httpd/httpd-vhosts.conf /etc/httpd/conf.d/myweb.conf
```

**Why?** Apache comes with a sample virtual host template. We copy it so we have a ready-made starting point and don't break the main config file.

---

### Step 3️⃣ — Edit the Config File

```bash
[root@server ~]# nano /etc/httpd/conf.d/myweb.conf
```

**Edit it to look like this:**

```apache
#################### My website Configuration ##################

<VirtualHost 192.168.102.140:80>
    ServerAdmin    root@server.iforward.in
    DocumentRoot   "/var/www/Satrangi"
    ServerName     server.iforward.in
    ServerAlias    server.iforward.in
    ErrorLog       "/var/log/httpd/https-error_log"
    CustomLog      "/var/log/httpd/https-access_log" common
</VirtualHost>
```

**Explanation of each line:**

| Directive | Meaning |
|---|---|
| `VirtualHost 192.168.102.140:80` | This block applies to requests on this IP and port 80 |
| `ServerAdmin` | Email of the admin (shown in error pages) |
| `DocumentRoot` | Where website files are stored |
| `ServerName` | Main hostname of the website |
| `ServerAlias` | Alternate names that also point here |
| `ErrorLog` | Where Apache logs errors |
| `CustomLog` | Where Apache logs access requests |

---

### Step 4️⃣ — Create Website Files

```bash
# Create the document root directory (if custom)
[root@server ~]# mkdir -p /var/www/Satrangi

# Or use default location:
[root@server ~]# cd /var/www/html/
[root@server html]# nano index.html
```

**index.html content:**
```html
<h1> THIS IS Simple Website </h1>
<p>This is used as a single website hosting</p>
```

---

### Step 5️⃣ — Start and Enable Apache

```bash
[root@server ~]# systemctl enable --now httpd
```

**What this does:**
- `enable` = Start Apache automatically when server boots
- `--now` = Also start it right now (no need to run `start` separately)

**Sample Output:**
```
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service
→ /usr/lib/systemd/system/httpd.service
```

---

### Step 6️⃣ — Configure Firewall

```bash
# Allow HTTP (port 80)
[root@server ~]# firewall-cmd --permanent --add-service=http --zone=public
success

# Reload firewall to apply changes
[root@server ~]# firewall-cmd --reload
success

# Verify
[root@server ~]# firewall-cmd --list-all
public (active)
  services: cockpit dhcpv6-client dns http https nfs ssh
```

> ⚠️ **Common Mistake:** Forgetting to run `--reload` after adding a service. Your change won't apply until you reload!

---

### Step 7️⃣ — Test the Website

**From command line:**
```bash
[root@client ~]# curl 192.168.102.140
<h1> THIS IS Simple Website </h1>
<p>This is used as a single website hosting</p>
```

**From browser:** Open Firefox → Type `http://192.168.102.140`

**With hostname (DNS required):** `http://server.iforward.in`

---

## 4. 🔗 Alias & Redirect

### 🗂️ Alias — Host Multiple Pages Under One Site

An **Alias** lets you serve content from a different folder using a URL path.

**Example:** Visiting `http://server.iforward.in/linux` shows content from `/var/www/html/linux/`

**Step 1:** Create the folder and page:
```bash
[root@server ~]# mkdir /var/www/html/linux
[root@server ~]# nano /var/www/html/linux/index.html
```

```html
<h1>_____ THIS IS LINUX _____</h1>
```

**Step 2:** Add Alias to your config file:
```apache
<VirtualHost 192.168.1.11:80>
    ServerAdmin  root@dns.iforward.in
    DocumentRoot "/var/www/html"
    Alias        /linux /var/www/html/linux     ← ADD THIS LINE
    ServerName   dns.iforward.in
    ...
</VirtualHost>
```

**Step 3:** Reload Apache:
```bash
[root@server ~]# systemctl reload httpd
```

**Test:** Visit `http://192.168.1.11/linux` → Shows "THIS IS LINUX" ✅

---

### ↪️ Redirect — Send Visitors to Another Website

A **Redirect** automatically sends the visitor from your URL to a completely different website.

**Example:** Visiting `/3` on your site → Takes user to `https://www.yoinsights.com`

**Add this to your config:**
```apache
<VirtualHost 192.168.1.11:80>
    DocumentRoot "/var/www/html"
    Alias        /linux /var/www/html/linux
    Redirect     /3 "https://www.yoinsights.com"    ← ADD THIS
    ServerName   dns.iforward.in
    ...
</VirtualHost>
```

```bash
[root@server ~]# systemctl reload httpd
```

**Test:** Visit `http://dns.iforward.in/3` → Browser immediately redirects to yoinsights.com ✅

---

## 5. 🖥️ Virtual Web Hosting

### 💡 What is Virtual Hosting?

Virtual hosting = **One server → Multiple websites**

Instead of buying a separate server for each website, you can run many websites on the same machine!

There are **2 types:**

| Type | How it works | Example |
|---|---|---|
| 🔌 **Port-Based** | Different port numbers for different sites | `site1.com:80` and `site1.com:8080` |
| 🏷️ **Name-Based** | Different domain names on same IP | `site1.com` and `site2.com` both point to same IP |

---

### 5.1 🔌 Port-Based Virtual Hosting

**Concept:** Your main site runs on port 80. A second site runs on port 8080 (or any other free port).

#### Full Lab Steps:

**Step 1:** Create document root for the new site:
```bash
[root@server ~]# mkdir /var/www/site1
```

**Step 2:** Create a webpage for it:
```bash
[root@server ~]# nano /var/www/site1/index.html
```

```html
<h1>___THIS MY WEBsite for Site no 1____</h1>
<h2>=====SITE-1=======</h2>
```

**Step 3:** Create a new config file:
```bash
[root@server conf.d]# cp myweb.conf portbased.conf
[root@server conf.d]# nano portbased.conf
```

**Edit portbased.conf:**
```apache
#################### My website Configuration ##################

#Listen 443
<VirtualHost 192.168.102.140:443>
    ServerAdmin   root@server.iforward.in
    DocumentRoot  "/var/www/Satrangi"
    ServerName    server.iforward.in
    ServerAlias   server.iforward.in
        SSLEngine           on
        SSLCertificateFile    /etc/pki/tls/certs/server.crt
        SSLCertificateKeyFile /etc/pki/tls/private/server.key

    ErrorLog    "/var/log/httpd/https-error_log"
    CustomLog   "/var/log/httpd/https-access_log" common
</VirtualHost>
```

> ⚠️ **Common Mistake from Image 4/5:** The config showed `SSLCertificateKetFile` (typo — missing 'y') which caused Apache to fail with:
> ```
> AH00526: Syntax error on line 38 of /etc/httpd/conf.d/portbased.conf:
> ```
> ✅ **Fix:** Make sure it's `SSLCertificateKeyFile` (with 'y')

**Step 4:** Reload Apache:
```bash
[root@server conf.d]# systemctl restart httpd
```

**Step 5:** Allow port in firewall:
```bash
[root@server ~]# firewall-cmd --add-port=8080/tcp --permanent --zone=public
success
[root@server ~]# firewall-cmd --reload
success
[root@server ~]# firewall-cmd --list-all
  ports: 80/tcp 8080/tcp
```

**Step 6:** Test from client browser:  
`http://192.168.1.11:8080` → Shows "THIS MY WEBsite for Site no 1" ✅

---

### 5.2 🏷️ Name-Based Virtual Hosting

**Concept:** Two different domain names point to the SAME IP, but Apache serves different websites based on the domain name in the HTTP request.

**Example:**
- `dns.iforward.in` → Shows Website A
- `prod.iforward.in` → Shows Website B
- Both resolve to `192.168.1.11`

#### Full Lab Steps:

**Step 1:** Create new website directory:
```bash
[root@server ~]# mkdir /var/www/name
[root@server ~]# nano /var/www/name/index.html
```

```html
<h1>____Name Based Virtual Web Hosting____ </h1>
<p>Name based</p>
```

**Step 2:** Update DNS zone files to add the new hostname:
```bash
[root@server ~]# nano /var/named/dns.flz
```

```dns
$TTL 1D
@       IN SOA  dns.iforward.in. root.iforward.in. (
                        2025082901 ; serial
                        1D         ; refresh
                        1H         ; retry
                        1W         ; expire
                        3H )       ; minimum
        IN  NS  dns.iforward.in.

www     IN  CNAME  dns

prod    IN  A    192.168.1.11    ← ADD THIS (new hostname)

dns     IN  A    192.168.1.11
@       IN  A    192.168.1.11
client  IN  A    192.168.1.22
```

Also update reverse zone `/var/named/dns.rlz`:
```dns
11  IN  PTR  prod.iforward.in.   ← ADD THIS
```

**Step 3:** Reload DNS service:
```bash
[root@server ~]# systemctl reload named.service
```

**Step 4:** Create the Apache config:
```bash
[root@server conf.d]# cp portbased.conf namebased.conf
[root@server conf.d]# nano namebased.conf
```

```apache
######## My NAME BASED Website #####

<VirtualHost 192.168.1.11:80>
    ServerAdmin  root@prod.iforward.in
    DocumentRoot "/var/www/name"
    ServerName   prod.iforward.in       ← DIFFERENT domain!
    ErrorLog     "/var/log/httpd/dns.iforward.in-error_log"
    CustomLog    "/var/log/httpd/dns.iforward.in-access_log" common
</VirtualHost>
```

**Step 5:** Reload Apache:
```bash
[root@server conf.d]# systemctl reload httpd.service
```

**Step 6:** Test from client:  
`http://prod.iforward.in` → Shows "Name Based Virtual Web Hosting" ✅  
`http://dns.iforward.in` → Shows the original website ✅

> 🧠 **How does Apache know which site to show?**  
> When the browser sends the request, it includes the `Host:` header (e.g., `Host: prod.iforward.in`). Apache reads this header and matches it against `ServerName` in each VirtualHost block!

---


## 10. 📋 Quick Reference Cheat Sheet

### 🔧 Apache Commands

```bash
# Install Apache
dnf install httpd* -y

# Start / Stop / Restart / Reload
systemctl start httpd
systemctl stop httpd
systemctl restart httpd       # Full restart (interrupts connections)
systemctl reload httpd        # Graceful reload (no interruption)

# Enable at boot
systemctl enable httpd

# Check status
systemctl status httpd

# Check config for errors BEFORE restart
httpd -t                      # Outputs: Syntax OK  or shows error line

# List virtual hosts
httpd -S

# Check logs
tail -f /var/log/httpd/error_log
tail -f /var/log/httpd/access_log
```

---

### 🔥 Firewall Quick Reference

```bash
# Add services
firewall-cmd --permanent --add-service=http --zone=public
firewall-cmd --permanent --add-service=https --zone=public
firewall-cmd --permanent --add-service=squid --zone=public

# Add custom port
firewall-cmd --add-port=8080/tcp --permanent --zone=public

# Apply changes
firewall-cmd --reload

# List everything
firewall-cmd --list-all
```

---

### 📁 Important File Locations

```
Apache:
  /etc/httpd/conf/httpd.conf          ← Main config (don't edit much)
  /etc/httpd/conf.d/                  ← Put YOUR config files here
  /etc/httpd/conf.d/ssl.conf          ← SSL settings
  /var/www/html/                      ← Default document root
  /var/log/httpd/error_log            ← Error log
  /var/log/httpd/access_log           ← Access log

SSL Certificates:
  /etc/pki/tls/certs/server.crt      ← Certificate (public)
  /etc/pki/tls/private/server.key    ← Private key (secret!)

Squid:
  /etc/squid/squid.conf              ← Main config
  /var/log/squid/access.log          ← Who visited what
  /var/log/squid/cache.log           ← Internal squid operations
  /var/spool/squid/                  ← Disk cache location
```

---
## 🎓 Knowledge Check Questions

After reading this guide, test yourself:

1. What is the difference between `DocumentRoot` and `ServerName`?
2. If you want to host `site1.com` and `site2.com` on the same server with the same IP, which type of virtual hosting do you use?
3. What command do you run to test your Apache config for errors before restarting?
4. Where do you put the SSL private key file? Why is that location important?
5. What Squid directive allows a specific subnet to use the proxy?
6. What does `http_access deny !Safe_ports` mean in Squid?
7. How do you view which websites a specific client is accessing through Squid?

---

> 📌 **Lab Environment Used:** Red Hat Enterprise Linux 9 (RHEL 9)  
> 🏫 **Course:** iForward IT Academy — Linux Administration  
> 🗓️ **Lab Date:** April 30, 2026  
> 🖥️ **Server IP:** `192.168.102.140` | **Client IP:** `192.168.102.142`

---

*Happy Learning! 🐧✨ — If you get stuck, check `systemctl status <service>` and `journalctl -xe` for detailed error messages.*
