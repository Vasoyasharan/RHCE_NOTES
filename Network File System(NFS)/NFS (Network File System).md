# 🖧 NFS (Network File System) — Complete Setup Guide on Red Hat / Rocky Linux / AlmaLinux

> **Your Lab Setup:**
> 
> - 🖥️ **Server IP:** `192.168.102.140`
> - 💻 **Client IP:** `192.168.102.142`
> - 📁 **Shared Directory:** `/nfs-share`

---

## 📖 What is NFS?

**NFS (Network File System)** allows one Linux machine (the **server**) to share a directory over the network so another Linux machine (the **client**) can mount and use it as if it were a local folder.

```
🖥️ SERVER (192.168.102.140)          💻 CLIENT (192.168.102.142)
┌─────────────────────────┐           ┌──────────────────────────┐
│  /nfs-share/            │◄─────────►│  /mnt/nfs-client/        │
│  (actual files here)    │   Network │  (mounted view of share) │
└─────────────────────────┘           └──────────────────────────┘
```

---

## 🗺️ Full Configuration Flow (Don't Skip Steps!)

```
SERVER SIDE                          CLIENT SIDE
────────────────────────             ─────────────────────────
1. Install nfs-utils          →      6. Install nfs-utils
2. Create /nfs-share          →      7. Create /mnt/nfs-client
3. Edit /etc/exports          →      8. showmount -e (verify)
4. exportfs -rav              →      9. mount the share
5. Start nfs-server           →      10. Test + fstab (permanent)
   Open firewall
   Check SELinux
```

---

## 🖥️ SERVER CONFIGURATION (192.168.102.140)

### ✅ Step 1: Verify / Install `nfs-utils`

```bash
rpm -q nfs-utils
```

**Expected Output (if already installed):**

```
nfs-utils-2.5.4-38.el9.x86_64
```

If **NOT installed**, run:

```bash
yum install nfs-utils -y
```

**Expected Output:**

```
Installed:
  nfs-utils-1:2.5.4-38.el9.x86_64
  rpcbind-1.2.6-7.el9.x86_64
  ...
Complete!
```

---

### ✅ Step 2: Create the Shared Directory

```bash
mkdir /nfs-share
```

Verify it exists:

```bash
ls -ld /nfs-share
```

**Expected Output:**

```
drwxr-xr-x. 2 root root 6 Apr 25 08:45 /nfs-share
```

> ⚠️ **CRITICAL:** The directory name in `/etc/exports` MUST match exactly. `/nfs-share` ≠ `/nfs_share` ≠ `/nfsshare`

---

### ✅ Step 3: Configure `/etc/exports` (The Share Config File)

```bash
nano /etc/exports
```

Add this line:

```
/nfs-share 192.168.102.142(rw,sync,no_root_squash)
```

**What each option means:**

|Option|Meaning|
|---|---|
|`/nfs-share`|The directory to share|
|`192.168.102.142`|Only THIS client IP can access it|
|`rw`|Read + Write permissions|
|`sync`|Write data to disk before confirming (safe)|
|`no_root_squash`|Client's root user = Server's root user|

Verify the file is saved correctly:

```bash
cat /etc/exports
```

**Expected Output:**

```
/nfs-share 192.168.102.142(rw,sync,no_root_squash)
```

---

### ✅ Step 4: Apply the Export Configuration

```bash
exportfs -rav
```

**Expected Output:**

```
exporting 192.168.102.142:/nfs-share
```

Double-check active exports:

```bash
exportfs -v
```

**Expected Output:**

```
/nfs-share      192.168.102.142(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

> ⚠️ **If you see NO output here** → the export wasn't applied. Check `/etc/exports` again!

---

### ✅ Step 5: Start & Enable NFS Services

```bash
systemctl enable --now nfs-server
systemctl enable --now rpcbind
```

Check their status:

```bash
systemctl status nfs-server
```

**Expected Output:**

```
● nfs-server.service - NFS server and services
     Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled)
     Active: active (running) since Sat 2024-04-25 08:50:00 IST
```

```bash
systemctl status rpcbind
```

**Expected Output:**

```
● rpcbind.service - RPC Bind
     Active: active (running)
