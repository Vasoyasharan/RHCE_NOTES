# 🖥️ LVM Partition Creation & Setting Type to `8e` (Linux LVM) on RHEL 9.7

---

## 1. Prerequisites & Environment

|Item|Detail|
|---|---|
|OS|RHEL 9.7|
|Hypervisor|VMware Workstation|
|User|`root` (all commands run as root)|
|Shell|`[root@server1 admin]#`|
|Existing disks|`nvme0n1` (70G, OS disk), `sda`, `sdb`, `sdc`, `sdd` (each 10G)|
|Existing LVM|PV: `/dev/nvme0n1p3` → VG: `rhel` → LVs: `root` (50G) + `swap` (4G)|

> 💡 **Tip:** All partition changes require `root` privileges. Always back up data before modifying partitions.

---

## 2. Step 1 — Check Existing Physical Volumes (`pvs`)

### 🔧 Command

```bash
pvs
```

### 📺 What Happens

The `pvs` command lists all Physical Volumes (PVs) in a compact summary format.

### ✅ Example Output

```
  PV             VG   Fmt  Attr PSize  PFree
  /dev/nvme0n1p3 rhel lvm2 a--  54.00g    0
```

### 📖 Output Explained

|Column|Meaning|
|---|---|
|`PV`|Physical Volume device path|
|`VG`|Volume Group it belongs to|
|`Fmt`|LVM format (`lvm2`)|
|`Attr`|Attributes (`a--` = allocatable)|
|`PSize`|Total physical size|
|`PFree`|Free space remaining|

> 🔍 **Note:** `PFree = 0` means the existing PV is fully used — no room to add more LVs without adding new PVs.

---

## 3. Step 2 — Detailed PV Info (`pvdisplay`)

### 🔧 Command

```bash
pvdisplay
```

### 📺 What Happens

Shows full detailed information about every Physical Volume.

### ✅ Example Output

```
  --- Physical volume ---
  PV Name               /dev/nvme0n1p3
  VG Name               rhel
  PV Size               54.00 GiB / not usable 2.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              13824
  Free PE               0
  Allocated PE          13824
  PV UUID               uHYNJo-icTI-rcMZ-EG4Y-oqmA-cAcd-6M5UDh
```

### 📖 Key Fields Explained

| Field          | Value          | Meaning                                            |
| -------------- | -------------- | -------------------------------------------------- |
| `PV Size`      | 54.00 GiB      | Total raw size of the physical volume              |
| `Allocatable`  | yes (but full) | Can be used but currently 100% allocated           |
| `PE Size`      | 4.00 MiB       | Physical Extent size (smallest unit of allocation) |
| `Total PE`     | 13824          | Total number of extents                            |
| `Free PE`      | 0              | Zero extents available                             |
| `Allocated PE` | 13824          | All extents are in use                             |

> 💡 **PE (Physical Extent)** is the basic unit of storage in LVM. 13824 × 4 MiB = 54 GiB total.

---

## 4. Step 3 — Check Volume Groups (`vgs` + `vgdisplay`)

### 🔧 Commands

```bash
vgs
vgdisplay
```

### ✅ `vgs` Output

```
  VG   #PV #LV #SN Attr   VSize  VFree
  rhel   1   2   0 wz--n- 54.00g     0
```

### ✅ `vgdisplay` Output

```
  --- Volume group ---
  VG Name               rhel
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               54.00 GiB
  PE Size               4.00 MiB
  Total PE              13824
  Alloc PE / Size       13824 / 54.00 GiB
  Free  PE / Size       0 / 0
  VG UUID               RGNnta-9Pul-UX0f-Nagk-2EV8-KwKF-GOMhsB
```

### 📖 Key Fields

|Field|Value|Meaning|
|---|---|---|
|`VG Name`|rhel|Volume Group name|
|`Cur LV`|2|Two Logical Volumes exist (`root` and `swap`)|
|`VG Size`|54.00 GiB|Total size of the VG|
|`Free PE / Size`|0 / 0|No free space at all|

> ⚠️ **Important:** `VFree = 0` means we **cannot create new LVs** without first adding new PVs. That's why we need to partition the additional disks!

---

## 5. Step 4 — Check Logical Volumes (`lvdisplay`)

### 🔧 Command

```bash
lvdisplay
```

### ✅ Example Output

