# 🔐 SSH — Secure Shell: Complete Guide with Lab Examples

> **Based on real lab work on RHEL systems** _Your systems: `client1 (192.168.29.44)` ↔ `server (192.168.29.242)`_

---

## 🤔 What is SSH?

**SSH (Secure Shell)** is a network protocol that lets you **remotely log in and control another computer securely** over an encrypted connection.

Think of it like a **locked tunnel** between two computers — everything inside the tunnel is encrypted, so no one can spy on your commands or passwords.

|Feature|Description|
|---|---|
|🔒 Encrypted|All traffic is encrypted end-to-end|
|🔑 Authenticated|Verifies both user and server identity|
|🖥️ Remote Access|Control servers from anywhere|
|📁 File Transfer|SCP/SFTP for secure file transfer|
|🔀 Port Forwarding|Tunnel other protocols through SSH|

---

## 🔄 How SSH Works

### The Big Picture

```
YOUR MACHINE (Client)                      REMOTE MACHINE (Server)
┌─────────────────────┐                   ┌─────────────────────┐
│                     │                   │                     │
│  $ ssh admin@       │◄──── Network ────►│  sshd daemon        │
│    192.168.29.242   │    (Encrypted)    │  (listens port 22)  │
│                     │                   │                     │
│  ~/.ssh/            │                   │  /etc/ssh/          │
│  ├── id_rsa         │                   │  ├── sshd_config    │
│  ├── id_rsa.pub     │                   │  ├── ssh_host_*     │
│  └── known_hosts    │                   │  └── authorized_keys│
│                     │                   │    (per user)       │
└─────────────────────┘                   └─────────────────────┘
     CLIENT (You)                              SERVER (Remote)
```

---

### 🤝 SSH Handshake — Step by Step

```
CLIENT (192.168.29.44)              SERVER (192.168.29.242)
       │                                      │
       │──── 1. TCP Connect (port 22) ───────►│
       │                                      │
       │◄─── 2. Server sends its PUBLIC KEY ──│
       │         (Server Identity Proof)       │
       │                                      │
       │  [Client checks known_hosts file]     │
       │  ✅ "Yes, I know this server"         │
       │  ❓ "New server, trust it?" (first    │
       │      time only — TOFU)                │
       │                                      │
       │──── 3. Agree on encryption algo ────►│
       │◄─── (Diffie-Hellman Key Exchange) ───│
       │                                      │
       │   🔐 Encrypted Tunnel Established    │
       │                                      │
       │──── 4. User Authentication ─────────►│
       │    (password OR SSH key)              │
       │                                      │
       │◄─── 5. Auth Success → Shell Granted ─│
       │                                      │
       │  [admin@server ~]$                   │
       │                                      │
```

> 💡 **TOFU = Trust On First Use** — The first time you connect to a server, SSH asks "Are you sure you want to connect?" After you say yes, the server's key is saved in `~/.ssh/known_hosts` and you won't be asked again.

---

## 📁 SSH Configuration Files

There are **two sides** — Client and Server — each has its own config files.

### 🖥️ SERVER-SIDE Files (`/etc/ssh/`)

|File|Purpose|
|---|---|
|`/etc/ssh/sshd_config`|🔧 **Main server config** — controls how the SSH server behaves|
|`/etc/ssh/ssh_host_rsa_key`|🔑 Server's private RSA key (never shared)|
|`/etc/ssh/ssh_host_rsa_key.pub`|📢 Server's public RSA key (sent to clients)|
|`/etc/ssh/ssh_host_ed25519_key`|🔑 Server's private Ed25519 key|
|`/etc/ssh/ssh_host_ed25519_key.pub`|📢 Server's public Ed25519 key|
|`/etc/ssh/ssh_host_ecdsa_key`|🔑 Server's private ECDSA key|
|`/etc/ssh/banner`|📢 Message shown BEFORE login (warning/banner)|

