# 📦 LVM Advanced Operations — Extend, Reduce & Migrate on RHEL 9.7

> 📹  Extending LV, creating second LV, reducing LV with filesystem resize  
> 📹  Extending VG with new PV, migrating LV data with `pvmove`, reducing VG with `vgreduce`, removing PV with `pvremove`

> ⚠️ **Prerequisite:** This guide continues from the base LVM setup (PV → VG → LV → mkfs → mount) covered in the previous guide. Starting state: `lv1` (13G ext4) is mounted at `/xfs/`, `vg1` has 4 PVs totalling ~19.98G.

---

## 🖥️ Starting State Overview

Before these videos begin, the system is in the following state:

```
vg1:
  ├─ lv1  (13G, ext4, mounted at /xfs/)    ← extended previously from 10G
  └─ lv2  (6.98G, not yet formatted)

PVs in vg1:
  /dev/sda1  5G
  /dev/sda2  5G
  /dev/sdb1  5G
  /dev/sdc1  5G   ← this will be migrated away from

Notepad (on screen): /dev/mapper/vg1-lv1   9.8G   24K   9.3G   1% /xfs
```

The on-screen text editor shows reference output from `df -h` confirming `lv1` is ~9.8G (before the extension shown in this video).

---

## 📹  1 — Extend LV & Reduce LV

---

### ✅ Step 1: Check Current LV State and VG Free Space

**Commands typed in video:**

```bash
lvs
vgs
```

**📟 Exact output of `lvs`:**

```
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root rhel -wi-ao---- 50.00g
  swap rhel -wi-ao----  4.00g
  lv1  vg1  -wi-ao---- 13.00g
  lv2  vg1  -wi-a-----  6.98g
```

**📟 Exact output of `vgs`:**

```
  VG   #PV #LV #SN Attr   VSize   VFree
  rhel   1   2   0 wz--n- 54.00g     0
  vg1    4   2   0 wz--n- 19.98g  4.00m
```

> 📌 `vg1` has 4 PVs, 2 LVs (`lv1` at 13G and `lv2` at 6.98G) with only **4.00m free** — almost all space is allocated. .

---

### ✅ Step 2: Extend lv1 — Grow the Logical Volume with `lvextend`

> 📌 This step is seen in the very first frame of the video being typed. The extension was already applied to `lv1` bringing it from ~10G up to 13G.

**Command :**

```bash
lvcreate -L 6.98G -n lv2 vg1
```

**📟 Exact output:**

```
  Rounding up size to full physical extent 6.98 GiB
  Logical volume "lv2" created.
```

**What it does:**  
Creates a new Logical Volume named `lv2` of size ~6.98 GiB from the remaining free space in `vg1`. This LV will later be formatted, filesystem-checked, and then reduced to demonstrate LV shrinking.

> 💡 LVM rounds your requested size up to the nearest full Physical Extent (4 MiB boundary). Here `6.98G` rounds up cleanly to `6.98 GiB`.


**Flag breakdown:**

|Flag|Meaning|
|---|---|
|`-L 6.98G`|Allocate ~6.98 GiB of space|
|`-n lv2`|Name the new LV `lv2`|
|`vg1`|Allocate from Volume Group `vg1`|

---

### ✅ Step 3: Verify Both LVs and VG Free Space

**Commands**

```bash
lvs
vgs
```

**📟 Exact output of `lvs`:**

```
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root rhel -wi-ao---- 50.00g
  swap rhel -wi-ao----  4.00g
  lv1  vg1  -wi-ao---- 13.00g
  lv2  vg1  -wi-a-----  6.98g
```

**📟 Exact output of `vgs`:**

```
  VG   #PV #LV #SN Attr   VSize   VFree
  rhel   1   2   0 wz--n- 54.00g     0
  vg1    4   2   0 wz--n- 19.98g  4.00m
```

> 📌 Both LVs confirmed:
> 
> - `lv1` = 13.00g (active/open — `ao` in Attr = actively open/mounted)
> - `lv2` = 6.98g (inactive — `a-` in Attr = allocated but not yet active/mounted)
> - `VFree = 4.00m` → Virtually all space in `vg1` is now consumed

---

### ✅ Step 4: Extend FS & Navigate into the Mounted Filesystem

**Command :**

```bash
resize2fs /dev/vg1/lv1 (enter)
cd /xfs
```

---

### ✅ Step 5: Check Mounted Filesystem Size with `df -h`

**Command :**

```bash
df -h
```

