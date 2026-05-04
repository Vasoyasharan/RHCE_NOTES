## 6. 🔒 HTTPS with Self-Signed Certificate

### 🤔 What is HTTPS and Why Do We Need It?

| HTTP | HTTPS |
|---|---|
| Data sent as **plain text** | Data is **encrypted** |
| Anyone on the network can read it | Cannot be read even if intercepted |
| No certificate needed | Requires SSL/TLS certificate |
| Port **80** | Port **443** |

**Real-world risk of HTTP:**  
```
Without HTTPS (HTTP):
Your password typed: "mypassword123"
What attacker sees on network: "mypassword123"  ← DANGEROUS!

With HTTPS:
Your password typed: "mypassword123"  
What attacker sees: "ITM0IRyiEhVpa6Vn..." ← ENCRYPTED! ✅
```

---

### 🔑 How SSL/TLS Works — Simple Explanation

```
1. Server has TWO keys:
   🔑 Private Key  → Kept SECRET on the server. Never shared.
   🗝️  Public Key   → Shared with everyone (inside the certificate)

2. When you connect:
   - Server sends you its PUBLIC KEY (in the certificate)
   - Your browser uses the PUBLIC KEY to encrypt data
   - Only the server can decrypt it using its PRIVATE KEY

3. Think of it like a padlock:
   - Public Key = Open padlock (anyone can lock data with it)
   - Private Key = The key to open the padlock (only server has it)
```

---

### 🛠️ Step-by-Step HTTPS Configuration

#### Step 1️⃣ — Install Required Packages

```bash
[root@server ~]# yum install httpd openssl mod_ssl -y
```

- `httpd` = Apache web server
- `openssl` = Tool to create certificates
- `mod_ssl` = Apache module that enables SSL/HTTPS support

---

#### Step 2️⃣ — Generate Self-Signed Certificate

```bash
[root@server named]# openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout server.key \
  -out server.crt
```

**Breaking down this command:**

| Part | Meaning |
|---|---|
| `req -x509` | Create a certificate (X.509 format — industry standard) |
| `-nodes` | No password on the key (so Apache can start without asking) |
| `-days 365` | Certificate valid for 365 days |
| `-newkey rsa:2048` | Generate a new 2048-bit RSA key pair |
| `-keyout server.key` | Save private key to this file |
| `-out server.crt` | Save certificate to this file |

**You will be asked to fill in certificate info:**
```
Country Name (2 letter code) [XX]: IN
State or Province Name (full name) []: GUJARAT
Locality Name (eg, city) [Default City]: SURAT
Organization Name (eg, company) [Default Company Ltd]: iForward IT Academy
Organizational Unit Name (eg, section) []: IT/Operation
Common Name (eg, your server's hostname) []: server.iforawrd.in
Email Address []: ava@iforward.in
```

**After running, check your files:**
```bash
[root@server named]# ll
-rw-r--r--. 1 root root  1497 Apr 30 07:50 server.crt   ← Certificate
-rw-------. 1 root root  1704 Apr 30 07:47 server.key   ← Private Key
```

> 🔐 Notice `server.key` has permissions `rw-------` — only root can read it. This is correct for a private key!

---

#### Step 3️⃣ — Copy Files to Correct Locations

```bash
# Copy certificate to the certs folder
[root@server named]# cp server.crt /etc/pki/tls/certs/

# Copy private key to the private folder
[root@server named]# cp server.key /etc/pki/tls/private/
```

**Verify they're in place:**
```bash
[root@server named]# ll /etc/pki/tls/certs
-rw-r--r--. 1 root root  1497 Apr 30 07:55 server.crt   ✅

[root@server named]# ll /etc/pki/tls/private/
-rw-------. 1 root root  1704 Apr 30 07:53 server.key   ✅
```

---

#### Step 4️⃣ — Configure ssl.conf

```bash
[root@server ~]# nano /etc/httpd/conf.d/ssl.conf
```

Find and set these lines (they already exist, just update paths):

```apache
SSLCertificateFile    /etc/pki/tls/certs/server.crt
SSLCertificateKeyFile /etc/pki/tls/private/server.key
```

**Verify with grep:**
```bash
[root@server conf.d]# cat ssl.conf | grep pki
SSLCertificateFile /etc/pki/tls/certs/server.crt
SSLCertificateKeyFile /etc/pki/tls/private/server.key
#SSLCertificateChainFile /etc/pki/tls/certs/server-chain.crt
#SSLCACertificateFile /etc/pki/tls/certs/ca-bundle.crt
```

---

#### Step 5️⃣ — Create HTTPS VirtualHost Config

```bash
[root@server conf.d]# nano portbased.conf
```

```apache
#################### My website Configuration ##################

<VirtualHost 192.168.102.140:443>
    ServerAdmin   root@server.iforward.in
    DocumentRoot  "/var/www/Satrangi"
    ServerName    server.iforward.in
    ServerAlias   server.iforward.in
        SSLEngine             on
        SSLCertificateFile    /etc/pki/tls/certs/server.crt
        SSLCertificateKeyFile /etc/pki/tls/private/server.key

    ErrorLog    "/var/log/httpd/https-error_log"
    CustomLog   "/var/log/httpd/https-access_log" common
</VirtualHost>
```

> ⚠️ **Critical:** The directive is `SSLCertificateKeyFile` 
---

#### Step 6️⃣ — Allow HTTPS in Firewall

```bash
[root@server ~]# firewall-cmd --permanent --add-service=https --zone=public
success
[root@server ~]# firewall-cmd --reload
success
[root@server ~]# firewall-cmd --list-all
  services: cockpit dhcpv6-client dns http https mountd nfs rpc-bind samba squid ssh
```

---

#### Step 7️⃣ — Restart Apache & Test

```bash
[root@server conf.d]# systemctl restart httpd
```

**If it fails, check status:**
```bash
[root@server conf.d]# systemctl status httpd
```

**Test:** Open browser → `https://server.iforward.in`

You'll see a **"Not Secure"** warning ⚠️ — this is **NORMAL** for self-signed certificates! Real websites use certificates from a trusted Certificate Authority (CA) like Let's Encrypt.

Click "Advanced" → "Accept Risk and Continue" → Your website loads over HTTPS! ✅

> 🌟 **From Image 6:** The website (Satrangi Fab House) was successfully loading at `https://server.iforward.in` — notice the "Not secure" label in the address bar, which is expected for self-signed certs.

---


### 🔒 SSL/OpenSSL Commands

```bash
# Generate self-signed certificate (valid 1 year)
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout server.key \
  -out server.crt

# View certificate details
openssl x509 -in server.crt -text -noout

# Copy to correct RHEL locations
cp server.crt /etc/pki/tls/certs/
cp server.key /etc/pki/tls/private/
```
