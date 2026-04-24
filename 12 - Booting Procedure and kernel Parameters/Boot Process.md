# 🐧 Linux Boot Process — RHEL/CentOS Complete Guide

> **System:** Red Hat Enterprise Linux 9.7 (Plow) | Kernel: `5.14.0-611.5.1.el9_7.x86_64`

---

## 🗺️ Boot Process Overview

```
Power ON
   │
   ▼
┌─────────┐    ┌─────────┐    ┌──────────────┐    ┌────────┐    ┌─────────┐    ┌────────┐
│BIOS/UEFI│───▶│MBR/GPT  │───▶│ GRUB2        │───▶│ Kernel │───▶│ systemd │───▶│ Target │
│(Firmware│    │(512 bytes│   │ Bootloader   │    │+initram│    │ (PID 1) │    │(login) │
│ POST)   │    │on disk) │    │/boot/grub2/  │    │ fs     │    │         │    │        │
└─────────┘    └─────────┘    └──────────────┘    └────────┘    └─────────┘    └────────┘
```

| Stage | Role | Key Files |
|-------|------|-----------|
| BIOS/UEFI | Hardware init, POST, finds bootloader | Firmware (chip) |
| MBR/GPT | Points to GRUB2 | First 512 bytes of disk |
| GRUB2 | Loads kernel + initramfs | `/boot/grub2/grub.cfg` |
| Kernel | Core OS, mounts root fs | `/boot/vmlinuz-*` |
| initramfs | Temporary root filesystem | `/boot/initramfs-*.img` |
| systemd | PID 1, starts all services | `/lib/systemd/systemd` |
| Target | Defines final system state | `/etc/systemd/system/default.target` |

---

## ⚡ Stage 1: BIOS/UEFI

**BIOS** (Basic Input/Output System) or **UEFI** (Unified Extensible Firmware Interface) is the first code that runs when you power on the machine.

### What it does:
- Performs **POST** (Power-On Self-Test) — checks CPU, RAM, storage
- Detects bootable devices (HDD, SSD, USB, CD)
- Loads the **MBR** (legacy) or **EFI partition** (UEFI) into memory
- Hands control to the bootloader

### UEFI vs BIOS:
| Feature | BIOS | UEFI |
|---------|------|------|
| Disk support | MBR (max 2TB) | GPT (up to 9.4ZB) |
| Secure Boot | ❌ | ✅ |
| Boot speed | Slower | Faster |
| Interface | Text only | GUI possible |

> 💡 In Image 6, the system uses UEFI (you can see **UEFI Firmware Settings** in the GRUB menu).

---

## 💾 Stage 2: MBR / GPT

### MBR (Master Boot Record)
- Located in the **first 512 bytes** of the disk
- Contains a small bootloader code (446 bytes) + partition table (64 bytes) + signature (2 bytes)
- The MBR code loads **Stage 1.5 / Stage 2** of GRUB2

### GPT (GUID Partition Table)
- Modern replacement for MBR (used with UEFI)
- Supports more than 4 primary partitions
- GRUB2 is installed in the **EFI System Partition** (`/boot/efi`)

### Relevant commands:
```bash
# Check partition table type
fdisk -l /dev/sda

# View EFI partition
ls /boot/efi/

# Check if system uses UEFI or BIOS
ls /sys/firmware/efi   # If directory exists → UEFI
```

---

## 🥾 Stage 3: GRUB2 Bootloader

**GRUB2** (GRand Unified Bootloader version 2) is the default bootloader for RHEL/CentOS 7+.

### What it does:
- Displays the boot menu (kernel selection)
- Loads the selected **kernel** (`vmlinuz`) into memory
- Loads **initramfs** (initial RAM filesystem)
- Passes kernel parameters (from `grub.cfg`)

### GRUB2 Directory Structure:
```
/boot/
├── grub2/
│   ├── grub.cfg          ← Auto-generated GRUB config (DO NOT EDIT MANUALLY)
│   ├── grubenv           ← Stores saved environment variables (default kernel, etc.)
│   └── themes/           ← GRUB themes
└── efi/                  ← EFI boot files (UEFI systems only)
    └── EFI/
        └── redhat/
            └── grub.efi
```

### Key GRUB2 Files:

| File | Purpose |
|------|---------|
| `/etc/default/grub` | ✅ **Edit this** — Human-readable GRUB settings |
| `/boot/grub2/grub.cfg` | ⚠️ Auto-generated — Never edit manually |
| `/boot/grub2/grubenv` | Stores default boot entry, boot-once settings |
| `/etc/grub.d/` | Scripts that build `grub.cfg` |

### Viewing the GRUB menu (Image 11):
When you reboot with `GRUB_TIMEOUT_STYLE=menu`, you'll see:
```
GRUB version 2.06

  ┌──────────────────────────────────────────────┐
  │ *Red Hat Enterprise Linux (5.14.0-611.5.1... │  ← Default entry
  │  Red Hat Enterprise Linux (0-rescue-f943...) │  ← Rescue kernel
  │  UEFI Firmware Settings                      │  ← UEFI settings
  └──────────────────────────────────────────────┘

  Use ↑ and ↓ to select. Press 'e' to edit before booting.
  Press 'c' for command-line. ESC to return.
```

---

## 🧠 Stage 4: Kernel & initramfs

### Kernel (`vmlinuz`)
The compressed Linux kernel binary. Once loaded by GRUB2:
1. Decompresses itself into RAM
2. Initializes hardware (CPU, memory, devices)
3. Mounts the **initramfs** as a temporary root filesystem
4. Runs `/init` (inside initramfs) which is `systemd`
5. Finds and mounts the real root filesystem (`/`)
6. Pivots root to the real filesystem
7. Executes `/sbin/init` → systemd (PID 1)

### Files in `/boot/` (from Image 6):
```bash
[root@client1 admin]# ls /boot/
config-5.14.0-611.5.1.el9_7.x86_64       ← Kernel build config
efi/                                       ← EFI partition
grub2/                                     ← GRUB2 config dir
initramfs-0-rescue-f943bea8acba44be9...img ← Rescue initramfs
initramfs-5.14.0-611.5.1.el9_7.x86_64.img ← Main initramfs
initramfs-5.14.0-611.5.1.el9_7.x86_64kdump.img ← Kdump initramfs
loader/                                    ← Boot loader entries
lost+found/
symvers-5.14.0-611.5.1.el9_7.x86_64.gz   ← Kernel symbol versions
System.map-5.14.0-611.5.1.el9_7.x86_64   ← Kernel symbol table
vmlinuz-0-rescue-f943bea8acba44be9...     ← Rescue kernel
vmlinuz-5.14.0-611.5.1.el9_7.x86_64      ← Main kernel
```

### All Kernel Files Explained:

| File | Description |
|------|-------------|
| `vmlinuz-<version>` | 🔵 **The actual kernel** — compressed executable |
| `initramfs-<version>.img` | 🔵 **Initial RAM filesystem** — temporary root fs with drivers & tools |
| `initramfs-<version>kdump.img` | Used by kdump for kernel crash dumps |
| `System.map-<version>` | Kernel symbol table — maps function names to memory addresses |
| `config-<version>` | Kernel compile-time configuration |
| `symvers-<version>.gz` | Module symbol versions for compatibility checks |
| `vmlinuz-0-rescue-*` | Rescue kernel (minimal, for recovery) |
| `initramfs-0-rescue-*.img` | Rescue initramfs (used with rescue kernel) |

### initramfs Deep Dive:
```bash
# View contents of initramfs
lsinitrd /boot/initramfs-$(uname -r).img

# Rebuild initramfs (after kernel module changes)
dracut --force /boot/initramfs-$(uname -r).img $(uname -r)

# Check current kernel version
uname -r
# Output: 5.14.0-611.5.1.el9_7.x86_64
```

---

## ⚙️ Stage 5: systemd

**systemd** is PID 1 — the first process started by the kernel and the parent of all other processes.

### Verify systemd is running (Image 2):
```bash
[admin@adminpc ~]$ ps -ef | grep systemd
root   416   1   0 07:02 ?   /usr/lib/systemd/systemd-journald
root   517   1   0 07:02 ?   /usr/lib/systemd/systemd-udevd
root   878   1   0 07:02 ?   /usr/lib/systemd/systemd-oomd
root   880   1   0 07:02 ?   /usr/lib/systemd/systemd-resolved
root   881   1   0 07:02 ?   /usr/lib/systemd/systemd-timesyncd
root  1021   1   0 07:02 ?   /usr/lib/systemd/systemd-logind
root  1025   1   0 07:02 ?   /usr/lib/systemd/systemd-machined
adminpc 2742 1  0 07:02 ?   /usr/lib/systemd/systemd --user
```