```
  --- Logical volume ---
  LV Path                /dev/rhel/swap
  LV Name                swap
  VG Name                rhel
  LV UUID                UAoX5d-NjIy-J6jj-8ZNm-unbT-BmDM-2L3mKV
  LV Write Access        read/write
  LV Creation host, time server1.iforward.in, 2026-03-17 07:48:05 +0530
  LV Status              available
  # open                 2
  LV Size                4.00 GiB
  Current LE             1024
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:1

  --- Logical volume ---
  LV Path                /dev/rhel/root
  LV Name                root
  VG Name                rhel
  LV UUID                XFU35W-1DQh-Lu2C-jokq-KHlr-Y44S-lD7G18
  LV Write Access        read/write
  LV Creation host, time server1.iforward.in, 2026-03-17 07:48:05 +0530
  LV Status              available
  # open                 1
  LV Size                50.00 GiB
  Current LE             12800
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0
```

### 📖 Two LVs Exist

|LV|Path|Size|Purpose|
|---|---|---|---|
|swap|`/dev/rhel/swap`|4.00 GiB|Linux swap space|
|root|`/dev/rhel/root`|50.00 GiB|Root filesystem `/`|

> 🟢 Both LVs show `LV Status: available` — meaning they are active and in use.

---

## 6. Step 5 — Check Block Devices (`lsblk`)

### 🔧 Command

```bash
lsblk
```

### ✅ Example Output

```
NAME            MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda               8:0    0   10G  0 disk
sdb               8:16   0   10G  0 disk
sdc               8:32   0   10G  0 disk
sdd               8:48   0   10G  0 disk
sr0              11:0    1 1024M  0 rom
nvme0n1         259:0    0   70G  0 disk
├─nvme0n1p1     259:1    0    1G  0 part /boot/efi
├─nvme0n1p2     259:2    0    1G  0 part /boot
└─nvme0n1p3     259:3    0   54G  0 part
  ├─rhel-root   253:0    0   50G  0 lvm  /
  └─rhel-swap   253:1    0    4G  0 lvm  [SWAP]
```

### 📖 Disk Layout

|Device|Size|Type|Notes|
|---|---|---|---|
|`sda`|10G|disk|✅ Raw — no partitions yet|
|`sdb`|10G|disk|✅ Raw — no partitions yet|
|`sdc`|10G|disk|✅ Raw — no partitions yet|
|`sdd`|10G|disk|✅ Raw — no partitions yet|
|`nvme0n1`|70G|disk|OS disk with LVM|

> 🎯 **Plan:** We will partition `sda` first, then clone its layout to `sdb` and `sdc` using `sfdisk`.

---

## 7. Step 6 — Launch `fdisk` on `/dev/sda`

### 🔧 Command

```bash
fdisk /dev/sda
```

### ✅ Example Output

```
Welcome to fdisk (util-linux 2.37.4).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x1f0dba31.

Command (m for help):
```

### 📖 What This Means

- `fdisk` is an interactive command-line partitioning tool
- Changes are **in-memory only** until you type `w` (write)
- `Device does not contain a recognized partition table` — the disk is blank/raw
- A new DOS (MBR) disklabel is automatically initialized

> ⚠️ **WARNING:** `fdisk` does NOT save anything until you type `w`. You can safely exit with `q` (quit without saving) at any time.

---

## 8. Step 7 — View fdisk Help Menu (`m`)

### 🔧 Inside fdisk, type:

```
m
```

### ✅ Example Output

```
Help:

  DOS (MBR)
   a   toggle a bootable flag
   b   edit nested BSD disklabel
   c   toggle the dos compatibility flag

  Generic
   d   delete a partition
   F   list free unpartitioned space
   l   list known partition types
   n   add a new partition
   p   print the partition table
   t   change a partition type
   v   verify the partition table
   i   print information about a partition

  Misc
   m   print this menu
   u   change display/entry units
   x   extra functionality (experts only)

  Script
   I   load disk layout from sfdisk script file
   O   dump disk layout to sfdisk script file

  Save & Exit
   w   write table to disk and exit
   q   quit without saving changes

  Create a new label
   g   create a new empty GPT partition table
   o   create a new empty DOS partition table
   s   create a new empty Sun partition table
```

### 📖 Most Important Commands

