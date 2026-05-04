# 🗂️ Enterprise Samba File Server Lab Guide
## Department-Based Access Control with Linux Permissions + ACL + SGID

> **Lab Environment:** RHEL 9 / CentOS Stream | Samba 4.x | Server IP: `192.168.174.130`

---

## 🎯 Lab Objective

Build a **production-style Samba file server** where:
- Each department (`hr`, `it`, `finance`) has its own share
- Users can **only** access their own department's share
- Files created inside a share **automatically inherit** the correct group and permissions
- ACLs provide **granular, per-user/per-group** access beyond basic Unix permissions

---

## 🏗️ Architecture Overview

```
/samba-share/
├── hr/          ← owned by root:hr  | mode: 2770 | ACL: @hr=rwx, others=---
├── iit/         ← owned by root:iit | mode: 2770 | ACL: @iit=rwx, others=---
└── finance/     ← owned by root:finance | mode: 2770 | ACL: @finance=rwx, others=---

Users:
  user_hr1  → group: hr
  user_iit1 → group: iit
  user_fin1 → group: finance

Samba Shares:
  \\192.168.174.130\hr      → valid users: @hr
  \\192.168.174.130\iit     → valid users: @iit
  \\192.168.174.130\finance → valid users: @finance
```

---

## 🧩 Step-by-Step Setup

### 🔵 STEP 1 — Create Department Groups

**Why?** Groups are the backbone of access control. Instead of managing permissions per-user, we assign permissions to groups, then add users to groups. This scales to hundreds of users easily.

```bash
groupadd hr
groupadd iit
groupadd finance
```

**Verify groups were created:**
```bash
grep -E "^hr:|^iit:|^finance:" /etc/group
```

**Expected Output:**
```
finance:x:1003:
hr:x:1001:
iit:x:1002:
```

---

### 👤 STEP 2 — Create Users

```bash
# Create users
useradd user_hr1
useradd user_iit1
useradd user_fin1

# Set passwords (use a strong password in production!)
passwd user_hr1
passwd user_iit1
passwd user_fin1
```

> ⚠️ **Note from Lab Screenshots:** The password was accepted despite the "BAD PASSWORD" warning because we confirmed it twice. In production, always use passwords ≥ 8 characters to avoid this warning.

---

### 👥 STEP 3 — Assign Users to Department Groups

```bash
usermod -aG hr   user_hr1
usermod -aG iit  user_iit1
usermod -aG finance user_fin1
```

> ⚠️ **Common Mistake Seen in Lab:** `usermod -aG it user_iit1` fails because the group is named `iit`, not `it`. Always match group names exactly.

```
usermod: group 'it' does not exist   ← WRONG (group is 'iit')
```

**Verify membership:**
```bash
id user_hr1
```
```
uid=1001(user_hr1) gid=1001(user_hr1) groups=1001(user_hr1),1004(hr)
```

---

### 🔐 STEP 4 — Add Samba Users

Linux users and Samba users are **two separate databases**. A user must exist in both to access Samba shares.

```bash
smbpasswd -a user_hr1
smbpasswd -a user_iit1
smbpasswd -a user_fin1
```

**Expected Output (per user):**
```
New SMB password:
Retype new SMB password:
Added user user_hr1.
```

**Verify Samba user list:**
```bash
pdbedit -L
```
```
user_hr1:1001:
user_iit1:1002:
user_fin1:1003:
```

---

### 📁 STEP 5 — Create Department Directories

```bash
mkdir -p /samba-share/hr
mkdir -p /samba-share/iit
mkdir -p /samba-share/finance
```

---

### 🔑 STEP 6 — Set Group Ownership

```bash
chown -R root:hr      /samba-share/hr
chown -R root:iit     /samba-share/iit
chown -R root:finance /samba-share/finance
```

**Why root as owner?** The directory is *administered* by root, but *used* by the group. The SGID bit (Step 7) ensures all new files inherit the group, not the creating user's primary group.