### Key systemd Directories:

| Path | Description |
|------|-------------|
| `/lib/systemd/system/` | Default unit files (don't edit these) |
| `/etc/systemd/system/` | ✅ Admin customizations (overrides above) |
| `/run/systemd/system/` | Runtime units (temporary, lost on reboot) |
| `/usr/lib/systemd/systemd` | The systemd binary |

### Important systemd Commands:
```bash
systemctl list-units              # List all active units
systemctl list-units --failed     # List failed units
systemctl status <service>        # Status of a service
systemctl start <service>         # Start service (temporary)
systemctl stop <service>          # Stop service
systemctl enable <service>        # Enable on boot
systemctl disable <service>       # Disable on boot
systemctl daemon-reload           # Reload unit files
journalctl -xe                    # View systemd logs
```

---

## 🎯 Stage 6: Runlevels / Targets

### The Old Way vs New Way:

| Old Runlevel | systemd Target | Description |
|-------------|----------------|-------------|
| 0 | `poweroff.target` | Halt/shutdown |
| 1 | `rescue.target` | Single-user/rescue mode |
| 2,3,4 | `multi-user.target` | Multi-user CLI (no GUI) |
| 5 | `graphical.target` | Multi-user with GUI |
| 6 | `reboot.target` | Reboot |

> 💡 `/etc/inittab` is **obsolete** in RHEL 7+. As shown in Image 1:
> ```
> # inittab is no longer used.
> # ADDING CONFIGURATION HERE WILL HAVE NO EFFECT ON YOUR SYSTEM.
> # systemd uses 'targets' instead of runlevels.
> ```

### Check & Set Default Target:

```bash
# Check current runlevel (old style)
[root@client1 admin]# who -r
         run-level 5  2026-04-21 07:03

# Check current default target (new style)
[root@client1 ~]# systemctl get-default
graphical.target

# Set default to CLI (multi-user)
[root@client1 ~]# systemctl set-default multi-user.target
Removed "/etc/systemd/system/default.target".
Created symlink /etc/systemd/system/default.target → /usr/lib/systemd/system/multi-user.target.

# Set default back to GUI
[root@client1 ~]# systemctl set-default graphical.target
Removed "/etc/systemd/system/default.target".
Created symlink /etc/systemd/system/default.target → /usr/lib/systemd/system/graphical.target.
```

### Switch Target Temporarily (Without Reboot):
```bash
# Switch to CLI right now (no reboot)
systemctl isolate multi-user.target

# Switch to GUI right now (no reboot)
systemctl isolate graphical.target

# Start GUI temporarily from CLI (startx)
startx
# This starts a graphical session temporarily.
# After you exit/logout, you return to CLI.
# The DEFAULT TARGET is unchanged.
```

### How `default.target` Works:
```bash
# It's just a symlink!
ls -la /etc/systemd/system/default.target
# → /usr/lib/systemd/system/multi-user.target   (when CLI is default)
# → /usr/lib/systemd/system/graphical.target    (when GUI is default)
```

---

## 📁 All Configuration Files Reference

### GRUB2 Files:
| File | Editable? | Purpose |
|------|-----------|---------|
| `/etc/default/grub` | ✅ YES | Main GRUB settings (timeout, kernel args) |
| `/boot/grub2/grub.cfg` | ❌ NO (auto-generated) | Actual GRUB config read at boot |
| `/boot/grub2/grubenv` | Via `grub2-editenv` | Saved variables (default entry) |
| `/etc/grub.d/00_header` | ✅ Advanced | GRUB header script |
| `/etc/grub.d/10_linux` | ✅ Advanced | Linux boot entries |
| `/etc/grub.d/40_custom` | ✅ YES | Custom menu entries |

### Kernel & Boot Files:
| File | Purpose |
|------|---------|
| `/boot/vmlinuz-$(uname -r)` | Compressed kernel image |
| `/boot/initramfs-$(uname -r).img` | Initial RAM disk |
| `/boot/System.map-$(uname -r)` | Kernel symbol table |
| `/boot/config-$(uname -r)` | Kernel build configuration |

### systemd Files:
| File/Dir | Purpose |
|----------|---------|
| `/etc/systemd/system/default.target` | Symlink → default boot target |
| `/lib/systemd/system/*.target` | Built-in target definitions |
| `/lib/systemd/system/*.service` | Service unit files |
| `/etc/systemd/system/` | Admin override unit files |
| `/etc/systemd/system.conf` | Global systemd configuration |

### Legacy (Obsolete but present):
| File | Status |
|------|--------|
| `/etc/inittab` | ❌ Ignored by systemd (kept for reference only) |
| `/etc/rc.d/` | ❌ Legacy SysV init scripts |

---

## 🔧 GRUB2 Configuration Deep Dive

### Step 1: Edit `/etc/default/grub`

```bash
nano /etc/default/grub
```

**File contents (Image 8 & 10):**
```bash
GRUB_TIMEOUT=15                          # ← Wait 15 seconds at boot menu
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved                       # ← Remember last chosen entry
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=1G-2G:192M,2G-64G:256M,64G-:512M \
  resume=/dev/mapper/rhel-swap \
  rd.lvm.lv=rhel/root \
  rd.lvm.lv=rhel-swap rhgb quiet"       # ← Kernel command-line args
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
GRUB_TIMEOUT_STYLE=menu                  # ← Show menu (added manually)
```

### Key Settings Explained:

| Setting | Values | Description |
|---------|--------|-------------|
| `GRUB_TIMEOUT` | Number (seconds) | How long to show menu before auto-boot. `-1` = wait forever |
| `GRUB_DEFAULT` | `0`, `saved`, entry name | Which entry to boot. `saved` uses `grubenv` |
| `GRUB_TIMEOUT_STYLE` | `menu`, `countdown`, `hidden` | `menu` = always show; `hidden` = don't show unless key pressed |
| `GRUB_CMDLINE_LINUX` | Space-separated params | Extra kernel parameters |
| `rhgb` | Flag | Red Hat Graphical Boot (splash screen) |
| `quiet` | Flag | Suppress most boot messages |

### Step 2: Regenerate `grub.cfg`

After editing `/etc/default/grub`, regenerate the actual config:

```bash
# BIOS/MBR systems:
grub2-mkconfig -o /boot/grub2/grub.cfg

# UEFI systems:
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
```

**Output (Image 9):**
```
Generating grub configuration file ...
Adding boot menu entry for UEFI Firmware Settings ...
done
```

### Step 3: Show GRUB Menu Always (Fix Hidden Menu)

```bash
# Method 1: Edit /etc/default/grub
# Add or change: GRUB_TIMEOUT_STYLE=menu
# Then regenerate config

# Method 2: Unset menu_auto_hide in grubenv
grub2-editenv - unset menu_auto_hide

# Verify grubenv
cat /boot/grub2/grubenv
```

### grubby — Manage Kernel Entries:

```bash
# Show default kernel
grubby --default-kernel
# Output: /boot/vmlinuz-5.14.0-611.5.1.el9_7.x86_64

# Set a specific kernel as default
grubby --set-default /boot/vmlinuz-5.14.0-611.5.1.el9_7.x86_64

# Add kernel parameter
grubby --update-kernel=DEFAULT --args="ipv6.disable=1"

# Remove kernel parameter
grubby --update-kernel=DEFAULT --remove-args="rhgb quiet"

# List all kernels
grubby --info=ALL
```

---

## 📦 Kernel Files in `/boot`

```bash
[root@client1 admin]# ls /boot/
```

| File | What it does |
|------|-------------|
| `vmlinuz-5.14.0-611.5.1.el9_7.x86_64` | 🔵 **The Linux kernel** — loads into RAM at boot |
| `initramfs-5.14.0-611.5.1.el9_7.x86_64.img` | 🔵 **Temporary root filesystem** — contains drivers to mount real `/` |
| `initramfs-5.14.0-611.5.1.el9_7.x86_64kdump.img` | 💥 Used when kernel crashes (kdump) to capture crash dump |
| `System.map-5.14.0-611.5.1.el9_7.x86_64` | 📋 Symbol table — maps kernel function names → memory addresses (used for debugging) |
| `config-5.14.0-611.5.1.el9_7.x86_64` | ⚙️ Shows exactly how the kernel was compiled (which features enabled/disabled) |
| `symvers-5.14.0-611.5.1.el9_7.x86_64.gz` | 🔗 Module symbol versions — ensures loaded modules are compatible with this kernel |
| `vmlinuz-0-rescue-f943bea8acba44be9c8bcdcc2800fdbf` | 🆘 Rescue kernel (minimal, for recovery) |
| `initramfs-0-rescue-*.img` | 🆘 Rescue initramfs |
| `grub2/` | 📁 GRUB2 configuration directory |
| `efi/` | 📁 UEFI EFI partition |
| `loader/` | 📁 Boot loader entries (BLS — Boot Loader Specification) |

---

## 🔐 Reset Root Password (RHEL)

> ⚠️ **Requires physical/console access to the machine**

### Method 1: rd.break (Recommended for RHEL 7/8/9)

**Step 1:** Reboot the system
```bash
reboot
```

**Step 2:** At GRUB menu, press `e` to edit the boot entry

**Step 3:** Find the line starting with `linux` and add `rd.break` at the end:
```
linux /boot/vmlinuz-5.14.0-... ro crashkernel=... rhgb quiet rd.break
```

**Step 4:** Press `Ctrl+X` to boot with this modified entry

**Step 5:** You'll drop into an emergency shell. Run:
```bash
# Mount sysroot as read-write
mount -o remount,rw /sysroot

# Change root to the actual system
chroot /sysroot

# Now change the password
passwd root
# Enter new password twice

# Mark filesystem for SELinux relabeling (CRITICAL on RHEL!)
touch /.autorelabel

# Exit chroot
exit

# Exit emergency shell (system will reboot and relabel)
exit
```

**Step 6:** System reboots and SELinux relabels all files (takes a few minutes). After that, log in with the new password.

> ⚠️ **The `touch /.autorelabel` step is critical on RHEL!** Without it, SELinux will deny access to the new `/etc/shadow` and login will fail.

### Method 2: init=/bin/bash (Alternative)

**Step 1:** At GRUB menu, press `e` to edit

**Step 2:** Find the `linux` line and replace `rhgb quiet` with:
```
init=/bin/bash
```

**Step 3:** Press `Ctrl+X` to boot

**Step 4:** At the bash prompt:
```bash
mount -o remount,rw /
passwd root
# Enter new password
touch /.autorelabel
exec /sbin/init
```

---

## 🔒 Set GRUB2 Password

Protecting GRUB2 with a password prevents unauthorized users from editing boot parameters or booting into single-user mode.

### Step 1: Generate Hashed Password

```bash
grub2-mkpasswd-pbkdf2
```

**Example interaction:**
```
Enter password: 
Reenter password: 
PBKDF2 hash of your password is:
grub.pbkdf2.sha512.10000.ABC123DEF456...longhashere...
```
> 📋 Copy the entire hash starting from `grub.pbkdf2.sha512...`

### Step 2: Add Password to GRUB Config

```bash
nano /etc/grub.d/40_custom
```

**Add these lines:**
```bash
#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.

set superusers="admin"
password_pbkdf2 admin grub.pbkdf2.sha512.10000.ABC123DEF456...YOUR_HASH_HERE...
```

> 💡 Replace `admin` with your desired username and paste your actual hash.

### Step 3: Regenerate GRUB Config

```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
# OR for UEFI:
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
```

### Step 4: Protect Specific Menu Entries (Optional)

To require password only for certain entries (not all), edit `/etc/grub.d/10_linux` or add to `40_custom`:

```bash
# Allow booting default entry without password
# but require password to edit
set superusers="admin"
password_pbkdf2 admin grub.pbkdf2.sha512.10000....

# In menu entry, add --unrestricted to allow booting without password:
menuentry "RHEL 9.7" --unrestricted {
    ...
}

# Or --users "" to allow any user (no auth needed) to boot:
menuentry "RHEL 9.7" --users "" {
    ...
}
```

### GRUB2 Password Commands Summary:

```bash
# Generate hashed password
grub2-mkpasswd-pbkdf2

# Edit custom GRUB file to add password
nano /etc/grub.d/40_custom

# Regenerate grub.cfg (BIOS)
grub2-mkconfig -o /boot/grub2/grub.cfg

# Regenerate grub.cfg (UEFI)
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

# Verify the password was added to grub.cfg
grep -i password /boot/grub2/grub.cfg
```

---

## 🔄 Practical Workflow: Switch Between Targets

### Scenario: Switch from GUI to CLI and back

**Check current state:**
```bash
[root@client1 ~]# who -r
         run-level 3  2026-04-21 07:32      ← Currently at CLI (runlevel 3)

[root@client1 ~]# systemctl get-default
multi-user.target                            ← Default is CLI
```

**Set GUI as permanent default:**
```bash
[root@client1 ~]# systemctl set-default graphical.target
Removed "/etc/systemd/system/default.target".
Created symlink /etc/systemd/system/default.target → /usr/lib/systemd/system/graphical.target.

[root@client1 ~]# reboot
# After reboot → boots into GUI (graphical.target)
```

**After reboot in GUI, set CLI as permanent default again:**
```bash
[root@client1 ~]# systemctl get-default
graphical.target

[root@client1 ~]# systemctl set-default multi-user.target
Removed "/etc/systemd/system/default.target".
Created symlink /etc/systemd/system/default.target → /usr/lib/systemd/system/multi-user.target.

[root@client1 ~]# reboot
# After reboot → boots into CLI (multi-user.target)
```

**Start GUI temporarily from CLI (without changing default):**
```bash
[root@client1 ~]# startx
# Opens graphical session
# When you log out of GUI, you return to CLI
# Default target is STILL multi-user.target
```

**Switch target without rebooting:**
```bash
# From GUI to CLI (immediately kills graphical session!)
systemctl isolate multi-user.target

# From CLI to GUI (starts graphical session)
systemctl isolate graphical.target
```

---

## 📊 Complete Command Reference

### Boot & Target Commands:
```bash
who -r                                    # Show current runlevel
systemctl get-default                     # Show default target
systemctl set-default multi-user.target   # Set CLI as default
systemctl set-default graphical.target    # Set GUI as default
systemctl isolate multi-user.target       # Switch to CLI NOW
systemctl isolate graphical.target        # Switch to GUI NOW
startx                                    # Temporarily start GUI
```

### GRUB2 Commands:
```bash
nano /etc/default/grub                           # Edit GRUB settings
grub2-mkconfig -o /boot/grub2/grub.cfg           # Regenerate config (BIOS)
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg  # Regenerate config (UEFI)
grub2-editenv - unset menu_auto_hide              # Force menu to show
grub2-editenv list                                # Show grubenv contents
grub2-mkpasswd-pbkdf2                             # Generate GRUB password hash
grubby --default-kernel                           # Show default kernel
grubby --info=ALL                                 # Show all kernel entries
```

### Kernel Commands:
```bash
uname -r                                  # Show running kernel version
uname -a                                  # Show all kernel info
lsinitrd /boot/initramfs-$(uname -r).img  # List initramfs contents
dracut --force                            # Rebuild initramfs
```

### systemd Commands:
```bash
systemctl status <service>               # Service status
systemctl start/stop/restart <service>   # Manage service
systemctl enable/disable <service>       # Auto-start on boot
systemctl list-units                     # List all units
systemctl list-units --failed            # List failed units
journalctl -xe                           # View logs
journalctl -b                            # Logs from current boot
journalctl -b -1                         # Logs from previous boot
```

---

## 🧩 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| GRUB menu not showing | `grub2-editenv - unset menu_auto_hide` or set `GRUB_TIMEOUT_STYLE=menu` |
| Boot into wrong target | `systemctl set-default <target>` then reboot |
| Forgot root password | Boot with `rd.break`, chroot, `passwd root`, `touch /.autorelabel` |
| `grub.cfg` changes not applying | Always run `grub2-mkconfig` after editing `/etc/default/grub` |
| System stuck in boot | Boot rescue kernel from GRUB menu |
| `initramfs` errors | Rebuild with `dracut --force` |

---

> 📌 **Remember:** `/etc/default/grub` → edit here → `grub2-mkconfig` → `/boot/grub2/grub.cfg` (auto-generated)

> 📌 **Remember:** `systemctl set-default` just changes a symlink at `/etc/systemd/system/default.target`

> 📌 **Remember:** After changing root password in recovery mode, **always** run `touch /.autorelabel` on RHEL for SELinux!

---

*Generated for RHEL 9.7 (Plow) | Kernel 5.14.0-611.5.1.el9_7.x86_64*