```bash
# View all server SSH files
ls -la /etc/ssh/

# Output:
total 608
drwxr-xr-x.  4 root root    142 Apr 19 08:00 .
drwxr-xr-x. 80 root root   8192 Apr 19 08:00 ..
-rw-------.  1 root root    590 Apr 19 08:00 ssh_host_ecdsa_key
-rw-r--r--.  1 root root    162 Apr 19 08:00 ssh_host_ecdsa_key.pub
-rw-------.  1 root root    387 Apr 19 08:00 ssh_host_ed25519_key
-rw-r--r--.  1 root root     82 Apr 19 08:00 ssh_host_ed25519_key.pub
-rw-------.  1 root root   2578 Apr 19 08:00 ssh_host_rsa_key
-rw-r--r--.  1 root root    554 Apr 19 08:00 ssh_host_rsa_key.pub
-rw-------.  1 root root   3667 Apr 19 08:00 sshd_config
```

---

### 💻 CLIENT-SIDE Files (`~/.ssh/`)

|File|Purpose|
|---|---|
|`~/.ssh/config`|⚙️ Client-side SSH shortcuts & settings|
|`~/.ssh/known_hosts`|📋 Servers you've connected to before (their public keys)|
|`~/.ssh/id_rsa`|🔑 Your private key (NEVER share this!)|
|`~/.ssh/id_rsa.pub`|📢 Your public key (safe to share)|
|`~/.ssh/authorized_keys`|✅ Public keys allowed to log into THIS machine as this user|

---

### 🔧 Deep Dive: `/etc/ssh/sshd_config`

This is the **brain of the SSH server**. It lives on the **SERVER** and controls all SSH behavior.

```bash
# On SERVER — View the config
cat /etc/ssh/sshd_config

# Or edit it
sudo nano /etc/ssh/sshd_config
# OR
sudo vim /etc/ssh/sshd_config
```

**Structure of the file:**

```bash
# Lines starting with # are COMMENTS (ignored)
# Format:   DirectiveName   Value

Port 22                        # SSH listens on this port
AddressFamily inet             # Use IPv4 only
ListenAddress 0.0.0.0          # Listen on all interfaces

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

SyslogFacility AUTHPRIV        # Logging category
LogLevel INFO                  # How much to log

LoginGraceTime 2m              # Time allowed to login before disconnect
PermitRootLogin no             # Allow root SSH login?
StrictModes yes                # Check permissions on key files
MaxAuthTries 6                 # Max password attempts per connection
MaxSessions 10                 # Max SSH sessions per connection

PubkeyAuthentication yes       # Allow key-based login
AuthorizedKeysFile .ssh/authorized_keys   # Where to find allowed keys

PasswordAuthentication yes     # Allow password login
PermitEmptyPasswords no        # Allow accounts with no password?

Banner /etc/ssh/banner         # Show a message before login
```

> ⚠️ **After editing sshd_config, always restart SSH:**
> 
> ```bash
> sudo systemctl restart sshd
> # OR (reload without dropping existing sessions)
> sudo systemctl reload sshd
> ```

---

## 🔑 Key Directives Explained

### 1️⃣ `PermitRootLogin`

**What it does:** Controls whether the `root` user can log in directly via SSH.

```bash
# In /etc/ssh/sshd_config on SERVER:

PermitRootLogin no          # ❌ Root CANNOT SSH in at all (most secure)
PermitRootLogin yes         # ✅ Root CAN SSH in (risky!)
PermitRootLogin prohibit-password   # Root can login BUT only with SSH key, NOT password
PermitRootLogin forced-commands-only # Root can login only to run specific commands
```

**Why does this matter?**

```
❌ BAD (PermitRootLogin yes):
   Attacker tries: ssh root@192.168.29.242
   If they guess password → they own your ENTIRE server!

✅ GOOD (PermitRootLogin no):
   Attacker tries: ssh root@192.168.29.242
   Server says: Permission denied — root login not allowed
   Attacker must know a valid username AND password/key
```

