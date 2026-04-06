 # 🖥️ RHEL 9.7 — Disk Management & Filesystem Administration

> **Lab Environment:** Red Hat Enterprise Linux 9.7 | VMware Workstation | `root@server1`  
> **Topics:** Partitioning · MBR & GPT · fdisk · ext4 · XFS · Mounting · fsck · xfs_repair · /etc/fstab

---

## 1. Disk Identification

Linux identifies storage devices using a standardized naming scheme. Understanding these names is the first step in disk management.

### 1.1 Device Naming Conventions

| Device Name        | Type               | Example               | Notes                          |
| ------------------ | ------------------ | --------------------- | ------------------------------ |
| `/dev/sda`         | SCSI/SATA/SAS disk | sda, sdb, sdc…        | First disk = sda, Second = sdb |
| `/dev/nvme0n1`     | NVMe SSD           | nvme0n1, nvme1n1…     | `n` = namespace number         |
| `/dev/sda1`        | SCSI partition     | sda1, sda2…           | Number = partition index       |
| `/dev/nvme0n1p1`   | NVMe partition     | nvme0n1p1, p2…        | `p` = partition prefix         |
| `/dev/sr0`         | CD/DVD-ROM         | /dev/sr0              | Read-only optical drive        |
| `/dev/mapper/name` | LVM logical volume | /dev/mapper/rhel-root | LVM managed devices            |

### 1.2 Key Commands for Disk Discovery

|Command|Purpose|
|---|---|
|`lsblk`|List block devices in tree format (NAME, SIZE, TYPE, MOUNTPOINTS)|
|`fdisk -l`|List all partition tables on all disks|
|`fdisk -l /dev/sda`|List partition table for a specific disk|
|`lsblk -f`|Show filesystem type, UUID, and mount points|
|`blkid`|Show UUIDs and filesystem types for all devices|
|`df -h`|Show mounted filesystem usage (human-readable)|
|`parted -l`|List all disks with parted (shows GPT/MBR type)|

### 1.3 Lab Disk Layout (`lsblk` output)

```
NAME        MAJ:MIN  SIZE  TYPE  MOUNTPOINTS
sda           8:0    10G   disk
├─sda1        8:1     2G   part  /mnt
├─sda2        8:2     2G   part
├─sda3        8:3     2G   part
├─sda4        8:4     1K   part  (Extended)
├─sda5        8:5     1G   part
├─sda6        8:6     1G   part
├─sda7        8:7     1G   part
└─sda8        8:8  1019M   part
sdb           8:16   10G   disk
sdc           8:32   10G   disk
sdd           8:48   10G   disk
nvme0n1     259:0    70G   disk
├─nvme0n1p1 259:1     1G   part  /boot/efi
├─nvme0n1p2 259:2     1G   part  /boot
└─nvme0n1p3 259:3    54G   part
  ├─rhel-root 253:0  50G   lvm   /
  └─rhel-swap 253:1   4G   lvm   [SWAP]
```

---

## 2. Partition Table Types — MBR vs GPT

|Feature|MBR (Master Boot Record)|GPT (GUID Partition Table)|
|---|---|---|
|Standard|Legacy BIOS (DOS)|UEFI (modern systems)|
|Max Disk Size|**2 TB**|**9.4 ZB (virtually unlimited)**|
|Max Partitions|**4 primary** (or 3P + 1 Extended)|**128 partitions** (default)|
|Partition IDs|1-byte type codes (e.g., `83`=Linux)|128-bit GUID per partition|
|Redundancy|Single copy — vulnerable to corruption|Backup GPT at end of disk|
|Boot Support|BIOS / Legacy boot|UEFI boot|
|fdisk identifier|`Disklabel type: dos`|`Disklabel type: gpt`|
|Your `/dev/sda`|✅ Uses **MBR (dos)**|—|
|Your `nvme0n1`|—|✅ Uses **GPT**|

> **When to use GPT:** Modern systems with UEFI, disks > 2 TB, or when needing more than 4 partitions.  
> **When to use MBR:** Legacy BIOS systems, older VMs, or compatibility with older tools.

---

## 3. fdisk — Interactive Partition Editor

`fdisk` is the standard interactive tool for managing MBR and GPT partition tables.

