### ✅ Step 1: Reduce lv2 Filesystem Size with `resize2fs`

> ⚠️ **CRITICAL WARNING:** Reducing an LVM Logical Volume is a **destructive, irreversible operation** if done incorrectly. You MUST shrink the **filesystem first**, then shrink the **LV**. Never the other way around.

**The correct LV reduction sequence (shown in video):**

1. `e2fsck -f <device>` — force filesystem check ✅ (done in Step 9)
2. `resize2fs <device> <new_size>` — shrink filesystem first ← **This step**
3. `lvreduce -L <new_size> <device>` — then shrink the LV

**Command typed in the video:**

```bash
resize2fs /dev/vg1/lv2 1G
```

---

**What it does:**  
Shrinks the **ext4 filesystem** inside `lv2` from ~7G down to **1G**. This must be done while the filesystem is **unmounted**. `resize2fs` moves all data blocks to fit within the new smaller boundary.

> 📌 This command being typed slowly, confirming the exact syntax: `resize2fs /dev/vg1/lv2 1G`

> ⚠️ The LV device itself is not shrunk by this command — only the filesystem metadata is updated. After this, you must also run `lvreduce` to match the LV size to the new filesystem size.

**📟 Expected output example:**

```
resize2fs 1.46.5 (30-Dec-2021)
Resizing the filesystem on /dev/vg1/lv2 to 262144 (4k) blocks.
The filesystem on /dev/vg1/lv2 is now 262144 (4k) blocks long.
```

> 💡 `262144 blocks × 4k = 1,073,741,824 bytes = 1 GiB`

**Complete LV Reduction Sequence (the full safe workflow):**

```bash
# Step A — Always unmount first if mounted
umount /mount/point

# Step B — Force filesystem check (mandatory)
e2fsck -f /dev/vg1/lv2

# Step C — Shrink the filesystem to target size
resize2fs /dev/vg1/lv2 1G

# Step D — Shrink the LV to match (never smaller than the filesystem!)
lvreduce -L +1G /dev/vg1/lv2

# Step E — Re-run filesystem check to confirm integrity
e2fsck -f /dev/vg1/lv2
```

---

## 📹  Extend VG, Migrate LV & Reduce VG

---

### ✅ Step 2: Check Current State — `df -h` and `lsblk`

**Commands typed in video:**

```bash
df -h
lsblk
```

**📟 Exact `df -h` output shown:**

```
Filesystem                  Size  Used Avail Use% Mounted on
devtmpfs                    4.0M     0  4.0M   0% /dev
tmpfs                       1.8G     0  1.8G   0% /dev/shm
tmpfs                       725M  9.8M  715M   2% /run
efivarfs                    256K   76K  176K  31% /sys/firmware/efi/efivars
/dev/mapper/rhel-root        49G   32G   15G  69% /
/dev/nvme0n1p2              974M  327M  580M  37% /boot
/dev/nvme0n1p1             1022M  7.4M 1015M   1% /boot/efi
tmpfs                       363M  112K  363M   1% /run/user/1001
/dev/mapper/vg1-lv1          14G   40K   13G   1% /xfs
tmpfs                       363M   36K  363M   1% /run/user/1002
```

**📟 Exact `lsblk` output shown:**

```
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda               8:0    0   10G  0 disk
├─sda1            8:1    0    5G  0 part
│ └─vg1-lv1     253:2    0   14G  0 lvm  /xfs
└─sda2            8:2    0    5G  0 part
  └─vg1-lv2     253:3    0    6G  0 lvm
sdb               8:16   0   10G  0 disk
├─sdb1            8:17   0    5G  0 part
│ └─vg1-lv1     253:2    0   14G  0 lvm  /xfs
└─sdb2            8:18   0    5G  0 part
sdc               8:32   0   10G  0 disk
├─sdc1            8:33   0    5G  0 part
│ └─vg1-lv1     253:2    0   14G  0 lvm  /xfs
│ └─vg1-lv2     253:3    0    6G  0 lvm
└─sdc2            8:34   0    5G  0 part
sdd               8:48   0   10G  0 disk
sr0              11:0    1 1024M  0 rom
...
```

> 📌 Goal of this video: **migrate all LV data off `sdc1`** so it can be safely removed from `vg1` — using `pvmove`. This is a live, online data migration technique (even while LV is mounted, though here it is unmounted first).

---

### ✅ Step 3: Try to Unmount `/xfs/` — Target Busy Error

**Command typed in the video:**

```bash
umount /xfs
```

**📟 Exact error output:**

```
umount: /xfs: target is busy.
```

> ❌ **Why this failed:** A process (the current shell session) has its working directory **inside** `/xfs/`. The kernel prevents unmounting a filesystem that is actively in use.