**Real-world practice:**

```bash
# On SERVER — Disable root login
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl reload sshd

# Test from CLIENT — should be denied:
ssh root@192.168.29.242
# Output: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

---

### 2️⃣ `AuthorizedKeysFile`

**What it does:** Tells SSH **where to look** for the list of public keys allowed to log in as a user.

```bash
# Default setting in /etc/ssh/sshd_config:
AuthorizedKeysFile  .ssh/authorized_keys

# This means: look at   /home/USERNAME/.ssh/authorized_keys
# For user "admin":     /home/admin/.ssh/authorized_keys
# For user "root":      /root/.ssh/authorized_keys
```

**The file looks like this** (`~/.ssh/authorized_keys` on SERVER):

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7...veryLongKey...== admin@client1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...anotherKey...== admin@laptop
```

Each line = one public key = one device that is allowed to SSH in **without a password**.

```bash
# On SERVER — View who can SSH in as admin
cat /home/admin/.ssh/authorized_keys

# Add a public key manually (paste the key)
echo "ssh-rsa AAAA...== user@machine" >> /home/admin/.ssh/authorized_keys

# Correct permissions (REQUIRED — SSH will refuse if permissions are wrong)
chmod 700 /home/admin/.ssh
chmod 600 /home/admin/.ssh/authorized_keys
```

---

### 3️⃣ `PermitEmptyPasswords`

**What it does:** Controls whether accounts with **no password set** can log in via SSH.

```bash
# In /etc/ssh/sshd_config on SERVER:
PermitEmptyPasswords no     # ❌ Accounts with empty password CANNOT SSH (safe default)
PermitEmptyPasswords yes    # ✅ Empty password accounts CAN SSH (VERY DANGEROUS!)
```

**Why is `yes` dangerous?**

```
If you create a user and forget to set a password:
  $ sudo useradd testuser
  (no passwd set → empty password)

With PermitEmptyPasswords yes:
  Anyone can: ssh testuser@192.168.29.242
  And just press ENTER for password → THEY'RE IN! 😱

Always keep this as: PermitEmptyPasswords no
```

---

### 4️⃣ `PasswordAuthentication`

**What it does:** Controls whether users can log in using a **password** (as opposed to SSH keys only).

```bash
# In /etc/ssh/sshd_config on SERVER:
PasswordAuthentication yes   # ✅ Users can login with password (default)
PasswordAuthentication no    # ❌ Password login disabled — KEYS ONLY
```

**When to use `no`?** After you've set up SSH key authentication for all users, disable password auth. This makes your server much more secure because:

```
With PasswordAuthentication yes:
  $ ssh admin@192.168.29.242
  Password: ←── attacker can try to brute-force guess this

With PasswordAuthentication no:
  $ ssh admin@192.168.29.242
  Permission denied (publickey) ←── no password to guess!
  You MUST have the private key file to get in
```

**Typical secure setup (do in this order!):**

```bash
# Step 1: Set up key auth first (so you don't lock yourself out!)
# Step 2: Then on SERVER, disable password auth:
sudo nano /etc/ssh/sshd_config
# Change: PasswordAuthentication yes → PasswordAuthentication no
sudo systemctl reload sshd
```

---

## 🗝️ Authentication Using Keys

This is the **most important and most secure** SSH feature. Let's understand it completely.

### 🧠 The Concept: Lock and Key

```
PUBLIC KEY  = 🔓 The LOCK  (you can share this with anyone / put it on servers)
PRIVATE KEY = 🔑 The KEY   (you NEVER share this — stays on your machine!)

Server has the LOCK (public key) in authorized_keys
You have the KEY  (private key) in ~/.ssh/id_rsa

SSH Login = "Prove you have the key that matches this lock"
```

---

### 📍 Where to Create Keys?

> ✅ **ALWAYS create keys on the CLIENT machine** (the machine YOU sit at)

