
---

# 🧱 Step 1: Get Required Files

### 1. Download RHEL ISO

- Go to: [https://developers.redhat.com/](https://developers.redhat.com/)
    
- Create free account
    
- Download:  
    👉 **RHEL 9.7 Binary DVD ISO**
    

⚠️ Don’t download boot ISO unless you know what you're doing.

---

# 💻 Step 2: Create VM in VMware

### Configuration (don’t guess — use this):

- **Type**: Custom (Advanced)
    
- **Guest OS**:  
    👉 Linux → Red Hat Enterprise Linux 9 (64-bit)
    
- **RAM**:  
    👉 Minimum: 2GB  
    👉 Recommended: 4GB+
    
- **CPU**:  
    👉 4 cores minimum
    
- **Disk**:  
    👉 70 GB (thin provision)
    
- **Network**:  
    👉 NAT (for internet)  
    OR  
    👉 Bridged (for lab access)
    

---

# 💿 Step 3: Attach ISO

- Select: **Use ISO image**
    
- Browse → select downloaded RHEL 9.7 ISO
    

---

# 🚀 Step 4: Start Installation

### Select:

👉 **Install Red Hat Enterprise Linux 9**

![](https://github.com/Vasoyasharan/RHCE_NOTES/blob/main/image/installation%20of%20RHEL%209.7/installation%20of%20RHEL%209.7.png?raw=true)

---

# ⚙️ Step 5: Installation Configuration (IMPORTANT)

Inside installer:

### 1. Installation Destination

- Select disk
    
- Choose: **Automatic partitioning**
    
👉 Don’t overcomplicate LVM now unless lab requires it.

![](https://github.com/Vasoyasharan/RHCE_NOTES/blob/main/image/installation%20of%20RHEL%209.7/disk%20partition.png?raw=true)

---

### 2. Software Selection

Choose one:

- **Minimal Install** ✅ (BEST for real learning)
    
- OR
    
- Server with GUI (if you're still transitioning)
    

👉 If you pick GUI, you’re slowing your Linux learning. Be honest.

![](https://github.com/Vasoyasharan/RHCE_NOTES/blob/main/image/installation%20of%20RHEL%209.7/server%20with%20GUI.png?raw=true)

---

### 3. Network & Hostname

- Turn ON network
    
- Hostname:
    
    ```
	server1.iforward.in
    ```
    
![](https://github.com/Vasoyasharan/RHCE_NOTES/blob/main/image/installation%20of%20RHEL%209.7/network%20stack.png?raw=true)

---

### 4. Root Password

Set strong password:

```
full name: user1

password : Test@123
```

👉 Same as your lab — consistent 👍

![](https://github.com/Vasoyasharan/RHCE_NOTES/blob/main/image/installation%20of%20RHEL%209.7/new%20user%20create.png?raw=true)

---

### 5. Create User

Example:

```
Username: admin
Password: Test@123
Make administrator ✔
```

---

# ▶️ Step 6: Begin Installation

- Click **Begin Installation**
    
- Wait (5–15 min)
    

---

# 🔁 Step 7: Reboot

- Remove ISO (important)
    
- Boot into system
    

---

# 🔐 Step 8: Register RHEL (CRITICAL)

If you skip this → no updates, no repos = useless system ❌

Run:

```bash
subscription-manager register
subscription-manager attach --auto
```

---

# 📦 Step 9: Update System

```bash
dnf update -y
```

---

# 🧠 Reality Check (Read This)

You said you're moving from MCSE → RHEL.

Here’s the truth:

❌ If you install GUI → you're still thinking like Windows admin  
✅ If you go minimal + CLI → now you're actually learning Linux

---

# 🔥 What You SHOULD Do Next (Don’t Skip)

After install, build THIS lab:

1. Create users & groups
    
2. Configure SSH
    
3. Setup Apache (httpd)
    
4. Setup FTP / Samba
    
5. Practice permissions (chmod, chown)
    
6. Setup firewall (firewalld)
    
7. SELinux basics (very important)
    

---
