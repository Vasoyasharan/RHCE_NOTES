# 🔐 Linux ACL (Access Control List) — Complete Deep Dive Guide

> 📌 A practical, hands-on guide to understanding and managing ACLs in Linux with real command examples and outputs.

---

## 🧠 What is ACL? <a name="what-is-acl"></a>

**ACL (Access Control List)** is an extended permission system in Linux that allows you to give **specific permissions to specific users or groups** on a file or directory — **beyond** the traditional owner/group/others model.

### 🔵 Traditional Linux Permissions (Limited)

```
drwxr-xr-x  amit IT  itdata/
```

With standard permissions, you can only set:

- **Owner** permissions
- **Group** permissions
- **Others** permissions

### 🟢 ACL (Fine-Grained Control)

With ACL, you can say:

- `user1` → `rw-` (read & write only)
- `user2` → `rwx` (full access)
- `user3` → `r--` (read only)
- `group1` → `r-x`
- `group2` → `rwx`
- Everyone else (others) → `r--`

> 💡 **Real-world analogy**: Think of ACL like a VIP guest list at a club. Standard permissions = only 3 categories (owner, group, public). ACL = individual names on the list with their own specific access level.

---

## ❓ Why ACL over Standard Permissions? <a name="why-acl"></a>

|Feature|Standard Permissions|ACL|
|---|---|---|
|Control per user|❌ No|✅ Yes|
|Control per group|❌ Only 1 group|✅ Multiple groups|
|Inheritance for new files|❌ No|✅ Yes (with defaults)|
|Fine-grained access|❌ Limited|✅ Full control|

---

## 🛠️ Key Commands: setfacl & getfacl <a name="key-commands"></a>

### `setfacl` — Set/Modify ACL

```bash
setfacl <options> <arguments> <file/folder>
```

|Option|Meaning|
|---|---|
|`-m`|**Modify** — add or update an ACL entry|
|`-x`|**Remove** — delete a specific ACL entry|
|`-b`|**Remove all** ACL entries|
|`-R`|**Recursive** — apply to all files/folders inside|
|`-d`|**Default** — set default ACL (inherited by new files)|
|`u:username:perms`|Set for a **specific user**|
|`g:groupname:perms`|Set for a **specific group**|
|`o:perms`|Set for **others**|
|`m:perms`|Set the **mask**|

### `getfacl` — View ACL

```bash
getfacl <file/folder>
```

---

## 👥 Setup: Create Users & Groups <a name="setup"></a>

### Step 1 — Create 3 Users

```bash
[root@server1 quota]# useradd user1
[root@server1 quota]# useradd user2
[root@server1 quota]# useradd user3
```

Set passwords for each:

```bash
[root@server1 quota]# passwd user1
Changing password for user user1.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.

[root@server1 quota]# passwd user2
Changing password for user user2.
New password:
passwd: all authentication tokens updated successfully.

[root@server1 quota]# passwd user3
Changing password for user user3.
New password:
passwd: all authentication tokens updated successfully.
```

### Step 2 — Create 3 Groups

```bash
[root@server1 quota]# groupadd group1
[root@server1 quota]# groupadd group2
[root@server1 quota]# groupadd group3
```

### Step 3 — Create a Directory & Set Ownership

```bash
[root@server1 quota]# mkdir dir1
[root@server1 quota]# chown amit:IT dir1
[root@server1 quota]# ll
total 12
drwxr-xr-x. 2 amit IT    4096 Apr 11 07:40 dir1
drwxrws--T. 3 amit IT    4096 Apr 10 08:55 itdata
drwxr-xr-x. 2 root root  4096 Apr  9 08:35 root1
```

---

## 👤 Set ACL on Users <a name="set-acl-users"></a>

### Set permissions for user1 → `rw-`

```bash
[root@server1 quota]# setfacl -m u:user1:rw- dir1
```

### Set permissions for user2 → `rwx`

```bash
[root@server1 quota]# setfacl -m u:user2:rwx dir1
```

### Set permissions for user3 → `r--`

```bash
[root@server1 quota]# setfacl -m u:user3:r-- dir1
```

