# 🔐 Linux File System Security — Red Hat / RHEL Guide

> **Series:** Linux Administration | **Chapter:** File System Security **Covers:** `chmod` · `chown` · `chgrp` · Special & Advanced Permissions

---
![[Pasted image 20260413123015.png]]
## 🧠 Understanding Linux Permission Model

Every file and directory in Linux has **three permission categories** and **three permission types**:

```
Category     →   Owner (u)   Group (g)   Others (o)
Permission   →   r  w  x     r  w  x     r  w  x
Octal bit    →   4  2  1     4  2  1     4  2  1
```

|Symbol|Name|On a File|On a Directory|
|---|---|---|---|
|`r`|Read|View file contents|List directory contents|
|`w`|Write|Modify file contents|Create/delete files inside|
|`x`|Execute|Run the file/script|Enter (cd into) directory|
|`-`|None|No permission|No permission|

### 🔍 Reading the Permission String

```bash
$ ls -l /etc/passwd
-rw-r--r--. 1 root root 2847 Apr  1 10:00 /etc/passwd
```

```
- rw- r-- r-- .  1  root  root  2847  Apr 1  /etc/passwd
│ │   │   │   │  │  │     │
│ │   │   │   │  │  │     └── Group owner
│ │   │   │   │  │  └──────── User owner
│ │   │   │   │  └─────────── Hard link count
│ │   │   │   └────────────── SELinux context dot (Red Hat)
│ │   │   └────────────────── Others: read only
│ │   └────────────────────── Group: read only
│ └────────────────────────── Owner: read + write
└──────────────────────────── File type (- = regular file)
```

**File type characters:**

|Char|Type|
|---|---|
|`-`|Regular file|
|`d`|Directory|
|`l`|Symbolic link|
|`b`|Block device|
|`c`|Character device|
|`s`|Socket|
|`p`|Named pipe (FIFO)|

---

## 📁 File & Directory Permissions

### Creating sample files to practice with

```bash
# Create test files and directories
$ mkdir -p /tmp/sectest/project
$ touch /tmp/sectest/file1.txt
$ touch /tmp/sectest/script.sh
$ echo "echo Hello Red Hat" > /tmp/sectest/script.sh

# Check default permissions
$ ls -l /tmp/sectest/
total 4
-rw-rw-r--. 1 adminuser adminuser   19 Apr 13 09:00 script.sh
-rw-rw-r--. 1 adminuser adminuser    0 Apr 13 09:00 file1.txt
drwxrwxr-x. 2 adminuser adminuser    6 Apr 13 09:00 project
```

---

## 🔧 `chmod` — Change File Mode

`chmod` changes **what actions are allowed** on a file or directory.

### Syntax

```bash
chmod [OPTIONS] MODE FILE
```

### 📌 Two Methods: Symbolic & Octal

---

### Method 1️⃣ — Symbolic Mode

Uses letters to represent who (`u`, `g`, `o`, `a`) and what (`+`, `-`, `=`):

```
chmod  [who] [operator] [permission]  file
         u       +           r
         g       -           w
         o       =           x
         a
```

#### Examples — Symbolic Mode

```bash
# Add execute permission for the owner
$ chmod u+x /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwxrw-r--. 1 adminuser adminuser 19 Apr 13 09:00 /tmp/sectest/script.sh
#  ^── owner now has execute

# Remove write permission from group
$ chmod g-w /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwxr--r--. 1 adminuser adminuser 19 Apr 13 09:00 /tmp/sectest/script.sh
#     ^── group write removed

# Add read+write for others
$ chmod o+rw /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-rw-rw-. 1 adminuser adminuser 0 Apr 13 09:00 file1.txt
#        ^^ others now have rw

# Set exact permissions for all using =
$ chmod u=rwx,g=rx,o=r /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwxr-xr--. 1 adminuser adminuser 19 Apr 13 09:00 script.sh

# Apply to all (a) — give everyone read
$ chmod a+r /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-rw-rw-. 1 adminuser adminuser 0 Apr 13 09:00 file1.txt
```

---

### Method 2️⃣ — Octal (Numeric) Mode