```
❌ WRONG: Create keys on the server
✅ RIGHT:  Create keys on the CLIENT

WHY? Because the private key must NEVER leave your machine.
     If you create it on the server, you'd have to copy the private key
     to your client — that's a security risk!
```

**In your lab:**

- Create keys on: **client1 (192.168.29.44)**
- Copy public key to: **server (192.168.29.242)**

---

### 📝 Step-by-Step: Key-Based Authentication

#### 🔵 STEP 1 — Create the key pair (on CLIENT)

```bash
# Run this on CLIENT (192.168.29.44) as your user
[admin@client1 ~]$ ssh-keygen -t ed25519 -C "admin@client1"

# What each flag means:
# -t ed25519    = Key type (ed25519 is modern & secure; rsa also common)
# -C "comment"  = A label to identify this key (usually your email or user@host)

# Output:
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/admin/.ssh/id_ed25519):  ← Press ENTER
Created directory '/home/admin/.ssh'.
Enter passphrase (empty for no passphrase):  ← Optional but recommended
Enter same passphrase again:
Your identification has been saved in /home/admin/.ssh/id_ed25519
Your public key has been saved in /home/admin/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:abc123XYZdef456GHI789jklMNO... admin@client1
The key's randomart image is:
+--[ED25519 256]--+
|       .=o+.     |
|      o +*.      |
|     . B =o      |
|      = B+o      |
|     . oS=o      |
+----[SHA256]-----+
```

**Check what was created:**

```bash
[admin@client1 ~]$ ls -la ~/.ssh/

Output:
total 16
drwx------. 2 admin admin   57 Apr 19 09:00 .
drwx------. 4 admin admin  128 Apr 19 09:00 ..
-rw-------. 1 admin admin  411 Apr 19 09:00 id_ed25519       ← PRIVATE KEY (never share!)
-rw-r--r--. 1 admin admin   96 Apr 19 09:00 id_ed25519.pub   ← PUBLIC KEY  (safe to share)
```

**View your public key:**

```bash
[admin@client1 ~]$ cat ~/.ssh/id_ed25519.pub

Output:
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm8...longstring...3kQ admin@client1
```

---

#### 🔵 STEP 2 — Copy public key to SERVER

**Method 1: Using `ssh-copy-id` (Easiest — Recommended)**

```bash
# Run this on CLIENT (192.168.29.44)
[admin@client1 ~]$ ssh-copy-id admin@192.168.29.242

# Output:
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be sent: '/home/admin/.ssh/id_ed25519.pub'
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s)
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is
to install the new keys
admin@192.168.29.242's password:   ← Enter SERVER password ONE LAST TIME

Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'admin@192.168.29.242'"
and check to make sure that only the key(s) you wanted were added.
```

> 💡 `ssh-copy-id` automatically adds your public key to `~/.ssh/authorized_keys` on the server AND sets the correct permissions!

**Method 2: Manual copy (if ssh-copy-id is unavailable)**

```bash
# On CLIENT — Get your public key content
[admin@client1 ~]$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC...== admin@client1

# On SERVER — Create .ssh dir and add the key
[admin@server ~]$ mkdir -p ~/.ssh
[admin@server ~]$ chmod 700 ~/.ssh
[admin@server ~]$ echo "ssh-ed25519 AAAAC3NzaC...== admin@client1" >> ~/.ssh/authorized_keys
[admin@server ~]$ chmod 600 ~/.ssh/authorized_keys
```

---

#### 🔵 STEP 3 — Verify on SERVER

```bash
# On SERVER — Check the authorized_keys file
[admin@server ~]$ cat ~/.ssh/authorized_keys

Output:
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm8...longstring...3kQ admin@client1
```

---

#### 🔵 STEP 4 — Test the key login (on CLIENT)

```bash
# On CLIENT — SSH without password
[admin@client1 ~]$ ssh admin@192.168.29.242

# If you set a passphrase on the key, you'll be asked for THAT (not the server password)
# If no passphrase — you go straight in!

Output:
Last login: Sun Apr 19 10:14:30 2026
[admin@server ~]$    ← You're in! No password needed! 🎉
```