---

## 🔥 SGID + Default ACL — The Core Concept (Step 7 & 9)

> 💡 This is the **most important section** to understand. These two mechanisms work together to prevent broken permissions in a shared directory.

### 🔴 The Problem Without SGID + Default ACL

Imagine `user_hr1` (primary group: `user_hr1`) creates a file in `/samba-share/hr`:

```
Without SGID:
-rw-r--r-- 1 user_hr1 user_hr1  report.txt   ← group is user_hr1, NOT hr!
```

Now `user_hr2` (in the `hr` group) tries to read `report.txt` — they **can't**, because the file's group is `user_hr1`, not `hr`.

### ✅ The Solution: SGID (Step 7)

**SGID = Set Group ID** on a directory means: *"Any file created inside this directory inherits the directory's group, regardless of who creates it."*

```bash
chmod 2770 /samba-share/hr
chmod 2770 /samba-share/iit
chmod 2770 /samba-share/finance
```

Breaking down `2770`:
| Digit | Meaning |
|-------|---------|
| `2`   | SGID bit — new files inherit directory's group |
| `7`   | Owner (root) → rwx |
| `7`   | Group (hr/iit/finance) → rwx |
| `0`   | Others → no permissions |

```
With SGID:
-rw-rw---- 1 user_hr1 hr  report.txt   ← group is now 'hr' ✅
```

**Verify SGID is set:**
```bash
ls -ld /samba-share/hr
```
```
drwxrws--- 2 root hr 4096 Apr 28 07:32 /samba-share/hr
         ^
         's' here = SGID is active
```

> The `s` in the group execute position confirms SGID is set. If you see `S` (capital), execute bit is missing — fix with `chmod g+x`.

---

### ✅ The Solution: Default ACLs (Step 9)

**Default ACLs** are "template permissions" that are automatically applied to every new file or subdirectory created inside a directory.

**Without Default ACLs:**
Even with SGID, newly created *subdirectories* might not have the right ACL entries for the group to traverse them.

**With Default ACLs:**
Every new file/subdir gets a pre-set ACL automatically.

```bash
# --- HR Share ACL Setup ---

# Step 8: Access ACL — who can access RIGHT NOW
setfacl -m g:hr:rwx /samba-share/hr      # hr group gets rwx
setfacl -m o::---   /samba-share/hr      # others get nothing

# Step 9: Default ACL — template for NEW files/dirs created inside
setfacl -d -m u::rwx    /samba-share/hr  # owner gets rwx by default
setfacl -d -m g:hr:rwx  /samba-share/hr  # hr group gets rwx by default
setfacl -d -m o::---    /samba-share/hr  # others get nothing by default
```

Also add default for specific user (user_hr1):
```bash
setfacl -m u:user_hr1:rwx /samba-share/hr
```

### 🔄 How SGID + Default ACL Work Together

```
user_hr1 creates /samba-share/hr/reports/ (a subdirectory)
        │
        ├── SGID ensures → group = hr  (not user_hr1)
        │
        └── Default ACL ensures → ACL entries copied:
                user::rwx
                group:hr:rwx
                other::---
                mask::rwx
```

**Result:** Any user in `hr` can read/write/execute in `reports/`, AND any file they create inside `reports/` will also inherit these rules — infinitely deep! 🎯

---

### 🔐 STEP 8 & 9 — Apply ACLs for All Departments

```bash
# ---- HR ----
setfacl -m g:hr:rwx /samba-share/hr
setfacl -m o::--- /samba-share/hr
setfacl -m u:user_hr1:rwx /samba-share/hr
setfacl -d -m u::rwx /samba-share/hr
setfacl -d -m g:hr:rwx /samba-share/hr
setfacl -d -m o::--- /samba-share/hr

# ---- IIT ----
setfacl -m g:iit:rwx /samba-share/iit
setfacl -m o::--- /samba-share/iit
setfacl -m u:user_iit1:rwx /samba-share/iit
setfacl -d -m u::rwx /samba-share/iit
setfacl -d -m g:iit:rwx /samba-share/iit
setfacl -d -m o::--- /samba-share/iit

# ---- Finance ----
setfacl -m g:finance:rwx /samba-share/finance
setfacl -m o::--- /samba-share/finance
setfacl -m u:user_fin1:rwx /samba-share/finance
setfacl -d -m u::rwx /samba-share/finance
setfacl -d -m g:finance:rwx /samba-share/finance
setfacl -d -m o::--- /samba-share/finance
```

