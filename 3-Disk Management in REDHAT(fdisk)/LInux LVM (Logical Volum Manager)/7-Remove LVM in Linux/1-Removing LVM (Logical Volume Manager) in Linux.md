# 🗑️ Complete LVM Removal — Step-by-Step Guide

---
## ⚠️ IMPORTANT WARNING

> **🚨 This process is IRREVERSIBLE. All data on the LVM volumes will be permanently destroyed.**  
> Before proceeding, make sure you have:
> 
> - ✅ Backed up all important data
> - ✅ Identified the correct LV/VG/PV names (don't confuse with your OS root LVM!)
> - ✅ Root (`root`) access on the system
> - ✅ Confirmed none of the volumes contain live system mounts like `/`, `/boot`, or `/swap`

---
## 🔍 LVM Architecture Overview

Before removing anything, it helps to understand the 3-layer LVM stack — we must remove from **top to bottom**:

```
┌─────────────────────────────────────────┐
│        Filesystem  (ext4 / xfs)         │  ← Layer 4: Unmount first
├─────────────────────────────────────────┤
│     Logical Volume  (lv1, lv2 ...)      │  ← Layer 3: Wipe → Deactivate → Remove
├─────────────────────────────────────────┤
│       Volume Group  (vg1)               │  ← Layer 2: Remove after LVs gone
├─────────────────────────────────────────┤
│  Physical Volumes  (sda1, sdb1, sdb2…)  │  ← Layer 1: Remove after VG gone
├─────────────────────────────────────────┤
│    Raw Disk Partitions  (sda, sdb …)    │  ← Layer 0: Delete with fdisk last
└─────────────────────────────────────────┘
```

> 🔑 **Rule:** Always work from the **top layer down**. You cannot remove a VG while LVs exist in it. You cannot remove a PV while it still belongs to a VG.

---

## ✅ Prerequisites & Initial Check

Always start by surveying the existing LVM layout before doing anything:

```bash
# List all Logical Volumes
lvs

# List all Volume Groups
vgs

# List all Physical Volumes
pvs

# Show block devices and their mount points
lsblk

# Show current disk usage
df -h
```

### 📤 Example `lvs` Output (from the video):

```
  LV    VG    Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root  rhel  -wi-ao----  50.00g
  swap  rhel  -wi-ao----   4.00g
  lv1   vg1   -wi-a-----  14.00g
  lv2   vg1   -wi-a-----   5.98g
```

> 🔑 In the video, the target LVs are **`lv1`** and **`lv2`** inside **`vg1`**. The `root` and `swap` under `rhel` are the **OS volumes — do NOT touch those!**

---

## 📂 Step 1 — Unmount All Filesystems

Before anything can be removed, every filesystem mounted on those LVs must be unmounted.

 two filesystems were mounted:

- `/ext4` — mounted on `lv1` (ext4 type)
- `/xfs` — mounted on `lv2` (xfs type)

```bash
umount /ext4
umount /xfs
```

### 📤 Example Output:

```
[root@server1 /]# umount /ext4
[root@server1 /]# umount /xfs
[root@server1 /]#
```

> ✅ No output = success. Both filesystems are now unmounted.

> 💡 If you get `target is busy`, a process is still using the mount. Find and kill it with:
> 
> ```bash
> fuser -km /ext4
> ```

---

## 🧹 Step 2 — Wipe Filesystem Signatures from LVs

After unmounting, the filesystem signatures (superblocks) still exist on the LVs. We use `wipefs` to erase them cleanly so the device won't be accidentally auto-mounted or recognised as a filesystem.

```bash
wipefs -a /dev/vg1/lv1
wipefs -a /dev/vg1/lv2
```

### 📤 Exact Output from Video:

```
[root@server1 /]# wipefs -a /dev/vg1/lv1
/dev/vg1/lv1: 2 bytes were erased at offset 0x00000438 (ext4): 53 ef

[root@server1 /]# wipefs -a /dev/vg1/lv2
/dev/vg1/lv2: 2 bytes were erased at offset 0x00000438 (ext4): 53 ef
```

---

## 🔴 Step 3 — Deactivate Logical Volumes (lvchange -an)

Before removing LVs, they must be **deactivated** (taken offline). An active LV has its device mapper entry open and cannot be removed.

```bash
lvchange -an /dev/vg1/lv2
lvchange -an /dev/vg1/lv1
```

### 📤 Example Output:

```
[root@server1 /]# lvchange -an /dev/vg1/lv2
[root@server1 /]# lvchange -an /dev/vg1/lv1
[root@server1 /]#
```

> ✅ No output = success. Both LVs are now deactivated.

> 🔑 **Flag meaning:** `-an` = activate (`-a`) to **no** (`n`). This deactivates the LV.  
> To activate, use `-ay` (activate = yes).

---

## ✔️ Step 4 — Verify LV Deactivation with lvs

After deactivating, confirm the Attr column changed from `-wi-a-----` (active) to `-wi-------` (inactive):

```bash
lvs
```
### 📤 Output After Deactivation:

```
  LV    VG    Attr       LSize
  lv1   vg1   -wi-------  14.00g    ← no 'a' = inactive ✅
  lv2   vg1   -wi-------   5.98g    ← no 'a' = inactive ✅
```

> 🔑 **Reading the Attr column:** The 5th character is the activity flag. `a` = active, `-` = inactive.

---

## 🗑️ Step 5 — Remove Logical Volumes (lvremove)

Now with the LVs deactivated, we can safely remove them one by one.

```bash
lvremove /dev/vg1/lv1
lvremove /dev/vg1/lv2
```

> ```bash
> lvremove -f /dev/vg1
> ```

---

## ✔️ Step 6 — Confirm LVs are Gone

```bash
lvs
```

### 📤 Output After Removing lv1 and lv2:

```
  LV    VG    Attr       LSize
  root  rhel  -wi-ao----  50.00g
  swap  rhel  -wi-ao----   4.00g
```

> ✅ `lv1` and `lv2` under `vg1` are completely gone. Only the OS volumes `root` and `swap` under `rhel` remain — which we correctly leave untouched.

---

# **🗑️ Step 7 — Remove the Volume Group (vgremove)**

---

With all LVs removed, the Volume Group `vg1` is now empty and can be deleted.

```bash
vgremove vg1
```

### 📤 Exact Output from Video:

```
[root@server1 /]# vgremove vg1
  Volume group "vg1" successfully removed
```

> ✅ VG `vg1` is now completely gone.

---

## ✔️ Step 8 — Verify VG is Gone with vgs

```bash
vgs
```

### 📤 Output After vgremove:

```
  VG    #PV #LV #SN Attr   VSize   VFree
  rhel    1   2   0 wz--n- 54.00g     0
```

> ✅ `vg1` is gone. Only the OS VG `rhel` remains — as expected.

---

# 🗑️ Step 9 — Remove Physical Volumes (pvremove)

---

Now we wipe the LVM metadata headers from each of the underlying physical volume partitions. The PV labels must be removed so the disks are completely clean.

### ✅ Correct Commands — Remove Each PV Partition:

```bash
pvremove /dev/sda1
pvremove /dev/sdb1
pvremove /dev/sdb2
pvremove /dev/sda2
```

### 📤 Exact Output from Video:

```
[root@server1 /]# pvremove /dev/sda1
  Labels on physical volume "/dev/sda1" successfully wiped.

[root@server1 /]# pvremove /dev/sdb1
  Labels on physical volume "/dev/sdb1" successfully wiped.

[root@server1 /]# pvremove /dev/sdb2
  Labels on physical volume "/dev/sdb2" successfully wiped.

[root@server1 /]# pvremove /dev/sdc1
  No PV found on device /dev/sdc1.

[root@server1 /]# pvremove /dev/sda2
  Labels on physical volume "/dev/sda2" successfully wiped.
```

---

## 🔍 Step 10 — Inspect Remaining Disks with lsblk

After pvremove, run `lsblk` to see which disk partitions still exist that need to be deleted:

```bash
lsblk
```

### 📤 Exact Output :

```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda           8:0    0   10G  0 disk
├─sda1        8:1    0    5G  0 part
└─sda2        8:2    0    5G  0 part
sdb           8:16   0   10G  0 disk
├─sdb1        8:17   0    5G  0 part
└─sdb2        8:18   0    5G  0 part
sdc           8:32   0   10G  0 disk
├─sdc1        8:33   0    5G  0 part
└─sdc2        8:34   0    5G  0 part
sdd           8:48   0   10G  0 disk
sr0           11:0   1 1024M  0 rom
nvme0n1     259:0    0   70G  0 disk
├─nvme0n1p1 259:1    0    1G  0 part /boot/efi
├─nvme0n1p2 259:2    0    1G  0 part /boot
└─nvme0n1p3 259:3    0   54G  0 part
  ├─rhel-root 253:0  0   50G  0 lvm  /
  └─rhel-swap 253:1  0    4G  0 lvm  [SWAP]
```

---

## 💾 Step 11 — Delete Disk Partitions with fdisk

We use `fdisk` to enter each disk interactively and delete its partitions. This must be done for **each disk** that had LVM partitions.

### 🅰️ Delete Partitions on `/dev/sda`

```bash
fdisk /dev/sda
```

Inside `fdisk`, the interactive session goes as follows:

```
Welcome to fdisk (util-linux 2.37.4).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): d
Partition number (1,2, default 2):
```

Type `d` to delete, then press **Enter** to select the default (partition 2):

```
Partition 2 has been deleted.

Command (m for help): d
Selected partition 1
Partition 1 has been deleted.

Command (m for help): p
```

After `p` (print), confirm no partitions remain:

```
Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
...
(no partition table entries shown)

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

> 🔑 **fdisk key commands used:**
> 
> |Key|Action|
> |---|---|
> |`d`|Delete a partition|
> |`p`|Print / list current partitions|
> |`w`|Write changes and exit|
> |`q`|Quit without saving|

---

### 🅱️ Delete Partitions on `/dev/sdb`

```bash
fdisk /dev/sdb
```

```
Command (m for help): d
Partition number (1,2, default 2):
Partition 2 has been deleted.

Command (m for help): d
Selected partition 1
Partition 1 has been deleted.

Command (m for help): p

Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x1f0dba31

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

> ✅ Both partitions deleted and written to disk. `Syncing disks.` confirms the kernel partition table is now updated.

---

### 🅲️ Repeat for Remaining Disks

Repeat the same `fdisk` sequence for each remaining disk that had partitions (`/dev/sdc`, etc.):

```bash
fdisk /dev/sdc
```

Inside fdisk:

```
Command (m for help): d
Command (m for help): d
Command (m for help): w
```

---

## ✔️ Step 12 — Final Verification

After all steps are complete, run these commands to verify everything is clean:

```bash
# Confirm no LVs remain in vg1
lvs

# Confirm vg1 is gone
vgs

# Confirm no PVs remain on removed disks
pvs

# Confirm partitions are gone on all disks
lsblk
```

### 📤 Expected Clean `lsblk` Output:

```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda           8:0    0   10G  0 disk             ← Clean, no partitions 🎉
sdb           8:16   0   10G  0 disk             ← Clean, no partitions 🎉
sdc           8:32   0   10G  0 disk             ← Clean, no partitions 🎉
sdd           8:48   0   10G  0 disk
nvme0n1     259:0    0   70G  0 disk
├─nvme0n1p1 259:1    0    1G  0 part /boot/efi   ← OS disk, untouched ✅
├─nvme0n1p2 259:2    0    1G  0 part /boot
└─nvme0n1p3 259:3    0   54G  0 part
  ├─rhel-root 253:0  0   50G  0 lvm  /
  └─rhel-swap 253:1  0    4G  0 lvm  [SWAP]
```

> 🎉 **LVM is completely removed!** All disks are clean raw disks, ready for reuse.

---
