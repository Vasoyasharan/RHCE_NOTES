# RHEL 9.7 Storage & Disk Management: Partition Deletion Tutorial

---
## Process Monitoring Commands

The video shows several process monitoring commands used to inspect the system state:

### fuser - Find Processes Using Files/Devices

**Command from Video Context:**

```bash
fuser -cu /dev/sda1
```

**Breakdown:**

- `-c` = Check which processes have the device open
- `-u` = Show username of process owner
- `/dev/sda1` = Target device

**Output Example:**

```
/dev/sda1: 1234(root) 5678(admin)
```

**Meaning:** Processes with PID 1234 (owned by root) and 5678 (owned by admin) are using `/dev/sda1`

**Kill Processes Using Device:**

```bash
fuser -ck /dev/sda1
```

**Breakdown:**

- `-c` = Match only if device is open
- `-k` = Kill the matching processes

**Warning:** This is dangerous - kills processes that depend on the device

### lsof - List Open Files

**Command from Video Context:**

```bash
lsof /xfs
```

**Purpose:** Show all open files on the `/xfs` mount point

**Output Example:**

```
COMMAND  PID  USER  FD  TYPE  DEVICE  SIZE  NODE  NAME
bash     123  root  cwd DIR   64,1    4096 1234  /xfs
cat      456  user  0r  REG   64,1    1024 5678  /xfs/file.txt
```

**Information:**

- `COMMAND`: Process name that has file open
- `PID`: Process ID
- `USER`: User running the process
- `FD`: File descriptor (cwd=current working directory, 0r=stdin readable, etc)
- `TYPE`: DIR=directory, REG=regular file, etc
- `DEVICE`: Device number (64,1 = major,minor device number)
- `SIZE`: File size
- `NODE`: Inode number
- `NAME`: Full path to file

**Why This Matters in Video Context:** Before unmounting `/xfs`, you need to know if any processes are using it. If they are, umount will fail with "device is busy" error.

**Solution:**

```bash
# Find what's using /xfs
lsof /xfs

# Kill the processes (if safe to do so)
kill -9 PID

# Then umount
umount /xfs
```

### du - Disk Usage

**Command from Video Context:**

```bash
du -h /xfs
```

**Breakdown:**

- `-h` = Human-readable format (K, M, G instead of bytes)
- `/xfs` = Directory to analyze

**Output Example:**

```
16K    /xfs/lost+found
20K    /xfs
```

**Meaning:**

- The `/xfs/lost+found` directory uses 16K
- The entire `/xfs` mount uses 20K total

**Extended Usage:**

```bash
du -h --max-depth=1 /xfs
# Shows space used by each subdirectory (one level)
# Useful to identify large directories before deletion

du -sh /xfs
# -s = summarize (show total only, no breakdown)
# Output: 20K /xfs
```

--- 

## Exact Step-by-Step Commands

### Step 1: Initial Mount Attempt with Label

**Command:**

```bash
mount LABEL=HR /xfs/
```

**Expected Output:** Successfully mounts the XFS filesystem that has the label "HR" set.

```
[root@server1 /]# df -h
Filesystem              Size  Used  Avail  Use%  Mounted on
devtmpfs                4.0M     0   4.0M    0%  /dev
tmpfs                   1.8G     0   1.8G    0%  /dev/shm
tmpfs                   725M  9.8M   715M    2%  /run
efivarfs                256K   76K   176K   31%  /sys/firmware/efi/efivars
/dev/mapper/rhel-root    49G   31G    16G   67%  /
/dev/nvme0n1p2          974M  327M   580M   37%  /boot
/dev/nvme0n1p1         1022M  7.4M  1015M    1%  /boot/efi
tmpfs                   363M  100K   363M    1%  /run/user/1001
/dev/sda1               2.0G  24K    1.8G    1%  /xfs
```

---

### Step 2: Unmount the Filesystem

**Command:**

```bash
umount /xfs
```

**Expected Output:**

```
(no output on success - returns to prompt)
```

**What This Does:**

- Removes the mount point from the filesystem hierarchy
- Prevents the device from being in use
- Essential before making changes to fstab or wiping filesystems

**Verification:**

```
[root@server1 /]# df -h
Filesystem              Size  Used  Avail  Use%  Mounted on
devtmpfs                4.0M     0   4.0M    0%  /dev
tmpfs                   1.8G     0   1.8G    0%  /dev/shm
tmpfs                   725M  9.8M   715M    2%  /run
efivarfs                256K   76K   176K   31%  /sys/firmware/efi/efivars
/dev/mapper/rhel-root    49G   31G    16G   67%  /
/dev/nvme0n1p2          974M  327M   580M   37%  /boot
/dev/nvme0n1p1         1022M  7.4M  1015M    1%  /boot/efi
tmpfs                   363M  100K   363M    1%  /run/user/1001
```

