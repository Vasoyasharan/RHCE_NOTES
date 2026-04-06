# 🖥️ LVM (Logical Volume Manager) — Complete Step-by-Step Guide on RHEL 9.7


---
## 🧠 What is LVM?

**LVM (Logical Volume Manager)** is a device-mapper framework in Linux that provides a flexible and powerful abstraction layer over physical storage devices. It allows you to:

- 📦 Combine multiple physical disks into one large storage pool
- 📏 Create, resize, and delete logical volumes without repartitioning
- 🔄 Extend or shrink volumes on the fly (even while mounted in some cases)
- 🛡️ Take snapshots of volumes for backups

---

## 🏗️ LVM Architecture Overview

```
Physical Disks (HDD/SSD/Partitions)
        ↓
  Physical Volumes (PV)        ← pvcreate
        ↓
   Volume Groups (VG)          ← vgcreate
        ↓
  Logical Volumes (LV)         ← lvcreate
        ↓
  Filesystem (ext4/xfs/etc.)   ← mkfs.ext4 / mkfs.xfs
        ↓
     Mount Point               ← mount
```

| Layer                | Tool        | Purpose                                       |
| -------------------- | ----------- | --------------------------------------------- |
| Physical Volume (PV) | `pvcreate`  | Tags a disk/partition for LVM use             |
| Volume Group (VG)    | `vgcreate`  | Pools multiple PVs into one storage group     |
| Logical Volume (LV)  | `lvcreate`  | Creates a virtual partition from the VG pool  |
| Filesystem           | `mkfs.ext4` | Formats the LV so it can store data           |
| Mount                | `mount`     | Makes the LV accessible in the directory tree |