### 3.1 Opening fdisk

```bash
# Open a disk for partitioning (as root)
fdisk /dev/sdb

# List partition table without entering interactive mode
fdisk -l /dev/sda
```

### 3.2 All fdisk Commands (`m` for help)

Inside fdisk, press **`m`** to display the full help menu:

#### DOS (MBR) Commands

|Key|Description|
|---|---|
|`a`|Toggle a bootable flag on a partition|
|`b`|Edit nested BSD disklabel|
|`c`|Toggle the DOS compatibility flag|

#### Generic Commands

|Key|Description|
|---|---|
|`d`|Delete a partition|
|`F`|List free unpartitioned space|
|`l`|List known partition types (e.g., 82=swap, 83=Linux)|
|`n`|Add a new partition|
|`p`|Print the current partition table|
|`t`|Change a partition's type code|
|`v`|Verify the partition table for errors|
|`i`|Print detailed information about a partition|

#### Misc Commands

|Key|Description|
|---|---|
|`m`|Print this help menu|
|`u`|Change display/entry units (sectors ↔ cylinders)|
|`x`|Extra functionality (experts only) — use with caution!|

#### Script Commands

|Key|Description|
|---|---|
|`I`|Load disk layout from an sfdisk script file|
|`O`|Dump disk layout to an sfdisk script file|

#### Save & Exit

|Key|Description|
|---|---|
|`w`|✅ **Write table to disk and EXIT** — saves all changes|
|`q`|❌ **Quit WITHOUT saving** — safe to cancel|

#### Create a New Label

|Key|Description|
|---|---|
|`g`|Create a new empty **GPT** partition table|
|`G`|Create a new empty SGI (IRIX) partition table|
|`o`|Create a new empty **DOS (MBR)** partition table|
|`s`|Create a new empty Sun partition table|

### 3.3 Common Partition Type Codes

|Code (hex)|Type|Use Case|
|---|---|---|
|`83`|Linux|Standard Linux data partition (ext4, xfs, etc.)|
|`82`|Linux swap|Swap space|
|`8e`|Linux LVM|LVM physical volume|
|`5`|Extended|Container for logical partitions (MBR only)|
|`fd`|Linux RAID auto|Software RAID member|
|`ef`|EFI System|EFI/UEFI boot partition|
|`7`|NTFS/HPFS|Windows NTFS partition|

### 3.4 Lab Partition Table (`fdisk -l /dev/sda`)

```
[root@server1 admin]# fdisk -l /dev/sda

Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos                    ← MBR partition table
Disk identifier: 0x49383b8a

Device      Boot    Start       End   Sectors   Size  Id  Type
/dev/sda1           2048   4196351   4194304     2G   83  Linux
/dev/sda2        4196352   8390655   4194304     2G   83  Linux
/dev/sda3        8390656  12584959   4194304     2G   83  Linux
/dev/sda4       12584960  20971519   8386560     4G    5  Extended
/dev/sda5       12587008  14684159   2097152     1G   83  Linux
/dev/sda6       14686208  16783359   2097152     1G   83  Linux
/dev/sda7       16785408  18882559   2097152     1G   83  Linux
/dev/sda8       18884608  20971519   2086912  1019M   83  Linux
```

**Partition Layout Explained:**

- **sda1–sda3** → Primary partitions (3 total, each 2 GB, type `83` Linux)
- **sda4** → Extended partition (4 GB) — acts as a container, type `5`
- **sda5–sda8** → Logical partitions living inside sda4
- **MBR Rule:** Maximum 4 primary; use Extended + Logical to exceed this limit

---

## 4. Filesystems in RHEL — ext4 vs XFS

|Feature|ext4|XFS|
|---|---|---|
|Full Name|Fourth Extended Filesystem|XFS Filesystem|
|Default in RHEL|RHEL 6 and earlier|✅ **RHEL 7+ (including 9.7)**|
|Max File Size|16 TB|**8 EB**|
|Max Volume Size|1 EB|**8 EB**|
|Journal Type|Metadata journaling|Metadata journaling (write-ahead log)|
|Shrink Support|✅ Yes (offline)|❌ **No — cannot shrink!**|
|Grow Support|✅ Online/Offline|✅ Online only|
|Performance|Good general purpose|Better for large files & parallel I/O|
|Repair Tool|`e2fsck`|`xfs_repair`|
|Create Tool|`mkfs.ext4`|`mkfs.xfs`|
|Info Tool|`tune2fs -l` / `dumpe2fs`|`xfs_info`|
|Your Lab|✅ Installed on `/dev/sda1`|✅ Installed on `/dev/sda2`|