|Key|Action|
|---|---|
|`n`|➕ Add new partition|
|`p`|📋 Print partition table|
|`t`|🔄 Change partition type|
|`l`|📃 List all partition type codes|
|`w`|💾 Write and exit (SAVES changes)|
|`q`|🚪 Quit WITHOUT saving|

---

## 9. Step 8 — Create Partition 1 on `/dev/sda` (`n`)

### 🔧 Inside fdisk, type:

```
n
```

### ✅ Interactive Dialogue & Responses

```
Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p):                          ← Press ENTER (accept default = primary)

Using default response p.
Partition number (1-4, default 1):           ← Press ENTER (accept default = 1)
First sector (2048-20971519, default 2048):  ← Press ENTER (accept default)
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-20971519, default 20971519): +5G
                                             ← Type: +5G then ENTER

Created a new partition 1 of type 'Linux' and of size 5 GiB.
Partition #1 contains a ext4 signature.

Do you want to remove the signature? [Y]es/[N]o: Y
                                             ← Type: Y then ENTER

The signature will be removed by a write command.
```

### 📖 What Each Prompt Means

|Prompt|Response|Reason|
|---|---|---|
|Partition type|`p` (Enter)|Primary partition|
|Partition number|`1` (Enter)|First partition|
|First sector|Enter|Use default (2048) for alignment|
|Last sector|`+5G`|Create a 5 GiB partition|
|Remove signature?|`Y`|Wipe old filesystem signature|

> 💡 **`+5G` Syntax:** You can use `+5G`, `+2048M`, `+512K` etc. to specify partition size. Using the default last sector would use the entire remaining disk.

---

## 10. Step 9 — Create Partition 2 on `/dev/sda` (`n` again)

### 🔧 Inside fdisk, type:

```
n
```

### ✅ Interactive Dialogue & Responses

```
Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p):                              ← Press ENTER (primary)

Using default response p.
Partition number (2-4, default 2):               ← Press ENTER (accept 2)
First sector (10487808-20971519, default 10487808): ← Press ENTER
Last sector, +/-sectors or +/-size{K,M,G,T,P} (10487808-20971519, default 20971519): +5G
                                                 ← Type: +5G then ENTER

Created a new partition 2 of type 'Linux' and of size 5 GiB.
```

> 📌 **Note:** After creating partition 1 (5G), the first available sector for partition 2 automatically starts at `10487808` — right after where partition 1 ends.

---

## 11. Step 10 — Print Partition Table (`p`)

### 🔧 Inside fdisk, type:

```
p
```

### ✅ Example Output

```
Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x1f0dba31

Device     Boot    Start      End  Sectors Size Id Type
/dev/sda1           2048 10487807 10485760   5G 83 Linux
/dev/sda2       10487808 20971519 10483712   5G 83 Linux

Filesystem/RAID signature on partition 1 will be wiped.
```

### 📖 Partition Table Columns

|Column|Meaning|
|---|---|
|`Device`|Partition path|
|`Boot`|Boot flag (empty = not bootable)|
|`Start` / `End`|Sector range|
|`Sectors`|Total sector count|
|`Size`|Human-readable size|
|`Id`|Partition type code (currently `83` = Linux)|
|`Type`|Partition type name|

> ⚠️ **Notice:** Both partitions currently show `Id = 83` (Linux). We need to change this to `8e` (Linux LVM)!

---

## 12. Step 11 — Change Partition Type (`t`) → List Types (`l`)

### 🔧 Inside fdisk, type:

```
t
```

### ✅ Dialogue

```
Command (m for help): t
Partition number (1,2, default 2): 2
Hex code or alias (type L to list all): l
```

Type `l` to see all partition type codes:

```
00 Empty            24 NEC DOS          81 Minix / old Lin  bf Solaris
01 FAT12            27 Hidden NTFS Win  82 Linux swap / So  c1 DRDOS/sec (FAT-
02 XENIX root       39 Plan 9           83 Linux            c4 DRDOS/sec (FAT-
03 XENIX usr        3c PartitionMagic   84 OS/2 hidden or   c6 DRDOS/sec (FAT-
04 FAT16 <32M       40 Venix 80286      85 Linux extended   c7 Syrinx
05 Extended         41 PPC PReP Boot    86 NTFS volume set  da Non-FS data
06 FAT16            42 SFS              87 NTFS volume set  db CP/M / CTOS / .
07 HPFS/NTFS/exFAT  4d QNX4.x          88 Linux plaintext  de Dell Utility
08 AIX              4e QNX4.x 2nd part  8e Linux LVM        df BootIt
09 AIX bootable     4f QNX4.x 3rd part  93 Amoeba           e1 DOS access
...

Aliases:
   linux  - 83
   swap   - 82
   extended - 05
   uefi   - EF
   raid   - FD
   lvm    - 8E      ← THIS IS WHAT WE WANT
   linuxex - 85
```

