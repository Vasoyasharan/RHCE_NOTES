
---

# 📦 EPEL Repository in RHEL 9 – Complete Guide

## 🔍 What is EPEL?

**EPEL (Extra Packages for Enterprise Linux)** is a repository created and maintained by the Fedora Project.

👉 It provides **additional high-quality packages** for Enterprise Linux distributions like:

- Red Hat Enterprise Linux (RHEL)
    
- CentOS
    
- Rocky Linux
    

---

## ⚡ Why EPEL is Important

Let’s cut the nonsense — EPEL exists because **RHEL is intentionally limited**. You don’t get many useful tools by default.

### ✅ Key Features

- 📦 **Massive package collection** (tools not in default RHEL)
    
- 🔐 **Secure & open-source** (maintained by Fedora SIG)
    
- ⚙️ **No conflicts** with base RHEL packages
    
- 🏢 **Enterprise-grade stability**
    
- 🔄 **Regular updates**
    

👉 Example tools you get:

- `neofetch`
    
- `htop`
    
- `fail2ban`
    
- `nmap` (sometimes newer versions)
    

---

## 🧠 Important Concept (Don’t Skip)

👉 EPEL **does NOT replace system packages**  
👉 It only **adds extra packages**

If you think EPEL is like Ubuntu PPA — ❌ wrong  
It’s more controlled and stable.

---

# 🛠️ Install EPEL Repository in RHEL 9

---

## 🔹 Step 1: Switch to Root User

```bash
sudo -i
```

👉 You need root privileges. No shortcuts here.

---

## 🔹 Step 2: Update System

```bash
dnf update -y
```

![](https://www.tecmint.com/wp-content/uploads/2022/05/Update-RHEL-9.png)

💡 Why?

- Sync repository metadata
    
- Avoid dependency issues later
    

---

## 🔹 Step 3: Enable CodeReady Builder Repo

```bash
subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
```

![](https://www.tecmint.com/wp-content/uploads/2022/05/Add-Codeready-Builder-Repo.png)

⚠️ Brutal truth:  
If you skip this → **EPEL will break dependencies**

👉 CodeReady provides **development libraries** required by EPEL packages.

---

## 🔹 Step 4: Install EPEL Repository

```bash
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
```

![](https://www.tecmint.com/wp-content/uploads/2022/05/Install-EPEL-in-RHEL-9.png)

✔️ This installs:

- EPEL repo config
    
- GPG keys (for package verification)
    

---

## 🔹 Step 5: Verify Installation

```bash
yum repolist
```

👉 You should see:

```
epel
```

If not → you messed up somewhere. Fix it before continuing.

![](https://www.tecmint.com/wp-content/uploads/2022/05/Check-EPEL-in-RHEL-9.png)

---

# 📦 Using EPEL Repository

---

## 🔹 List All Available Packages (EPEL Only)

```bash
dnf --disablerepo="*" --enablerepo="epel" list available
```

👉 This avoids noise from other repos.

![](https://www.tecmint.com/wp-content/uploads/2022/05/List-Packages-from-EPEL-1536x368.png)

---

## 🔹 Search for a Package

Example: search `neofetch`

```bash
yum --disablerepo="*" --enablerepo="epel" list available | grep neofetch
```

---

## 🔹 Get Package Details

```bash
yum --enablerepo=epel info neofetch.noarch
```

📌 Shows:

- Description
    
- Version
    
- Dependencies
    
- Source
    
![](https://www.tecmint.com/wp-content/uploads/2022/05/List-Package-Info-in-RHEL.png)

---

## 🔹 Install Package from EPEL

```bash
yum --enablerepo=epel install neofetch.noarch -y
```

![](https://www.tecmint.com/wp-content/uploads/2022/05/Install-Package-from-EPEL-1536x550.png)

---

## 🔹 Verify Installation

```bash
neofetch
```

![](https://www.tecmint.com/wp-content/uploads/2022/05/Check-RHEL-9-Info.png)

✔️ If it runs → success  
❌ If not → check dependencies or repo

---

# ⚠️ Common Mistakes (Reality Check)

### ❌ Mistake 1: Not enabling CodeReady repo

👉 Result: dependency errors

---

### ❌ Mistake 2: Mixing repos blindly

👉 You break system stability

---

### ❌ Mistake 3: Using `yum` without understanding

👉 In RHEL 9:

- `yum` = wrapper of `dnf`
    

---

### ❌ Mistake 4: Installing everything from EPEL

👉 Don’t be stupid — only install what you need

---

# 🧩 Best Practices

- ✔️ Always verify repo before installing
    
- ✔️ Use `dnf info` before installing packages
    
- ✔️ Avoid unnecessary packages (security risk)
    
- ✔️ Keep system updated regularly
    

---

# 🏁 Conclusion

EPEL is **not optional** if you’re serious about working with RHEL.

👉 It gives you:

- More tools 🧰
    
- Better flexibility ⚙️
    
- Real-world usability 💻
    

But:  
👉 Misuse it → you’ll break your system

---

If you want next level 🔥  
I can show you:

- How to create your own local EPEL mirror (for offline labs)
    
- How attackers abuse extra packages (security angle 😈)
    
- Real-world admin scenarios using EPEL
    

Just ask.