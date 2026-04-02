## 🌐 Setting Up YUM Server via FTP

This allows OTHER machines on the network to use your server as a package source.

### On the **Server** (machine with the packages):

```bash
# Step 1: Install and start the FTP service
rpm -q vsftpd                    # Check if installed
rpm -ivh vsftpd-*.rpm            # Install if not present
systemctl start vsftpd --now          # Start the service
systemctl enable vsftpd          # Auto-start on reboot
systemctl status vsftpd         # shows vsftpd status

# Step 2: Create directory for packages
mkdir -p /var/ftp/pub/rhel9.7

# Step 3: Copy DVD contents to FTP directory
cp -rvpf /run/media/root/RHEL-9-7-0-BaseOS-x86_64/* /var/ftp/pub/rhel8/

# Step 4: Create local repo file pointing to FTP path
nano /etc/yum.repos.d/local.repo
```

```ini
[ftprepo1]
name=baseOS software
baseurl=file:///var/ftp/pub/rhel8/BaseOS
gpgcheck=0
enabled=1

[ftprepo2]
name=AppStream software
baseurl=file:///var/ftp/pub/rhel8/AppStream
gpgcheck=0
enabled=1
```

### On the **Client** (machine that will use the repo):

```bash
# Step 1: Check connectivity to server
ping 192.168.68.123

# Step 2: Create repo file pointing to server
nano /etc/yum.repos.d/ftp.repo
```

```ini
[baseos]
name=baseOS software
baseurl=ftp://192.168.68.123/pub/rhel8/BaseOS
gpgcheck=0
enabled=1

[appstream]
name=AppStream software
baseurl=ftp://192.168.68.123/pub/rhel8/AppStream
gpgcheck=0
enabled=1
```

```bash
# Step 3: Test the connection
yum clean all       # Clear old cache
yum repolist        # Verify repos are visible
yum list            # List all available packages
```

> 💡 **Why FTP for a YUM server?** FTP is simple, fast, and doesn't require authentication for anonymous reads — making it perfect for internal software distribution. For external/internet-facing setups, HTTPS is recommended for security.



Here's your **clean, well-organized, and easy-to-understand** version of the FTP setup guide with nice emojis for better readability:

---

### **✅ Complete VSFTPD Setup Guide (Server + Client)**  
**Red Hat Enterprise Linux 9.7**

You have successfully changed the hostnames:  
- **Server**: `server.iforward.in`  
- **Client**: `client.iforward.in`

---

### **🖥️ SERVER SIDE CONFIGURATION**

#### **1. Install VSFTPD**  
```bash
sudo su 
yum install vsftpd -y
```
- Wait for the installation to complete.  
- Type `y` if it asks for confirmation.

#### **2. Start and Enable VSFTPD Service**  
```bash
systemctl start vsftpd
systemctl enable vsftpd
systemctl status vsftpd
```
**Expected**: The service should show as **active (running)** ✅

#### **3. Configure VSFTPD (Main Settings)**  
```bash
nano /etc/vsftpd/vsftpd.conf
```

**Make the following changes**:

- Find and **uncomment** these two lines (remove the `#`):
  ```conf
  anon_upload_enable=YES
  anon_mkdir_write_enable=YES
  ```

- **Save & Exit**:  
  `Ctrl + O` → Press `Enter` → `Ctrl + X`

Then restart the service:
```bash
systemctl restart vsftpd
```

#### **4. Configure Firewall**  
```bash
firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload
```

#### **5. Create Test Directory**  
```bash
cd /var/ftp/pub
mkdir rhel9.7
ls
```
You should see the folder `rhel9.7` created.

#### **6. Temporarily Disable SELinux** (for testing)  
```bash
getenforce          # Should show "Enforcing"
setenforce 0        # Set to Permissive mode
```

---

### **💻 CLIENT SIDE ACCESS**

#### **1. Check Connectivity (Ping Test)**  
On the **Client** machine:
```bash
ping server1.iforward.in
# OR
ping 192.168.68.123     # Replace with your server's actual IP
```
Press `Ctrl + C` to stop.

#### **2. Access via Terminal (Command Line)**  
```bash
ftp server1.iforward.in
# OR
ftp 192.168.68.123
```

- Login as: **`anonymous`**  
- Password: Just press **Enter** (or type any email like `guest@example.com`)

After login, try these commands:
- `ls` → to see files/folders  
- `cd pub` → go to public directory  
- `pwd` → show current path

#### **3. Access via GUI (File Manager - Easier)**  

1. Open **Files** (File Manager) on the Client  
2. Click on **Other Locations**  
3. In the **Connect to Server** box at the bottom, type:
   ```
   ftp://server1.iforward.in
   ```
   or
   ```
   ftp://192.168.68.123
   ```
4. Click **Connect**  
5. You should see the `pub` folder  
6. Open `pub` → you will see the `rhel9.7` folder created from the server ✅

---