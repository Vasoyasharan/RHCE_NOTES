
---

# 📦 RPM Command Structure

```bash
rpm [OPTIONS] [PACKAGE]
```
![](https://www.redhat.com/rhdc/managed-files/sysadmin/2020-04/p2.png)

---

- The **_RPM Package Manager_** (RPM) is an open packaging system, which runs on Red Hat Enterprise Linux as well as other Linux and UNIX systems.

# 🧠 1. INSTALL / UPGRADE OPTIONS (Package Management)

## 🔹 Install

```bash
rpm -ivh package.rpm
```

## 🔹 Upgrade

```bash
rpm -Uvh package.rpm
```

## 🔹 Fresh Install (fail if already installed)

```bash
rpm -ivh --replacepkgs package.rpm
```

---

## 🔥 Important Flags

|Option|Meaning|
|---|---|
|`-i`|Install|
|`-U`|Upgrade|
|`-v`|Verbose|
|`-h`|Progress bar|
|`--force`|Force install|
|`--nodeps`|Ignore dependencies ⚠️|
|`--replacepkgs`|Reinstall|
|`--replacefiles`|Overwrite files|
|`--test`|Dry run (no install)|

---

# ❌ 2. REMOVE OPTIONS

```bash
rpm -e package_name
```

### Flags:

|Option|Meaning|
|---|---|
|`-e`|Erase/remove|
|`--nodeps`|Remove without dependency check ⚠️|

---

# 🔍 3. QUERY OPTIONS (MOST USED 🔥)

## 🔹 Basic Queries

```bash
rpm -q package
rpm -qa
```

## 🔹 Detailed Queries

|Command|Meaning|
|---|---|
|`rpm -qi pkg`|Package info|
|`rpm -ql pkg`|List files|
|`rpm -qc pkg`|Config files|
|`rpm -qd pkg`|Documentation|
|`rpm -qf /path/file`|Find package of file|
|`rpm -qp file.rpm`|Query rpm file (not installed)|

---

## 🔥 Advanced Query

```bash
rpm -q --whatprovides /usr/sbin/httpd
rpm -q --whatrequires package
```

---

# 🔐 4. VERIFY OPTIONS (Security 🔥)

```bash
rpm -V package
```

👉 Checks:

- File size
    
- Permissions
    
- MD5 checksum
    
- Ownership
    

---

# 📦 5. PACKAGE FILE OPTIONS (Before Install)

- software information
```bash
rpm -qip package.rpm   # Info
rpm -qlp package.rpm   # Files inside
```

---

# 🔑 6. SIGNATURE / SECURITY

```bash
rpm -K package.rpm
```

👉 Verify signature

---

# 📂 7. DATABASE OPTIONS

|Command|Meaning|
|---|---|
|`rpm --rebuilddb`|Rebuild rpm DB|
|`rpm --initdb`|Initialize DB|

---

# 📊 8. SCRIPT & DEBUG OPTIONS (Advanced)

|Option|Meaning|
|---|---|
|`--scripts`|Show install scripts|
|`--test`|Test install|
|`--noscripts`|Skip scripts|

---

# ⚠️ 9. DANGEROUS OPTIONS (Use carefully 💀)

|Option|Risk|
|---|---|
|`--nodeps`|Break system|
|`--force`|Overwrite everything|
|`--noscripts`|Skip critical setup|

---
# 10 Find directory where install package

```
which vsftpd
rpm -qf /sbin/vsftpd
```
## ✅ Output

`vsftpd-3.0.5-6.el9.x86_64`

👉 Meaning:

- File belongs to `vsftpd` package
- Version + architecture shown


---


# 🧠 Real Understanding (Not Memorization)

👉 RPM works in **4 modes**:

1. Install / Upgrade
    
2. Remove
    
3. Query
    
4. Verify
    

If you understand these → you don’t need to memorize everything

---

# 🧪 What You Should Practice NOW

Run these:

```bash
rpm -qa | head
rpm -qi bash
rpm -ql bash
rpm -qf /etc/passwd
rpm -V bash
```

---

# 🧠 Interview Killer Answer

If asked:

> Explain RPM options

👉 Say this (clean answer):

✔ RPM has 4 main functions: install, remove, query, verify  
✔ `-i`, `-U`, `-e` for package management  
✔ `-q` for querying  
✔ `-V` for verification  
✔ Supports flags like `--nodeps`, `--force`, `--test`

---
Good — now you’re hitting **danger zone + real admin usage** 🔥  
I’ll break each command with **what it REALLY does + when you should/shouldn’t use it** ⚠️

---

# ⚠️ 1. `rpm -ivh [pkg] --force`

```bash
rpm -ivh package.rpm --force
```

## 🧠 What it does

👉 Forces installation even if:

- Package already installed
    
- File conflicts exist
    

---

## 💀 Reality

- Overwrites files blindly
    
- Can break working apps
    
- Can corrupt dependencies
    

---

## ✅ When to use

✔ Reinstall broken package  
✔ Fix corrupted files

---

## ❌ When NOT to use

❌ Normal installation  
❌ Production system without reason

---

# ☠️ 2. `rpm -ivh [pkg] --nodeps`

```bash
rpm -ivh package.rpm --nodeps
```

## 🧠 What it does

👉 Ignores dependency checks completely

---

## 💀 Reality

- Installs incomplete software
    
- App may crash immediately
    
- Creates dependency hell
    

---

## ✅ When to use

✔ Lab/testing  
✔ Debugging broken system

---

## ❌ Never in real production

👉 This is how people destroy servers

---

# 📦 3. `rpm -ql vsftpd`

```bash
rpm -ql vsftpd
```

## 🧠 What it does

👉 Lists ALL files installed by vsftpd

---

## ✅ Example output

```bash
/usr/sbin/vsftpd
/etc/vsftpd/vsftpd.conf
/usr/lib/systemd/system/vsftpd.service
```

---

## 🔥 Why important

- Find config files
    
- Find service files
    
- Debug missing files
    

---

# 🔍 4. `rpm -ql vsftpd | grep etc`

```bash
rpm -ql vsftpd | grep etc
```

## 🧠 What it does

👉 Filters only config-related files

---

## ✅ Output

```bash
/etc/vsftpd/vsftpd.conf
/etc/logrotate.d/vsftpd
```

---

## 🔥 Real use

👉 Quickly locate config files instead of searching manually

---

# 🔐 5. `rpm -V vsftpd`

```bash
rpm -V vsftpd
```

## 🧠 What it does

👉 Verifies package integrity

---

## 🔍 Checks:

- File size
    
- Permissions
    
- Ownership
    
- MD5 checksum
    

---

## ✅ Output Cases

### ✔ No output

👉 Everything is intact

---

### ⚠️ If modified:

```bash
S.5....T /etc/vsftpd/vsftpd.conf
```

---

## 🧠 Meaning of codes

|Code|Meaning|
|---|---|
|S|Size changed|
|M|Mode (permissions) changed|
|5|Checksum changed|
|T|Timestamp changed|

---

# 💀 Real Scenario (Important)

👉 If someone edits config:

```bash
vi /etc/vsftpd/vsftpd.conf
```

Then:

```bash
rpm -V vsftpd
```

👉 You’ll detect changes instantly

---

# 🧠 Big Picture (Understand this)

|Command|Purpose|Risk|
|---|---|---|
|`--force`|Override conflicts|⚠️ Medium|
|`--nodeps`|Ignore dependencies|☠️ High|
|`-ql`|List files|✅ Safe|
|`-V`|Verify integrity|🔥 Powerful|

---

# ⚠️ Brutal Reality

If you:

- Use `--nodeps` casually → ❌ reject
    
- Use `--force` without reason → ❌ reject
    
- Don’t know `rpm -V` → ❌ weak admin
    

---

# 🧪 What You Should Do NOW

1. Modify config:
    

```bash
vi /etc/vsftpd/vsftpd.conf
```

2. Then:
    

```bash
rpm -V vsftpd
```

👉 Observe changes

---

# 🔥 Final Take

👉 `rpm -ql` = exploration  
👉 `rpm -V` = security + troubleshooting  
👉 `--force / --nodeps` = last resort weapons


🔥 INTERVIEW ANSWER (USE THIS EXACTLY)

“RPM metadata includes package information such as installed files, versions, dependencies, scripts, and integrity data. If the RPM database is lost, the system still contains the files, but RPM loses track of all installed packages, making package management operations unreliable or impossible.”

---


