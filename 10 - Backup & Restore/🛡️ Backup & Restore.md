# 🛡️ Backup & Restore on Red Hat Enterprise Linux (RHEL 9.7)

### Using `tar` + `scp` + `rsync` with 🔐 Passwordless SSH Key Authentication

---

## 🖥️ Lab Setup

|Role|Hostname|IP Address|
|---|---|---|
|🔴 Server (Main RHEL 9.7)|`client1`|`192.168.68.117`|
|🟡 Client (Clone/Backup Target)|`clone1`|`192.168.68.118`|

> 💡 **Goal:** Take a backup of `/etc` from the **Server**, compress it using `tar + gzip`, transfer it to the **Client** at `/root/backup_files/` — first using `scp`, then using the more powerful `rsync`.

---

## 🔐 Step 1 — Set Up Passwordless SSH (Key Authentication)

> Without this, every `scp` and `rsync` command will ask for a password. We fix that once here, then never again!

### 📍 On the Client  (`192.168.68.117`) — Generate SSH Key Pair

```bash
[root@client1 ~]# ssh-keygen 
```

**📤 Expected Output:**

```
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):   ← Press ENTER
Enter passphrase (empty for no passphrase):                ← Press ENTER
Enter same passphrase again:                               ← Press ENTER
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:xXxXxXxXxXxXxXxXxXxXxXxXxXxX root@client1
```

> 🗝️ This creates TWO files:
> 
> - `/root/.ssh/id_rsa` → **Private Key** (stays on server, NEVER share!)
> - `/root/.ssh/id_rsa.pub` → **Public Key** (this goes to the client)

---

### 📍 Copy Public Key to the CLIENT (`192.168.68.118`)

```bash
[root@client1 ~]# ssh-copy-id root@192.168.68.118
```

**📤 Expected Output:**

```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
The authenticity of host '192.168.68.118 (192.168.68.118)' can't be established.
ED25519 key fingerprint is SHA256:xXxXxXxXxX.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes      ← type yes
root@192.168.68.118's password:                                               ← LAST TIME you enter password!

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.68.118'"
and check to make sure that only the key(s) you wanted were added.
```

---

### ✅ Test Passwordless Login

```bash
[root@client1 ~]# ssh root@192.168.68.118
```

**📤 Expected Output:**

```
Last login: Sat Apr 18 07:54:09 2026
[root@clone1 ~]#                  ← You're IN without any password! 🎉
```

```bash
[root@clone1 ~]# exit             ← Go back to server
logout
Connection to 192.168.68.118 closed.
```

---

## 📦 Step 2 — Create Backup using `tar`

> We will compress the entire `/etc` directory into a single `.tar.gz` file and store it locally first at `/root/`.

### 📍 On SERVER (`192.168.68.117`)

```bash
[root@client1 ~]# tar -czvf /root/etc_backup.tar.gz /etc
```

### 🔍 Flag Breakdown:

|Flag|Meaning|
|---|---|
|`-c`|**C**reate a new archive|
|`-z`|Compress using **g**zip|
|`-v`|**V**erbose — show files being archived|
|`-f`|Specify **f**ilename of the archive|

**📤 Expected Output (partial):**