---

### 📋 Verify ACLs (Step 9 Expected Output)

```bash
getfacl /samba-share/hr
```

**✅ Perfect Expected Output:**
```
getfacl: Removing leading '/' from absolute path names
# file: samba-share/hr
# owner: root
# group: hr
# flags: -s-
user::rwx
user:user_hr1:rwx
group::rwx
group:hr:rwx
mask::rwx
other::---
default:user::rwx
default:group::rwx
default:group:hr:rwx
default:mask::rwx
default:other::---
```

> **Key things to verify:**
> - `# flags: -s-` → confirms SGID is active
> - `group:hr:rwx` → hr group has full access
> - `other::---` → outsiders blocked
> - All `default:` entries present → inheritance is configured

---

## ⚙️ STEP 10: Samba Configuration (`smb.conf`)

Edit `/etc/samba/smb.conf`:

```bash
vim /etc/samba/smb.conf
```

Add/update the following (keep the `[global]` section intact):

```ini
[global]
   workgroup = WORKGROUP
   server string = Samba Department File Server
   log file = /var/log/samba/log.%m
   max log size = 50
   security = user
   passdb backend = tdbsam

# ─────────────────────────────────────
# HR Department Share
# ─────────────────────────────────────
[hr]
   path = /samba-share/hr
   valid users = @hr
   writable = yes
   browseable = yes
   create mask = 0770
   directory mask = 2770
   force group = hr

# ─────────────────────────────────────
# IT Department Share
# ─────────────────────────────────────
[iit]
   path = /samba-share/iit
   valid users = @iit
   writable = yes
   browseable = yes
   create mask = 0770
   directory mask = 2770
   force group = iit

# ─────────────────────────────────────
# Finance Department Share
# ─────────────────────────────────────
[finance]
   path = /samba-share/finance
   valid users = @finance
   writable = yes
   browseable = yes
   create mask = 0770
   directory mask = 2770
   force group = finance
```

> 💡 **`force group`** is a Samba-level reinforcement of SGID — it forces the group of all files created via Samba to be the department group, even if a user's shell session has a different primary group.

**Validate config syntax:**
```bash
testparm
```
```
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
Server role: ROLE_STANDALONE

Press enter to see a dump of your service definitions
```

---

### 🔁 STEP 11 — Restart Samba

```bash
systemctl restart smb
systemctl enable smb
systemctl status smb
```

**Expected Status Output:**
```
● smb.service - Samba SMB Daemon
     Loaded: loaded (/usr/lib/systemd/system/smb.service; enabled; preset: disabled)
     Active: active (running) since Tue 2026-04-28 07:45:00 IST; 3s ago
```

Also restart `nmb` for NetBIOS name resolution:
```bash
systemctl restart nmb
```

---

## 🧪 Verification & Expected Outputs

### Step 12 — List Directories on Server

```bash
ls -ld /samba-share/*/
```

**✅ Expected Output:**
```
drwxrws---. 2 root finance 4096 Apr 28 07:32 /samba-share/finance/
drwxrws--. 3 root hr       4096 Apr 28 07:57 /samba-share/hr/
drwxrws---. 2 root iit     4096 Apr 28 07:32 /samba-share/iit/
```

> **Decode the permissions string `drwxrws---`:**
> ```
> d  rwx  rws  ---
> │   │    │    └── others: no permissions ✅
> │   │    └─────── group: rwx + s (SGID active) ✅
> │   └──────────── owner (root): rwx ✅
> └──────────────── d = directory
> ```

