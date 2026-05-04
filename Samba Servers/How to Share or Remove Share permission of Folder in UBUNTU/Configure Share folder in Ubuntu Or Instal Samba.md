
- assume Thar this is the Path which i wanna share 

```
/media/adminpc/data/MCSE
```

- In your case that is Different path or Share Folder...
---
![image](https://preview.redd.it/linux-mint-i-clearly-see-samba-share-is-installed-by-v0-8xy4xmmemoca1.png?auto=webp&s=2761e3b56b8c578478eb6b68a8bbf4a588ad2b35)
## ✅ STEP 1: Fix ownership & permissions (CRITICAL)

Run this **exactly** 👇

```bash
sudo chown -R adminpc:adminpc /media/adminpc/data/MCSE
sudo chmod -R 775 /media/adminpc/data/MCSE
```

🔴 If you skip this → sharing WILL break. Period.

---

## ✅ STEP 2: Install Samba (if not already)

```bash
sudo apt update
sudo apt install samba -y
```

![image](https://www.technig.com/wp-content/uploads/2015/10/Installing-App-In-Ubuntu-Linux.jpg)

Verify:

```bash
smbd --version
```

---

## ✅ STEP 3: Share THIS folder via Samba (Terminal – Correct way)

Open Samba config:

```bash
sudo nano /etc/samba/smb.conf
```

Go to the **BOTTOM** and add 👇

```ini
[MCSE]
   path = /media/adminpc/data/MCSE (Shared Location Path folder)
   browseable = yes
   writable = yes
   read only = no
   valid users = adminpc (Username of PC)
```

![image](https://vitux.com/wp-content/uploads/2019/05/word-image-170.png)

⚠️ Notice:

- ❌ No spaces in share name
    
- ❌ No guest access (good habit)
    
- ✔ Explicit path
    share folder in Network in Ubuntu using terminal

Save → `CTRL+O` → `ENTER` → `CTRL+X`

---

## ✅ STEP 4: Add Samba password (MANDATORY)

Linux user ≠ Samba user.

```bash
sudo smbpasswd -a Username(adminpc)
sudo smbpasswd -e Username(adminpc)
```

Remember this password 🔐

![image](https://linuxhint.com/wp-content/uploads/2021/08/share-folder-on-local-network-with-ubuntu-09.png)

---

## ✅ STEP 5: Restart Samba

```bash
sudo systemctl restart smbd
sudo systemctl restart nmbd
```

Check:

```bash
systemctl status smbd
```

![image](https://linuxhint.com/wp-content/uploads/2021/08/share-folder-on-local-network-with-ubuntu-04.png)

Must be **active (running)**.

---

## ✅ STEP 6: Allow firewall (very common miss ❌)

```bash
sudo ufw allow samba
```

![image](https://linuxhint.com/wp-content/uploads/2021/08/share-folder-on-local-network-with-ubuntu-05.png)

---

## ✅ STEP 7: VERIFY (no assumptions)

```bash
testparm
smbclient -L localhost -U adminpc
```

You **MUST** see:

```
MCSE   Disk
```

If you don’t → it’s NOT shared. End of discussion.

---

## 🖥️ Access from Windows (THIS is the correct format)
### Steps:

1️⃣ Open **Files**  
2️⃣ Click **Other Locations** (left sidebar)  
3️⃣ At bottom → **Connect to Server**  
4️⃣ Enter **EXACTLY** this (important 👇):

```
smb://media/adminpc/data/MCSE
```

5️⃣ Click **Connect**  
6️⃣ Enter:

- Username (from your sir’s PC)
    
- Password
    
- Domain (if asked)
    

If credentials are right → folder opens 🔓📂

**OR**

On Windows File Explorer:

```
\\<Linux-IP>\MCSE
```

Example:

```
\\192.168.1.20\MCSE
```

![image](https://johnpili.com/connect-to-windows-shared-folder-on-ubuntu-18-04-lts/in-nautilus-file-browser-enter-the-url-of-the-windows-share.png)


![image](https://linuxhint.com/wp-content/uploads/2021/08/share-folder-on-local-network-with-ubuntu-12.png)



---

## 🐧 Access from another Linux machine

GUI:

```
smb://192.168.1.20/MCSE
```

Terminal mount:

```bash
sudo mount -t cifs //192.168.1.20/MCSE /mnt/mcse -o username=adminpc
```

---

## 🚨 Brutal Truth (read twice)

- Sharing from `/media` **without fixing permissions = failure**
    
- GUI sharing alone is **not enough**
    
- Spaces in share names cause pain
    
- If `smbclient -L localhost` doesn’t show it → it’s not shared
    

---