```
tar: Removing leading `/' from member names
/etc/
/etc/hosts
/etc/hostname
/etc/passwd
/etc/shadow
/etc/fstab
/etc/ssh/
/etc/ssh/sshd_config
...
(many more files)
```

### ✅ Verify the backup file was created:

```bash
[root@client1 ~]# ls -lh /root/etc_backup.tar.gz
```

**📤 Expected Output:**

```
-rw-r--r--. 1 root root 7.0M Apr 18 08:05 /root/etc_backup.tar.gz
```

> 📁 Your backup is **7MB** compressed and ready to transfer!

---

## 📁 Step 3 — Prepare Backup Directory on Client

> Before transferring, make sure the destination folder exists on the client.

### 📍 On CLIENT (`192.168.68.118`) — via SSH from server

```bash
[root@client1 ~]# ssh root@192.168.68.118 "mkdir -p /root/backup_files"
```

**📤 Expected Output:**

```
(no output = success ✅)
```

Or log into client directly and verify:

```bash
[root@client1 ~]# ssh root@192.168.68.118
[root@clone1 ~]# ls /root/
backup_files/
[root@clone1 ~]# exit
```

---

## 🚀 Step 4 — Transfer using `scp`

> `scp` = **Secure Copy Protocol** — copies files over SSH. Simple but transfers the **entire file every time**, even if nothing changed.

### 📍 On SERVER (`192.168.68.117`)

```bash
[root@client1 ~]# scp /root/etc_backup.tar.gz root@192.168.68.118:/root/backup_files/
```

**📤 Expected Output:**

```
etc_backup.tar.gz                    100% 6875KB  52.3MB/s   00:00
```

> ✅ File transferred! 6875KB at 52.3MB/s in under a second (LAN speed).

### ⚠️ Problem with `scp`:

- Every time you run it, it copies the **entire file from scratch**
- Even if only 1 line in `/etc/hosts` changed, it re-sends all 7MB
- **`rsync` solves this problem!** 👇

---

## ⚡ Step 5 — Transfer using `rsync` (Better than scp!)

> `rsync` = **Remote Sync** — only transfers the **differences** (delta). Much faster for repeated backups!

### 🔍 Understanding the Command

```bash
rsync -avzrh SOURCE USER@DESTINATION_IP:DESTINATION_PATH
```

|Flag|Meaning|
|---|---|
|`-a`|**A**rchive mode — preserves permissions, timestamps, symlinks, owner|
|`-v`|**V**erbose — shows what's being transferred|
|`-z`|**Z**ip/compress data during transfer|
|`-r`|**R**ecursive — include subdirectories|
|`-h`|**H**uman-readable sizes (KB, MB, GB)|

---

### 📍 First Transfer (Full Sync) — On SERVER

```bash
[root@client1 ~]# rsync -avzrh /root/etc_backup.tar.gz root@192.168.68.118:/root/backup_files/
```

**📤 Expected Output:**

```
sending incremental file list
etc_backup.tar.gz

sent 110 bytes  received 15.99K bytes  1.89K bytes/sec
total size is 7.04M  speedup is 437.29
```

> 🎯 Notice: `speedup is 437.29` — rsync is already being smart about compression!

---

### 📍 Second Transfer (No Changes) — Run Again Immediately

```bash
[root@client1 ~]# rsync -avzrh /root/etc_backup.tar.gz root@192.168.68.118:/root/backup_files/
```

**📤 Expected Output:**

```
sending incremental file list

sent 67 bytes  received 12 bytes  14.36 bytes/sec
total size is 7.04M  speedup is 89,113.54
```

> 🚀 **WOW!** Only **67 bytes** sent this time (just metadata checksums)! The `speedup is 89,113.54` means rsync was **89,000x more efficient** than re-sending the whole file! This is the **power of rsync** — it skips unchanged files entirely! ✨

---

### 📍 Sync an Entire Directory (Advanced)

```bash
[root@client1 ~]# rsync -avzrh /etc/ root@192.168.68.118:/root/backup_files/etc_mirror/
```

> This syncs the **live `/etc` directory** directly — great for keeping a real-time mirror!

---

## 📂 Step 6 — Restore / Extract the Backup on Client

> Now let's go to the client and restore the backup.

### 📍 On CLIENT (`192.168.68.118`)

```bash
[root@client1 ~]# ssh root@192.168.68.118
[root@clone1 ~]# ls /root/backup_files/
```

**📤 Expected Output:**

```
etc_backup.tar.gz
```

### Extract the backup:

```bash
[root@clone1 ~]# tar -xzvf /root/backup_files/etc_backup.tar.gz -C /root/backup_files/
```

### 🔍 Flag Breakdown:

|Flag|Meaning|
|---|---|
|`-x`|E**x**tract the archive|
|`-z`|Decompress g**z**ip|
|`-v`|**V**erbose output|
|`-f`|Specify **f**ile|
|`-C`|**C**hange to this directory before extracting|

**📤 Expected Output (partial):**

```
etc/
etc/hosts
etc/hostname
etc/passwd
etc/fstab
etc/ssh/
etc/ssh/sshd_config
...
```

### ✅ Verify extraction:

```bash
[root@clone1 ~]# ls /root/backup_files/
```

**📤 Expected Output:**

```
etc/  etc_backup.tar.gz
```

```bash
[root@clone1 ~]# ls /root/backup_files/etc/ | head -10
```

**📤 Expected Output:**

```
adjtime
aliases
alternatives/
anacrontab
at.deny
audit/
bash_completion.d/
bashrc
binfmt.d/
chrony.conf
```

> 🎉 **Backup fully restored!** All `/etc` files are now available on the client.

---

## 🔁 Step 7 — Automate with a Shell Script

> Let's put this all together into one script you can run with a single command or schedule with cron!

### 📍 On SERVER — Create the script

```bash
[root@client1 ~]# nano /root/auto_backup.sh
```

Paste this content:

```bash
#!/bin/bash
# =====================================================
# 🛡️  Auto Backup Script — RHEL 9.7
# Server: 192.168.68.117 → Client: 192.168.68.118
# =====================================================