---

### ✅ Step 4: Find Processes Using `/xfs/` with `fuser -cu`

**Command typed in the video:**

```bash
fuser -cu /xfs/
```

**What it does:**  
Lists all processes currently using the mount point. `-c` shows only processes using the filesystem, `-u` shows the **username** of each process owner.

**📟 Exact output shown:**

```
/xfs/:               8185c(user1)
```

> 📌 Process `8185` owned by `user1` is using `/xfs/`. The `c` suffix means the process has `/xfs/` as its **current working directory**.

---

### ✅ Step 5: Kill All Processes Using `/xfs/` with `fuser -ck`

**Command typed in the video:**

```bash
fuser -ck /xfs/
```

**What it does:**  
Sends `SIGKILL` to all processes using `/xfs/`. `-c` targets only filesystem users, `-k` kills them. This forcibly terminates the process blocking the unmount.

**📟 Exact output shown:**

```
/xfs/:               8185c
```

> ⚠️ Use this with care in production — it forcibly kills processes without warning. Always check what processes are running before killing.

Then `fuser -cu /xfs/` is run again to confirm no more processes:

```bash
fuser -cu /xfs/
```

Returns nothing — all processes cleared.

---

### ✅ Step 6: Unmount `/xfs/` Successfully with `umount`

**Command typed in the video:**

```bash
umount /xfs
```
---

### ✅ Step 7: Create a New Physical Volume on sdb2 with `pvcreate`

**Command typed in the video:**

```bash
pvcreate /dev/sdb2
```

**What it does:**  
Initializes `/dev/sdb2` (a previously unused 5G partition on `sdb`) as a new LVM Physical Volume. This adds fresh storage capacity that will be used to extend `vg1`, giving room to receive the migrated data from `sdc1`.

**📟 Exact output shown:**

```
  Physical volume "/dev/sdb2" successfully created.
```

---

### ✅ Step 8: Extend vg1 with sdb2 using `vgextend`

**Command typed in the video:**

```bash
vgextend vg1 /dev/sdb2
```

**What it does:**  
Adds the newly created PV `/dev/sdb2` into the existing Volume Group `vg1`. This gives `vg1` an extra ~5 GiB of free space — enough to receive the data being migrated off `sdc1`.

**📟 Exact output shown:**

```
  Volume group "vg1" successfully extended
```

---

### ✅ Step 9: Verify VG and PV State with `vgdisplay` and `pvs`

**Commands typed in the video:**

```bash
vgdisplay
pvs
```

**📟 Exact `vgdisplay` output for `vg1`:**

```
--- Volume group ---
VG Name               vg1
System ID
Format                lvm2
Metadata Areas        4
Metadata Sequence No  7
VG Access             read/write
VG Status             resizable
MAX LV                0
Cur LV                2
Open LV               0
Max PV                0
Cur PV                4
Act PV                4
VG Size               19.98 GiB
PE Size               4.00 MiB
Total PE              5116
Alloc PE / Size       5115 / 19.98 GiB
Free  PE / Size          1 / 4.00 MiB
VG UUID               0WY1o7-hNV0-uNJQ-j8ov-Lo8A-kDyj-dqHGRH
```

**📟 Exact `pvs` output:**

```
  PV             VG   Fmt  Attr PSize   PFree
  /dev/nvme0n1p3 rhel lvm2 a--  54.00g     0
  /dev/sda1      vg1  lvm2 a-- <5.00g     0
  /dev/sda2      vg1  lvm2 a-- <5.00g     0
  /dev/sdb1      vg1  lvm2 a-- <5.00g     0
  /dev/sdb2      vg1  lvm2 --- <5.00g <5.00g
  /dev/sdc1      vg1  lvm2 a-- <5.00g  4.00m
```

> 📌 Key observations:
> 
> - `/dev/sdb2` is now in `vg1` with `<5.00g` **fully free** (`PFree = <5.00g`) — ready to receive migrated data
> - `/dev/sdc1` has only `4.00m` free — almost all its PEs are used by LV data
> - `vg1` now has 4 PVs: `sda1`, `sda2`, `sdb1`, `sdb2` + old `sdc1`

---

### ✅ Step 10: Migrate LV Data Off sdc1 with `pvmove`

> 🔑 **This is the core operation of this video.** `pvmove` relocates all Physical Extents (data blocks) from one PV to other PVs in the same VG — **without losing data**.

**Command typed in the video:**

```bash
pvmove /dev/sdc1 /dev/sdb2
```

**What it does:**  
Moves all data currently stored on `/dev/sdc1` to `/dev/sdb2`. LVM does this by copying each Physical Extent one at a time. The `-v` flag (verbose) is implicitly shown via the progress output.