---

### Step 3: Edit /etc/fstab Configuration

**Command:**

```bash
nano /etc/fstab
```

- it shows like 
```
# /etc/fstab
# Created by anaconda on Tue Mar 17 02:18:41 2026
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
/dev/mapper/rhel-root   /               ext4    defaults        1 1
UUID=3cee44e1-7a17-49a1-86b4-8607f725ff14 /boot   ext4    defaults        1 2
UUID=0FCA-2127          /boot/efi       vfat    umask=0077,shortname=winnt 0 2
/dev/mapper/rhel-swap   none            swap    defaults        0 0


#Manually Create Mount Entry ....................................................


# device_name directory_name   file_system   mount option/mask_dumpting_check-seq

# UUID=52d06027-6b33-4821-b189-ab4b20dacedd    /xfs   ext4    defaults        0       0

```

**Original Entry (Using UUID):**

```
UUID=52d86027-6b33-4821-b189-ab4b20dacedd  /xfs  ext4  defaults  0  0
```

**Modified Entry (Using LABEL):**

```
LABEL=HR        /xfs    ext4    defaults        0       0
```

**What Changed:**

- Replaced `UUID=52d86027-6b33-4821-b189-ab4b20dacedd` with `LABEL=HR`
- Filesystem type remains `ext4`
- Mount options remain `defaults`
- Dump and pass flags remain `0 0`

---

### Step 4: Reload Systemd Configuration

**Command:**

```bash
systemctl daemon-reload
```

**Output:**

```
(no output on success)
```

**Critical Context (RHEL 9.7+):** This command is **absolutely required** on modern RHEL systems before running `mount -a`. Here's why:

- Modern RHEL uses `systemd-mount` and `systemd-run` to manage mounts
- systemd reads `/etc/fstab` and generates dynamic mount units
- When you edit `/etc/fstab`, those generated units become stale
- `systemctl daemon-reload` forces systemd to:
    1. Reload all configuration files from disk
    2. Regenerate mount units from the updated `/etc/fstab`
    3. Update the dependency tree
    4. Ensure services that depend on these mounts are aware of changes

**Without this step:**

- `mount -a` may use cached/outdated mount data
- Services may fail to start
- Filesystem dependencies may break
- Boot process could fail on next restart

---

### Step 5: Apply fstab Changes

**Command:**

```bash
mount -a
```

**Output:**

```
(no output on success)
```

**What This Does:**

- Reads `/etc/fstab` and mounts all filesystems marked with `0` in the `dump` field (second to last)
- Applies the new LABEL=HR mount configuration
- Verifies that the mount works with the label-based reference
- Does NOT re-mount already mounted filesystems

**Verification:**

```bash
df -h
# Shows: LABEL=HR mounted at /xfs with ext4 filesystem type
```

**Output Example:**

```
Filesystem      Type     Size  Used Avail Use% Mounted on
/dev/sdc1       ext4    1014M   33M  932M   1%  /xfs
```

---
### Step 6: Reboot System 

- after creating permanent mount point to verify that is working

  ```
  reboot
  ```

---
### Step 7: Verify Partition Identification

**Command:**

```bash
blkid
```

**Key Output Lines:**

```
/dev/sda1: LABEL="HR" UUID="52d86027-6b33-4821-b189-ab4b20dacedd" TYPE="ext4" PARTUUID="49383b8a-01"
/dev/sda2: UUID="9cd62f01-654b-4114-a233-614330778c97" TYPE="xfs" PARTUUID="49383b8a-02"
/dev/sda3: PARTUUID="49383b8a-03"
/dev/sda5: PARTUUID="49383b8a-05"
/dev/sda6: PARTUUID="49383b8a-06"
/dev/sda7: PARTUUID="49383b8a-07"
/dev/sda8: PARTUUID="49383b8a-08"
```

**What This Shows:**

- `/dev/sdc1` has LABEL="HR" - this is what we mounted
- `/dev/sdc2` is XFS formatted
- Other partitions exist on the same disk `/dev/sdc`
- Each partition has unique PARTUUID identifiers

**Specific Partition Check:**

```bash
blkid /dev/sda1
```

**Output:**

```
/dev/sda1: LABEL="HR" UUID="52d86027-6b33-4821-b189-ab4b20dacedd" TYPE="ext4" PARTUUID="49383b8a-01"
```

---