---

### Step 12 — Verify HR share contents after test

```bash
ls /samba-share/hr
```

**✅ Expected Output (after user creates `hr_test` dir via smbclient):**
```
hr_test
```

Verify the directory inherited correct group:
```bash
ls -ld /samba-share/hr/hr_test
```
```
drwxrwsr-x 2 user_hr1 hr 4096 Apr 28 07:57 /samba-share/hr/hr_test
                       ^^
                       group = hr (inherited via SGID) ✅
```

---

## 🔬 Testing — Cross-Department Access

### Step 13 — Test HR User on HR Share ✅

```bash
smbclient //192.168.174.130/hr -U user_hr1
```
```
Password for [WORKGROUP\user_hr1]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Tue Apr 28 07:32:11 2026
  ..                                  D        0  Tue Apr 28 07:32:11 2026

                81987992 blocks of size 1024. 58055340 blocks available
smb: \>
```

**Create a test directory:**
```
smb: \> mkdir hr_test
smb: \> ls
  .                                   D        0  Tue Apr 28 07:57:22 2026
  ..                                  D        0  Tue Apr 28 07:32:11 2026
  hr_test                             D        0  Tue Apr 28 07:57:22 2026

                81987992 blocks of size 1024. 58055340 blocks available
smb: \> ^C
```

---

### Step 13 — Test HR User Accessing IIT Share ❌ (Should Fail!)

```bash
smbclient //192.168.174.130/iit -U user_hr1
```
```
Password for [WORKGROUP\user_hr1]:
tree connect failed: NT_STATUS_ACCESS_DENIED
```

> 🛡️ **This is the expected and correct result!** `user_hr1` is NOT in the `iit` group, so Samba's `valid users = @iit` blocks access immediately. This confirms our isolation is working perfectly.

---

### Step 13 — Test Finance User Accessing Finance Share ✅

```bash
smbclient //192.168.174.130/finance -U user_fin1
```
```
Password for [WORKGROUP\user_fin1]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Tue Apr 28 07:32:11 2026
  ..                                  D        0  Tue Apr 28 07:32:11 2026

                81987992 blocks of size 1024. 58055340 blocks available
smb: \>
```

---

### Full ACL Inheritance Test

```bash
# As root: create a file as user_hr1 via su
su - user_hr1 -c "touch /samba-share/hr/test_file.txt"

# Check what permissions it got
ls -la /samba-share/hr/test_file.txt
getfacl /samba-share/hr/test_file.txt
```

**✅ Expected Output:**
```bash
# ls output:
-rw-rw---- 1 user_hr1 hr 0 Apr 28 08:10 /samba-share/hr/test_file.txt
                       ^^
                       group = hr (SGID working!) ✅

# getfacl output:
# file: samba-share/hr/test_file.txt
# owner: user_hr1
# group: hr
user::rw-
group::rw-
group:hr:rw-
mask::rw-
other::---
```

---

## 🎁 BONUS — Advanced Scenarios

### 🔒 Bonus 1: Read-Only Manager Access

**Scenario:** A `manager` user needs read-only access to ALL department shares to review files, without write permissions.

**Step 1: Create manager user and add to all groups**
```bash
useradd manager
passwd manager
smbpasswd -a manager
usermod -aG hr,iit,finance manager
```

**Step 2: Apply read-only ACL to all shares**
```bash
setfacl -m u:manager:r-x /samba-share/hr
setfacl -m u:manager:r-x /samba-share/iit
setfacl -m u:manager:r-x /samba-share/finance

# Default ACL — read-only for new files too
setfacl -d -m u:manager:r-- /samba-share/hr
setfacl -d -m u:manager:r-- /samba-share/iit
setfacl -d -m u:manager:r-- /samba-share/finance
```