**📟 Exact progress output shown in video:**

```
  /dev/sdc1: Moved: 2.74%
  /dev/sdc1: Moved: 60.25%
  /dev/sdc1: Moved: 80.28%
  /dev/sdc1: Moved: 100.00%
```

> ✅ Migration completed at 100%! All data from `sdc1` has been safely moved to `sdb2`.

---

### ✅ Step 11: Remove sdc1 from vg1 with `vgreduce`

**First attempt shown in video (error):**

```bash
vgreduce vg1 /dev/sda2
```

**📟 Exact output shown:**

```
  Removed "/dev/sdc1" from volume group "vg1"
```

> ✅ `sdc1` is no longer part of `vg1`.

---

### ✅ Step 12: Verify PVs After vgreduce with `pvs`

**Command typed in the video:**

```bash
pvs
```

**📟 Exact output shown:**

```
  PV             VG   Fmt  Attr PSize   PFree
  /dev/nvme0n1p3 rhel lvm2 a--  54.00g     0
  /dev/sda1      vg1  lvm2 a-- <5.00g     0
  /dev/sda2      vg1  lvm2 a-- <5.00g     0
  /dev/sdb1      vg1  lvm2 a-- <5.00g     0
  /dev/sdb2      vg1  lvm2 a-- <5.00g  4.00m
  /dev/sdc1           lvm2 --- 5.00g   5.00g
```

> 📌 `/dev/sdc1` now shows:
> 
> - **VG column = empty** — no longer assigned to any VG
> - **PFree = 5.00g** — all space is free again
> - Still has LVM metadata (`lvm2` Fmt) — it needs `pvremove` to fully clean it

---

### ✅ Step 13: Wipe sdc1 LVM Metadata with `pvremove`

**Command typed in the video:**

```bash
pvremove /dev/sdc1
```

**📟 Expected output:**

```
  Labels on physical volume "/dev/sdc1" successfully wiped.
```

> 🔑 **The full safe PV removal workflow is:**
> 
> ```
> pvmove /dev/sdc1       ← move all data off
> vgreduce vg1 /dev/sdc1 ← detach from VG
> pvremove /dev/sdc1     ← wipe LVM label
> ```

---

### ✅ Step 14: Re-mount lv1 Back to `/xfs/`

**Commands shown in video (first attempt fails):**

```bash
mount /dev/vg1/lv1
```

**📟 Error output:**

```
mount: /dev/vg1/lv1: can't find in /etc/fstab.
```

> ❌ `mount` without a mountpoint looks in `/etc/fstab`. Since `lv1` has no fstab entry, it fails.

**Correct command:**

```bash
mount /dev/vg1/lv1 /xfs/
```

**📟 Output:**

```
[root@server1 /]#
```

> ✅ No output = successfully mounted. `lv1` is back online at `/xfs/`.

---

### ✅ Step 15: Verify Final State — `ll /xfs/` and `lsblk`

**Commands typed in the video:**

```bash
ll /xfs/
lsblk
```

**📟 Exact `ll /xfs/` output:**

```
total 32
drwxr-xr-x. 2 root root 4096 Apr  3 08:10 f1
drwxr-xr-x. 2 root root 4096 Apr  3 08:10 f2
drwxr-xr-x. 2 root root 4096 Apr  3 08:10 f3
drwxr-xr-x. 2 root root 4096 Apr  3 08:10 f4
drwx------. 2 root root 16384 Apr  2 08:32 lost+found
```

> ✅ All original directories (f1, f2, f3, f4) and `lost+found` are intact after migration — **no data was lost**.

**📟 Exact `lsblk` output shown:**

```
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda               8:0    0   10G  0 disk
├─sda1            8:1    0    5G  0 part
│ └─vg1-lv1     253:2    0   14G  0 lvm  /xfs
└─sda2            8:2    0    5G  0 part
  └─vg1-lv2     253:3    0    6G  0 lvm
sdb               8:16   0   10G  0 disk
├─sdb1            8:17   0    5G  0 part
│ └─vg1-lv1     253:2    0   14G  0 lvm  /xfs
└─sdb2            8:18   0    5G  0 part
  └─vg1-lv1     253:2    0   14G  0 lvm  /xfs
  └─vg1-lv2     253:3    0    6G  0 lvm
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

> 📌 Final state confirmed:
> 
> - **`sdc1`** is now completely bare — no LVM labels, no LV data
> - **`vg1-lv1`** (14G) now spans `sda1`, `sdb1`, and `sdb2` — migrated successfully
> - **`vg1-lv2`** spans `sda2` and `sdb2`
> - **`sdd`** remains unused

---