> 🎯 **Key Code:** `8e` = **Linux LVM** — this is the partition type required for LVM Physical Volumes.

---

## 13. Step 12 — Set Partition 2 Type to `8e` (Linux LVM)

### 🔧 Inside fdisk, at the hex code prompt:

```
8e
```

### ✅ Full Dialogue

```
Command (m for help): t
Partition number (1,2, default 2): 2
Hex code or alias (type L to list all): 8e

Changed type of partition 'Linux' to 'Linux LVM'.

Command (m for help):
```

> ✅ **Success!** Partition 2 (`/dev/sda2`) is now typed as `Linux LVM`.

---

## 14. Step 13 — Set Partition 1 Type to `8e` (Linux LVM)

### 🔧 Inside fdisk, type `t` again for partition 1:

```
Command (m for help): t
Partition number (1,2, default 2): 1
Hex code or alias (type L to list all): 8e

Changed type of partition 'Linux' to 'Linux LVM'.

Command (m for help):
```

> ✅ **Success!** Partition 1 (`/dev/sda1`) is also now typed as `Linux LVM`.

> 💡 **Why set both?** In LVM, every partition that will become a Physical Volume (PV) should have type `8e`. This is a best practice for clarity and compatibility, even though LVM tools don't strictly enforce it.

---

## 15. Step 14 — Print Partition Table to Confirm (`p`)

### 🔧 Inside fdisk, type:

```
p
```

### ✅ Example Output — Both Partitions Now Show `8e Linux LVM`

```
Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x1f0dba31

Device     Boot    Start      End  Sectors Size Id Type
/dev/sda1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sda2       10487808 20971519 10483712   5G 8e Linux LVM

Filesystem/RAID signature on partition 1 will be wiped.
```

> 🎉 **Both partitions now show `Id = 8e` and `Type = Linux LVM`!** The layout is correct. Time to save.

---

## 16. Step 15 — Write & Save Changes (`w`)

### 🔧 Inside fdisk, type:

```
w
```

### ✅ Example Output

```
Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

[root@server1 admin]#
```

### 📖 What Happens

|Message|Meaning|
|---|---|
|`The partition table has been altered.`|Changes written to disk|
|`Calling ioctl() to re-read partition table.`|Kernel is notified of new partition layout|
|`Syncing disks.`|Disk buffers flushed|
|Returns to shell|fdisk exited successfully|

> ⚠️ **This is the point of no return!** After `w`, the partition table is written to disk. Always double-check with `p` before typing `w`.

---

## 17. Step 16 — Run `udevadm settle`

### 🔧 Command

```bash
udevadm settle
```

### 📺 What Happens

This command waits for the udev daemon to finish processing all queued device events (like the newly written partition table). It ensures `/dev/sda1` and `/dev/sda2` exist in the system before proceeding.

### ✅ Output

```
[root@server1 admin]# udevadm settle
[root@server1 admin]#
```

> 💡 **Why is this important?** Without `udevadm settle`, subsequent commands like `pvcreate /dev/sda1` might fail because the kernel hasn't finished updating the device nodes yet.

---

## 18. Step 17 — Clone Partition Layout to `/dev/sdb` and `/dev/sdc` using `sfdisk`

Instead of manually repeating all the `fdisk` steps for `sdb` and `sdc`, the instructor uses a powerful one-liner to **clone the partition layout** from `sda`.

### 🔧 Clone `sda` layout → `sdc`

```bash
sfdisk -d /dev/sda | sfdisk /dev/sdc
```

### ✅ Example Output

