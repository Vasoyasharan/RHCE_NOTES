
---

# 📄 🧪 RPM DATABASE FAILURE & RECOVERY LAB

_(for Red Hat Enterprise Linux 8/9 – SQLite based)_

### Why this is dangerous

The **RPM database (`rpmdb.sqlite`)** is the brain of your package manager (`dnf` or `yum`).
- It keeps track of every piece of software installed on your Linux system, including versions, files, and dependencies.

- **Data Loss:** Since a healthy database is usually several megabytes, forcing it down to 100 bytes deletes almost all the data.
    
- **Corruption:** It doesn't "cleanly" remove entries; it literally cuts the file off mid-sentence. The database will become unreadable and corrupted.
    
- **System Paralysis:** You won't be able to install, update, or remove software because the system no longer knows what is currently installed

---

# 🎯 OBJECTIVE

To simulate RPM database failure scenarios and recover the system using backup and rebuild methods.

---

# 🖥️ ENVIRONMENT

- OS: RHEL 8 / 9
    
- Tools: `rpm`
    
- DB Type: SQLite (`rpmdb.sqlite`)
    

---

# 🔹 STEP 1: VERIFY RPM DATABASE

```bash
rpm -qa | head
```

👉 Confirms system has installed packages  
👉 DB is working normally

---

# 🔹 STEP 2: TAKE BACKUP (CRITICAL)

```bash
mkdir /root/rpm-backup
cp -rvpf /var/lib/rpm/* /rpm_backup_db/
```

- **`-r`**: Includes everything **inside** the folder (recursive).
- **`-v`**: **Shows** you each file as it copies (verbose).
- **`-p`**: **Remembers** the original dates and permissions (preserve).
- **`-f`**: Overwrites existing files **without asking** (force).

👉 This is your **recovery point**

---

# 🔹 STEP 3: FAILURE SCENARIOS

---

## 💣 CASE 1: DELETE RPM DATABASE

```bash
rm -rf /var/lib/rpm/*
```

### 🔍 Test:

```bash
rpm -qa
```

### ✅ Observation:

- No output
    
- New DB files auto-created
    

### 🧠 Explanation:

**What happens if RPM DB is deleted?**
> **RPM automatically recreates** an **empty database** on **next query** such as **`rpm -qa`**, but all package metadata is lost, making package management unusable until restored or rebuilt.

---

## 💣 CASE 2: CORRUPT DATABASE

```bash
truncate -s 100 /var/lib/rpm/rpmdb.sqlite
```

|**Part**|**Meaning**|
|---|---|
|**`truncate`**|The command used to shrink or extend the size of a file.|
|**`-s 100`**|Sets the size to exactly 100 bytes.|
|**`/var/lib/rpm/rpmdb.sqlite`**|The target file (the SQLite database for RPM).|

### 🔍 Test:

```bash
rpm -qa
```

### ❌ Expected Errors:

- `database disk image is malformed`
    
- `cannot open Packages database`

### 🧠 Explanation:

- DB exists but is unreadable
    
- RPM fails to query packages
    

---

## 💣 CASE 3: PERMISSION ISSUE

```bash
chmod 000 /var/lib/rpm/rpmdb.sqlite
```

### 🔍 Test:

```bash
rpm -qa
```

### ❌ Expected Errors:

- `permission denied`
    

### 🧠 Explanation:

- RPM cannot access DB due to permission restriction
    

---

# 🔹 STEP 4: RECOVERY METHODS

---

## 🔁 METHOD 1: RESTORE FROM BACKUP (BEST)

```bash
rm -rf /var/lib/rpm/*
cp -av /root/rpm-backup/* /var/lib/rpm/
```

---

## 🔁 METHOD 2: REBUILD DATABASE

```bash
rpm --rebuilddb
```

👉 Works only if partial DB exists

---

# 🔹 STEP 5: VERIFICATION

```bash
rpm -qa | head
yum list installed | head
```

👉 Packages should appear again  
👉 System is restored

---

# ⚠️ KEY LEARNINGS (IMPORTANT)

### 🔥 What happens if RPM DB is deleted?

👉 Answer:

> RPM automatically recreates an empty database on next query, but all package metadata is lost, making package management unusable until restored or rebuilt.

---

### 🔥 Key Concepts:

- RPM DB = metadata only (not actual packages)
    
- Deleting DB ≠ uninstall software
    
- YUM/DNF depends on RPM
    
- If RPM fails → package management fails
    

---

# 🚨 REAL-WORLD IMPACT

If RPM DB is lost:

- Cannot install/update/remove packages
    
- System becomes unmanageable
    
- Requires backup or rebuild
    

---

# 🧠 INTERVIEW QUESTIONS

### ❓ Q1: What happens when RPM DB is corrupted?

👉 RPM commands fail with database errors

---

### ❓ Q2: Difference between delete vs corrupt?

|Scenario|Result|
|---|---|
|Delete DB|New empty DB created|
|Corrupt DB|Errors occur|
|Permission issue|Access denied|

---

### ❓ Q3: How to recover RPM DB?

👉 Answer:

- Restore from backup
    
- Use `rpm --rebuilddb`
    

---

# 🏁 CONCLUSION

RPM database is critical for system package management.  
Proper backup and understanding of failure scenarios are essential for system recovery.

---