CLIENT_IP="192.168.68.118"
BACKUP_DIR="/root/backup_files"
SOURCE="/etc"
ARCHIVE_NAME="etc_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
ARCHIVE_PATH="/root/$ARCHIVE_NAME"

echo "📦 Step 1: Creating tar.gz backup of $SOURCE..."
tar -czvf "$ARCHIVE_PATH" "$SOURCE" > /dev/null 2>&1
echo "✅ Archive created: $ARCHIVE_PATH"

echo "⚡ Step 2: Syncing to client $CLIENT_IP using rsync..."
rsync -avzrh "$ARCHIVE_PATH" root@"$CLIENT_IP":"$BACKUP_DIR"/

echo "🎉 Backup complete! File saved at $CLIENT_IP:$BACKUP_DIR/$ARCHIVE_NAME"
```

### Make it executable and run:

```bash
[root@client1 ~]# chmod +x /root/auto_backup.sh
[root@client1 ~]# bash /root/auto_backup.sh
```

**📤 Expected Output:**

```
📦 Step 1: Creating tar.gz backup of /etc...
✅ Archive created: /root/etc_backup_20260418_090000.tar.gz
⚡ Step 2: Syncing to client 192.168.68.118 using rsync...
sending incremental file list
etc_backup_20260418_090000.tar.gz

sent 110 bytes  received 15.99K bytes  1.89K bytes/sec
total size is 7.04M  speedup is 437.29
🎉 Backup complete! File saved at 192.168.68.118:/root/backup_files/etc_backup_20260418_090000.tar.gz
```

---

### ⏰ Schedule with Cron (Run Every Day at 2 AM)

```bash
[root@client1 ~]# crontab -e
```

Add this line:

```
0 2 * * * /bin/bash /root/auto_backup.sh >> /var/log/backup.log 2>&1
```

> 🕑 This runs the backup **automatically every day at 2:00 AM** and logs output to `/var/log/backup.log`

---

## 📊 rsync vs scp Comparison

|Feature|`scp`|`rsync`|
|---|---|---|
|📁 Transfer method|Full copy always|Only changed blocks (delta)|
|🚀 Speed (2nd run)|Same as 1st run|Near-instant if no changes|
|🗜️ Compression|Optional (`-C`)|Built-in (`-z`)|
|📂 Directory sync|Yes (`-r`)|Yes (`-r` or `-a`)|
|🔗 Preserve permissions|No|Yes (`-a`)|
|🔁 Resume interrupted|No|Yes (`--partial`)|
|💼 Best for|One-time transfers|Regular/scheduled backups|

---

## 🗂️ Quick Reference — All Commands

```bash
# 🔐 Setup SSH Key Auth (do once)
ssh-keygen -t rsa -b 4096
ssh-copy-id root@192.168.68.118

# 📦 Create backup archive
tar -czvf /root/etc_backup.tar.gz /etc

# 🚀 Transfer using scp
scp /root/etc_backup.tar.gz root@192.168.68.118:/root/backup_files/

# ⚡ Transfer using rsync
rsync -avzrh /root/etc_backup.tar.gz root@192.168.68.118:/root/backup_files/

# 📂 Extract / Restore on client
tar -xzvf /root/backup_files/etc_backup.tar.gz -C /root/backup_files/

# 🔁 Sync entire directory with rsync
rsync -avzrh /etc/ root@192.168.68.118:/root/backup_files/etc_mirror/
```

---

## 🧠 Key Concepts Summary

```
SERVER (192.168.68.117)              CLIENT (192.168.68.118)
─────────────────────                ──────────────────────
/etc/ ──── tar ──────► etc_backup.tar.gz
                              │
                    ┌─────────┴──────────┐
                    │                    │
                   scp               rsync ✅
                    │                    │
                    └─────────┬──────────┘
                              ▼
                  /root/backup_files/etc_backup.tar.gz
                              │
                             tar -x
                              │
                              ▼
                  /root/backup_files/etc/  (restored!)
```

---

> 💬 **Pro Tip:** Always use `rsync` for repeated/scheduled backups. Use `scp` only for quick one-time transfers. With SSH key auth set up, both are completely passwordless! 🔐✨

---

_Guide based on RHEL 9.7 | rsync version 3.2.5 | OpenSSH_