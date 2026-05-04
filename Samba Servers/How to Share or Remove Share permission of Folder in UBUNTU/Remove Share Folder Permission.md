# 🛑 HOW TO STOP / UN-SHARE A FOLDER IN LINUX (SAMBA)

---

## ✅ METHOD 1: Remove the Share from Samba (BEST & CLEAN) 🧠✅

This **completely stops** sharing. This is what admins do.

---

### 🔹 STEP 1: Open Samba config

```bash
sudo nano /etc/samba/smb.conf
```

---

### 🔹 STEP 2: Find your share block

Example (your case):

```ini
[MCSE]
   path = /media/adminpc/data/MCSE
   browseable = yes
   writable = yes
   read only = no
   valid users = adminpc
```

---

### 🔹 STEP 3: DELETE the whole block ❌

Remove **everything from**:

```
[MCSE]
```

to the last line of that share.

⚠️ Don’t delete other shares by mistake.

---

### 🔹 STEP 4: Save and exit

- `CTRL + O` → `ENTER`
    
- `CTRL + X`
    

---

### 🔹 STEP 5: Restart Samba 🔄

```bash
sudo systemctl restart smbd
sudo systemctl restart nmbd
```

---

### 🔹 STEP 6: Verify (NO ASSUMPTIONS)

```bash
smbclient -L localhost
```

✅ If `MCSE` is **NOT listed** → share is stopped  
❌ If it still shows → you didn’t remove it properly

---

## ✅ METHOD 2: Disable Samba Service (Stops ALL shares) 🚨

Use this if you want **NO sharing at all**.

---

### 🔹 Stop Samba temporarily

```bash
sudo systemctl stop smbd
sudo systemctl stop nmbd
```

### 🔹 Disable on boot

```bash
sudo systemctl disable smbd
sudo systemctl disable nmbd
```

💣 Result:

- No Linux folder is shared
    
- Windows can’t access anything
    

---

## ✅ METHOD 3: Block Sharing via Firewall (Quick Kill Switch) 🔥

Samba still exists, but **network access is blocked**.

```bash
sudo ufw deny samba
```

---

## 🧹 OPTIONAL (Security Cleanup – Recommended)

If you don’t want Samba users anymore:

```bash
sudo smbpasswd -x adminpc
```

This removes the Samba account (Linux user stays). 

---