![](https://www.baeldung.com/wp-content/uploads/sites/2/2023/01/LVM_component.png)

---

## 🖥️ Prerequisites & Environment

|Detail|Value|
|---|---|
|OS|RHEL 9.7|
|Platform|VMware Workstation|
|User|`root@server1`|
|Working directory|`/home/admin`|
|Disks used|`/dev/sda1`, `/dev/sdb1`, `/dev/sdc1`|
|Each disk size|5.00 GiB|
|VG Name|`vg1`|
|LV Name|`lv1`|
|Mount point|`/mnt/`|

> ✅ You must be **root** to run all LVM commands shown in the video.

---

## 📹 VIDEO 3 — Creating Physical Volumes (PV) and Volume Group (VG)

---

### ✅ Step 1: Create Physical Volumes with `pvcreate`

**Command typed in the video:**

```bash
pvcreate /dev/sda1 /dev/sdb1 /dev/sdc1
```

**What it does:**  
Initializes three disk partitions (`/dev/sda1`, `/dev/sdb1`, `/dev/sdc1`) as LVM Physical Volumes. This writes LVM metadata to each disk, marking them as usable for LVM.

**📟 Exact output shown in video (highlighted in green):**

```
Physical volume "/dev/sda1" successfully created.
Physical volume "/dev/sdb1" successfully created.
Physical volume "/dev/sdc1" successfully created.
```

> 💡 **Note:** All three are created in a single command by listing all three devices separated by spaces.

---

### ✅ Step 2: Verify PVs with `pvs`

**Command typed in the video:**

```bash
pvs
```

**What it does:**  
Displays a short summary table of all Physical Volumes currently known to LVM on the system.

**📟 Exact output shown in video:**

```
  PV             VG   Fmt  Attr PSize  PFree
  /dev/nvme0n1p3 rhel lvm2 a--  54.00g    0
  /dev/sda1           lvm2 ---   5.00g 5.00g
  /dev/sdb1           lvm2 ---   5.00g 5.00g
  /dev/sdc1           lvm2 ---   5.00g 5.00g
```

> 📌 Notice the three new PVs (`/dev/sda1`, `/dev/sdb1`, `/dev/sdc1`) show **no VG assigned** yet (empty VG column) and their full 5.00g is free (`PFree`).  
> `/dev/nvme0n1p3` already belongs to the existing `rhel` VG.

---

### ✅ Step 3: Detailed PV Inspection with `pvdisplay`

**Command typed in the video:**

```bash
pvdisplay
```

**What it does:**  
Displays detailed, verbose information about **every** Physical Volume on the system, including size, UUID, PE (Physical Extent) count, and which VG it belongs to.

**📟 Exact output shown in video (key sections for new PVs):**

```
"/dev/sdb1" is a new physical volume of "5.00 GiB"
--- NEW Physical volume ---
PV Name               /dev/sdb1
VG Name               
PV Size               5.00 GiB
Allocatable           NO
PE Size               0
Total PE              0
Free PE               0
Allocated PE          0
PV UUID               bmERCu-zR08-B82R-P5et-9b5l-AzNk-WujZPp

"/dev/sdc1" is a new physical volume of "5.00 GiB"
--- NEW Physical volume ---
PV Name               /dev/sdc1
VG Name               
PV Size               5.00 GiB
Allocatable           NO
PE Size               0
Total PE              0
Free PE               0
Allocated PE          0
PV UUID               IMkQCu-1Xxd-m9Xf-njRS-y9HC-c0wq-lQwN0M
```

> 📌 The label **"NEW Physical volume"** confirms the PVs are not yet assigned to any VG. `Allocatable: NO` means they cannot be used until added to a Volume Group.

At the bottom of the output, a second `pvs` call is shown confirming all four PVs:

```
  PV             VG   Fmt  Attr PSize  PFree
  /dev/nvme0n1p3 rhel lvm2 a--  54.00g    0
  /dev/sda1           lvm2 ---   5.00g 5.00g
  /dev/sdb1           lvm2 ---   5.00g 5.00g
  /dev/sdc1           lvm2 ---   5.00g 5.00g
```

---

### ✅ Step 4: Check Existing Volume Groups with `vgs`

**Command typed in the video:**

```bash
vgs
```

**What it does:**  
Displays a brief summary table of all Volume Groups. This is run **before** creating the new VG to confirm the current state.

**📟 Exact output shown in video:**

```
  VG   #PV #LV #SN Attr   VSize  VFree
  rhel   1   2   0 wz--n- 54.00g    0
```

> 📌 Only the existing `rhel` VG exists at this point. It has 1 PV, 2 LVs, and 0 free space.

---

### ✅ Step 5: Create a New Volume Group with `vgcreate`

**Command typed in the video** (typed gradually as seen across frames):

```bash
vgcreate vg1 /dev/sda1 /dev/sdb1 /dev/sdc1
```

**What it does:**  
Creates a new Volume Group named **`vg1`** by pooling the three Physical Volumes (`/dev/sda1`, `/dev/sdb1`, `/dev/sdc1`) together. The total size will be approximately 3 × 5 GiB = ~14.99 GiB.

**📟 Exact output shown in video:**

```
  Volume group "vg1" successfully created
```

> 💡 **Syntax:** `vgcreate <VG_name> <PV1> <PV2> <PV3> ...`  
> You can add as many PVs as you want in a single `vgcreate` command.

---

### ✅ Step 6: Verify the New VG with `vgs`

**Command typed in the video:**

```bash
vgs
```

**📟 Exact output shown in video:**

```
  VG   #PV #LV #SN Attr   VSize   VFree
  rhel   1   2   0 wz--n-  54.00g      0
  vg1    3   0   0 wz--n- <14.99g <14.99g
```

> 📌 The new `vg1` now appears:
> 
> - **#PV = 3** → 3 Physical Volumes assigned
> - **#LV = 0** → No Logical Volumes created yet
> - **VSize = <14.99g** → Total pool size (~3 × 5 GiB)
> - **VFree = <14.99g** → All space is still free

---

### ✅ Step 7: Detailed VG Inspection with `vgdisplay`

**Command typed in the video:**

```bash
vgdisplay
```

**What it does:**  
Shows detailed metadata about every Volume Group on the system, including PE (Physical Extent) count, UUID, status, and free space.

**📟 Exact output for `vg1` shown in video:**

```
--- Volume group ---
VG Name               vg1
System ID             
Format                lvm2
Metadata Areas        3
Metadata Sequence No  1
VG Access             read/write
VG Status             resizable
MAX LV                0
Cur LV                0
Open LV               0
Max PV                0
Cur PV                3
Act PV                3
VG Size               <14.99 GiB
PE Size               4.00 MiB
Total PE              3837
Alloc PE / Size       0 / 0
Free  PE / Size       3837 / <14.99 GiB
VG UUID               0WY1o7-hNV0-uNJQ-j8ov-Lo8A-kDyj-dqHGRH
```

> 📌 Key fields to understand:
> 
> - **PE Size = 4.00 MiB** — The smallest allocatable unit in the VG
> - **Total PE = 3837** — Total number of Physical Extents available
> - **Free PE / Size = 3837 / <14.99 GiB** — All PEs are free (no LV created yet)
> - **VG Status = resizable** — The VG can be extended later

The output for the `rhel` VG is also shown above it for context:

```
--- Volume group ---
VG Name               rhel
...
VG Size               54.00 GiB
PE Size               4.00 MiB
Total PE              13824
Alloc PE / Size       13824 / 54.00 GiB
Free  PE / Size       0 / 0
```

---

### ✅ Step 8: Detailed PV Inspection After VG Assignment with `pvdisplay`

**Command typed in the video:**

```bash
pvdisplay
```

**What it does:**  
Runs `pvdisplay` again after the VG has been created. This confirms that all three PVs (`/dev/sda1`, `/dev/sdb1`, `/dev/sdc1`) are now properly assigned to `vg1`.

**📟 Exact output shown in video (for `vg1` PVs):**

```
--- Physical volume ---
PV Name               /dev/sda1
VG Name               vg1
PV Size               5.00 GiB / not usable 4.00 MiB
Allocatable           yes
PE Size               4.00 MiB
Total PE              1279
Free PE               1279
Allocated PE          0
PV UUID               dQMeIa-c8Uy-dEiG-V6cm-claO-NnrC-VBOVi9

--- Physical volume ---
PV Name               /dev/sdb1
VG Name               vg1
PV Size               5.00 GiB / not usable 4.00 MiB
Allocatable           yes
PE Size               4.00 MiB
Total PE              1279
Free PE               1279
Allocated PE          0
PV UUID               bmERCu-zR08-B82R-P5et-9b5l-AzNk-WujZPp

--- Physical volume ---
PV Name               /dev/sdc1
VG Name               vg1
PV Size               5.00 GiB / not usable 4.00 MiB
Allocatable           yes
PE Size               4.00 MiB
Total PE              1279
Free PE               1279
Allocated PE          0
PV UUID               IMkQCu-1Xxd-m9Xf-njRS-y9HC-c0wq-lQwN0M
```

> ✅ Now each PV shows:
> 
> - **VG Name = vg1** — Assigned to the new VG
> - **Allocatable = yes** — Ready to be used by Logical Volumes
> - **Free PE = 1279** — All 1279 Physical Extents are still free

---

## 📹 VIDEO 4 — Creating Logical Volume, Formatting & Mounting

---

### ✅ Step 9: Create a Logical Volume with `lvcreate`

**Command typed in the video:**

```bash
lvcreate -L 10G -n lv1 vg1
```

**What it does:**  
Creates a new Logical Volume named **`lv1`** of size **10 GiB** from the `vg1` Volume Group.

**Flags explained:**

|Flag|Meaning|
|---|---|
|`-L 10G`|Set the size of the LV to 10 GiB|
|`-n lv1`|Set the name of the LV to `lv1`|
|`vg1`|The Volume Group to allocate space from|

**📟 Exact output shown in video:**

```
  Logical volume "lv1" created.
```

> 💡 After this, the LV is accessible at the device path: `/dev/vg1/lv1` (also aliased as `/dev/mapper/vg1-lv1`)

---

### ✅ Step 10: Verify LV with `lvs`

**Command typed in the video:**

```bash
lvs
```

**What it does:**  
Displays a summary table of all Logical Volumes on the system.

**📟 Exact output shown in video:**

```
  LV   VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root rhel -wi-ao---- 50.00g
  swap rhel -wi-ao----  4.00g
  lv1  vg1  -wi-a-----  10.00g
```

> 📌 The new `lv1` appears in VG `vg1` with:
> 
> - **LSize = 10.00g** — 10 GiB allocated
> - **Attr = -wi-a-----** — Write/inactive/allocatable (not yet mounted/active with data)

---

### ✅ Step 11: Detailed LV Inspection with `lvdisplay`

**Command typed in the video:**

```bash
lvdisplay
```

**What it does:**  
Shows verbose details for all Logical Volumes. The output scrolls through `root`, `swap` (from the `rhel` VG), and then `lv1`.

**📟 Exact output for `lv1` (from `lvdisplay`) shown across frames:**

```
--- Logical volume ---
LV Path                /dev/vg1/lv1
LV Name                lv1
VG Name                vg1
LV UUID                wblHVp-md9t-mPZa-0Kz7-zWWZ-tmzN-5nMi5Q
LV Write Access        read/write
LV Creation host, time server1.iforward.in, 2026-04-02 08:23:08 +0530
LV Status              available
# open                 0
LV Size                10.00 GiB
Current LE             2560
Segments               3
Allocation             inherit
Read ahead sectors     auto
- currently set to     256
Block device           253:2
```

> 📌 Key fields:
> 
> - **LV Path = /dev/vg1/lv1** — Full device path to use for formatting/mounting
> - **LV Size = 10.00 GiB** — Confirmed size
> - **Segments = 3** — The LV spans 3 physical extents (across 3 PVs)
> - **LV Status = available** — Ready to be used
> - **Block device = 253:2** — The kernel device number

---

### ✅ Step 12: Verify Updated VG Status with `vgdisplay`

**Command typed in the video:**

```bash
vgdisplay
```

**📟 Exact output for `vg1` shown in video (after LV creation):**

```
--- Volume group ---
VG Name               vg1
...
VG Size               <14.99 GiB
PE Size               4.00 MiB
Total PE              3837
Alloc PE / Size       2560 / 10.00 GiB
Free  PE / Size       1277 / <4.99 GiB
VG UUID               0WY1o7-hNV0-uNJQ-j8ov-Lo8A-kDyj-dqHGRH
```

> 📌 Now notice:
> 
> - **Alloc PE / Size = 2560 / 10.00 GiB** — 2560 PEs used by `lv1`
> - **Free PE / Size = 1277 / <4.99 GiB** — ~5 GiB still free in the VG

---

### ⚠️ Step 13: Debug — Wrong `lvdisplay` arguments (Error Example)

**Commands typed in the video (demonstrating errors):**

```bash
lvdisplay lg1
lvdisplay lv1
```

**📟 Exact error output shown in video:**

```
  Volume group "lg1" not found
  Cannot process volume group lg1
  Volume group "lv1" not found
  Cannot process volume group lv1
```

> ❌ **Why this failed:**  
> `lvdisplay` expects a **full device path** or no argument at all — NOT just the LV name.
> 
> - `lvdisplay lg1` → wrong: `lg1` is not a VG or path
> - `lvdisplay lv1` → wrong: `lv1` alone is not a valid path

---

### ✅ Step 14: Correct `lvdisplay` with Full Path

**Correct command typed in the video:**

```bash
lvdisplay /dev/vg1/lv1
```

**📟 Exact output shown in video:**

```
--- Logical volume ---
LV Path                /dev/vg1/lv1
LV Name                lv1
VG Name                vg1
LV UUID                wblHVp-md9t-mPZa-0Kz7-zWWZ-tmzN-5nMi5Q
LV Write Access        read/write
LV Creation host, time server1.iforward.in, 2026-04-02 08:23:08 +0530
LV Status              available
# open                 0
LV Size                10.00 GiB
Current LE             2560
Segments               3
Allocation             inherit
Read ahead sectors     auto
- currently set to     256
Block device           253:2
```

> ✅ **Correct syntax:** Always use the **full path** `/dev/<VG_name>/<LV_name>` when passing an argument to `lvdisplay`.

---

### ✅ Step 15: Confirm LV with `lvs`

**Command typed in the video:**

```bash
lvs
```

**📟 Exact output shown in video:**

```
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root rhel -wi-ao---- 50.00g
  swap rhel -wi-ao----  4.00g
  lv1  vg1  -wi-a-----  10.00g
```

> ✅ Confirms `lv1` exists in `vg1` at 10.00g, ready for formatting.

---

### ✅ Step 16: Format the Logical Volume with `mkfs.ext4`

**Command typed in the video (first attempt):**

```bash
mkfs.ext4 /dev/vg1/lv1
```

**What it does:**  
Creates an **ext4 filesystem** on the Logical Volume `/dev/vg1/lv1`, making it ready to store files.

**📟 Exact output shown in video:**

```
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 2621440 4k blocks and 655360 inodes
Filesystem UUID: 6f3f0e8d-d9cb-4251-aeb7-48ef639eed88
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

> 📌 Key info:
> 
> - **Block size: 4k** — Standard for ext4
> - **655360 inodes** — Maximum number of files/directories
> - **Journal created** — ext4 journaling enabled for data integrity
> - **Filesystem UUID** — Unique identifier for this filesystem

---

### ✅ Step 17: Wipe Old Filesystem Signatures with `wipefs`

**Command typed in the video:**

```bash
wipefs -a /dev/vg1/lv1
```

**What it does:**  
Erases all existing filesystem signatures/superblocks from the device. This is done to ensure a completely clean state before re-formatting (avoids old metadata conflicts).

**📟 Exact output shown in video:**

```
/dev/vg1/lv1: 2 bytes were erased at offset 0x00000438 (ext4): 53 ef
```

> 📌 The `53 ef` at offset `0x438` is the **ext4 magic number** — `wipefs` found and erased the previous ext4 signature created in Step 16.  
> This is a deliberate clean-up step shown in the video to demonstrate how to wipe and redo a filesystem.

---

### ✅ Step 18: Re-format with `mkfs.ext4` (Clean Filesystem)

**Command typed in the video:**

```bash
mkfs.ext4 /dev/vg1/lv1
```

**📟 Exact output shown in video:**

```
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 2621440 4k blocks and 655360 inodes
Filesystem UUID: c4b53bdb-b930-4b6d-bd84-1187a9a86434
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

> 📌 Notice the **new UUID** (`c4b53bdb-...`) — different from Step 16, confirming a fresh format.

---

### ⚠️ Step 19: Mount the Logical Volume — Wrong FS Type Error

**Command typed in the video (wrong attempt):**

```bash
mount /dev/vg1/lv1  /xfs/
```

**📟 Exact error output shown in video:**

```
mount: /xfs: wrong fs type, bad option, bad superblock on /dev/mapper/vg1-lv1,
       missing codepage or helper program, or other error.
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
```

> ❌ **Why this failed:**
> 
> - The mount point `/xfs/` does **not exist** on the system
> - The filesystem was formatted as **ext4**, not XFS — the path `/xfs/` was a typo/wrong directory
> - The error also hints that `systemd` needs a `daemon-reload`

---

### ✅ Step 20: Mount the Logical Volume Correctly to `/mnt/`

**Command typed in the video (correct):**

```bash
mount /dev/vg1/lv1  /mnt/
```

**What it does:**  
Mounts the Logical Volume `lv1` to the `/mnt/` directory, making the 10 GiB ext4 filesystem accessible at `/mnt/`.

**📟 Output shown in video:**

```
mount: (hint) your fstab has been modified, but systemd still uses
       the old version; use 'systemctl daemon-reload' to reload.
```

> ⚠️ The mount **succeeds** but systemd shows a **hint** (not an error) that `/etc/fstab` was modified and the daemon needs to be reloaded.  
> This is a common informational message on systemd-based systems. The filesystem **IS** mounted.

---

### ✅ Step 21: Reload systemd with `systemctl daemon-reload`

**Command typed in the video:**

```bash
systemctl daemon-reload
```

**What it does:**  
Instructs systemd to re-read its configuration files, including `/etc/fstab`, clearing the warning shown in Step 20.

**📟 Output shown in video:**

```
[root@server1 admin]#
```

> ✅ No output = success. The daemon has reloaded cleanly.

---

## 🗺️ Complete LVM Flow Summary

```
📀 /dev/sda1 ──┐
📀 /dev/sdb1 ──┼──► pvcreate ──► Physical Volumes (PV) ──► vgcreate vg1 ──► Volume Group vg1 (~15 GiB)
📀 /dev/sdc1 ──┘                                                                       │
                                                                                        ▼
                                                                          lvcreate -L 10G -n lv1 vg1
                                                                                        │
                                                                                        ▼
                                                                              Logical Volume lv1 (10 GiB)
                                                                              at /dev/vg1/lv1
                                                                                        │
                                                                                        ▼
                                                                              mkfs.ext4 /dev/vg1/lv1
                                                                                        │
                                                                                        ▼
                                                                              mount /dev/vg1/lv1 /mnt/
                                                                                        │
                                                                                        ▼
                                                                              🗂️ /mnt/ ← 10 GiB usable!
```

---

## 📋 All Commands Quick Reference

|#|Command|Purpose|
|---|---|---|
|1|`pvcreate /dev/sda1 /dev/sdb1 /dev/sdc1`|Create Physical Volumes|
|2|`pvs`|Short summary of all PVs|
|3|`pvdisplay`|Detailed info on all PVs|
|4|`vgs`|Short summary of all VGs|
|5|`vgcreate vg1 /dev/sda1 /dev/sdb1 /dev/sdc1`|Create Volume Group `vg1`|
|6|`vgs`|Verify new VG|
|7|`vgdisplay`|Detailed info on all VGs|
|8|`pvdisplay`|Verify PVs now assigned to VG|
|9|`lvcreate -L 10G -n lv1 vg1`|Create 10 GiB Logical Volume `lv1`|
|10|`lvs`|Short summary of all LVs|
|11|`lvdisplay`|Detailed info on all LVs|
|12|`vgdisplay`|Check VG free space after LV creation|
|13|`lvdisplay /dev/vg1/lv1`|Detailed info on specific LV (correct syntax)|
|14|`mkfs.ext4 /dev/vg1/lv1`|Format LV with ext4 filesystem|
|15|`wipefs -a /dev/vg1/lv1`|Wipe old filesystem signatures|
|16|`mkfs.ext4 /dev/vg1/lv1`|Re-format LV with fresh ext4|
|17|`mount /dev/vg1/lv1 /mnt/`|Mount LV to `/mnt/`|
|18|`systemctl daemon-reload`|Reload systemd after fstab hint|

---

## ⚠️ Common Errors & Fixes

|❌ Error|🔍 Cause|✅ Fix|
|---|---|---|
|`Volume group "lg1" not found`|Typo — `lg1` instead of `vg1`|Use correct VG name: `vgdisplay /dev/vg1/lv1`|
|`Volume group "lv1" not found`|Passing LV name without full path to `lvdisplay`|Use full path: `lvdisplay /dev/vg1/lv1`|
|`mount: wrong fs type`|Mount point doesn't exist or wrong FS type specified|Ensure mount dir exists; use correct fs type (e.g., `/mnt/` not `/xfs/`)|
|`fstab modified, systemd hint`|systemd caches fstab and needs to re-read it|Run `systemctl daemon-reload`|
|PV shows `Allocatable: NO`|PV created but not yet added to a VG|Run `vgcreate` or `vgextend` to add PV to a VG|

---

## 💡 Key Concepts & Tips

### 🔑 Physical Extent (PE)

The smallest unit of storage in LVM. Default size is **4 MiB**. When you create a 10 GiB LV, LVM allocates 2560 PEs (10240 MiB ÷ 4 MiB = 2560).

### 🔑 Device Mapper Alias

After `lvcreate`, the LV is available at two equivalent paths:

```
/dev/vg1/lv1          ← Friendly symlink
/dev/mapper/vg1-lv1   ← Device mapper node
```

Both point to the same block device.

### 🔑 `vgs` vs `vgdisplay`

- `vgs` → Quick one-line-per-VG summary table (great for scripting)
- `vgdisplay` → Verbose multi-line details (great for debugging/learning)

Same pattern applies for `pvs`/`pvdisplay` and `lvs`/`lvdisplay`.

### 🔑 `wipefs` Before Re-formatting

Always run `wipefs -a <device>` before re-using a device that may have old filesystem metadata. This prevents `mkfs` from complaining about existing signatures.

### 🔑 Persistent Mounts

The `mount` command used here is **temporary** (lost after reboot). To make it **permanent**, add an entry to `/etc/fstab`:

```
/dev/vg1/lv1    /mnt    ext4    defaults    0 0
```

Then run `systemctl daemon-reload` to apply.

### 🔑 Extending a VG Later

```bash
# Add a new PV to an existing VG
pvcreate /dev/sdd1
vgextend vg1 /dev/sdd1
```

### 🔑 Extending an LV Later

```bash
# Extend lv1 by 5 GiB
lvextend -L +5G /dev/vg1/lv1
# Resize the filesystem to use the new space
resize2fs /dev/vg1/lv1
```

---

> 📝 **Document prepared from video recordings on RHEL 9.7 (VMware Workstation)**  
> 🗓️ **Recorded on:** Thu Apr 2, 2026  
> 🖥️ **System:** `root@server1:/home/admin`  
> ✍️ **Covers:** LVM PV creation → VG creation → LV creation → ext4 format → mount