---

## 5. Creating Filesystems

### 5.1 Creating ext4 on `/dev/sda1`

```bash
[root@server1 admin]# mkfs.ext4 /dev/sda1

mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: 52d86027-6b33-4821-b189-ab4b20dacedd
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

**Output Explained:**

|Field|Meaning|
|---|---|
|`524288 4k blocks`|524,288 blocks × 4096 bytes = **2 GB** total space|
|`131072 inodes`|Space for 131,072 files/directories|
|`Filesystem UUID`|Unique identifier — used in `/etc/fstab` for persistent mounting|
|`Superblock backups`|Multiple copies of metadata for disaster recovery|
|`journal (16384 blocks)`|Write-ahead log for crash consistency|

### 5.2 Creating XFS on `/dev/sda2`

```bash
[root@server1 admin]# mkfs.xfs /dev/sda2

meta-data=/dev/sda2              isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=1 inobtcount=1 nrext64=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=16384, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

**XFS Parameters Explained:**

|Parameter|Meaning|
|---|---|
|`agcount=4`|4 Allocation Groups — XFS divides disk into AGs for parallel I/O|
|`agsize=131072 blks`|Each AG is 131,072 × 4096 bytes = 512 MB|
|`isize=512`|Inode size of 512 bytes (stores file metadata)|
|`crc=1`|CRC checksums enabled for metadata integrity|
|`bsize=4096`|Block size = 4096 bytes (standard 4K blocks)|
|`reflink=1`|Reflink support enabled (copy-on-write, deduplication)|
|`internal log`|Journal stored inside the filesystem data area|

---

## 6. Filesystem Check & Repair

> ⚠️ **Critical Rule:** Always **unmount** a filesystem before running `e2fsck` or `xfs_repair`. Running these on a mounted filesystem causes data corruption.

### 6.1 e2fsck — Check ext4 (`/dev/sda1`)

```bash
# Check ext4 filesystem (must be UNMOUNTED first!)
[root@server1 admin]# e2fsck /dev/sda1

e2fsck 1.46.5 (30-Dec-2021)
/dev/sda1: clean, 11/131072 files, 26156/524288 blocks
           ↑ 11 files used, 26156 blocks used — filesystem is healthy
```

**e2fsck Options:**

|Command|Purpose|
|---|---|
|`e2fsck /dev/sda1`|Basic check|
|`e2fsck -f /dev/sda1`|Force check even if marked clean|
|`e2fsck -p /dev/sda1`|Auto-repair (preen) — fix safe errors automatically|
|`e2fsck -y /dev/sda1`|Answer 'yes' to all repair prompts automatically|
|`e2fsck -n /dev/sda1`|Dry-run — check only, make NO changes|

### 6.2 xfs_repair — Repair XFS (`/dev/sda2`)

```bash
[root@server1 admin]# xfs_repair /dev/sda2

Phase 1 - find and verify superblock...
Phase 2 - using internal log...
        - zero log...
        - scan filesystem freespace and inode maps...
        - found root inode chunk
Phase 3 - for each AG...
        - scan and clear agi unlinked lists...
        - process known inodes and perform inode discovery...
        - agno = 0  ... agno = 1  ... agno = 2  ... agno = 3
Phase 4 - check for duplicate blocks...
        - agno = 0  ... agno = 1  ... agno = 2  ... agno = 3
Phase 5 - rebuild AG headers and trees...
        - reset superblock...
Phase 6 - check inode connectivity...
        - traversing filesystem ...
        - moving disconnected inodes to lost+found ...
Phase 7 - verify and correct link counts...
done
```

**xfs_repair Phases:**