**Step 3: Add read-only manager share in smb.conf**
```ini
[hr]
   path = /samba-share/hr
   valid users = @hr manager
   writable = yes
   browseable = yes
   create mask = 0770
   directory mask = 2770
   force group = hr
   write list = @hr          ← only hr group can write; manager is read-only via ACL
```

**Verify manager can read but NOT write:**
```bash
smbclient //192.168.174.130/hr -U manager
```
```
smb: \> ls          ← works ✅
smb: \> mkdir test  ← fails: NT_STATUS_ACCESS_DENIED ✅
```

---

### 🔀 Bonus 2: Cross-Department ACL Override

**Scenario:** `user_hr1` needs temporary read access to the `finance` share for an audit.

```bash
# Grant user_hr1 read-only access to finance share
setfacl -m u:user_hr1:r-x /samba-share/finance

# Verify
getfacl /samba-share/finance | grep user_hr1
```
```
user:user_hr1:r-x
```

**Update smb.conf to allow user_hr1 into the finance share:**
```ini
[finance]
   path = /samba-share/finance
   valid users = @finance user_hr1      ← add user_hr1 explicitly
   writable = yes
   browseable = yes
   create mask = 0770
   directory mask = 2770
   force group = finance
```

```bash
systemctl restart smb

# Test: user_hr1 can now READ finance
smbclient //192.168.174.130/finance -U user_hr1
```
```
smb: \> ls       ← works ✅
smb: \> mkdir x  ← NT_STATUS_ACCESS_DENIED ✅ (read-only as intended)
```

**Remove temporary access when audit is done:**
```bash
setfacl -x u:user_hr1 /samba-share/finance
```
And remove `user_hr1` from `valid users` in `smb.conf`.

---

### 👻 Bonus 3: Hidden Shares (Admin-Only)

**Scenario:** An `admin-backup` share exists on the server but is invisible when users browse the network. Only users who know the exact share name can connect.

**smb.conf configuration:**
```ini
[admin-backup]
   path = /samba-share/admin-backup
   valid users = root admin_user
   writable = yes
   browseable = no              ← HIDDEN from network browse list
   create mask = 0700
   directory mask = 0700

# Hidden IPC$ style — use $ suffix convention (Windows style)
[finance$]
   path = /samba-share/finance-archive
   valid users = @finance
   writable = no
   browseable = no              ← won't appear in \\server\ listing
   create mask = 0770
```

**Create the hidden share directory:**
```bash
mkdir -p /samba-share/admin-backup
chmod 700 /samba-share/admin-backup
chown root:root /samba-share/admin-backup
```

**Access hidden share (must know the exact name):**
```bash
# This works — you must type the share name explicitly
smbclient //192.168.174.130/admin-backup -U root

# This will NOT show admin-backup in the list
smbclient -L //192.168.174.130 -U user_hr1
```
```
Sharename       Type      Comment
---------       ----      -------
hr              Disk
iit             Disk
finance         Disk
IPC$            IPC       IPC Service
        ← admin-backup is invisible ✅
```

---

## 📋 Quick Reference Cheatsheet