Each permission is a **number**: `r=4`, `w=2`, `x=1`. Add them per category.

```
Owner  Group  Others
 rwx    r-x    r--
 4+2+1  4+0+1  4+0+0
  7      5      4
```

#### Common Octal Values

|Octal|Binary|Permissions|
|---|---|---|
|`7`|111|rwx|
|`6`|110|rw-|
|`5`|101|r-x|
|`4`|100|r--|
|`3`|011|-wx|
|`2`|010|-w-|
|`1`|001|--x|
|`0`|000|---|

#### Examples — Octal Mode

```bash
# 755: Owner=rwx, Group=r-x, Others=r-x (common for scripts/dirs)
$ chmod 755 /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwxr-xr-x. 1 adminuser adminuser 19 Apr 13 09:00 script.sh

# 644: Owner=rw-, Group=r--, Others=r-- (common for regular files)
$ chmod 644 /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-r--r--. 1 adminuser adminuser 0 Apr 13 09:00 file1.txt

# 600: Owner=rw-, Group=---, Others=--- (private files like SSH keys)
$ chmod 600 ~/.ssh/id_rsa
$ ls -l ~/.ssh/id_rsa
-rw-------. 1 adminuser adminuser 2590 Apr 13 09:00 /home/adminuser/.ssh/id_rsa

# 700: Owner=rwx, no access for group/others (private scripts)
$ chmod 700 /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwx------. 1 adminuser adminuser 19 Apr 13 09:00 script.sh

# 000: No permissions for anyone
$ chmod 000 /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
----------. 1 adminuser adminuser 0 Apr 13 09:00 file1.txt
```

---

### ♻️ Recursive chmod with `-R`

```bash
# Apply permissions to a directory and ALL contents recursively
$ chmod -R 755 /tmp/sectest/project/

# Verify
$ ls -lR /tmp/sectest/project/
/tmp/sectest/project/:
total 0
drwxr-xr-x. 2 adminuser adminuser 6 Apr 13 09:00 subdir
-rwxr-xr-x. 1 adminuser adminuser 0 Apr 13 09:00 test.sh
```

> ⚠️ **Warning:** Be careful with `-R` on directories containing both files and subdirs — files usually shouldn't have execute permission. Consider using `find` instead:
> 
> ```bash
> # Set 755 for directories only
> find /tmp/sectest -type d -exec chmod 755 {} \;
> # Set 644 for files only
> find /tmp/sectest -type f -exec chmod 644 {} \;
> ```

---

## 👤 `chown` — Change Ownership

`chown` changes the **user owner** (and optionally the **group**) of a file or directory.

### Syntax

```bash
chown [OPTIONS] [USER][:GROUP] FILE
```

> 🔑 Only **root** (or `sudo`) can change file ownership in Red Hat/RHEL.

### Examples

```bash
# Change owner to 'alice'
$ sudo chown alice /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-r--r--. 1 alice adminuser 0 Apr 13 09:00 file1.txt
#             ^── owner changed to alice

# Change owner to 'bob' and group to 'developers'
$ sudo chown bob:developers /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-r--r--. 1 bob developers 0 Apr 13 09:00 file1.txt
#             ^   ^── group also changed

# Change only the group (using chown with colon)
$ sudo chown :sysadmins /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwxr-xr-x. 1 adminuser sysadmins 19 Apr 13 09:00 script.sh
#                        ^── group changed, owner unchanged

# Recursive ownership change
$ sudo chown -R alice:developers /tmp/sectest/project/
$ ls -lR /tmp/sectest/project/
/tmp/sectest/project/:
total 0
-rw-r--r--. 1 alice developers 0 Apr 13 09:00 report.txt
drwxr-xr-x. 2 alice developers 6 Apr 13 09:00 data

# Change owner using UID (numeric)
$ sudo chown 1001 /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-r--r--. 1 alice adminuser 0 Apr 13 09:00 file1.txt
# UID 1001 resolved to 'alice'

# Verify current owner info
$ stat /tmp/sectest/file1.txt
  File: /tmp/sectest/file1.txt
  Size: 0
  Uid: ( 1001/   alice)   Gid: ( 1002/developers)
Access: -rw-r--r--.
```