|Phase|What Happens|
|---|---|
|Phase 1|Find and verify the superblock (primary metadata block)|
|Phase 2|Process the internal transaction log|
|Phase 3|Scan each Allocation Group, process inodes|
|Phase 4|Check for duplicate block references|
|Phase 5|Rebuild AG header trees (b-trees)|
|Phase 6|Check inode connectivity, move orphans to `lost+found`|
|Phase 7|Verify and correct hard link counts|

> 💡 `xfs_repair -L` forces log zeroing — use **only as a last resort** (may lose recent writes).

---

## 7. Mounting Filesystems

### 7.1 Temporary Mount Commands (Lab)

```bash
# Mount sda1 (ext4) to /mnt
[root@server1 admin]# mount /dev/sda1 /mnt

# Create a mount point for sda2 (XFS)
[root@server1 /]# mkdir xfs

# Mount sda2 (XFS) to /xfs
[root@server1 /]# mount /dev/sda2 /xfs/

# Verify mounts
[root@server1 /]# mount | grep sda
/dev/sda1 on /mnt type ext4 (rw,relatime,seclabel)
/dev/sda2 on /xfs type xfs  (rw,relatime,seclabel,attr2,inode64,logbufs=8,logsize=32k,noquota)
```

### 7.2 Mount Command Reference

|Command|Description|
|---|---|
|`mount /dev/sda1 /mnt`|Mount sda1 at /mnt (auto-detects filesystem)|
|`mount -t ext4 /dev/sda1 /mnt`|Mount with explicit filesystem type|
|`mount -t xfs /dev/sda2 /xfs`|Mount XFS with explicit type|
|`mount`|List ALL currently mounted filesystems|
|`mount \| grep sda`|Filter mount list for sda devices|
|`umount /mnt`|Unmount by mount point|
|`umount /dev/sda1`|Unmount by device name|
|`lsblk`|Verify mount points in block device tree|
|`df -h`|Show disk usage of mounted filesystems|

### 7.3 Mount Options Explained

|Option|Meaning|
|---|---|
|`rw`|Read-Write mode (not read-only)|
|`relatime`|Update atime only if older than mtime/ctime (performance optimization)|
|`seclabel`|SELinux security labels enabled on this filesystem|
|`attr2`|XFS: Use v2 on-disk inode attribute format|
|`inode64`|XFS: Allow inode numbers > 32-bit (large filesystems)|
|`logbufs=8`|XFS: 8 log buffers in memory for I/O performance|
|`logsize=32k`|XFS: Log buffer size = 32 KB|
|`noquota`|XFS: Disk quotas are disabled|

### 7.4 Persistent Mounts — `/etc/fstab`

Temporary mounts are lost on reboot. Use `/etc/fstab` for permanent mounts.

---

#### Step 1 — Get UUID using `blkid`

```bash
[root@server1 /]# blkid

/dev/sdb1: UUID="52d86027-6b33-4821-b189-ab4b20dacedd"  TYPE="ext4"   PARTUUID="49383b8a-01"
/dev/sdb2: UUID="9cd62f01-654b-4114-a233-614330f78c97"  TYPE="xfs"    PARTUUID="49383b8a-02"
/dev/sdb3: PARTUUID="49383b8a-03"
/dev/sdb5: PARTUUID="49383b8a-05"
/dev/sdb6: PARTUUID="49383b8a-06"
/dev/sdb7: PARTUUID="49383b8a-07"
/dev/sdb8: PARTUUID="49383b8a-08"
/dev/sda:  PTUUID="d3e628e2"  PTTYPE="dos"
/dev/mapper/rhel-root: LABEL="root partition"  UUID="432fd8d0-5319-4ba0-b97f-e6c96bf52850"  TYPE="ext4"
/dev/mapper/rhel-swap: LABEL="Swap-Memory"     UUID="a18e6854-0b1b-4c66-9535-f1e94b676620"  TYPE="swap"
/dev/nvme0n1p1: UUID="9FCA-2127"  TYPE="vfat"  PARTLABEL="EFI System Partition"
/dev/nvme0n1p2: LABEL="boot partition"  UUID="3cee44e1-7a17-49a1-8664-8607f725ff14"  TYPE="ext4"
/dev/nvme0n1p3: UUID="uHYNJo-..."  TYPE="LVM2_member"
```

**blkid Fields:**