**📟 Exact output shown:**

```
Filesystem                  Size  Used Avail Use% Mounted on
devtmpfs                    4.0M     0  4.0M   0% /dev
tmpfs                       1.8G     0  1.8G   0% /dev/shm
tmpfs                       725M  9.8M  715M   2% /run
efivarfs                    256K   76K  176K  31% /sys/firmware/efi/efivars
/dev/mapper/rhel-root        49G   32G   15G  69% /
/dev/nvme0n1p2              974M  327M  580M  37% /boot
/dev/nvme0n1p1             1022M  7.4M 1015M   1% /boot/efi
tmpfs                       363M  132K  363M   1% /run/user/1001
/dev/mapper/vg1-lv1          13G   40K   13G   1% /xfs
tmpfs                       363M   36K  363M   1% /run/user/1002
```

> 📌 Key line to note: `/dev/mapper/vg1-lv1 13G 40K 13G 1% /xfs`  
> The filesystem is now **13G** (confirming `lv1` was already extended). Only 40K is used — nearly empty.

---

### ✅ Step 7: Run Filesystem Check on lv2 with `e2fsck`

**Command typed in the video:**

```bash
e2fsck -f /dev/vg1/lv2
```

**What it does:**  
Performs a **forced** filesystem check (`-f`) on `lv2`. This is **mandatory** before any resize operation on ext2/ext3/ext4 filesystems. If the filesystem has errors, `resize2fs` will refuse to run.

**📟 Exact output shown in video:**

```
e2fsck 1.46.5 (30-Dec-2021)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/vg1/lv2: 11/457856 files (0.0% non-contiguous), 53173/1829888 blocks
```

> ✅ All 5 passes complete — filesystem is clean. The summary shows:
> 
> - `11/457856 files` — only system overhead files
> - `53173/1829888 blocks` — minimal blocks used

---

### ✅ Step 8: Format lv2 with ext4 using `mkfs.ext4`

**Command typed in the video:**

```bash
mkfs.ext4 /dev/vg1/lv2
```

**📟 Exact output shown in video:**

```
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 1829888 4k blocks and 457856 inodes
Filesystem UUID: 0321ad5c-de6d-422d-99e0-917023233e85
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

> 📌 `lv2` (~7G) formatted successfully as ext4 with 1,829,888 blocks at 4k block size. UUID assigned: `0321ad5c-de6d-422d-99e0-917023233e85`.

---

### ✅ Step 9: Run Filesystem Check Again on lv2 with `e2fsck -f`

**Command typed in the video:**

```bash
e2fsck -f /dev/vg1/lv2
```

**What it does:**  
Runs `e2fsck` again after the fresh format. This is done **before** `resize2fs` to confirm the filesystem is clean and ready for resizing. This step is **critical** — `resize2fs` will refuse to shrink without a clean `e2fsck` pass immediately before.

**📟 Exact output shown in video:**

```
e2fsck 1.46.5 (30-Dec-2021)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/vg1/lv2: 11/457856 files (0.0% non-contiguous), 53173/1829888 blocks
```

> ✅ Clean pass — all 5 stages pass. Now ready for `resize2fs`.

---

### ✅ Step 10: Inspect Block Device Layout with `lsblk`

**Command typed in the video (from `/xfs/` directory):**

```bash
lsblk
```

**📟 Exact output shown in video:**

```
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda               8:0    0   10G  0 disk
├─sda1            8:1    0    5G  0 part
│ └─vg1-lv1     253:2    0   13G  0 lvm  /xfs
└─sda2            8:2    0    5G  0 part
  └─vg1-lv2     253:3    0    7G  0 lvm
sdb               8:16   0   10G  0 disk
├─sdb1            8:17   0    5G  0 part
│ └─vg1-lv1     253:2    0   13G  0 lvm  /xfs
└─sdb2            8:18   0    5G  0 part
sdc               8:32   0   10G  0 disk
├─sdc1            8:33   0    5G  0 part
│ └─vg1-lv1     253:2    0   13G  0 lvm  /xfs
│ └─vg1-lv2     253:3    0    7G  0 lvm
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

> 📌 Key observations:
> 
> - `lv1` (13G, mounted at `/xfs/`) spans 3 PVs: `sda1`, `sdb1`, `sdc1` — shown by the same device number `253:2` appearing under all three
> - `lv2` (7G) spans `sda2` and `sdc1` — device number `253:3`
> - `sdb2` and `sdd` are completely unused (no LVM under them)

---