```

---

### ✅ Step 6: Open Firewall Ports

> 💀 **This step kills most setups if skipped!**

```bash
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload
```

Verify:

```bash
firewall-cmd --list-all
```

**Expected Output (look for these services):**

```
services: cockpit dhcpv6-client mountd nfs rpc-bind ssh
```

---

### ✅ Step 7: Handle SELinux (Don't Ignore!)

**Quick temporary test** (turns off SELinux enforcement):

```bash
setenforce 0
```

**Permanent fix** (better — keep SELinux on but allow NFS):

```bash
setsebool -P nfs_export_all_rw 1
setsebool -P nfs_export_all_ro 1
```

Check current status:

```bash
getsebool nfs_export_all_rw
```

**Expected Output:**

```
nfs_export_all_rw --> on
```

---

### 🎯 SERVER VERIFICATION CHECKLIST

Run this on the server before touching the client:

```bash
ls -ld /nfs-share           # Directory exists?
cat /etc/exports            # Correct path and IP?
exportfs -v                 # Export is active?
systemctl status nfs-server # Service running?
systemctl status rpcbind    # RPC running?
firewall-cmd --list-all     # Firewall open?
```

---

## 💻 CLIENT CONFIGURATION (192.168.102.142)

### ✅ Step 8: Install `nfs-utils` on Client

```bash
yum install nfs-utils -y
```

**Expected Output (same as server):**

```
Complete!
```

> 💡 **From your screenshot:** You already did this — `mkdir /mnt/nfs-client` and `ll` showing the directory was created. ✅

---

### ✅ Step 9: Create Mount Point

```bash
mkdir /mnt/nfs-client
```

Verify:

```bash
ls /mnt/
```

**Expected Output:**

```
drwxr-xr-x. 2 root root 4096 Apr 25 08:40 nfs-client
```

---

### ✅ Step 10: Verify Server Export BEFORE Mounting

> 🔥 **This is the debug step most beginners skip!**

```bash
showmount -e 192.168.102.140
```

**✅ If server is configured correctly:**

```
Export list for 192.168.102.140:
/nfs-share 192.168.102.142
```

**❌ If you see this (your screenshot error):**

```
clnt_create: RPC: Unable to receive
```

→ Server's `rpcbind` or `nfs-server` is not running, OR firewall is blocking.

---

### ✅ Step 11: Mount the NFS Share

```bash
mount 192.168.102.140:/nfs-share /mnt/nfs-client
```

**Expected Output:** _(No output = SUCCESS!)_

Verify it mounted:

```bash
df -h
```

**Expected Output:**

```
Filesystem                        Size  Used Avail Use% Mounted on
192.168.102.140:/nfs-share        17G  2.1G   15G  13% /mnt/nfs-client
```

Or:

```bash
mount | grep nfs
```

**Expected Output:**

```
192.168.102.140:/nfs-share on /mnt/nfs-client type nfs4 (rw,relatime,...)
```

---

### ✅ Step 12: Test the Connection (Critical!)

**On CLIENT — create a test file:**

```bash
touch /mnt/nfs-client/test.txt
echo "Hello from Client!" > /mnt/nfs-client/test.txt
```

**On SERVER — verify the file appeared:**

```bash
ls /nfs-share/
cat /nfs-share/test.txt
```

**Expected Output on Server:**

```
test.txt
Hello from Client!
```

> 🎉 **If you see the file on the server → NFS is working perfectly!**

---

### ✅ Step 13: Make Mount Permanent (Survives Reboot)

Edit fstab:

```bash
nano /etc/fstab
```

Add this line at the bottom:

```
192.168.102.140:/nfs-share  /mnt/nfs-client  nfs  defaults  0  0
```

Test fstab without rebooting:

```bash
umount /mnt/nfs-client
mount -a
df -h | grep nfs
```

**Expected Output:**

```
192.168.102.140:/nfs-share   17G  2.1G   15G  13% /mnt/nfs-client
```

---

## 🚨 Troubleshooting — Your Exact Errors Explained

### ❌ Error 1: `clnt_create: RPC: Unable to receive`

**What it means:** The client cannot talk to the server's RPC service.

**Fix on SERVER:**

```bash
systemctl restart rpcbind
systemctl restart nfs-server
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --reload
```

**Check from Client:**

```bash
rpcinfo -p 192.168.102.140
```

**Expected Output:**

```
   program vers proto   port  service
    100000    4   tcp    111  portmapper
    100003    4   tcp   2049  nfs
    100005    3   tcp  20048  mountd