---

## 👥 `chgrp` — Change Group

`chgrp` changes **only the group** ownership of a file or directory.

### Syntax

```bash
chgrp [OPTIONS] GROUP FILE
```

### Examples

```bash
# Change group of a single file
$ sudo chgrp webteam /tmp/sectest/file1.txt
$ ls -l /tmp/sectest/file1.txt
-rw-r--r--. 1 alice webteam 0 Apr 13 09:00 file1.txt
#                   ^── group changed to webteam

# Change group of a directory recursively
$ sudo chgrp -R devops /tmp/sectest/project/
$ ls -l /tmp/sectest/
drwxr-xr-x. 3 adminuser devops 45 Apr 13 09:00 project

# Using group ID (GID) instead of name
$ sudo chgrp 1005 /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwxr-xr-x. 1 adminuser devops 19 Apr 13 09:00 script.sh

# Verify the group change
$ stat /tmp/sectest/script.sh | grep Gid
  Uid: ( 1000/adminuser)   Gid: ( 1005/   devops)
```

### 🆚 `chown` vs `chgrp` — When to use which?

|Task|Command|
|---|---|
|Change owner only|`chown alice file`|
|Change group only|`chgrp devops file` OR `chown :devops file`|
|Change owner AND group|`chown alice:devops file`|

---

## ⭐ Special / Advanced Permissions

Beyond standard `rwx`, Linux provides **three special permission bits** that enable powerful (and potentially dangerous) behaviors.

```
Special Bits  →   SUID    SGID    Sticky
Octal         →    4       2        1
Position      →  before owner/group/others octal
```

---

### 1️⃣ SUID — Set User ID

**On executable files:** When a user runs the file, it executes with the **file owner's privileges** (not the running user's).

**On directories:** Has no standard effect (ignored in most cases).

#### How to Identify SUID

```bash
# An 's' in the owner execute position means SUID is set
$ ls -l /usr/bin/passwd
-rwsr-xr-x. 1 root root 32648 Apr  1 08:00 /usr/bin/passwd
#   ^── 's' here = SUID is set (owner execute bit replaced by 's')
```

#### Setting SUID

```bash
# Create a test script
$ cp /usr/bin/id /tmp/sectest/myid
$ ls -l /tmp/sectest/myid
-rwxr-xr-x. 1 root root 37360 Apr 13 09:10 /tmp/sectest/myid

# Set SUID using symbolic mode
$ sudo chmod u+s /tmp/sectest/myid
$ ls -l /tmp/sectest/myid
-rwsr-xr-x. 1 root root 37360 Apr 13 09:10 /tmp/sectest/myid
#   ^── 's' = SUID active

# Set SUID using octal (4 prefix)
$ sudo chmod 4755 /tmp/sectest/myid
$ ls -l /tmp/sectest/myid
-rwsr-xr-x. 1 root root 37360 Apr 13 09:10 /tmp/sectest/myid

# Remove SUID
$ sudo chmod u-s /tmp/sectest/myid
$ ls -l /tmp/sectest/myid
-rwxr-xr-x. 1 root root 37360 Apr 13 09:10 /tmp/sectest/myid
```

> ⚠️ **Capital 'S' warning:** If SUID is set but execute is NOT set for owner, you'll see `S` (capital) — meaning SUID is set but ineffective.
> 
> ```bash
> $ sudo chmod 4644 /tmp/sectest/myid
> $ ls -l /tmp/sectest/myid
> -rwSr--r--. 1 root root 37360 Apr 13 09:10 /tmp/sectest/myid
> #   ^── Capital S = SUID set but NO execute permission (ineffective!)
> ```

#### 🔍 Find all SUID files on system

```bash
$ sudo find / -perm -4000 -type f 2>/dev/null
/usr/bin/chage
/usr/bin/gpasswd
/usr/bin/newgrp
/usr/bin/su
/usr/bin/passwd
/usr/bin/sudo
/usr/sbin/unix_chkpwd
```

> 🛡️ **Security Tip:** Regularly audit SUID files. An unexpected SUID binary can be a sign of compromise.

---

