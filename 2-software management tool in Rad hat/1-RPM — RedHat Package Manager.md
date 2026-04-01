# 📦 Linux Package Management: RPM 

---

## 📖 What is Package Management?

In Linux, **software is distributed as packages** — bundles containing:

- 📄 Binary executables (the actual programs)
- ⚙️ Configuration files
- 📚 Documentation
- 🔗 Metadata (version, dependencies, author info)

Without a package manager, you'd have to manually track every file installed by every software — a nightmare at scale. Package managers automate installation, removal, upgrades, and verification.

### 🔑 Key Concept: Dependencies

Most software relies on _other_ software to function. For example:

- A video player needs audio libraries
- A web server needs SSL libraries

This chain of requirements is called a **dependency tree**. Managing it manually is error-prone. Package managers solve this automatically.

---
## 🔴 RPM — RedHat Package Manager

### What is RPM?

RPM is the **low-level** package tool used in Red Hat-based distributions (RHEL, CentOS, Fedora). Think of it like a screwdriver — powerful and precise, but you do the work manually.

### 📦 RPM Package Naming Convention

Understanding the filename helps you know exactly what you're installing:

```
vsftpd  -  3.0.3  -  28  .  el8  .  x86_64  .rpm
  │          │         │      │        │
  │          │         │      │        └── Architecture (x86_64 = 64-bit Intel/AMD)
  │          │         │      └─────────── OS version (el8 = Enterprise Linux 8)
  │          │         └────────────────── Release number (build iteration)
  │          └──────────────────────────── Version number
  └─────────────────────────────────────── Package name
```

> 💡 **Why does this matter?** Installing a package for the wrong architecture (e.g., i686 on a 64-bit system) can cause failures or even system instability.

## 1. Core Concepts – Why RPM & YUM Exist

| Tool          | Level      | Purpose                                  | Dependency Handling | Best For                                     |
| ------------- | ---------- | ---------------------------------------- | ------------------- | -------------------------------------------- |
| **RPM**       | Low-level  | Install/remove/query single `.rpm` files | ❌ Manual            | Offline installs, troubleshooting, forensics |
| **YUM / DNF** | High-level | Manage packages from **repositories**    | ✅ Automatic         | Daily use, updates, group installs           |

**Underlying Truths:**
- Every `.rpm` file is a compressed archive (`cpio`) containing binaries, configs, scripts, and **metadata**.
- RPM database (`/var/lib/rpm/`) tracks **everything** installed on the system.
- YUM/DNF reads **repository metadata** (repodata/) to solve dependencies automatically.

**💡 Best Practice:**  
**Always prefer YUM/DNF** unless you have a very specific reason (offline, custom `.rpm`, or debugging).

**⚠️ Risks of RPM-only:**
- Forgetting dependencies → broken apps
- Overwriting config files → lost customizations
- Corrupted RPM DB → `rpm -qa` fails (see rebuild section)

---

### 🏗️ Where are Packages Stored on a DVD/ISO?

When you attach a RHEL DVD/ISO, packages are organized in two folders:

|Folder|Contents|
|---|---|
|`BaseOS`|Core OS packages — essential system libraries, kernel components|
|`AppStream`|Application packages — web servers, databases, tools|

```bash
# Mount the ISO first
mount /dev/sr0 /mnt

# Navigate and explore
ls /mnt/AppStream/Packages/
ls /mnt/BaseOS/Packages/
```

> ⚠️ **Best Practice:** Always mount before trying to access DVD packages. Unmounted devices show no content.

---

## 🛠️ RPM Command Reference

### 1. 🔍 Query All Installed Packages

```bash
rpm -qa
```

**What's happening under the hood:**

- `-q` = query mode
- `-a` = all packages
- RPM reads from its database at `/var/lib/rpm/` to return this list

> 💡 **Pro tip:** Pipe to `wc -l` to count how many packages are installed:
> 
> ```bash
> rpm -qa | wc -l
> ```

---

### 2. 🔎 Check if a Specific Package is Installed

```bash
rpm -q vsftpd
# OR
rpm -qa vsftpd

# If you're unsure of the exact name:
rpm -qa | grep -i vsft*
```

**Understanding `-i` in grep:** The `-i` flag makes the search **case-insensitive**. This matters because package names can start with uppercase or have mixed casing.

**Expected Outputs:**

|Output|Meaning|
|---|---|
|`vsftpd-3.0.3-28.el8.x86_64`|✅ Package is installed|
|_(empty / no output)_|❌ Package is NOT installed|

---

### 3. 🧪 Test Installation Before Actually Installing