### Verify with getfacl

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/
# owner: amit
# group: IT
user::rwx          ← Owner (amit) has full access
user:user1:rw-     ← user1 can read & write only
user:user2:rwx     ← user2 has full access
user:user3:r--     ← user3 can only read
group::r-x         ← IT group has read & execute
mask::rwx          ← Mask (max effective permissions)
other::r-x         ← Everyone else: read & execute
```

> 🔔 Notice the `+` sign in `ll` output — it indicates ACL is set on the directory:

```bash
drwxrwxr--+ 2 amit IT  4096 Apr 11 07:40 dir1
```

---

## 👥 Set ACL on Groups <a name="set-acl-groups"></a>

### Set permissions for group1 → `r-x`

```bash
[root@server1 quota]# setfacl -m g:group1:r-x dir1
```

### Set permissions for group2 → `rwx`

```bash
[root@server1 quota]# setfacl -m g:group2:rwx dir1
```

### Verify

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/
# owner: amit
# group: IT
user::rwx
user:user1:rw-
user:user2:rwx
user:user3:r--
group::r-x
group:group1:r-x    ← group1 can read & execute
group:group2:rwx    ← group2 has full access
mask::rwx
other::r-x
```

---

## 🌍 Set ACL on Others <a name="set-acl-others"></a>

### Restrict others to read-only

```bash
[root@server1 quota]# setfacl -m o:r-- dir1
```

### Verify

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/
# owner: amit
# group: IT
user::rwx
user:user1:rw-
user:user2:rwx
user:user3:r--
group::r-x
group:group1:r-x
group:group2:rwx
mask::rwx
other::r--          ← Others now only have read access
```

---

## ➕➖ Add & Remove ACL Entries <a name="add-remove"></a>

### ➕ Add a new user ACL entry

```bash
[root@server1 quota]# setfacl -m u:user1:rwx dir1
```

### ➕ Add a new group ACL entry

```bash
[root@server1 quota]# setfacl -m g:group3:r-- dir1
```

### ➖ Remove a specific user's ACL

```bash
[root@server1 quota]# setfacl -x u:user1 dir1/
```

Output after removing user1:

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/
# owner: amit
# group: IT
user::rwx
user:user2:rwx      ← user1 is GONE
user:user3:r--
group::r-x
group:group1:r-x
group:group2:rwx
mask::rwx
other::r--
```

### ➖ Remove a specific group's ACL

```bash
[root@server1 quota]# setfacl -x g:group3 dir1/
```

### 🗑️ Remove ALL ACL entries (reset to standard permissions)

```bash
[root@server1 quota]# setfacl -b dir1/
```

> ⚠️ **Warning**: `-b` removes everything including defaults. Use carefully!

---

## 🔁 Recursive ACL <a name="recursive-acl"></a>

Apply ACL to a directory **and all its contents** (files and subdirectories):

```bash
[root@server1 quota]# setfacl -R -m u:user2:rwx dir1/
```

This sets `user2:rwx` on:

- `dir1/` itself
- `dir1/folder1/`
- `dir1/folder1/file1` (if any)
- All nested contents

### Verify recursive application

```bash
[root@server1 quota]# getfacl dir1/folder1/
# file: dir1/folder1/
# owner: user2
# group: user2
user::rwx
user:user1:rwx      ← Inherited from parent via -R
group::r-x
mask::rwx
other::r--
default:user::rwx
default:user:user1:rwx
default:group::r-x
default:mask::rwx
default:other::r--
```

> 💡 **Tip**: Use `-R` whenever you want your ACL settings to apply to all existing files and directories inside a folder.

---

## 🧬 Default ACL (Inherited Permissions) <a name="default-acl"></a>

### 🤔 What is Default ACL?

**Default ACL** is a special ACL setting on a **directory** that automatically gets **inherited** by any **new files or subdirectories** created inside it.

Without default ACL → new files get standard umask permissions only.  
With default ACL → new files automatically inherit defined ACL rules.

### Setting Default ACL

```bash
[root@server1 quota]# setfacl -m d:u:user1:rwx dir1/
```

> 🔑 The `d:` prefix stands for **default**