### 2️⃣ SGID — Set Group ID

**On executable files:** The process runs with the **group** of the file, not the user's group.

**On directories (most common use):** Files created inside the directory **inherit the directory's group** automatically.

#### How to Identify SGID

```bash
# An 's' in the GROUP execute position means SGID is set
$ ls -l /usr/bin/write
-rwxr-sr-x. 1 root tty 19544 Apr  1 08:00 /usr/bin/write
#      ^── 's' here = SGID is set

# On a directory
$ ls -ld /var/log/journal
drwxr-sr-x. 3 root systemd-journal 60 Apr 13 09:00 /var/log/journal
#      ^── SGID on directory: new files inherit group 'systemd-journal'
```

#### Setting SGID — Collaborative Directory Example

```bash
# Create a shared project directory
$ sudo mkdir /srv/shared-project
$ sudo chown root:developers /srv/shared-project
$ sudo chmod 2775 /srv/shared-project        # 2 = SGID
$ ls -ld /srv/shared-project
drwxrwsr-x. 2 root developers 6 Apr 13 09:15 /srv/shared-project
#      ^── 's' in group position = SGID active

# Now any file created inside inherits 'developers' group
$ su - alice
$ touch /srv/shared-project/alice-notes.txt
$ ls -l /srv/shared-project/alice-notes.txt
-rw-rw-r--. 1 alice developers 0 Apr 13 09:16 alice-notes.txt
#                  ^── auto-inherited 'developers' group!

# Set SGID using symbolic mode
$ sudo chmod g+s /srv/shared-project

# Remove SGID
$ sudo chmod g-s /srv/shared-project
```

#### 🔍 Find all SGID files/directories

```bash
$ sudo find / -perm -2000 -type f 2>/dev/null
/usr/bin/wall
/usr/bin/write
/usr/sbin/postdrop
/usr/sbin/postqueue

$ sudo find / -perm -2000 -type d 2>/dev/null
/var/log/journal
/run/log/journal
```

---

### 3️⃣ Sticky Bit

**On directories:** Only the **file owner**, the **directory owner**, or **root** can delete or rename files inside — even if others have write permission.

**On files:** Legacy/ignored on modern Linux kernels.

> 📌 **Classic example:** `/tmp` — everyone can write there, but you can only delete YOUR OWN files.

#### How to Identify Sticky Bit

```bash
# A 't' in the OTHERS execute position means Sticky Bit is set
$ ls -ld /tmp
drwxrwxrwt. 24 root root 4096 Apr 13 09:00 /tmp
#        ^── 't' = Sticky Bit set (others can write but not delete others' files)
```

#### Setting Sticky Bit

```bash
# Create a shared upload directory
$ sudo mkdir /srv/uploads
$ sudo chmod 1777 /srv/uploads       # 1 = sticky bit
$ ls -ld /srv/uploads
drwxrwxrwt. 2 root root 6 Apr 13 09:20 /srv/uploads
#        ^── 't' = Sticky Bit active

# Set Sticky Bit using symbolic mode
$ sudo chmod o+t /srv/uploads

# Demonstration: alice creates a file, bob cannot delete it
$ su - alice
$ touch /srv/uploads/alice-file.txt

$ su - bob
$ rm /srv/uploads/alice-file.txt
rm: cannot remove '/srv/uploads/alice-file.txt': Operation not permitted
# ✅ Sticky bit works — bob cannot delete alice's file!

# Remove Sticky Bit
$ sudo chmod o-t /srv/uploads
$ ls -ld /srv/uploads
drwxrwxrwx. 2 root root 6 Apr 13 09:25 /srv/uploads
#        ^── 'x' instead of 't' = sticky bit removed
```

> ⚠️ **Capital 'T' warning:** Like SUID/SGID, if sticky bit is set but others have NO execute permission, you see `T` (capital).
> 
> ```bash
> $ sudo chmod 1666 /srv/uploads
> $ ls -ld /srv/uploads
> drwxrwxrwT. 2 root root 6 Apr 13 09:25 /srv/uploads
> #        ^── Capital T = sticky set but no execute for others (unusual)
> ```

---

### 🧮 Special Permissions — Octal Summary