---

### 🗺️ Complete Key Auth Map

```
CLIENT (192.168.29.44)                    SERVER (192.168.29.242)
┌──────────────────────────┐              ┌──────────────────────────┐
│                          │              │                          │
│  ~/.ssh/id_ed25519       │              │  ~/.ssh/authorized_keys  │
│  (PRIVATE KEY 🔑)        │              │  (PUBLIC KEY 🔓)         │
│                          │              │                          │
│  ssh admin@server ──────►│── Challenge ►│                          │
│                          │◄─ Response ──│  "Prove you have the     │
│  [Signs with private key]│              │   matching private key"  │
│                          │─ Signed ────►│                          │
│                          │              │  [Verifies with public   │
│                          │              │   key in authorized_keys]│
│                          │◄─ SUCCESS ───│  ✅ MATCH → Access granted│
└──────────────────────────┘              └──────────────────────────┘

CREATE KEY HERE                           STORE PUBLIC KEY HERE
Run ssh-keygen here                       authorized_keys file here
```

---

### ⚠️ File Permission Rules (CRITICAL!)

SSH **refuses to work** if file permissions are too open. This is a security feature.

```bash
# On CLIENT — Correct permissions
chmod 700 ~/.ssh                    # Only owner can read/write/enter directory
chmod 600 ~/.ssh/id_ed25519         # Only owner can read/write private key
chmod 644 ~/.ssh/id_ed25519.pub     # Owner can write, others can read public key
chmod 600 ~/.ssh/authorized_keys    # Only owner can read/write

# On SERVER — Correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Check permissions
ls -la ~/.ssh/
# -rw-------  id_ed25519       (600 — private key)
# -rw-r--r--  id_ed25519.pub   (644 — public key)
# -rw-------  authorized_keys  (600 — authorized keys)
```

**If permissions are wrong, SSH will give:**

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/admin/.ssh/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
```

> Fix it: `chmod 600 ~/.ssh/id_ed25519`

---

## 🧪 Your Lab in Action

From your lab file, here's exactly what happened:

### Lab Setup

```
client1  IP: 192.168.29.44   (your machine — where you sit)
server   IP: 192.168.29.242  (remote server — what you SSH into)
user: admin (on both machines)
```

### What you did in the lab:

#### 1. SSH from client to server

``````````````bash
[admin@client1 .ssh]$ ssh admin@192.168.29.242

# Server displayed your banner (from /etc/ssh/banner file):
===========~~~~hi=~~++++++++++++
`````````````Buenos DIans_______
-__________be Posteddd_______!@#$%^&*(@#$%^&UI
____+++++This is a banner files to detect the CHanges=====
=========~~~ hey Welcome you to Avadh.com~~~==============
======~~~  Key Learning ~~~ ===============

# Then MOTD (Message of the Day):
Activate the web console with: systemctl enable --now cockpit.socket
...

# Login info:
Last failed login: Sun Apr 19 10:21:23 IST 2026 from 192.168.29.44 on ssh:notty
There was 1 failed login attempt since the last successful login.
Last login: Sun Apr 19 10:14:30 2026

[admin@server ~]$    ← Successfully logged in!
``````````````

#### 2. Setting up the Banner file (on SERVER)

```bash
# On SERVER — Create the banner file
[admin@server ~]$ sudo nano /etc/ssh/banner

# Add your content:
===========~~~~hi=~~++++++++++++
hey Welcome you to Avadh.com
This is a banner file to detect the Changes
======~~~  Key Learning ~~~ ===============

# Tell sshd to use this banner
[admin@server ~]$ sudo nano /etc/ssh/sshd_config
# Add or uncomment:
Banner /etc/ssh/banner

# Restart SSH
[admin@server ~]$ sudo systemctl restart sshd
```

#### 3. Key-based auth (in your .ssh directory)