```
Checking that no-one is using this disk right now ... OK

Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Created a new DOS disklabel with disk identifier 0x1f0dba31.
/dev/sdc1: Created a new partition 1 of type 'Linux LVM' and of size 5 GiB.
/dev/sdc2: Created a new partition 2 of type 'Linux LVM' and of size 5 GiB.
/dev/sdc3: Done.

New situation:
Disklabel type: dos
Disk identifier: 0x1f0dba31

Device     Boot    Start      End  Sectors Size Id Type
/dev/sdc1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sdc2       10487808 20971519 10483712   5G 8e Linux LVM

The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

### 📖 How `sfdisk` Clone Works

```
sfdisk -d /dev/sda     ← DUMP: exports partition table as a script
|                       ← pipe
sfdisk /dev/sdc        ← APPLY: applies the script to target disk
```

> 🚀 **Efficiency Win!** This one command replaces the entire manual `fdisk` process (Steps 6–16) for each additional disk. The same layout (two 5G partitions, both type `8e`) is copied instantly.

> 📌 **Note:** The same operation was performed for `/dev/sdb` — `sfdisk -d /dev/sda | sfdisk /dev/sdb` — creating identical partitions `/dev/sdb1` and `/dev/sdb2`.

---

## 19. Step 18 — Verify All Disks with `lsblk`

### 🔧 Command

```bash
lsblk
```

### ✅ Example Output

```
NAME            MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda               8:0    0   10G  0 disk
├─sda1            8:1    0    5G  0 part
└─sda2            8:2    0    5G  0 part
sdb               8:16   0   10G  0 disk
├─sdb1            8:17   0    5G  0 part
└─sdb2            8:18   0    5G  0 part
sdc               8:32   0   10G  0 disk
├─sdc1            8:33   0    5G  0 part
└─sdc2            8:34   0    5G  0 part
sdd               8:48   0   10G  0 disk
sr0              11:0    1 1024M  0 rom
nvme0n1         259:0    0   70G  0 disk
├─nvme0n1p1     259:1    0    1G  0 part /boot/efi
├─nvme0n1p2     259:2    0    1G  0 part /boot
└─nvme0n1p3     259:3    0   54G  0 part
  ├─rhel-root   253:0    0   50G  0 lvm  /
  └─rhel-swap   253:1    0    4G  0 lvm  [SWAP]
```

> ✅ **`sda`, `sdb`, `sdc`** now each have two 5G partitions. `sdd` remains unpartitioned.

---

## 20. Step 19 — Full Disk Listing with `fdisk -l`

### 🔧 Command

```bash
fdisk -l
```

### ✅ Example Output (key sections)

```
Disk /dev/nvme0n1: 70 GiB, 75161927680 bytes, 146800640 sectors
Disk model: VMware Virtual NVMe Disk
...
Disklabel type: gpt

Device          Start       End   Sectors Size Type
/dev/nvme0n1p1   2048   2099199   2097152   1G EFI System
/dev/nvme0n1p2  2099200  4196351   2097152   1G Linux filesystem
/dev/nvme0n1p3  4196352 117446655 113250304  54G Linux LVM

Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
...
Device     Boot    Start      End  Sectors Size Id Type
/dev/sda1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sda2       10487808 20971519 10483712   5G 8e Linux LVM

Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
...
Device     Boot    Start      End  Sectors Size Id Type
/dev/sdb1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sdb2       10487808 20971519 10483712   5G 8e Linux LVM

Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
...
Device     Boot    Start      End  Sectors Size Id Type
/dev/sdc1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sdc2       10487808 20971519 10483712   5G 8e Linux LVM