```
Full Octal:  [special][owner][group][others]
              [0-7]   [0-7]  [0-7]  [0-7]
```

|Bit|Symbolic|Octal|Effect|
|---|---|---|---|
|SUID|`u+s`|4xxx|Execute as file's owner|
|SGID|`g+s`|2xxx|Execute as file's group / inherit group in dirs|
|Sticky|`o+t`|1xxx|Only owner can delete their files in shared dirs|
|All 3|—|7xxx|All special bits set|

#### Combined Example

```bash
# SUID + SGID + Sticky on a file = 7755
$ sudo chmod 7755 /tmp/sectest/script.sh
$ ls -l /tmp/sectest/script.sh
-rwsrwsr-t. 1 root root 19 Apr 13 09:30 script.sh
#   ^ ^  ^── All three special bits set

# SGID + Sticky on a shared directory = 3775
$ sudo chmod 3775 /srv/shared-project
$ ls -ld /srv/shared-project
drwxrwsr-t. 2 root developers 6 Apr 13 09:30 /srv/shared-project
#      ^  ^── SGID + Sticky
```

---

## 🎭 `umask` — Default Permission Mask

`umask` defines the **default permissions removed** when new files/directories are created.

```
Maximum permissions:   666 (files)   777 (directories)
umask value:         - 022          - 022
                     ─────          ─────
Result:                644            755
```

```bash
# Check current umask
$ umask
0022

# Check with symbolic output
$ umask -S
u=rwx,g=rx,o=rx

# Create file and directory to see defaults
$ touch /tmp/newfile.txt
$ mkdir /tmp/newdir
$ ls -ld /tmp/newfile.txt /tmp/newdir
-rw-r--r--. 1 adminuser adminuser 0 Apr 13 09:35 /tmp/newfile.txt
drwxr-xr-x. 2 adminuser adminuser 6 Apr 13 09:35 /tmp/newdir

# Change umask for the session
$ umask 027
$ touch /tmp/securefile.txt
$ ls -l /tmp/securefile.txt
-rw-r-----. 1 adminuser adminuser 0 Apr 13 09:36 /tmp/securefile.txt
#         ^── no permissions for others!

# Restore default
$ umask 022
```

### Setting Permanent umask in Red Hat

```bash
# For a specific user — edit their shell profile
$ echo "umask 027" >> ~/.bashrc

# System-wide — edit /etc/profile or /etc/bashrc
$ sudo echo "umask 022" >> /etc/profile

# For specific user in /etc/login.defs
$ grep UMASK /etc/login.defs
UMASK           022
```

---

## 🔎 Checking Permissions at a Glance

```bash
# ls -l — standard permission listing
$ ls -l /tmp/sectest/
total 8
-rwxr-xr-x. 1 alice  developers 19 Apr 13 09:00 script.sh
-rw-r--r--. 1 alice  developers  0 Apr 13 09:00 file1.txt
drwxrwsr-t. 2 root   developers  6 Apr 13 09:00 project

# stat — detailed permission information
$ stat /tmp/sectest/script.sh
  File: /tmp/sectest/script.sh
  Size: 19
  Blocks: 8
  IO Block: 4096   regular file
Device: fd00h/64768d    Inode: 134518     Links: 1
Access: (0755/-rwxr-xr-x)  Uid: ( 1001/   alice)   Gid: ( 1002/developers)
Access: 2024-04-13 09:00:00.000000000 +0000
Modify: 2024-04-13 09:00:00.000000000 +0000
Change: 2024-04-13 09:00:00.000000000 +0000
 Birth: -

# find by permission — find world-writable files (security audit)
$ sudo find /etc -perm -002 -type f 2>/dev/null
# (should return nothing in a secure system)

# find files with no owner (orphaned — security risk)
$ sudo find / -nouser -o -nogroup 2>/dev/null

# getfacl — view ACL (Access Control List) permissions
$ getfacl /tmp/sectest/script.sh
# file: tmp/sectest/script.sh
# owner: alice
# group: developers
user::rwx
group::r-x
other::r-x
```

---

## 📊 Quick Reference Cheat Sheet

### chmod Octal Permissions