### Verify Default ACL

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/
# owner: amit
# group: IT
user::rwx
user:user1:rw-
user:user2:rwx
user:user3:r--
group::r-x
group:group1:r-x
group:group2:rwx
mask::rwx
other::r--
default:user::rwx           ← Default for owner
default:user:user1:rwx      ← Default: user1 gets rwx on NEW files
default:group::r-x          ← Default for group
default:mask::rwx           ← Default mask
default:other::r--          ← Default for others
```

### 🔬 How Default ACL Works — Live Demo

```bash
# As user2, create a new folder inside dir1
[user2@server1 dir1]$ mkdir folder1
[user2@server1 dir1]$ ll
total 8
drwxrwxr--+ 2 user2 user2  4096 Apr 11 08:10 folder1
```

```bash
# As root, check ACL of the newly created folder1
[root@server1 quota]# getfacl dir1/folder1/
# file: dir1/folder1/
# owner: user2
# group: user2
user::rwx
user:user1:rwx      ← ✅ Automatically inherited from dir1's default ACL!
group::r-x
mask::rwx
other::r--
default:user::rwx
default:user:user1:rwx
default:group::r-x
default:mask::rwx
default:other::r--
```

> 🎯 **Key Point**: `folder1` was **newly created** by user2, yet it **automatically got** `user:user1:rwx` because of the **default ACL** set on the parent `dir1/`. This is the power of default ACL!

### Remove Default ACL

```bash
# Remove a specific default entry
[root@server1 quota]# setfacl -x d:u:user1 dir1/

# Remove ALL default ACL entries
[root@server1 quota]# setfacl -k dir1/
```

---

## 🎭 Mask (Maximum Allowed Permissions) <a name="mask"></a>

### 🤔 What is Mask?

The **mask** defines the **maximum effective permissions** that can be granted to:

- Named users (except the owner)
- Named groups
- The owning group

> 💡 Think of mask as a **ceiling** or **cap** on permissions. Even if you set `user1:rwx`, if the mask is `r--`, the **effective permission** for user1 will only be `r--`.

### How Mask Works

```
user1 ACL:   rwx
mask:        r--
─────────────────
Effective:   r--   ← AND of user1's ACL and mask
```

The effective permission = (user's ACL) **AND** (mask)

### Viewing the Mask

```bash
[root@server1 quota]# getfacl dir1/
...
mask::rwx       ← Current mask allows rwx maximum
...
```

### Setting the Mask

```bash
# Restrict max permissions to read & execute only
[root@server1 quota]# setfacl -m m:r-x dir1/
```

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/
# owner: amit
# group: IT
user::rwx
user:user2:rwx       #effective:r-x   ← Even though user2 has rwx, effective is r-x due to mask!
user:user3:r--
group::r-x
group:group1:r-x
group:group2:rwx     #effective:r-x   ← Same cap applies to group2
mask::r-x            ← Mask is now r-x
other::r--
```

> ⚠️ **Important**: The mask does NOT affect:
> 
> - The **owner** (amit) — always uses their standard permissions
> - **Others** — always uses their standard permissions
> - Only affects named users, named groups, and owning group

### Restore Full Mask

```bash
[root@server1 quota]# setfacl -m m:rwx dir1/
```

> 🔔 **Auto-recalculation**: When you run `setfacl -m u:user:perms`, the mask is automatically recalculated to be the union of all ACL permissions. To prevent this, use `--no-mask` flag.

---

## 🔍 Verify with getfacl <a name="verify"></a>

### Understanding getfacl Output

```bash
[root@server1 quota]# getfacl dir1/
# file: dir1/           ← File/directory name
# owner: amit           ← Owner of the file
# group: IT             ← Owning group
# flags: -st            ← Special flags (s=setuid/setgid, t=sticky bit)
user::rwx               ← Owner's permissions
user:user1:rw-          ← Named user ACL
user:user2:rwx          ← Named user ACL
user:user3:r--          ← Named user ACL
group::r-x              ← Owning group permissions
group:group1:r-x        ← Named group ACL
group:group2:rwx        ← Named group ACL
mask::rwx               ← Mask (max effective for named users/groups)
other::r--              ← Others permissions
default:user::rwx       ← Default: new files inherit this for owner
default:user:user1:rwx  ← Default: new files inherit this for user1
default:group::r-x      ← Default: new files inherit this for group
default:mask::rwx       ← Default mask for new files
default:other::r--      ← Default: new files inherit this for others
```

### Check ACL is active (`+` sign in ls)

```bash
[root@server1 quota]# ll
drwxrwxr--+ 2 amit IT  4096 Apr 11 07:40 dir1
           ↑
           + means ACL is set on this file/directory
```

---

## 📋 Real World Scenario — Putting It All Together