```bash
# You navigated to .ssh on client1 — this shows you set up keys
[admin@client1 .ssh]$ ls
id_rsa  id_rsa.pub  known_hosts  authorized_keys
```

---

## 📊 Quick Reference Table

|Task|Command|Run On|
|---|---|---|
|Connect via SSH|`ssh user@IP`|CLIENT|
|Generate key pair|`ssh-keygen -t ed25519`|CLIENT|
|Copy public key to server|`ssh-copy-id user@IP`|CLIENT|
|View public key|`cat ~/.ssh/id_ed25519.pub`|CLIENT|
|View authorized keys|`cat ~/.ssh/authorized_keys`|SERVER|
|Edit SSH server config|`sudo nano /etc/ssh/sshd_config`|SERVER|
|Restart SSH service|`sudo systemctl restart sshd`|SERVER|
|Check SSH service status|`sudo systemctl status sshd`|SERVER|
|View SSH logs|`sudo journalctl -u sshd -f`|SERVER|
|Test config before restart|`sudo sshd -t`|SERVER|
|Connect with specific key|`ssh -i ~/.ssh/id_ed25519 user@IP`|CLIENT|
|Connect with verbose output|`ssh -v user@IP`|CLIENT|

---

## 🛡️ Security Best Practices

```bash
# Recommended /etc/ssh/sshd_config settings for a secure server:

Port 2222                       # Change from default 22 (reduces bot attacks)
PermitRootLogin no              # Never allow root SSH
PasswordAuthentication no       # Keys only (after setting up keys!)
PermitEmptyPasswords no         # No empty passwords
MaxAuthTries 3                  # Limit brute-force attempts
LoginGraceTime 30               # 30 seconds to authenticate
AllowUsers admin devuser        # Only specific users can SSH
Banner /etc/ssh/banner          # Show warning banner
X11Forwarding no                # Disable if not needed
```

---

## 🔍 Troubleshooting SSH

```bash
# Check if SSH is running on server
sudo systemctl status sshd

# Check SSH logs for errors
sudo journalctl -u sshd -n 50

# Test your config file for syntax errors
sudo sshd -t

# Verbose SSH from client (shows each step)
ssh -vvv admin@192.168.29.242

# Check if port 22 is open
ss -tlnp | grep sshd
# or
netstat -tlnp | grep :22

# Check firewall
sudo firewall-cmd --list-services | grep ssh
# Add if missing:
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

---

## 📌 Summary Mind Map

```
SSH
├── HOW IT WORKS
│   ├── TCP connection port 22
│   ├── Server sends public key
│   ├── Encrypted tunnel established
│   └── User authenticated
│
├── CONFIG FILES
│   ├── SERVER: /etc/ssh/sshd_config  ← main config
│   ├── SERVER: /etc/ssh/banner       ← pre-login message
│   ├── CLIENT: ~/.ssh/config         ← client shortcuts
│   └── CLIENT: ~/.ssh/known_hosts    ← trusted servers
│
├── KEY DIRECTIVES
│   ├── PermitRootLogin no            ← block root SSH
│   ├── AuthorizedKeysFile            ← where to find allowed keys
│   ├── PermitEmptyPasswords no       ← block empty passwords
│   └── PasswordAuthentication no     ← force key-only auth
│
└── KEY AUTHENTICATION
    ├── CREATE KEYS → on CLIENT (ssh-keygen)
    │   ├── ~/.ssh/id_ed25519     (private — NEVER share)
    │   └── ~/.ssh/id_ed25519.pub (public — safe to share)
    ├── COPY PUBLIC KEY → to SERVER (ssh-copy-id)
    │   └── goes into ~/.ssh/authorized_keys on SERVER
    └── LOGIN → from CLIENT without password!
```

---

_🎓 Guide created based on real lab work — RHEL/CentOS environment_ _💻 Lab: client1 (192.168.29.44) ↔ server (192.168.29.242)_