Disk /dev/mapper/rhel-root: 50 GiB, 53687091200 bytes, 104857600 sectors
...
Disk /dev/mapper/rhel-swap: 4 GiB, 4294967296 bytes, 8388608 sectors
```

> 💡 `fdisk -l` shows **every** disk and partition in the system including LVM mapper devices.

---

## 21. Step 20 — Filter Only `sd*` Disks (`fdisk -l | grep -i sd`)

### 🔧 Command

```bash
fdisk -l | grep -i sd
```

### ✅ Example Output (highlighted in video)

```
Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
/dev/sda1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sda2       10487808 20971519 10483712   5G 8e Linux LVM
Disk /dev/sdd: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
/dev/sdb1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sdb2       10487808 20971519 10483712   5G 8e Linux LVM
Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
/dev/sdc1           2048 10487807 10485760   5G 8e Linux LVM
/dev/sdc2       10487808 20971519 10483712   5G 8e Linux LVM
```

> 🎯 **Final Verification:** All `sd*` disks show clearly. `sda`, `sdb`, `sdc` each have 2 × 5G partitions of type `8e Linux LVM`. `sdd` has no partitions (it was not configured in this video).

---

## 22. LVM Concept Cheatsheet

```
┌─────────────────────────────────────────────────────────┐
│                    LVM Architecture                      │
├─────────────────────────────────────────────────────────┤
│  Physical Disks (sda, sdb, sdc...)                       │
│        ↓                                                 │
│  Partitions with type 8e (/dev/sda1, /dev/sda2...)       │
│        ↓  pvcreate                                       │
│  Physical Volumes (PV) — raw LVM storage units           │
│        ↓  vgcreate                                       │
│  Volume Group (VG) — pool of PVs combined                │
│        ↓  lvcreate                                       │
│  Logical Volumes (LV) — flexible "virtual" partitions    │
│        ↓  mkfs                                           │
│  Filesystems (ext4, xfs, etc.) — formatted & mounted     │
└─────────────────────────────────────────────────────────┘
```

|Layer|Tool|Example|
|---|---|---|
|Physical Volume|`pvcreate`, `pvs`, `pvdisplay`|`pvcreate /dev/sda1`|
|Volume Group|`vgcreate`, `vgs`, `vgdisplay`|`vgcreate myvg /dev/sda1`|
|Logical Volume|`lvcreate`, `lvs`, `lvdisplay`|`lvcreate -L 5G -n mylv myvg`|

---

## 23. Partition Type Codes Reference

| Hex Code | Type                | Use                                          |
| -------- | ------------------- | -------------------------------------------- |
| `83`     | Linux               | Standard Linux partition (ext4, xfs etc.)    |
| `82`     | Linux swap          | Swap space                                   |
| `8e` ⭐   | **Linux LVM**       | **LVM Physical Volume — used in this guide** |
| `fd`     | Linux raid auto     | Software RAID (mdadm)                        |
| `ee`     | GPT                 | GPT protective MBR                           |
| `ef`     | EFI (FAT-12/16/...) | EFI System Partition                         |

> ⭐ **`8e` is the star of this guide** — it identifies a partition as belonging to LVM.

---

## 24. Quick Command Summary

```bash
# ── INSPECT EXISTING LVM ──────────────────────────────────
pvs                        # List Physical Volumes (summary)
pvdisplay                  # Detailed PV information
vgs                        # List Volume Groups (summary)
vgdisplay                  # Detailed VG information
lvdisplay                  # Detailed LV information
lsblk                      # List all block devices
fdisk -l                   # List all disks & partitions

# ── CREATE PARTITIONS ON /dev/sda ────────────────────────
fdisk /dev/sda             # Open fdisk interactive mode
  m                        #   Help menu
  n → Enter → Enter → +5G #   New 5G partition (repeat twice)
  t → 2 → 8e              #   Change partition 2 type to LVM
  t → 1 → 8e              #   Change partition 1 type to LVM
  p                        #   Print table to verify
  w                        #   Write & exit (SAVES!)

# ── POST-WRITE ────────────────────────────────────────────
udevadm settle             # Wait for kernel to update device nodes

# ── CLONE LAYOUT TO OTHER DISKS ──────────────────────────
sfdisk -d /dev/sda | sfdisk /dev/sdb   # Clone sda → sdb
sfdisk -d /dev/sda | sfdisk /dev/sdc   # Clone sda → sdc

# ── VERIFY ───────────────────────────────────────────────
lsblk                              # Visual tree of all disks
fdisk -l                           # Full detail all disks
fdisk -l | grep -i sd              # Filter only sd* disks
```

---

## 🔜 Next Steps (After This Video)

Once the partitions are created with type `8e`, the next steps in the LVM workflow would be:

```bash
# 1. Create Physical Volumes
pvcreate /dev/sda1 /dev/sda2 /dev/sdb1 /dev/sdb2 /dev/sdc1 /dev/sdc2

# 2. Create a new Volume Group
vgcreate datavg /dev/sda1 /dev/sda2 /dev/sdb1 /dev/sdb2

# 3. Create Logical Volumes
lvcreate -L 10G -n datalv datavg

# 4. Format the Logical Volume
mkfs.xfs /dev/datavg/datalv

# 5. Mount it
mount /dev/datavg/datalv /mnt/data
```

---