```bash
rpm -ivh vsftpd-3.0.3-28.el8.x86_64.rpm --test

# Output:
Verifying... ################################# [100%]
Preparing... ################################# [100%]
```

![](https://camo.githubusercontent.com/3d5ca51fa1e541b371c774066d63df7999516e030d811bd40cbeb36936aaf33c/68747470733a2f2f7777772e7265646861742e636f6d2f726864632f6d616e616765642d66696c65732f73797361646d696e2f323032302d30342f70322e706e67)

**Flag breakdown:**

|Flag|Meaning|
|---|---|
|`-i`|Install|
|`-v`|Verbose (show details)|
|`-h`|Hash marks (progress bar `####`)|
|`--test`|Simulate — don't actually install|

> ✅ **Best Practice:** ALWAYS run `--test` before installing on a production server. If the hash progress shows **100%** without errors, the package is safe to install. If it shows an error mid-way, the package is corrupt or has unmet dependencies.

---

### 4. ⬇️ Install a Package | Force Install (Overwrite Conflicts) | 🚫 Install Without Dependencies

```bash
rpm -ivh vsftpd-3.0.3-28.el8.x86_64.rpm

# Force install (⚠️ dangerous!)
rpm -ivh vsftpd-3.0.3-28.el8.x86_64.rpm --force

# Install WITHOUT dependencies (⚠️ high risk!)
rpm -ivh httpd-2.4.37-16.rpm --nodeps
```

> ⚠️ **Risk:** RPM does **NOT** automatically resolve dependencies. If `vsftpd` needs library X and library X is not installed, the install will FAIL with a "Failed dependencies" error. You must install all dependencies manually or use YUM instead.


> ⚠️ **DANGER:** `--force` overwrites existing files without asking.  Use only when you're absolutely sure — and have a backup.

`--nodeps`
> ⚠️ **DANGER:** This installs the package even if its required libraries are missing. The software may install but will **fail to run**. Only use this when you know the dependencies are already present under different names, or in a controlled testing environment.

---

### 5. 🗑️ Remove / Uninstall a Package

```bash
rpm -e vsftpd
```

**Note:** `-e` stands for **erase**. You use just the package _name_, not the full filename.

> ⚠️ **Risk:** RPM also won't check if _other_ packages depend on the package you're removing. Removing a critical library that other software depends on can **break your system**. Always verify with `rpm -q --whatrequires <package>` before removal.

---

### 6. 📋 View Package Info Before Installing

```bash
rpm -qip vsftpd-3.0.3-28.el8.x86_64.rpm
```

**Flag breakdown:**

| Flag | Meaning                                            |
| ---- | -------------------------------------------------- |
| `-q` | Query                                              |
| `-i` | Info (show details)                                |
| `-p` | Target is a package _file_ (not installed package) |
🔹 Detailed Queries

| Command              | Meaning                        |
| -------------------- | ------------------------------ |
| `rpm -qi pkg`        | Package info                   |
| `rpm -ql pkg`        | List files                     |
| `rpm -qc pkg`        | Config files                   |
| `rpm -qd pkg`        | Documentation                  |
| `rpm -qf /path/file` | Find package of file           |
| `rpm -qp file.rpm`   | Query rpm file (not installed) |
## 🔥 Advanced Query

```bash
rpm -q --whatprovides /usr/sbin/httpd
rpm -q --whatrequires package
```


This shows: name, version, architecture, build date, license, description — all without installing it.

> 💡 **Why use this?** Before installing third-party software, review the package info to verify it's legitimate, correctly versioned, and from a trusted vendor.

---

### 7. 📋 View Info of an Already-Installed Package

```bash
rpm -qi vsftpd
```

_(No `-p` flag — because you're querying the installed package database, not a file)_

---

### 8. 🔗 Find Which Package a Command Belongs To

```bash
# Step 1: Find the path of the command
which vsftpd
# Output: /usr/sbin/vsftpd

# Step 2: Query which package owns that file
rpm -qf /usr/sbin/vsftpd
# Output: vsftpd-3.0.3-28.el8.x86_64
```

> 💡 **Real-world use case:** If you find an unfamiliar binary on your system and want to know which software installed it — this command tells you immediately.

---

### 9. 📂 List All Files Installed by a Package

```bash
rpm -ql vsftpd
```

This shows every file the package placed on your system — binaries, config files, documentation.

### 10. 📁 List Only Directories of a Package

```bash
rpm -qld vsftpd
```

---
****
### 11. 🔄 Upgrade a Package

```bash
rpm -Uvh vsftpd-newer-version.rpm
```

`-U` = Upgrade (also installs if not already installed)

---

### 12. ✅ Verify Package Integrity After Changes

```bash
rpm -V vsftpd
```

This compares the current state of installed files against what was originally installed. Output like:

```
S.5....T.  c /etc/vsftpd/vsftpd.conf
```

**Decoding the output:**

|Code|Meaning|
|---|---|
|`S`|File size changed|
|`5`|MD5 checksum changed|
|`T`|Modification time changed|
|`c`|It's a configuration file|

> 💡 **Security use case:** If a file that should NEVER change (like a binary) shows up in `rpm -V` output, this could indicate tampering or a security breach. System administrators use this regularly in security audits.

---
### 13 . 📂 DATABASE OPTIONS

| Command           | Meaning        |
| ----------------- | -------------- |
| `rpm --rebuilddb` | Rebuild rpm DB |
| `rpm --initdb`    | Initialize DB  |

---
## ⚠️ Risks & Best Practices with RPM

| ⚠️ Risk                                      | 💡 Mitigation                                             |
| -------------------------------------------- | --------------------------------------------------------- |
| Dependency hell — manual resolution          | Use YUM for dependency-aware installations                |
| Breaking system by removing shared libraries | Always check `rpm -q --whatrequires <pkg>` before removal |
| Installing corrupt packages                  | Always `--test` first                                     |
| Database corruption                          | Regular backups of `/var/lib/rpm/`                        |
| Installing wrong architecture                | Check filename carefully before installing                |
| `--force` breaking existing software         | Never use `--force` in production without a backup        |

---

## 🔧 Rebuilding a Corrupt RPM Database

### When Does Corruption Happen?

- 💥 Power failure during an RPM operation
- 🔄 System crash mid-transaction
- 💾 Disk errors
- 🔐 Stale lock files from a crashed process

### Symptoms

- `rpm -qa` returns no packages or hangs
- `yum update` fails with rpmdb errors
- "cannot open Packages database in /var/lib/rpm"
- "rpmdb: Lock table is out of available locker entries"
- rpm command segfaults

---

## 🧠 RPM vs YUM — When to Use What

| Scenario                                | Use                   | Why                           |
| --------------------------------------- | --------------------- | ----------------------------- |
| Installing from internet repo           | ✅ YUM                 | Auto dependency resolution    |
| Installing a single offline `.rpm` file | ✅ YUM localinstall    | Still resolves deps           |
| Querying installed packages             | Either                | RPM is slightly faster        |
| Checking which package owns a file      | Either                | `rpm -qf` or `yum provides`   |
| Installing without internet             | ✅ YUM with local repo | Best of both worlds           |
| Verifying package integrity             | ✅ RPM                 | `rpm -V` is powerful          |
| Undoing a recent install                | ✅ YUM                 | `yum history undo`            |
| Scripting bulk operations               | ✅ YUM                 | `-y` flag, better output      |
| Rebuilding corrupted database           | ✅ RPM tools           | `rpmdb_verify`, `--rebuilddb` |

---

## 📋 Quick Reference Cheat Sheet

### 🔴 RPM Commands

| Command                     | Description                   |
| --------------------------- | ----------------------------- |
| `rpm -qa`                   | List all installed packages   |
| `rpm -q vsftpd`             | Check if vsftpd is installed  |
| `rpm -qa \| grep -i name`   | Search installed packages     |
| `rpm -ivh pkg.rpm`          | Install package               |
| `rpm -ivh pkg.rpm --test`   | Test install (dry run)        |
| `rpm -ivh pkg.rpm --nodeps` | Install ignoring dependencies |
| `rpm -ivh pkg.rpm --force`  | Force install (overwrite)     |
| `rpm -Uvh pkg.rpm`          | Upgrade package               |
| `rpm -e vsftpd`             | Remove package                |
| `rpm -qi vsftpd`            | Info about installed package  |
| `rpm -qip pkg.rpm`          | Info about package file       |
| `rpm -ql vsftpd`            | List files in package         |
| `rpm -qld vsftpd`           | List directories of package   |
| `rpm -qf /usr/sbin/vsftpd`  | Which package owns this file  |
| `rpm -V vsftpd`             | Verify package integrity      |
| `rpm --rebuilddb`           | Rebuild RPM database          |

---

> 📌 **Remember the Golden Rule:**
> 
> - Use **RPM** when you need fine-grained control and are working with individual package files
> - Use **YUM** for almost everything else — it's safer, smarter, and handles the hard work for you

---

_📘 Guide prepared based on Yoinsights Technologies Pvt. Ltd. — Module 3: Package Management using RPM and YUM_