|Field|Meaning|
|---|---|
|`UUID`|Unique filesystem identifier — **stable across reboots** and disk renaming|
|`TYPE`|Filesystem type: `ext4`, `xfs`, `vfat`, `swap`, `LVM2_member`|
|`PARTUUID`|Partition UUID (from partition table) — different from filesystem UUID|
|`PTTYPE`|Partition table type: `dos` = MBR, `gpt` = GPT|
|`LABEL`|Optional human-readable label set at filesystem creation|
|`PTUUID`|Disk (not partition) UUID — shown on the disk device itself|

---

#### Step 2 — Verify with `lsblk -f`

```bash
[root@server1 admin]# lsblk -f

NAME   FSTYPE  FSVER  LABEL  UUID                                   FSAVAIL  FSUSE%  MOUNTPOINTS
sda
├─sda1   ext4    1.0         52d86027-6b33-4821-b189-ab4b20dacedd     1.8G      0%   /xfs
├─sda2   xfs                 9cd62f01-654b-4114-a233-614330f78c97
├─sda3
├─sda4
├─sda5
├─sda6
├─sda7
└─sda8
```

|Column|Meaning|
|---|---|
|`FSTYPE`|Filesystem type installed (blank = no filesystem)|
|`FSVER`|Filesystem version (e.g., ext4 version `1.0`)|
|`UUID`|Filesystem UUID — use this in `/etc/fstab`|
|`FSAVAIL`|Available free space (only shown when mounted)|
|`FSUSE%`|Percentage of filesystem used|
|`MOUNTPOINTS`|Where the filesystem is currently mounted|

---

#### Step 3 — Edit `/etc/fstab`

```bash
[root@server1 admin]# cat /etc/fstab

# /etc/fstab
# Created by anaconda on Tue Mar 17 02:18:41 2026

# --- System entries (created by installer) ---
/dev/mapper/rhel-root                                  /           ext4  defaults        1 1
UUID=3cee44e1-7a17-49a1-8664-8607f725ff14              /boot       ext4  defaults        1 2
UUID=9FCA-2127                                         /boot/efi   vfat  umask=0077,shortname=winnt  0 2
/dev/mapper/rhel-swap                                  none        swap  defaults        0 0

# --- Manually Create Mount Entry ---
# device           directory   filesystem   options   dump   check-seq
UUID=52d86027-6b33-4821-b189-ab4b20dacedd  /xfs  ext4  defaults  0  0
```

**fstab Columns Explained:**

|Column|Values & Meaning|
|---|---|
|Device|`UUID=...` (preferred) or `/dev/path` — UUID survives disk renaming|
|Mount Point|Directory where filesystem appears (must already exist!)|
|fstype|`ext4`, `xfs`, `vfat`, `swap`, `auto`, etc.|
|Options|`defaults` = rw, suid, dev, exec, auto, nouser, async|
|dump (5th)|`0` = don't backup; `1` = include in dump backup|
|pass (6th)|`0` = no fsck at boot; `1` = check first (root `/`); `2` = check after root|

> ⚠️ **Note:** In this lab, the ext4 filesystem (sda1) was mounted at `/xfs`. The mount point name is arbitrary in Linux — the filesystem type is what matters, not the directory name. Best practice: name mount points to reflect content (e.g., `/mnt/data-ext4`).

---

#### Step 4 — Reload systemd & Verify

```bash
# Reload systemd to pick up fstab changes
[root@server1 admin]# systemctl daemon-reload

# ⚠️  Common typo — 'deamon-reload' gives error:
# Unknown command verb deamon-reload.
# Correct spelling: daemon-reload

# Verify the persistent mount is active
[root@server1 admin]# df -h

Filesystem               Size   Used  Avail  Use%  Mounted on
/dev/mapper/rhel-root     49G    31G    16G   66%   /
/dev/nvme0n1p2           974M   327M   580M   37%   /boot
/dev/nvme0n1p1          1022M   7.4M  1015M    1%   /boot/efi
/dev/sdb1                2.0G    24K   1.8G    1%   /xfs    ← persistent mount confirmed!
```

> 💡 **UUID vs Device Name in fstab:**
> 
> - ✅ **UUID** (recommended): `UUID=52d86027-…` stays the same even if the disk moves to a different SATA port
> - ❌ **Device name** (fragile): `/dev/sda1` can change if you add another disk — system may fail to boot!
> - Get UUID with: `blkid /dev/sda1` or `lsblk -f`

