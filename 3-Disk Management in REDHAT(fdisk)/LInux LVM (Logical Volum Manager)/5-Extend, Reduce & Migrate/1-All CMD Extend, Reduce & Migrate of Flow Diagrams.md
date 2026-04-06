
## 🗺️ Complete Operation Flow Diagrams

### LV Reduction Flow

```
lv2 (7G, ext4)
    │
    ▼
e2fsck -f /dev/vg1/lv2         ← Step 1: Force filesystem check
    │
    ▼
resize2fs /dev/vg1/lv2 1G      ← Step 2: Shrink FILESYSTEM to 1G
    │
    ▼
lvreduce -L 1G /dev/vg1/lv2    ← Step 3: Shrink LV to match
    │
    ▼
lv2 (1G, ext4) ✅
```

### PV Migration Flow

```
BEFORE:                              AFTER:
vg1                                  vg1
 ├─ sda1 [lv1 data]                   ├─ sda1 [lv1 data]
 ├─ sda2 [lv2 data]                   ├─ sda2 [lv2 data]
 ├─ sdb1 [lv1 data]                   ├─ sdb1 [lv1 data]
 ├─ sdc1 [lv1+lv2 data] ← REMOVE     ├─ sdb2 [lv1+lv2 data] ← NEW
 └─ sdb2 [empty]                      └─ (sdc1 gone) ✅

Step 1: pvcreate /dev/sdb2            ← Initialize new PV
Step 2: vgextend vg1 /dev/sdb2        ← Add to VG
Step 3: pvmove /dev/sdc1 /dev/sdb2    ← Move ALL data off sdc1
Step 4: vgreduce vg1 /dev/sdc1        ← Remove sdc1 from VG
Step 5: pvremove /dev/sdc1            ← Wipe LVM label from sdc1
```

---

## 📋 All Commands Quick Reference

### Video 1 — Extend & Reduce

|#|Command|Purpose|
|---|---|---|
|1|`lvs`|Check current LV sizes and state|
|2|`vgs`|Check VG free space|
|3|`lvcreate -L 6.98G -n lv2 vg1`|Create second LV `lv2`|
|4|`cd /xfs`|Enter the mounted filesystem directory|
|5|`df -h`|Verify mounted filesystem size|
|6|`e2fsck -f /dev/vg1/lv2`|Force filesystem check before resize|
|7|`mkfs.ext4 /dev/vg1/lv2`|Format lv2 with ext4|
|8|`e2fsck -f /dev/vg1/lv2`|Force check again before resize|
|9|`lsblk`|Inspect full block device tree|
|10|`blkid`|Show UUIDs and filesystem types|
|11|`resize2fs /dev/vg1/lv2 1G`|Shrink ext4 filesystem to 1G|

### Video 2 — Migrate, Extend VG, Reduce VG

|#|Command|Purpose|
|---|---|---|
|12|`df -h`|Confirm mounted filesystems|
|13|`lsblk`|Confirm device layout before migration|
|14|`umount /xfs`|Attempt unmount (fails — busy)|
|15|`fuser -cu /xfs/`|Find processes using `/xfs/`|
|16|`fuser -ck /xfs/`|Kill processes using `/xfs/`|
|17|`umount /xfs`|Unmount successfully|
|18|`pvcreate /dev/sdb2`|Initialize new PV|
|19|`vgextend vg1 /dev/sdb2`|Add new PV to vg1|
|20|`vgdisplay`|Verify VG after extension|
|21|`pvs`|Verify PV state|
|22|`pvmove /dev/sdc1 /dev/sdb2`|Migrate all data off sdc1|
|23|`vgreduce vg1 /dev/sdc1`|Remove sdc1 from vg1|
|24|`pvs`|Confirm sdc1 removed from VG|
|25|`pvremove /dev/sdc1`|Wipe LVM metadata from sdc1|
|26|`mount /dev/vg1/lv1 /xfs/`|Re-mount lv1|
|27|`ll /xfs/`|Verify data intact after migration|
|28|`lsblk`|Confirm final block device layout|