|Octal|Permissions|Use Case|
|---|---|---|
|`777`|rwxrwxrwx|⚠️ All access (avoid!)|
|`755`|rwxr-xr-x|Scripts, public directories|
|`750`|rwxr-x---|Group-accessible scripts|
|`700`|rwx------|Private scripts/directories|
|`644`|rw-r--r--|Regular files, configs|
|`640`|rw-r-----|Group-readable configs|
|`600`|rw-------|Private files (SSH keys, etc.)|
|`444`|r--r--r--|Read-only for all|
|`400`|r--------|Read-only, owner only|

### Special Permission Octal Reference

|Octal|Special Bit|Description|
|---|---|---|
|`4755`|SUID + 755|Runs as file owner|
|`2755`|SGID + 755|Group inherited in directories|
|`1777`|Sticky + 777|Shared dir, owner-delete only|
|`3775`|SGID+Sticky|Collaborative shared directory|

### Command Summary

```bash
# ── chmod ──────────────────────────────────────────────────
chmod 755 file              # Octal: owner=rwx, group=rx, other=rx
chmod u+x file              # Add execute for owner
chmod g-w file              # Remove write from group
chmod o=r file              # Set others to read only
chmod a+r file              # Add read for all
chmod -R 755 directory/     # Recursive

# ── chown ──────────────────────────────────────────────────
chown alice file            # Change owner to alice
chown alice:devs file       # Change owner + group
chown :devs file            # Change group only
chown -R alice:devs dir/    # Recursive

# ── chgrp ──────────────────────────────────────────────────
chgrp devs file             # Change group to devs
chgrp -R devs dir/          # Recursive

# ── Special Permissions ────────────────────────────────────
chmod u+s file              # Set SUID
chmod g+s dir               # Set SGID (on directory)
chmod o+t dir               # Set Sticky Bit
chmod 4755 file             # SUID via octal
chmod 2775 dir              # SGID via octal
chmod 1777 dir              # Sticky via octal

# ── Find Special Permission Files ─────────────────────────
find / -perm -4000 -type f  # All SUID files
find / -perm -2000 -type f  # All SGID files
find / -perm -1000 -type d  # All Sticky directories
```

---

## 🛡️ Security Best Practices (Red Hat / RHEL)

1. **🔍 Audit SUID/SGID files regularly** — unexpected binaries may indicate compromise
2. **🚫 Avoid world-writable files** — `chmod o-w` on any file that doesn't need it
3. **📁 Use SGID on shared directories** — ensures group collaboration without ownership issues
4. **📌 Use Sticky Bit on shared writable dirs** — prevents accidental/malicious file deletion
5. **🔒 Restrict `/tmp` and `/var/tmp`** — ensure sticky bit is always set (`chmod 1777`)
6. **👤 Apply least privilege** — give only the minimum permissions needed
7. **🔑 Protect sensitive files** — SSH private keys at `600`, config files at `640` or `644`
8. **🔎 Use `find` for permission audits** — regularly scan for over-permissive files

```bash
# Quick security audit commands
$ sudo find / -perm -4000 2>/dev/null | sort   # SUID audit
$ sudo find / -perm -0002 -type f 2>/dev/null   # World-writable files
$ sudo find / -nouser 2>/dev/null               # Orphaned files (no owner)
$ sudo find / -nogroup 2>/dev/null              # Orphaned files (no group)
```

---

## 📚 Related Topics

- 🔐 **SELinux** — Mandatory Access Control (MAC) — adds another security layer in Red Hat
- 📋 **ACL (Access Control Lists)** — `setfacl` / `getfacl` — fine-grained permissions beyond `rwx`
- 🗂️ **Extended Attributes** — `chattr` / `lsattr` — immutable files, append-only logs
- 👥 **User & Group Management** — Previous chapter covering `useradd`, `groupadd`, `passwd`

---

> 📝 **Author Note:** All examples tested on **Red Hat Enterprise Linux 9 (RHEL 9)**. Commands are compatible with **CentOS Stream**, **Rocky Linux**, and **AlmaLinux**.

---

_⭐ If this guide helped you, consider starring the repository!_