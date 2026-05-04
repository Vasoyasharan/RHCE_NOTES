# 🖧 Samba Server — Complete Lab Guide for RHEL 

> 📘 **Based on:** Yoinsights Technologies Pvt. Ltd. — Samba Server Module  
> 🖥️ **Platform:** RHEL 7 / CentOS 7  
> 🔗 **Protocol:** SMB3 / CIFS over TCP port 445  
> 👨‍💻 **Level:** Beginner → Intermediate

---

## 1. 🤔 What is Samba?

Think of Samba as a **translator** between Linux and Windows. Windows uses a protocol called **SMB (Server Message Block)** to share files and printers on a network. Linux doesn't understand SMB natively — so **Samba** makes Linux speak the same language as Windows.

```
┌─────────────┐    SMB/CIFS    ┌─────────────┐
│  Windows PC │ ◄────────────► │ Linux/Samba │
│             │   Port 445     │   Server    │
└─────────────┘                └─────────────┘
```

### 🔑 Key Terms (Don't Get Confused!)

|Term|Simple Meaning|
|---|---|
|**SMB**|Server Message Block — old name for the Windows file-sharing protocol|
|**CIFS**|Common Internet File System — newer name for SMB|
|**Samba**|The open-source Linux software that implements SMB/CIFS|
|**NetBT**|NetBIOS over TCP/IP — how Samba sends data over the network|
|**SMB3**|The version used in RHEL 7 — supports encrypted connections|
|**Samba Server**|The Linux machine that _shares_ files/printers|
|**Samba Client**|The machine (Windows or Linux) that _accesses_ those shares|

### ✅ What Samba Can Do

- Share Linux files and printers with Windows systems
- Give Linux users access to files on Windows systems
- Allow a single Linux system to be **both** server AND client at the same time
- Share user home directories between Linux and Windows (eliminates duplicate home dirs)
- Use Linux and Windows domain credentials interchangeably

> 💡 **RHEL 7 ships with Samba v4.1** which uses **SMB3** protocol — supports **encrypted** transport connections to Windows and other Linux-based Samba servers.

---

## 2. 📦 Samba Packages

Samba is not one big package — it is split into smaller pieces. Here is what each piece does:

|Package Name|What It Does|When You Need It|
|---|---|---|
|`samba`|The **server** daemon — shares files/printers|Always (if you're a server)|
|`samba-client`|Client tools like `smbclient`, `smbtree`|To access Windows shares from Linux|
|`samba-common`|Shared config files needed by both|Always (installed as dependency)|
|`samba-winbind`|`winbindd` daemon — joins Windows domain, maps domain users to Linux|Only for domain environments|
|`samba-winbind-clients`|NSS library + PAM modules for `winbind`|Only if using `winbind`|
|`cifs-utils`|Allows `mount.cifs` command to mount shares|When you need to permanently mount shares|

> 🧠 **Simple rule:** Install `samba` for server. Install `samba-client` + `cifs-utils` for client. Install `samba-winbind` only for domains.

---

## 3. 🔧 Install Samba

### Step-by-Step Installation

```bash
# ─────────────────────────────────────────
# STEP 1: Install the Samba server package
# ─────────────────────────────────────────
[root@server ~]# yum install samba -y
```

**Expected Output:**

```
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
Resolving Dependencies
...
Installing:
 samba         x86_64    4.1.1-31.el7    base    529 k
Installing for dependencies:
 samba-common  x86_64    4.1.1-31.el7    base    682 k
 samba-libs    x86_64    4.1.1-31.el7    base    267 k

Complete!
```

```bash
# ─────────────────────────────────────────
# STEP 2: Install Samba client tools
# ─────────────────────────────────────────
[root@server ~]# yum install samba-client -y
```

**Expected Output:**

```
Installing:
 samba-client   x86_64    4.1.1-31.el7    base    617 k
Complete!
```

```bash
# ─────────────────────────────────────────
# STEP 3: Install cifs-utils (for mounting)
# ─────────────────────────────────────────
[root@server ~]# yum install cifs-utils -y
```

**Expected Output:**

```
Installing:
 cifs-utils   x86_64    6.2-6.el7    base    83 k
Complete!
```

```bash
# ─────────────────────────────────────────
# STEP 4: Install winbind (ONLY for domains)
# ─────────────────────────────────────────
[root@server ~]# yum install samba-winbind samba-winbind-clients -y
```

### ✅ Verify Installation

```bash
[root@server ~]# rpm -qa | grep samba
samba-4.1.1-31.el7.x86_64
samba-client-4.1.1-31.el7.x86_64
samba-common-4.1.1-31.el7.x86_64
samba-libs-4.1.1-31.el7.x86_64
samba-winbind-4.1.1-31.el7.x86_64
```

---

## 4. ⚙️ Samba Daemons and Services

After installation, Samba uses **three background daemons**. Think of daemons as background workers — they keep running silently and handle requests.

### 🔍 What Each Daemon Does

|Daemon|Service Name|Port|Job|
|---|---|---|---|
|`smbd`|`smb`|TCP **445**|File sharing, printing, user authentication, share locking|
|`nmbd`|`nmb`|UDP **137/138**|NetBIOS name resolution — like a phonebook for machine names|
|`winbindd`|`winbind`|—|Resolves Windows domain user/group info for Linux (only in domain environments)|

> 🧠 **Simple analogy:**
> 
> - `smbd` = The actual file store clerk who gives you files
> - `nmbd` = The receptionist who tells you which room (IP) to go to
> - `winbindd` = The HR department that verifies who you are from the domain

### 🚀 Start, Enable and Check Services

```bash
# Start both daemons
[root@server ~]# systemctl start smb
[root@server ~]# systemctl start nmb

# Enable them to start automatically on every reboot
[root@server ~]# systemctl enable smb
[root@server ~]# systemctl enable nmb
```

**Expected Output for enable:**

```
Created symlink from /etc/systemd/system/multi-user.target.wants/smb.service
 to /usr/lib/systemd/system/smb.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/nmb.service
 to /usr/lib/systemd/system/nmb.service.
```

```bash
# Check status of smb
[root@server ~]# systemctl status smb
```

**Expected Output:**

```
● smb.service - Samba SMB Daemon
   Loaded: loaded (/usr/lib/systemd/system/smb.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-01-01 10:00:00 IST; 5s ago
  Process: 1200 ExecStart=/usr/sbin/smbd (code=exited, status=0/SUCCESS)
 Main PID: 1234 (smbd)
   CGroup: /system.slice/smb.service
           └─1234 /usr/sbin/smbd
```

```bash
# Start winbind (only for domain environments)
[root@server ~]# systemctl start winbind
[root@server ~]# systemctl enable winbind
```

### 🔄 Reload vs Restart — Don't Confuse These!

```bash
# RESTART: stops + starts the daemon (causes brief disconnection)
[root@server ~]# systemctl restart smb

# RELOAD: only re-reads config WITHOUT stopping the daemon (no disconnection)
[root@server ~]# systemctl reload smb
```

> ✅ **Best practice:** Always use `reload` after editing `smb.conf` in production — it avoids disconnecting active users.

---

## 5. 📁 Important Configuration Files

These are the files Samba uses. You need to know where they live and what they do.

|File / Directory|Purpose|
|---|---|
|`/etc/samba/smb.conf`|🔑 The **main config file** — defines all shares, security, and global settings|
|`/etc/samba/smbusers`|Maps Windows usernames to Linux usernames (e.g. `oracle = wuser`)|
|`/etc/sysconfig/samba`|Startup options and directives used when Samba starts|
|`/var/lib/samba/private/smbpasswd`|Stores Samba-specific passwords (separate from Linux passwords!)|
|`/var/log/samba/`|Directory containing all Samba log files|

> ⚠️ **Important:** Samba uses its OWN password database (`smbpasswd`). A Linux user's login password is **NOT** automatically their Samba password. You must add them separately with `smbpasswd -a username`.

---

## 6. 🔧 Configure `smb.conf`

The file `/etc/samba/smb.conf` is the heart of Samba. Every time you want to create a new share or change settings, you edit this file.

### 📐 File Structure

The file is divided into **sections** — each section starts with a name in square brackets `[ ]`.

```
[global]     ← Server-wide settings (applies to everything)
[homes]      ← Automatically shares every user's home directory
[printers]   ← Printer sharing
[myshare]    ← Your custom share (you name it!)
```

### 🔍 View the Default Config

```bash
[root@server ~]# cat /etc/samba/smb.conf
```

**Sample output (trimmed):**

```ini
[global]
        workgroup = MYGROUP
        server string = Samba Server Version %v
        log file = /var/log/samba/log.%m
        max log size = 50
        security = user

[homes]
        comment = Home Directories
        browseable = no
        writable = yes

[printers]
        comment = All Printers
        path = /var/spool/samba
        browseable = no
        printable = yes
```

### ✅ Always Validate Config After Editing!

```bash
[root@server ~]# testparm
```

**Expected Output:**

```
Load smb config files from /etc/samba/smb.conf
rlimit_max: increasing rlimit_max (1024) to minimum Windows limit (16384)
Processing section "[homes]"
Processing section "[printers]"
Processing section "[myshare]"
Loaded services file OK.
Server role: ROLE_STANDALONE

Press enter to see a dump of your service definitions
```

> ✅ `Loaded services file OK` = your config is valid and ready to use.  
> ❌ If you see errors, fix them before restarting Samba!

### 📝 Common `smb.conf` Parameters Explained

|Parameter|What It Does|Example|
|---|---|---|
|`workgroup`|The Windows workgroup name|`workgroup = WORKGROUP`|
|`netbios name`|How this server appears in Windows Network Neighborhood|`netbios name = LINUXSERVER`|
|`security`|Authentication type (`user`, `share`, `domain`, `ADS`)|`security = user`|
|`comment`|Description shown when browsing shares|`comment = My Lab Share`|
|`path`|The Linux directory to share|`path = /samba-share`|
|`writable`|Allow write access (`yes`/`no`)|`writable = yes`|
|`guest ok`|Allow anonymous access without password|`guest ok = yes`|
|`browsable`|Show share in the list when browsing|`browsable = yes`|
|`valid users`|Restrict who can access the share|`valid users = john,mary`|

---

## 7. 🏗️ Three Server Types

> 🧠 **Think of it this way:**
> 
> - **Stand-alone** = A single shop that manages itself (no mall, no headquarters)
> - **Domain member** = A branch store that reports to a head office (domain controller)
> - **Domain controller** = The head office itself (manages all branch logins)

---

### 7.1 🟢 Stand-Alone Server Lab

A stand-alone server **does not join any domain**. It works in a **workgroup** (a simple peer-to-peer network). It manages its own users, its own passwords, and its own shares.

#### 🔑 When to use:

- Small office or home lab
- No Windows domain exists
- Simple file sharing between few machines

#### 📋 Complete Lab Steps

```bash
# ─────────────────────────────────────────
# STEP 1: Create the directory to share
# ─────────────────────────────────────────
[root@server ~]# mkdir -p /samba-share
[root@server ~]# chmod 777 /samba-share

# Verify the directory
[root@server ~]# ls -ld /samba-share
drwxrwxrwx. 2 root root 6 Jan 1 10:00 /samba-share
```

```bash
# ─────────────────────────────────────────
# STEP 2: Edit the main config file
# ─────────────────────────────────────────
[root@server ~]# vi /etc/samba/smb.conf
```

Add/edit the following content:

```ini
[global]
        workgroup = WORKGROUP
        netbios name = LINUXSERVER
        server string = My Samba Server
        security = user
        map to guest = bad user

# ── Your custom share ──
[myshare]
        comment = Samba Lab Share
        path = /samba-share
        browsable = yes
        writable = yes
        guest ok = yes
```

```bash
# ─────────────────────────────────────────
# STEP 3: Validate the config
# ─────────────────────────────────────────
[root@server ~]# testparm
Loaded services file OK.
```

```bash
# ─────────────────────────────────────────
# STEP 4: Create a Linux user
# ─────────────────────────────────────────
[root@server ~]# useradd sambauser1
[root@server ~]# passwd sambauser1
Changing password for user sambauser1.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
```

```bash
# ─────────────────────────────────────────
# STEP 5: Add the SAME user to Samba's
# own password database
# (Linux password ≠ Samba password!)
# ─────────────────────────────────────────
[root@server ~]# smbpasswd -a sambauser1
New SMB password:
Retype new SMB password:
Added user sambauser1.
```

```bash
# ─────────────────────────────────────────
# STEP 6: Start and enable services
# ─────────────────────────────────────────
[root@server ~]# systemctl start smb nmb
[root@server ~]# systemctl enable smb nmb
```

```bash
# ─────────────────────────────────────────
# STEP 7: Open firewall for Samba
# ─────────────────────────────────────────
[root@server ~]# firewall-cmd --permanent --add-service=samba
success
[root@server ~]# firewall-cmd --reload
success
```

#### 📡 Access Stand-Alone Server from Windows

Open `Run` (Win+R) on the Windows machine:

```
\\LINUXSERVER\myshare
```

Or to see all shares:

```
\\LINUXSERVER
```

Enter credentials: `sambauser1` / your Samba password

#### 📡 Access Stand-Alone Server from Linux

```bash
# ── On the CLIENT Linux machine ──

# Browse servers on the network
[root@client ~]# findsmb
IP ADDR        NETBIOS NAME    WORKGROUP    OS          VERSION
192.168.1.10   LINUXSERVER     WORKGROUP    Unix        Samba 4.1.1

# See all shares using smbtree
[root@client ~]# smbtree
WORKGROUP
  \\LINUXSERVER        My Samba Server
    \\LINUXSERVER\myshare     Samba Lab Share
    \\LINUXSERVER\IPC$        IPC Service

# Connect interactively with smbclient
[root@client ~]# smbclient //192.168.1.10/myshare -U sambauser1
Enter sambauser1's password:
Domain=[WORKGROUP] OS=[Unix] Server=[Samba 4.1.1]
smb: \> ls
  .                       D        0  Mon Jan  1 10:00:00 2024
  ..                      D        0  Mon Jan  1 09:00:00 2024
  testfile.txt            A     1024  Mon Jan  1 10:05:00 2024
smb: \> get testfile.txt
getting file \testfile.txt of size 1024 as testfile.txt
smb: \> exit

# Mount the share permanently
[root@client ~]# mkdir -p /mnt/standaloneShare
[root@client ~]# mount.cifs //192.168.1.10/myshare /mnt/standaloneShare \
  -o username=sambauser1,password=Pass@123

# Verify it mounted
[root@client ~]# df -h | grep cifs
//192.168.1.10/myshare  50G  10G  40G  20%  /mnt/standaloneShare

# Test read/write access
[root@client ~]# touch /mnt/standaloneShare/testfile_from_client.txt
[root@client ~]# ls /mnt/standaloneShare/
testfile.txt  testfile_from_client.txt
```

---

### 7.2 🟡 Domain Member Server Lab

A domain member server is a Linux/Samba server that **joins a Windows domain** (either NT4 or Active Directory). It still shares files, but **authentication is done by the domain controller** — not locally.

> 🧠 **Simple analogy:** A domain member is like an employee who needs to swipe their company ID card (domain credentials) to enter a department's server room. The company security (domain controller) decides if you're allowed in.

#### 🔑 When to use:

- Your company has a Windows domain (NT4 or Active Directory)
- Users should log in with their domain credentials
- Centralized authentication is needed

#### There are two sub-types:

##### Sub-type A: NT4 Domain Member

```bash
# ─────────────────────────────────────────
# STEP 1: Edit smb.conf for NT4 domain
# ─────────────────────────────────────────
[root@server ~]# vi /etc/samba/smb.conf
```

```ini
[global]
        workgroup = NT4DOMAIN
        netbios name = MEMBERSERVER
        security = domain

[deptshare]
        comment = Department Share
        path = /dept-share
        valid users = @NT4DOMAIN+staff
        writable = yes
        browsable = yes
```

```bash
# ─────────────────────────────────────────
# STEP 2: ⚠️ JOIN THE DOMAIN FIRST
# (Must do this BEFORE starting smb!)
# ─────────────────────────────────────────
[root@server ~]# net join -U administrator
Enter administrator's password:
Joined domain NT4DOMAIN.

# ─────────────────────────────────────────
# STEP 3: Now start smb and winbind
# ─────────────────────────────────────────
[root@server ~]# systemctl start smb nmb winbind
[root@server ~]# systemctl enable smb nmb winbind
```

##### Sub-type B: Active Directory (ADS) Domain Member

```bash
# ─────────────────────────────────────────
# STEP 1: Edit smb.conf for Active Directory
# ─────────────────────────────────────────
[root@server ~]# vi /etc/samba/smb.conf
```

```ini
[global]
        realm = EXAMPLE.COM
        security = ADS
        password server = kerberos.example.com

        # NOTE: realm MUST be in ALL CAPITAL LETTERS
        # password server only needed if AD and Kerberos
        # are on DIFFERENT servers

[adshare]
        comment = Active Directory Share
        path = /ad-share
        writable = yes
        browsable = yes
```

```bash
# ─────────────────────────────────────────
# STEP 2: Join Active Directory
# ─────────────────────────────────────────
[root@server ~]# net ads join -U administrator
Enter administrator's password:
Using short domain name -- EXAMPLE
Joined 'MEMBERSERVER' to dns domain 'example.com'

# ─────────────────────────────────────────
# STEP 3: Start services
# ─────────────────────────────────────────
[root@server ~]# systemctl start smb nmb winbind
[root@server ~]# systemctl enable smb nmb winbind
```

#### 📡 Access Domain Member Server from Windows

```
\\MEMBERSERVER\deptshare
```

When prompted, enter domain credentials:

- Username: `NT4DOMAIN\youruser` or `EXAMPLE\john`
- Password: your domain password

#### 📡 Access Domain Member Server from Linux

```bash
# Connect using domain username (use double backslash in shell)
[root@client ~]# smbclient //192.168.1.20/deptshare -U NT4DOMAIN\\john
Enter NT4DOMAIN\john's password:
Domain=[NT4DOMAIN] OS=[Unix] Server=[Samba 4.1.1]
smb: \>

# For Active Directory
[root@client ~]# smbclient //192.168.1.20/adshare -U EXAMPLE\\john
Enter EXAMPLE\john's password:
smb: \>

# Mount with domain credentials
[root@client ~]# mkdir -p /mnt/domainShare
[root@client ~]# mount.cifs //192.168.1.20/deptshare /mnt/domainShare \
  -o username=john,password=DomainPass@123,domain=NT4DOMAIN

# Verify mount
[root@client ~]# df -h | grep cifs
//192.168.1.20/deptshare  100G  20G  80G  20%  /mnt/domainShare
```

---

### 7.3 🔴 Domain Controller Lab

> ⚠️ **Critical limitation from the PDF:**  
> Samba **CANNOT** be configured as an **Active Directory Primary Domain Controller (PDC)**.  
> It CAN be configured as a **Windows NT4-style domain controller** only.

A domain controller manages user accounts and authenticates everyone who logs into the domain. It is similar to a **NIS server in Linux** — it holds a central database of users and groups.

#### 🔑 When to use:

- You need a central authentication server for a small Windows NT4-style domain
- You want Linux to act as the domain controller (without Active Directory)

#### 📋 Complete Lab Steps

```bash
# ─────────────────────────────────────────
# STEP 1: Edit smb.conf for NT4-style PDC
# ─────────────────────────────────────────
[root@pdc ~]# vi /etc/samba/smb.conf
```

```ini
[global]
        workgroup = MYNT4DOMAIN
        netbios name = PDC
        server string = Samba NT4 Domain Controller
        security = user

        # Domain controller settings
        domain master = yes
        local master = yes
        preferred master = yes
        os level = 65
        domain logons = yes

        # Logon scripts and profiles
        logon path = \\%N\profiles\%U
        logon drive = H:
        logon home = \\%N\%U

[netlogon]
        comment = Network Logon Service
        path = /var/lib/samba/netlogon
        guest ok = yes
        browsable = no

[profiles]
        comment = User Profiles
        path = /var/lib/samba/profiles
        browsable = no
        writable = yes
```

```bash
# ─────────────────────────────────────────
# STEP 2: Create required directories
# ─────────────────────────────────────────
[root@pdc ~]# mkdir -p /var/lib/samba/netlogon
[root@pdc ~]# mkdir -p /var/lib/samba/profiles
[root@pdc ~]# chmod 777 /var/lib/samba/profiles
```

```bash
# ─────────────────────────────────────────
# STEP 3: Start all services including winbind
# ─────────────────────────────────────────
[root@pdc ~]# systemctl start smb nmb winbind
[root@pdc ~]# systemctl enable smb nmb winbind
```

```bash
# ─────────────────────────────────────────
# STEP 4: Add a domain admin user
# ─────────────────────────────────────────
[root@pdc ~]# useradd domainadmin
[root@pdc ~]# smbpasswd -a domainadmin
New SMB password:
Retype new SMB password:
Added user domainadmin.

# Make this user a domain admin
[root@pdc ~]# net rpc rights grant domainadmin \
  SeMachineAccountPrivilege SePrintOperatorPrivilege \
  SeAddUsersPrivilege SeDiskOperatorPrivilege \
  SeRemoteShutdownPrivilege -U domainadmin
```

#### 📡 Access Domain Controller from Windows

On the Windows client machine:

1. Right-click **My Computer** → Properties → Computer Name → Change
2. Select **Domain**, type `MYNT4DOMAIN`
3. Enter domain admin credentials
4. Reboot Windows
5. At login screen, select **Log on to: MYNT4DOMAIN**

After joining, access shared resources:

```
\\PDC\netlogon
\\PDC\profiles
```

#### 📡 Access Domain Controller from Linux

```bash
# ── On the Linux client machine ──

# Verify winbind is running
[root@client ~]# systemctl status winbind
Active: active (running)

# List ALL domain users
[root@client ~]# wbinfo -u
MYNT4DOMAIN+administrator
MYNT4DOMAIN+domainadmin
MYNT4DOMAIN+john
MYNT4DOMAIN+mary

# List ALL domain groups
[root@client ~]# wbinfo -g
MYNT4DOMAIN+Domain Admins
MYNT4DOMAIN+Domain Users
MYNT4DOMAIN+Domain Guests

# Test user authentication against domain controller
[root@client ~]# wbinfo -a MYNT4DOMAIN\\john%Pass@123
plaintext password authentication succeeded
challenge/response password authentication succeeded

# Find the domain controller by NetBIOS name
[root@client ~]# nmblookup PDC
192.168.1.30 PDC<00>

# Connect to the netlogon share on the PDC
[root@client ~]# smbclient //192.168.1.30/netlogon -U domainadmin
Enter domainadmin's password:
smb: \>
```

---

## 8. 🪟 Access Linux Shares from Windows

Once your Samba server is running, Windows users can access it in multiple ways:

### Method 1 — Using Run Dialog

Press `Win + R` and type:

```
\\LINUXSERVER\sharename
```

### Method 2 — Browse All Shares

Press `Win + R` and type:

```
\\LINUXSERVER
```

You will see a list of all available shares.

### Method 3 — Map as a Network Drive (Permanent)

1. Open **File Explorer** → This PC
2. Click **Map network drive**
3. Drive letter: `Z:` (or any letter)
4. Folder: `\\LINUXSERVER\myshare`
5. Check **"Reconnect at sign-in"** for permanent mounting
6. Enter credentials: `sambauser1` / Samba password

> 🧠 **Remember:** Windows username must match the Linux username OR be mapped in `/etc/samba/smbusers`. If they are the same (e.g. both `john`), no mapping is needed — just add a Samba password with `smbpasswd -a john`.

---

## 9. 🐧 Access Windows Shares from Linux

From a Linux client, you can access Windows or Samba shares using several tools:

### Tool 1 — `findsmb` (Discover Servers)

```bash
[root@client ~]# findsmb
```

**Output:**

```
*=DMB
+=LMB

IP ADDR         NETBIOS NAME     WORKGROUP   OS              VERSION
----------------------------------------------------------------
192.168.1.10   LINUXSERVER      WORKGROUP   Unix            Samba 4.1.1
192.168.1.50   WINDOWSPC        WORKGROUP   Windows 10 Pro  10.0
```

### Tool 2 — `smbtree` (Browse All Shares)

```bash
[root@client ~]# smbtree
```

**Output:**

```
WORKGROUP
  \\WINDOWSPC          Windows 10 Pro
    \\WINDOWSPC\SharedDocs   Shared Documents
    \\WINDOWSPC\C$           Default Share
  \\LINUXSERVER        My Samba Server
    \\LINUXSERVER\myshare    Samba Lab Share
```

### Tool 3 — `smbclient` (Interactive FTP-style Access)

```bash
# Connect to a Windows share
[root@client ~]# smbclient //192.168.1.50/SharedDocs -U john
Enter john's password:
Domain=[WORKGROUP] OS=[Windows 10 Pro] Server=[]
smb: \>

# Useful commands inside smbclient:
smb: \> ls                    # list files
smb: \> get filename.txt      # download a file
smb: \> put localfile.txt     # upload a file
smb: \> mkdir newfolder       # create a folder
smb: \> help                  # see all commands
smb: \> exit                  # exit smbclient
```

### Tool 4 — `mount.cifs` (Permanently Mount a Share)

```bash
# Step 1: Install cifs-utils (if not already installed)
[root@client ~]# yum install cifs-utils -y

# Step 2: Create mount point
[root@client ~]# mkdir -p /mnt/windows-share

# Step 3: Mount the share
[root@client ~]# mount.cifs //192.168.1.50/SharedDocs /mnt/windows-share \
  -o username=john,password=Pass@123

# Step 4: Verify
[root@client ~]# df -h | grep cifs
//192.168.1.50/SharedDocs  500G  100G  400G  20%  /mnt/windows-share

# Step 5: Access files normally
[root@client ~]# ls /mnt/windows-share/
Document1.docx   Report.pdf   Photos/

# Step 6: Unmount when done
[root@client ~]# umount /mnt/windows-share
```

### Tool 5 — `nmblookup` (Find IP from NetBIOS Name)

```bash
# Find IP address of a machine by its NetBIOS name
[root@client ~]# nmblookup WINDOWSPC
192.168.1.50 WINDOWSPC<00>

[root@client ~]# nmblookup LINUXSERVER
192.168.1.10 LINUXSERVER<00>
```

---

## 10. 👥 `smbusers` — User Mapping

Sometimes the **Windows username is different from the Linux username**. Samba handles this with the `/etc/samba/smbusers` file.

### Default Content of `/etc/samba/smbusers`

```
root = administrator admin
nobody = guest pcguest smbguest
```

> 🧠 **Reading the format:** `linux_username = windows_username(s)`
> 
> - Line 1: Linux `root` user = Windows `administrator` or `admin`
> - Line 2: Linux `nobody` user = Windows `guest`, `pcguest`, or `smbguest`

### Add a Custom Mapping

**Scenario:** A Windows user named `wuser` wants to access files that belong to Linux user `oracle`.

```bash
# Step 1: Edit the smbusers file
[root@server ~]# vi /etc/samba/smbusers
```

Add this line:

```
oracle = wuser
```

```bash
# Step 2: Add a Samba password for the oracle Linux user
[root@server ~]# smbpasswd -a oracle
New SMB password:
Retype new SMB password:
Added user oracle.
```

Now when the Windows user `wuser` connects, Samba maps them to Linux user `oracle` automatically.

### View and Manage Samba Users

```bash
# List all Samba users
[root@server ~]# pdbedit -L
sambauser1:1001:
oracle:1002:
domainadmin:1003:

# Delete a Samba user
[root@server ~]# smbpasswd -x olduser
Deleted user olduser.

# Disable a Samba user (without deleting)
[root@server ~]# smbpasswd -d sambauser1
Disabled user sambauser1.

# Re-enable a Samba user
[root@server ~]# smbpasswd -e sambauser1
Enabled user sambauser1.
```

---

## 11. 🛠️ All Samba Utilities

These are all the command-line tools that come with Samba packages.

|Command|Package|What It Does|
|---|---|---|
|`smbtree`|`samba-client`|Text-based SMB network browser — shows domains, servers, shares|
|`smbclient`|`samba-client`|FTP-like client to access SMB/CIFS shares and printers|
|`smbpasswd`|`samba-common`|Add/modify/delete a user's Samba password|
|`smbcacls`|`samba-client`|View/modify Windows ACLs on Samba shared files|
|`nmblookup`|`samba-client`|Query NetBIOS names and resolve them to IP addresses|
|`net`|`samba`|Admin tool for Samba and remote CIFS servers (like Windows `net`)|
|`rpcclient`|`samba-client`|Execute Microsoft RPC functions from Linux|
|`smbcontrol`|`samba`|Send control messages to running smbd/nmbd/winbindd|
|`smbspool`|`samba-client`|Send a print file to an SMB printer|
|`smbstatus`|`samba`|Show active connections to the Samba server|
|`smbtar`|`samba-client`|Backup/restore Windows shares to Linux tape archive|
|`testparm`|`samba-common`|Validate the `/etc/samba/smb.conf` syntax|
|`wbinfo`|`samba-winbind-clients`|Get info from winbindd (domain users, groups)|
|`smbcquotas`|`samba-client`|Manage NTFS disk quotas on SMB file shares|
|`smbget`|`samba-client`|wget-style tool to download files over SMB|
|`findsmb`|`samba-client`|Query a subnet for all available Samba servers|

### 🔍 How to Find Which Package Provides a Command

```bash
# Step 1: Find the full path of the command
[root@server ~]# which smbtree
/bin/smbtree

# Step 2: Find which RPM package owns that binary
[root@server ~]# rpm -qf /bin/smbtree
samba-client-4.1.1-31.el7.x86_64
```

### 💡 The `net` Command (Most Powerful Admin Tool)

```bash
# Syntax: net <protocol> [options]
# Protocol can be: ads (Active Directory), rap (Win9x/NT3), rpc (Windows NT4+)

# Join a domain
[root@server ~]# net rpc join -U administrator

# List shares on a remote server
[root@server ~]# net rpc share list -S 192.168.1.50 -U john

# Add a new share on a remote Samba server
[root@server ~]# net rpc share add newshare=/mnt/newdir -S 192.168.1.10 -U admin

# Get help
[root@server ~]# net --help
```

---

## 12. 🔥 Firewall and SELinux

### 🔥 Firewall Configuration

Samba won't work through the firewall unless you open the right ports!

```bash
# Add Samba to firewall permanently
[root@server ~]# firewall-cmd --permanent --add-service=samba
success

# Reload firewall to apply changes
[root@server ~]# firewall-cmd --reload
success

# Verify samba is in the allowed services
[root@server ~]# firewall-cmd --list-services
dhcpv6-client samba ssh
```

**What ports does this open?**

|Port|Protocol|Purpose|
|---|---|---|
|445|TCP|SMB3 — main file sharing|
|137|UDP|NetBIOS name service (nmbd)|
|138|UDP|NetBIOS datagram service|
|139|TCP|NetBIOS session service (legacy)|

---

## 13. 🔎 Troubleshooting Commands

```bash
# ── Check who is currently connected to your Samba server ──
[root@server ~]# smbstatus
Samba version 4.1.1
PID     Username    Group       Machine         Protocol Version  Signing
------------------------------------------------------------------------
1234    sambauser1  sambauser1  192.168.1.50    SMB3_02

Service      pid    Machine        Connected at
-----------------------------------------------------
myshare      1234   192.168.1.50   Mon Jan  1 10:15:00 2024

# ── Validate config file (verbose mode) ──
[root@server ~]# testparm -v

# ── Look up a machine's IP from its name ──
[root@client ~]# nmblookup LINUXSERVER
192.168.1.10 LINUXSERVER<00>

# ── View live Samba logs ──
[root@server ~]# tail -f /var/log/samba/log.smbd

# ── Check SELinux denials ──
[root@server ~]# tail -f /var/log/audit/audit.log | grep denied

# ── Test authentication as a user ──
[root@client ~]# wbinfo -a domain\\username%password
plaintext password authentication succeeded
challenge/response password authentication succeeded

# ── Check all active Samba processes ──
[root@server ~]# ps aux | grep smb
root  1234  smbd -D
root  1235  smbd -D
root  1300  nmbd -D
```

### 🩺 Common Problems and Solutions

|Problem|Possible Cause|Solution|
|---|---|---|
|Can't see shares on Windows|Firewall blocking|`firewall-cmd --add-service=samba`|
|"Access Denied" on share|SELinux blocking|`setsebool -P samba_export_all_rw on`|
|Authentication fails|Wrong password type|Use `smbpasswd -a user` (Samba password ≠ Linux password)|
|Share not showing up|Config syntax error|Run `testparm` to check|
|Can't join domain|smb started before join|`net join` first, then `systemctl start smb`|
|Windows can't find server|`nmbd` not running|`systemctl start nmb`|

---

## 14. 📋 Quick Reference Cheatsheet

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SAMBA QUICK REFERENCE CHEATSHEET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSTALL
  yum install samba samba-client samba-common cifs-utils -y

SERVICES
  systemctl start smb nmb        ← Start
  systemctl enable smb nmb       ← Enable at boot
  systemctl restart smb nmb      ← Full restart (drops connections)
  systemctl reload smb           ← Soft reload (no disconnection)
  systemctl status smb           ← Check status

CONFIG
  /etc/samba/smb.conf            ← Main config
  testparm                       ← ALWAYS validate after editing!

USERS (Samba has its OWN password db!)
  smbpasswd -a username          ← Add user
  smbpasswd -x username          ← Delete user
  smbpasswd -d username          ← Disable user
  smbpasswd -e username          ← Enable user
  pdbedit -L                     ← List all Samba users

USER MAPPING
  /etc/samba/smbusers            ← linux_user = windows_user

ACCESS FROM WINDOWS
  \\LINUXSERVER\sharename        ← Access share directly
  \\LINUXSERVER                  ← Browse all shares

ACCESS FROM LINUX
  findsmb                        ← Find servers on subnet
  smbtree                        ← Browse all shares
  smbclient //ip/share -U user   ← Interactive access
  mount.cifs //ip/share /mnt     ← Mount permanently
  nmblookup SERVERNAME           ← Resolve NetBIOS → IP

DOMAIN COMMANDS
  net join -U admin              ← Join NT4 domain
  net ads join -U admin          ← Join Active Directory
  wbinfo -u                      ← List domain users
  wbinfo -g                      ← List domain groups
  wbinfo -a domain\\user%pass    ← Test domain auth

FIREWALL + SELINUX (RHEL)
  firewall-cmd --add-service=samba --permanent
  firewall-cmd --reload

TROUBLESHOOTING
  smbstatus                      ← Who's connected now
  testparm -v                    ← Verbose config check
  tail -f /var/log/samba/log.smbd ← Live server log
  tail -f /var/log/audit/audit.log | grep denied ← SELinux denials

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🗺️ Full Network Topology

```
                      TCP/IP NETWORK — Port 445 (SMB3)
    ═══════════════════════════════════════════════════════════

    ┌─────────────┐    \\LINUXSERVER\share    ┌──────────────────┐
    │ Windows PC  │ ──────────────────────►  │ Stand-alone      │
    │ 192.168.1.50│                          │ LINUXSERVER      │
    └─────────────┘                          │ security = user  │
                                             └──────────────────┘

    ┌─────────────┐  smbclient //ip/share    ┌──────────────────┐
    │ Linux client│ ──────────────────────►  │ Domain Member    │
    │ 192.168.1.20│    mount.cifs //ip/share │ MEMBERSERVER     │
    └─────────────┘                          │ security = domain│
                                             └──────────────────┘

    ┌─────────────┐  domain login / wbinfo   ┌──────────────────┐
    │ Win + Linux │ ──────────────────────►  │ Domain Controller│
    │   clients   │                          │ PDC              │
    └─────────────┘                          │ NT4-style only   │
                                             └──────────────────┘
```

---

> 📚 **Reference:** Yoinsights Technologies Pvt. Ltd. — Samba Server Module  
> 🌐 **Samba Official Docs:** https://www.samba.org  
> 📖 **Man pages:** `man smb.conf` | `man smbclient` | `man smbpasswd`  
> 🔧 **GUI Tools:** https://www.samba.org/samba/GUI/