### Step 8: List Partition Table

**Command:**

```bash
fdisk -l /dev/sda
```

**Key Output Section:**

```
Disk /dev/sdc: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x49383b8a

Device     Boot  Start      End  Sectors Size Id Type
/dev/sda1          2048  2099199  2097152 1.0G 83 Linux
/dev/sda2       2099200  4194303  2095104 1.0G 83 Linux
/dev/sda3       ...
```

**What This Shows:**

- Disk size: 2 GiB total
- Partition table type: DOS (MBR) - `dos` label type
- `/dev/sda1` starts at sector 2048, size 1.0G, Linux type
- `/dev/sda2` follows, also 1.0G Linux type
- Multiple partitions exist for deletion practice

---

### Step 9: Wipe Filesystem Metadata

**Command:**

```bash
wipefs -a /dev/sda2
```

**Output:**

```
(may show removed signatures, or no output)
```

**Critical Differences from Other Operations:**

|Operation|Purpose|Effect|Reversibility|
|---|---|---|---|
|`wipefs -a`|Remove filesystem signatures/metadata|Data remains, but filesystem unrecognizable|Difficult - requires data recovery|
|`mkfs`|Create new filesystem|Overwrites initial sectors, destroys data|Data likely unrecoverable|
|Partition deletion|Remove partition entry|Partition table updated, data accessible via raw device|Moderate - partition table may be recoverable|

---

### Step 10: Verify Metadata Removal

**Command:**

```bash
blkid
```

**Expected Result:** After `wipefs -a /dev/sda2`:

```
# /dev/sda2 should NOT appear in blkid output anymore
# Or appear with no TYPE, UUID, or LABEL information
```

---


### Sequence in the Video

```bash
# Step 1: Edit the file
nano /etc/fstab
# Changed UUID=... to LABEL=HR

# Step 2: Reload systemd (MUST be before mount -a)
systemctl daemon-reload

# Step 3: Apply the mounts
mount -a

# Step 4: Verify
df -Tf
```

### What Happens Without `systemctl daemon-reload`

**Scenario: Edit fstab but skip daemon-reload**

```bash
# Edit fstab
nano /etc/fstab
# Change: UUID=52d... to LABEL=HR

# Try to mount without reload
mount -a
# Possible outcomes:
# 1. Uses old cached unit - tries to mount by UUID
# 2. Mount succeeds but warnings appear
# 3. System boots with inconsistent mounts on restart

# Later at boot:
# systemd reads the reloaded fstab
# But there's no LABEL=HR created yet
# Boot process hangs or fails
```

### Important Note on `mount -a` Behavior

The `-a` flag tells mount to:

1. Read `/etc/fstab`
2. Skip entries already mounted (unless `-F` flag used)
3. Mount new entries that aren't currently mounted
4. Skip entries with `noauto` option

Combined with `daemon-reload`:

```bash
systemctl daemon-reload  # Sync systemd state with disk
mount -a                  # Apply all unmounted fstab entries
```

---

```bash
wipefs -a /dev/sdc1
# -a = wipe all signatures found

wipefs -a -b 512 /dev/sdc1
# -b 512 = wipe only signatures at 512-byte offset
# Useful for selective wiping

wipefs -p /dev/sdc1
# -p = preview (show what would be deleted)
# Does NOT actually delete anything

wipefs -a -f /dev/sdc1
# -f = force (don't ask for confirmation)
# Used in scripts/automation
```

### fdisk Command

**Purpose:** Disk partition table manipulation and inspection tool

**List Partitions (Read Mode):**

```bash
fdisk -l /dev/sdc
```

**Output from Video:**

```
Disk /dev/sdc: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x49383b8a

Device     Boot  Start      End  Sectors Size Id Type
/dev/sdc1           2048  2099199  2097152 1.0G 83 Linux
/dev/sdc2       2099200  4194303  2095104 1.0G 83 Linux
/dev/sdc3       ...
```

**Partition Table Information:**

|Field|Value|Explanation|
|---|---|---|
|Disk|`/dev/sdc`|Physical disk device|
|Size|2 GiB|Total disk capacity|
|Bytes|2147483648|Exact disk size in bytes|
|Sectors|4194304|Total sectors (8 billion bytes ÷ 512 bytes/sector)|
|Sector Size|512 bytes|Basic unit of disk I/O|
|Disklabel Type|`dos`|MBR partition table format|
|Disk ID|`0x49383b8a`|Unique disk identifier|

**Per-Partition Information:**