```

---

### ❌ Error 2: `No such file or directory` during mount

**What it means:** The server didn't export `/nfs-share` OR the path doesn't exist.

**Fix on SERVER:**

```bash
# Step 1: Check directory exists
ls -ld /nfs-share

# Step 2: Check exports file
cat /etc/exports

# Step 3: Re-apply exports
exportfs -rav

# Step 4: Restart service
systemctl restart nfs-server
```

---

### ❌ Error 3: `Permission denied` on mounted share

**What it means:** SELinux is blocking NFS access.

**Fix:**

```bash
# Temporary test
setenforce 0
mount 192.168.102.140:/nfs-share /mnt/nfs-client

# If it works, make permanent
setenforce 1
setsebool -P nfs_export_all_rw 1
```

---

### ❌ Error 4: `Connection timed out`

**What it means:** Firewall is blocking NFS traffic.

**Fix on SERVER:**

```bash
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload
firewall-cmd --list-all
```

---

## 🧠 Master Troubleshooting Decision Tree

```
Mount fails?
    │
    ▼
showmount -e SERVER_IP works?
    │
    ├─── NO ──► rpcbind issue or firewall
    │           systemctl restart rpcbind nfs-server
    │           firewall-cmd --add-service=rpc-bind
    │
    └─── YES ──► Does /nfs-share appear in export list?
                    │
                    ├─── NO ──► /etc/exports wrong
                    │          exportfs -rav
                    │
                    └─── YES ──► Try mounting
                                    │
                                    ├─── Permission Denied ──► SELinux
                                    │                          setsebool -P nfs_export_all_rw 1
                                    │
                                    └─── No such file ──► Path mismatch in /etc/exports
```

---

## 📋 Quick Reference Command Summary

### SERVER Commands

```bash
# Install
yum install nfs-utils -y

# Setup
mkdir /nfs-share
echo "/nfs-share 192.168.102.142(rw,sync,no_root_squash)" >> /etc/exports

# Apply & Start
exportfs -rav
systemctl enable --now nfs-server rpcbind

# Firewall
firewall-cmd --permanent --add-service={nfs,rpc-bind,mountd}
firewall-cmd --reload

# SELinux
setsebool -P nfs_export_all_rw 1

# Verify
exportfs -v
systemctl status nfs-server rpcbind
```

### CLIENT Commands

```bash
# Install
yum install nfs-utils -y

# Setup
mkdir /mnt/nfs-client

# Debug first!
showmount -e 192.168.102.140

# Mount
mount 192.168.102.140:/nfs-share /mnt/nfs-client

# Verify
df -h
mount | grep nfs

# Test
touch /mnt/nfs-client/testfile.txt

# Permanent (fstab)
echo "192.168.102.140:/nfs-share /mnt/nfs-client nfs defaults 0 0" >> /etc/fstab
mount -a
```

---

## 🔑 Key Concepts to Remember

|Concept|Explanation|
|---|---|
|`/etc/exports`|Server's config file — defines WHAT to share and WHO can access|
|`exportfs -rav`|Applies changes to `/etc/exports` without restart|
|`rpcbind`|Port mapper service — NFS needs this to work|
|`nfs-server`|The main NFS service on the server|
|`showmount -e`|Debug tool — verifies server is exporting correctly|
|`fstab`|Makes mount permanent across reboots|
|SELinux|Security layer — can silently block NFS if not configured|
|Firewall|Ports 111 (RPC) and 2049 (NFS) must be open|

---

## ✅ Final Success Verification

Run these commands — if ALL pass, your NFS is perfect:

**On SERVER:**

```bash
exportfs -v          # Shows /nfs-share
systemctl is-active nfs-server   # Output: active
systemctl is-active rpcbind      # Output: active
```

**On CLIENT:**

```bash
showmount -e 192.168.102.140     # Shows /nfs-share
df -h | grep nfs                 # Shows mounted filesystem
ls /mnt/nfs-client/              # Shows files from server
```

---

> 📝 **Note:** This guide is based on Red Hat Enterprise Linux 9 / Rocky Linux 9 / AlmaLinux 9. Commands are the same for RHEL 8 family.

> 🎓 **Lab Setup:** Server `192.168.102.140` → Client `192.168.102.142` | Share: `/nfs-share`