```
╔══════════════════════════════════════════════════════════════════╗
║          SAMBA FILE SERVER — COMMAND QUICK REFERENCE             ║
╠══════════════════════════════════════════════════════════════════╣
║ GROUP MANAGEMENT                                                  ║
║   groupadd <name>              Create a group                    ║
║   usermod -aG <group> <user>   Add user to group (-a = append)   ║
║   id <user>                    Show user's groups                ║
║                                                                  ║
║ SAMBA USERS                                                      ║
║   smbpasswd -a <user>          Add Samba user                    ║
║   smbpasswd -d <user>          Disable Samba user                ║
║   pdbedit -L                   List all Samba users              ║
║                                                                  ║
║ PERMISSIONS                                                      ║
║   chmod 2770 <dir>             Set SGID + rwxrwx---              ║
║   chown root:<group> <dir>     Set group ownership               ║
║                                                                  ║
║ ACL COMMANDS                                                      ║
║   setfacl -m g:<grp>:rwx <dir>   Set group ACL                   ║
║   setfacl -d -m g:<grp>:rwx <d>  Set DEFAULT (inherited) ACL     ║
║   setfacl -x u:<user> <dir>      Remove user's ACL entry         ║
║   setfacl -b <dir>               Remove ALL ACL entries           ║
║   getfacl <dir>                  View ACL entries                 ║
║                                                                  ║
║ SAMBA SERVICE                                                    ║
║   testparm                     Validate smb.conf syntax          ║
║   systemctl restart smb nmb    Restart Samba                     ║
║   systemctl status smb         Check Samba status                ║
║                                                                  ║
║ TESTING FROM CLIENT                                              ║
║   smbclient //<ip>/<share> -U <user>   Connect to share          ║
║   smbclient -L //<ip> -U <user>        List available shares     ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 🐛 Common Mistakes & Fixes

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| `usermod -aG it user` — group `it` doesn't exist | Use correct group name: `usermod -aG iit user` |
| SGID shows `S` (capital) instead of `s` | Execute bit missing: `chmod g+x /samba-share/hr` |
| New files don't inherit group | Check SGID with `ls -ld`; verify `s` in group position |
| New files lose ACL on creation | Apply **default ACLs** with `setfacl -d -m ...` |
| Samba user can't login | User may not be in Samba DB: `smbpasswd -a <user>` |
| Config changes not taking effect | Always run `testparm` then `systemctl restart smb` |
| `NT_STATUS_ACCESS_DENIED` unexpectedly | Check `valid users` in smb.conf AND Linux ACL |
| `getfacl` shows no default entries | Re-run: `setfacl -d -m g:<group>:rwx <dir>` |
| SELinux blocking Samba | Run: `setsebool -P samba_export_all_rw 1` |
| Firewall blocking Samba | `firewall-cmd --add-service=samba --permanent && firewall-cmd --reload` |

---

## 🔐 SELinux & Firewall (Production Checklist)

```bash
# Allow Samba to read/write user home dirs and shared dirs
setsebool -P samba_export_all_rw 1
setsebool -P samba_share_fusefs 1

# Label the samba-share directory for SELinux
semanage fcontext -a -t samba_share_t "/samba-share(/.*)?"
restorecon -Rv /samba-share/

# Open firewall for Samba
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload

# Verify
firewall-cmd --list-services | grep samba
```

---

## 📊 Summary: The Permission Layers

```
╔══════════════════════════════════════════════════════╗
║          THREE LAYERS OF ACCESS CONTROL              ║
╠══════════════════════╦═══════════════════════════════╣
║ Layer 1: Samba       ║ valid users = @hr             ║
║ (First Gate)         ║ Blocks non-HR users at        ║
║                      ║ network login level           ║
╠══════════════════════╬═══════════════════════════════╣
║ Layer 2: Linux       ║ chmod 2770 (rwxrws---)        ║
║ Permissions          ║ Group owner = hr              ║
║ (Second Gate)        ║ Others = no access            ║
╠══════════════════════╬═══════════════════════════════╣
║ Layer 3: ACL         ║ setfacl -m g:hr:rwx           ║
║ (Fine-Grained)       ║ Per-user/group granular       ║
║                      ║ control beyond basic Unix     ║
╠══════════════════════╬═══════════════════════════════╣
║ Inheritance: SGID    ║ chmod 2770 = 's' on group     ║
║ + Default ACL        ║ New files → inherit group     ║
║ (Persistence)        ║ New files → inherit ACLs      ║
╚══════════════════════╩═══════════════════════════════╝
```

---

*📝 Lab completed on RHEL 9 | Server: 192.168.174.130 | Client: admin-pc@0xhit*

*🔗 Reference: [Samba Documentation](https://www.samba.org/samba/docs/) | [Linux ACL Man Page](https://man7.org/linux/man-pages/man5/acl.5.html)*