---

## ⚠️ Common Errors & Fixes

|❌ Error|🔍 Cause|✅ Fix|
|---|---|---|
|`umount: target is busy`|A process has the mount point as its CWD or has open files there|Run `fuser -cu /xfs/` to find the process, then `fuser -ck /xfs/` to kill it|
|`Physical volume "/dev/sda2" still in use`|Tried `vgreduce` on a PV that still has LV data|Run `pvmove /dev/sda2` first to migrate data off, then retry `vgreduce`|
|`mount: can't find in /etc/fstab`|Running `mount <device>` without a mountpoint|Always specify both device AND mountpoint: `mount /dev/vg1/lv1 /xfs/`|
|`resize2fs` refuses to resize|Filesystem was not checked before resize|Always run `e2fsck -f <device>` immediately before `resize2fs`|
|Data corruption after LV reduce|Reduced the LV **before** the filesystem|Always: `e2fsck` → `resize2fs` → `lvreduce` (filesystem FIRST, then LV)|
|`pvmove` fails — no free PEs|No room on destination PV|Add a new PV first with `pvcreate` + `vgextend`, then retry `pvmove`|

---

## 💡 Key Concepts & Tips

### 🔑 LV Extension vs Filesystem Extension

Extending an LV does NOT automatically grow the filesystem inside it. You must:

```bash
# Extend the LV
lvextend -L +3G /dev/vg1/lv1

# Then extend the filesystem (ext4)
resize2fs /dev/vg1/lv1

# OR for XFS (XFS can only grow, not shrink)
xfs_growfs /xfs/
```

### 🔑 LV Reduction — The Golden Rule

**FILESYSTEM FIRST, LV SECOND. ALWAYS.**

```
❌ WRONG ORDER:  lvreduce → resize2fs  = DATA CORRUPTION
✅ RIGHT ORDER:  e2fsck → resize2fs → lvreduce = SAFE
```

> ⚠️ XFS filesystems **cannot be shrunk at all**. Only ext2/ext3/ext4 support reduction.

### 🔑 `fuser` — The Process Detective

```bash
fuser -cu /mount/point    # Find WHO is using the mount (with username)
fuser -ck /mount/point    # Kill all processes using the mount
fuser -cv /mount/point    # Verbose: show process details
```

### 🔑 `pvmove` — Live Data Migration

`pvmove` is one of LVM's most powerful features — it moves data between PVs **without downtime**:

```bash
pvmove /dev/sdc1              # Move to ANY available PV in the VG
pvmove /dev/sdc1 /dev/sdb2    # Move specifically to sdb2
pvmove -b /dev/sdc1           # Run in background (non-blocking)
pvmove --abort                # Abort an in-progress pvmove
```

### 🔑 The Complete PV Swap Workflow

To replace a failing or unwanted disk in an LVM VG:

```bash
# 1. Add replacement disk
pvcreate /dev/new_disk
vgextend vg_name /dev/new_disk

# 2. Migrate data away from old disk
pvmove /dev/old_disk /dev/new_disk

# 3. Remove old disk from VG
vgreduce vg_name /dev/old_disk

# 4. Wipe LVM metadata from old disk
pvremove /dev/old_disk

# 5. Now safely remove old disk from system
```

### 🔑 `lsblk` vs `pvs` — What to Use When

- `lsblk` → Shows the **physical tree**: disk → partition → LVM device → mount point. Best for understanding hardware layout.
- `pvs` / `vgs` / `lvs` → Shows **LVM logical view**: PEs, sizes, assignments, free space. Best for LVM operations.

### 🔑 `blkid` — Finding UUIDs

Use `blkid` when you need to:

- Identify what filesystem is on a device
- Get the UUID for an `/etc/fstab` entry
- Confirm a `pvremove` worked (device will no longer show `TYPE="LVM2_member"`)

---