```bash
# 1. Create directory
mkdir /quota/dir1
chown amit:IT /quota/dir1

# 2. Set user-level ACL
setfacl -m u:user1:rw- dir1     # user1: read & write
setfacl -m u:user2:rwx dir1     # user2: full access
setfacl -m u:user3:r-- dir1     # user3: read only

# 3. Set group-level ACL
setfacl -m g:group1:r-x dir1    # group1: read & execute
setfacl -m g:group2:rwx dir1    # group2: full access

# 4. Restrict others
setfacl -m o:r-- dir1           # others: read only

# 5. Set mask (cap max permissions)
setfacl -m m:rwx dir1           # allow up to rwx

# 6. Set default ACL (for new files/folders created inside dir1)
setfacl -m d:u:user1:rwx dir1
setfacl -m d:g:group1:r-x dir1

# 7. Apply everything recursively to existing contents
setfacl -R -m u:user2:rwx dir1

# 8. Remove a specific user's ACL
setfacl -x u:user1 dir1

# 9. Remove all ACL entries
setfacl -b dir1
```

---

## ⚡ Quick Reference Cheat Sheet <a name="cheatsheet"></a>

```bash
# ─── VIEW ────────────────────────────────────────────────
getfacl file/dir                    # View ACL of file or directory

# ─── SET USER ACL ────────────────────────────────────────
setfacl -m u:user1:rw- dir1        # user1 → read & write
setfacl -m u:user2:rwx dir1        # user2 → full access
setfacl -m u:user3:r-- dir1        # user3 → read only

# ─── SET GROUP ACL ───────────────────────────────────────
setfacl -m g:group1:r-x dir1       # group1 → read & execute
setfacl -m g:group2:rwx dir1       # group2 → full access

# ─── SET OTHERS ──────────────────────────────────────────
setfacl -m o:r-- dir1              # others → read only

# ─── SET MASK ────────────────────────────────────────────
setfacl -m m:r-x dir1              # mask → max is r-x

# ─── DEFAULT ACL (Inheritance) ───────────────────────────
setfacl -m d:u:user1:rwx dir1      # new files inherit user1:rwx
setfacl -m d:g:group1:r-x dir1     # new files inherit group1:r-x
setfacl -k dir1                    # remove all default ACL

# ─── RECURSIVE ───────────────────────────────────────────
setfacl -R -m u:user1:rwx dir1     # apply to dir1 and all contents

# ─── REMOVE ──────────────────────────────────────────────
setfacl -x u:user1 dir1            # remove user1's ACL entry
setfacl -x g:group1 dir1           # remove group1's ACL entry
setfacl -x d:u:user1 dir1          # remove user1's default ACL
setfacl -b dir1                    # remove ALL ACL entries (nuclear!)
```

---

## 🧩 Common Confusions — Cleared!

|❓ Confusion|✅ Answer|
|---|---|
|Does `-R` apply to future files?|❌ No. Use `-d` (default ACL) for future files|
|Does mask affect the owner?|❌ No. Owner always uses standard permissions|
|Does mask affect others?|❌ No. Others always use standard permissions|
|What does `+` in `ll` mean?|✅ ACL is set on the file/directory|
|Can mask be set lower than existing ACLs?|✅ Yes, it overrides effective permissions|
|Does `-b` remove default ACL too?|✅ Yes, `-b` removes everything|

---

## 🧪 Testing ACL as a User

```bash
# Switch to user1
su - user1

# Try to access dir1 (user1 has rw- but no execute/enter)
cd /quota/dir1
-bash: cd: dir1/: Permission denied   ← No 'x' permission!

# Switch to user2 (has rwx)
su - user2
cd /quota/dir1                         ← ✅ Works!
mkdir folder1                          ← ✅ Works! (user2 has write + execute)
```

> 💡 **Remember**: To **enter a directory**, you need **execute (`x`)** permission. Even if you have `rw-`, you cannot `cd` into it!

---

## 📦 Prerequisites

Make sure ACL is enabled on your filesystem. Check with:

```bash
mount | grep acl        # Look for 'acl' in mount options

# Or check /etc/fstab — add 'acl' option if missing:
/dev/sda1  /  ext4  defaults,acl  0 1
```

Install ACL tools if not present:

```bash
# RHEL/CentOS/Rocky
yum install acl

# Ubuntu/Debian
apt install acl
```

---

_📝 Guide based on live Linux lab session on Rocky Linux / RHEL 8+_  
_🔗 Commands tested on server1 with kernel ACL support enabled_