|Column|`/dev/sdc1`|Meaning|
|---|---|---|
|Device|`/dev/sdc1`|First partition on `/dev/sdc`|
|Boot|(empty)|Not marked as bootable|
|Start|2048|Starts at sector 2048 (LBA)|
|End|2099199|Ends at sector 2099199|
|Sectors|2097152|Total sectors: 2099199-2048+1|
|Size|1.0G|Capacity: 2097152 × 512 bytes|
|Id|83|Partition type: Linux|
|Type|Linux|Human-readable type|

**Interactive Mode (for modifications):**

```bash
fdisk /dev/sdc
```

**Interactive Commands (seen in tutorial context):**

```
m - print menu
p - print partition table
d - delete partition
n - new partition
w - write changes and exit
q - quit without saving
```

---

## Partition Deletion Best Practices

Based on the workflow shown in the video, here are best practices:

### Pre-Deletion Checklist

**1. Identify the Correct Partition**

```bash
# Step 1: List all partitions
lsblk -f
blkid

# Step 2: Verify with fdisk
fdisk -l

# Step 3: Check specific partition
blkid /dev/sdc1
# Output: LABEL="HR" UUID="52d86027-..." TYPE="ext4"

# Step 4: Verify this is the RIGHT partition
# Read the output carefully - no "oops" allowed here
```

**2. Backup Critical Data (if needed)**

```bash
# Before ANY deletion:
dd if=/dev/sdc1 of=/backup/sdc1.img bs=4M
# Creates complete disk image backup (can be large!)

# Or selective backup:
mount /dev/sdc1 /mnt/tmp
cp -r /mnt/tmp /backup/sdc1_contents
umount /mnt/tmp
```

**3. Check for Active Usage**

```bash
# Find processes using the partition
lsof /xfs
fuser -cu /xfs

# Find current working directory on mount
grep /xfs /proc/*/cwd 2>/dev/null

# If found, kill those processes carefully
kill -15 PID  # SIGTERM - allow graceful shutdown
sleep 2
kill -9 PID   # SIGKILL - force kill if needed
```

**4. Unmount the Filesystem**

```bash
# Basic unmount
umount /xfs

# Verify unmount
df /xfs  # should return "no such file" error
mount | grep /xfs  # should show nothing

# Forced unmount (if normal unmount fails)
umount -f /xfs  # force
umount -l /xfs  # lazy - unmount later when not in use
```

**5. Remove from fstab (if mounted at boot)**

```bash
# Edit fstab
nano /etc/fstab

# Remove or comment out the line:
# LABEL=HR  /xfs  ext4  defaults  0  2
# Or comment it:
# #LABEL=HR  /xfs  ext4  defaults  0  2

# Reload systemd
systemctl daemon-reload
```

### Deletion Steps (As Shown in Video)

**Step 1: Unmount**

```bash
umount /xfs
# Deactivates the filesystem
# Returns immediately if partition not in use
# Fails with "busy" error if processes using it
```

**Step 2: Wipe Filesystem Metadata**

```bash
wipefs -a /dev/sdc1
# Removes ext4 superblock and metadata
# Data sectors remain untouched but unreadable
# Prevents accidental remounting of old filesystem
```

**Step 3: Delete Partition Table Entry**

```bash
fdisk /dev/sdc
# (interactive menu)

# Commands:
# p - print current partitions
# d - delete partition
# (choose partition number: 1)
# w - write changes

# Or non-interactive:
echo -e "d\n1\nw" | fdisk /dev/sdc
# Sends: delete, partition 1, write
```

**Step 4: Verify Deletion**

```bash
# Check partition no longer in table
fdisk -l /dev/sdc
# Should NOT show /dev/sdc1

# Check blkid no longer finds it
blkid /dev/sdc1
# Should return: exit code 2, device not found
```

**Step 5: Verify Free Space**

```bash
# Check unallocated space available
fdisk -l /dev/sdc
# Total sectors should match sum of remaining partitions

# Create new partition if desired
fdisk /dev/sdc
# n - new partition
# (accept defaults or customize)
# w - write
```

---
### Issue : XFS vs ext4 confusion

**Problem:** Trying to use ext4 tools on XFS and vice versa

**In the Video:**

- `/dev/sdc1` = ext4 LABEL=HR
- `/dev/sdc2` = XFS (UUID based)

**Different Tools Required:**

|Operation|ext4|XFS|
|---|---|---|
|Label|`e2label`|`xfs_admin -L`|
|Check|`fsck -n`|`xfs_repair -n`|
|Grow|`resize2fs`|`xfs_growfs`|
|Create|`mkfs.ext4`|`mkfs.xfs`|
|Dump metadata|`dumpe2fs`|`xfs_metadump`|

---