---

## 8. Quick Reference

### 8.1 Complete Disk Management Workflow

|Step|Command|Purpose|
|---|---|---|
|1|`lsblk`|Identify available disks and current layout|
|2|`fdisk /dev/sdb`|Open disk for partitioning|
|3|`n → p/l → size → w`|Create partition and write to disk|
|4|`mkfs.ext4 /dev/sdb1`|Format partition with ext4|
|4 alt|`mkfs.xfs /dev/sdb2`|Format partition with XFS|
|5|`lsblk -f`|Confirm filesystem type and UUID|
|6|`blkid /dev/sdb1`|Get UUID for fstab entry|
|7|`mkdir /mountpoint`|Create mount directory|
|8|`mount /dev/sdb1 /mountpoint`|Mount the filesystem (temporary)|
|9|`vi /etc/fstab`|Add UUID-based entry for permanent mount|
|10|`systemctl daemon-reload`|Reload systemd to apply fstab changes|
|11|`df -h`|Verify persistent mount is active|

### 8.2 Full Command Quick-Reference Card

|Task|Command|
|---|---|
|List all block devices|`lsblk`|
|List block devices with filesystems & UUIDs|`lsblk -f`|
|Show partition table|`fdisk -l /dev/sda`|
|Interactive partition manager|`fdisk /dev/sdb`|
|Create ext4 filesystem|`mkfs.ext4 /dev/sda1`|
|Create XFS filesystem|`mkfs.xfs /dev/sda2`|
|Check ext4 filesystem|`e2fsck /dev/sda1`|
|Force check ext4|`e2fsck -f /dev/sda1`|
|Auto-repair ext4|`e2fsck -y /dev/sda1`|
|Repair XFS filesystem|`xfs_repair /dev/sda2`|
|Force XFS log zero (last resort)|`xfs_repair -L /dev/sda2`|
|Mount a filesystem|`mount /dev/sda1 /mnt`|
|Unmount a filesystem|`umount /mnt`|
|Show all mounted filesystems|`mount`|
|Show disk usage|`df -h`|
|Get ext4 filesystem info|`tune2fs -l /dev/sda1`|
|Get XFS filesystem info|`xfs_info /xfs`|
|Get device UUID|`blkid /dev/sda1`|
|Reload systemd after fstab edit|`systemctl daemon-reload`|
|Mount all entries from fstab|`mount -a`|

---

## 9. Lab Summary

### ✅ What You Accomplished

|#|Task|Details|
|---|---|---|
|1|**Identified disks**|Used `lsblk` and `fdisk -l` to explore `/dev/sda`, `sdb`, `sdc`, `sdd`, and `nvme0n1`|
|2|**Created partitions**|Built 3 primary + 1 extended + 4 logical partitions on `/dev/sda` using `fdisk` (MBR)|
|3|**Created ext4 on sda1**|Used `mkfs.ext4`, verified with `e2fsck` (clean, 11 files, 26156 blocks)|
|4|**Created XFS on sda2**|Used `mkfs.xfs`, repaired with `xfs_repair` (all 7 phases: **done**)|
|5|**Temporary mounts**|`sda1 → /mnt` (ext4), `sda2 → /xfs` (XFS) using `mount` command|
|6|**Retrieved UUIDs**|Used `blkid` to get `UUID=52d86027-…` (sda1/ext4) and `UUID=9cd62f01-…` (sda2/xfs)|
|7|**Verified with lsblk -f**|Confirmed FSTYPE (ext4/xfs), UUID, and mount points for all sda partitions|
|8|**Persistent mount in fstab**|Added `UUID=52d86027-6b33-4821-b189-ab4b20dacedd /xfs ext4 defaults 0 0`|
|9|**Reloaded systemd**|Used `systemctl daemon-reload` to apply fstab changes|
|10|**Verified persistent mount**|`df -h` confirms `/dev/sdb1` (2.0G) mounted at `/xfs`, 1% used ✅|

---

_RHEL 9.7 Lab Notes — server1 | Red Hat Enterprise Linux Disk Management_