# 🖥️ How to Remove Disk Partitions (`/dev/sda`, `sdb`, `sdc`, `sdd`) on RHEL 9.7
---
## 🧰 Prerequisites & Environment

| Item               | Detail                                         |
| ------------------ | ---------------------------------------------- |
| **OS**             | RHEL 9.7 (Red Hat Enterprise Linux)            |
| **Platform**       | VMware Workstation                             |
| **User**           | `root` (must be root to modify partitions)     |
| **Disks targeted** | `/dev/sda`, `/dev/sdb`, `/dev/sdc`, `/dev/sdd` |
| **Tools used**     | `lsblk`, `umount`, `mount`, `wipefs`, `sfdisk` |

> ⚠️ **WARNING:** All steps below **permanently destroy** partition data. Only do this on disks you are sure you want to wipe completely.

---

## 🔍 Step 1 — Check Current Disk Layout with `lsblk`

The instructor first tries `lsbl` (typo), which fails, then correctly runs `lsblk`:

```bash
[root@server1 admin]# lsblk
```

### 📄 Example Output:

```
NAME        MAJ:MIN RM    SIZE RO TYPE MOUNTPOINTS
sda           8:0    0     10G  0 disk
├─sda1        8:1    0      2G  0 part /xfs
├─sda2        8:2    0      2G  0 part
├─sda3        8:3    0      2G  0 part
├─sda4        8:4    0      1K  0 part
├─sda5        8:5    0      1G  0 part
├─sda6        8:6    0      1G  0 part
├─sda7        8:7    0      1G  0 part
└─sda8        8:8    0   1019M  0 part
sdb           8:16   0     10G  0 disk
├─sdb1        8:17   0      2G  0 part
├─sdb2        8:18   0      2G  0 part
├─sdb3        8:19   0      2G  0 part
├─sdb4        8:20   0      1K  0 part
├─sdb5        8:21   0      1G  0 part
├─sdb6        8:22   0      1G  0 part
├─sdb7        8:23   0      1G  0 part
└─sdb8        8:24   0   1019M  0 part
sdc           8:32   0     10G  0 disk
├─sdc1        8:33   0      2G  0 part
├─sdc2        8:34   0      2G  0 part
├─sdc3        8:35   0      2G  0 part
├─sdc4        8:36   0      1K  0 part
├─sdc5        8:37   0      1G  0 part
├─sdc6        8:38   0      1G  0 part
├─sdc7        8:39   0      1G  0 part
└─sdc8        8:40   0   1019M  0 part
sdd           8:48   0     10G  0 disk
sr0          11:0    1   1024M  0 rom
nvme0n1     259:0    0     70G  0 disk
├─nvme0n1p1 259:1    0      1G  0 part /boot/efi
├─nvme0n1p2 259:2    0      1G  0 part /boot
└─nvme0n1p3 259:3    0     54G  0 part
  ├─rhel-root 253:0  0     50G  0 lvm  /
  └─rhel-swap 253:1  0      4G  0 lvm  [SWAP]
```

---

## 🔓 Step 2 — Unmount Any Mounted Partition

The instructor sees that `/dev/sda1` is mounted at `/xfs`. Before wiping, it must be unmounted:

```bash
[root@server1 admin]# umount /xfs
```

> ✅ No output = success. The `/xfs` mount point is now released.

---

## ✅ Step 3 — Verify All Mounts Are Released

Run `mount -a` to re-read `/etc/fstab` and check nothing errors out:

```bash
[root@server1 admin]# mount -a
[root@server1 admin]#
```

> 💡 A clean prompt (no errors) means all mounts are fine.

---

## 🧹 Step 4 — Wipe the Disk Signature on `/dev/sda`

Use `wipefs -a` to wipe the filesystem/partition signatures from the **whole disk** device:

```bash
[root@server1 admin]# wipefs -a /dev/sda
```

### 📄 Example Output:

```
/dev/sda: 2 bytes were erased at offset 0x000001fe (dos): 55 aa
/dev/sda: calling ioctl to re-read partition table: Success
```

> 💡 **Explanation:**
> 
> - `55 aa` is the **DOS MBR signature** (the "magic bytes" at the end of the Master Boot Record)
> - `wipefs` zeroed those 2 bytes, making the disk appear as having no partition table
> - The kernel is told to re-read the partition table via `ioctl` — this succeeds immediately!

---

## 🔍 Step 6 — Verify sda Partition Is Now Gone with `lsblk`

```bash
[root@server1 admin]# lsblk
```

### 📄 Example Output (sda is now clean!):

```
NAME        MAJ:MIN RM    SIZE RO TYPE MOUNTPOINTS
sda           8:0    0     10G  0 disk           ← ✅ No more sda1–sda8!
sdb           8:16   0     10G  0 disk
├─sdb1        8:17   0      2G  0 part
...
sdc           8:32   0     10G  0 disk
├─sdc1        8:33   0      2G  0 part
...
sdd           8:48   0     10G  0 disk
```

> 🎉 `sda` is now a clean, empty disk with no partitions!

---
## 🔧 Step 7 — Use `sfdisk` to Wipe Partition Table on `/dev/sda`

Even after `wipefs`, the instructor uses `sfdisk` with the pipe trick to confirm/enforce the wipe. The command reads the (now-empty) partition layout from `sdd` (which is already empty) and writes it to `sda`:

```bash
[root@server1 admin]# sfdisk -d /dev/sdd | sfdisk /dev/sda
```

### 📄 Example Output:

```
sfdisk: /dev/sdd: does not contain a recognized partition table
Checking that no-one is using this disk right now ... OK

Disk /dev/sda: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

>>> Done.

New situation:
[root@server1 admin]# lsblk
```

> 💡 **How this works:**
> 
> - `sfdisk -d /dev/sdd` **dumps** the partition table of `sdd` (which is empty — no recognized table)
> - `|` (pipe) sends that empty output to `sfdisk /dev/sda`
> - `sfdisk /dev/sda` **writes** that empty table to `sda`
> - Result: `sda` now has an empty (or no) partition table — fully clean!

---

## 🔧 Step 8 — Verify sda Is Clean, Then Wipe `/dev/sdb`

After verifying `sda` is clean with `lsblk`, the instructor moves to `sdb`. First wipe its signature:

```bash
[root@server1 admin]# wipefs -a /dev/sdb
```

### 📄 Example Output (from frame showing sdb's existing partitions via sfdisk):

```
Old situation:

Device     Boot    Start      End  Sectors  Size Id Type
/dev/sdb1           2048  4196351  4194304    2G 83 Linux
/dev/sdb2        4196352  8390655  4194304    2G 82 Linux swap / Solaris
/dev/sdb3        8390656 12584959  4194304    2G 83 Linux
/dev/sdb4       12584960 20971519  8386560    4G  5 Extended
/dev/sdb5       12587008 14684159  2097152    1G 83 Linux
/dev/sdb6       14686208 16783359  2097152    1G 83 Linux
/dev/sdb7       16785408 18882559  2097152    1G 83 Linux
/dev/sdb8       18884608 20971519  2086912 1019M 83 Linux

>>> Done.

New situation:
Disklabel type: dos
Disk identifier: 0x49383b8a

Device     Boot    Start      End  Sectors  Size Id Type
/dev/sdb1           2048  4196351  4194304    2G 83 Linux
/dev/sdb2        4196352  8390655  4194304    2G 82 Linux swap / Solaris
/dev/sdb3        8390656 12584959  4194304    2G 83 Linux
/dev/sdb4       12584960 20971519  8386560    4G  5 Extended
/dev/sdb5       12587008 14684159  2097152    1G 83 Linux
/dev/sdb6       14686208 16783359  2097152    1G 83 Linux
/dev/sdb7       16785408 18882559  2097152    1G 83 Linux
/dev/sdb8       18884608 20971519  2086912 1019M 83 Linux

The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

---

## 🔧 Step 9 — Pipe sfdisk Output: Remove Partitions from `/dev/sdb` and Clone Empty Table to `/dev/sdb`

After `wipefs` on `sdb`, run `lsblk` to confirm sdb is clean, then apply the `sfdisk` pipe trick for `sdb`:

```bash
[root@server1 admin]# lsblk
```

Result shows `sdb` now has no partitions. Then:

```bash
[root@server1 admin]# wipefs -a /dev/sdc
```

### 📄 Example Output:

```
/dev/sdc: 2 bytes were erased at offset 0x000001fe (dos): 55 aa
/dev/sdc: calling ioctl to re-read partition table: Success
```

---

## 🔧 Step 10 — Wipe `/dev/sdc` Using the Same Pipe Method

```bash
[root@server1 admin]# sfdisk -d /dev/sdd | sfdisk /dev/sdb
```

### 📄 Example Output:

```
sfdisk: /dev/sdd: does not contain a recognized partition table
Checking that no-one is using this disk right now ... OK

Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

>>> Done.

New situation:
```

Then:

```bash
[root@server1 admin]# sfdisk -d /dev/sdd | sfdisk /dev/sdc
```

### 📄 Example Output:

```
sfdisk: /dev/sdd: does not contain a recognized partition table
Checking that no-one is using this disk right now ... OK

Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

>>> Done.

New situation:
```

---

## ✅ Step 11 — Final `lsblk` Verification — All Disks Are Clean

```bash
[root@server1 admin]# lsblk
```

### 📄 Final Output — All partitions removed! 🎉

```
NAME        MAJ:MIN RM    SIZE RO TYPE MOUNTPOINTS
sda           8:0    0     10G  0 disk    ← ✅ Clean!
sdb           8:16   0     10G  0 disk    ← ✅ Clean!
sdc           8:32   0     10G  0 disk    ← ✅ Clean!
sdd           8:48   0     10G  0 disk    ← ✅ Already was clean
sr0          11:0    1   1024M  0 rom
nvme0n1     259:0    0     70G  0 disk
├─nvme0n1p1 259:1    0      1G  0 part /boot/efi
├─nvme0n1p2 259:2    0      1G  0 part /boot
└─nvme0n1p3 259:3    0     54G  0 part
  ├─rhel-root 253:0  0     50G  0 lvm  /
  └─rhel-swap 253:1  0      4G  0 lvm  [SWAP]
```

> 🎉 **All four disks (`sda`, `sdb`, `sdc`, `sdd`) now show as clean disks with zero partitions!**  
> The OS disk `nvme0n1` is untouched and still running normally.

---

## 📝 Summary of All Commands Used

Here is the **exact sequence** from the video, in order:

```bash
# 1. Check disk layout
lsblk

# 2. Unmount the mounted sda1 partition
umount /xfs

# 3. Re-read fstab to verify clean state
mount -a

# 4. Wipe filesystem signature from sda (whole disk)
wipefs -a /dev/sda

# 5. Try individual partition wipe (will error — already gone)
wipefs -a /dev/sda1    # Expected: error, no such file
wipefs -a /dev/sda2    # Expected: error, no such file

# 6. Verify sda is clean
lsblk

# 7. Use sfdisk pipe to force empty partition table on sda
sfdisk -d /dev/sdd | sfdisk /dev/sda

# 8. Wipe sdb signature
wipefs -a /dev/sdb

# 9. Verify sdb via lsblk and apply sfdisk pipe
lsblk
sfdisk -d /dev/sdd | sfdisk /dev/sdb

# 10. Wipe sdc signature
wipefs -a /dev/sdc

# 11. Apply sfdisk pipe to sdc
sfdisk -d /dev/sdd | sfdisk /dev/sdc

# 12. Final verification
lsblk
```

---

## ❗ Common Errors & What They Mean

|Error Message|Meaning|Action|
|---|---|---|
|`bash: lsbl: command not found`|Typo — missing `k`|Type `lsblk`|
|`wipefs: error: /dev/sda1: probing initialization failed: No such file or directory`|✅ Partition already gone (wipefs on the parent disk already removed it)|No action needed — this is success!|
|`sfdisk: /dev/sdd: does not contain a recognized partition table`|✅ Source disk (`sdd`) is already empty, which is what we want|This is expected and correct|
|`umount: /xfs: target is busy`|Something is still using the mount|Run `fuser -km /xfs` then retry umount|

---

## 🧠 Key Concepts Explained

### What is `lsblk`?

Lists all **block devices** (disks and partitions) in a tree format. Shows name, size, type (`disk` or `part`), and mount points.

### What is `wipefs -a`?

Wipes the **magic bytes** (filesystem or partition table signatures) from a device. The `-a` flag removes **all** signatures found. After this, the disk looks "empty" to the OS and partition tools.

### What is `sfdisk -d /dev/X | sfdisk /dev/Y`?

- `sfdisk -d /dev/X` — **dumps** the partition table of disk X as text
- `|` — pipes that text as input to the next command
- `sfdisk /dev/Y` — **writes** that partition table to disk Y
- When X (`sdd`) has no partition table, writing its "empty" table to Y (`sda`, `sdb`, `sdc`) effectively clears Y's partition table too

### What is `umount`?

**Unmounts** a filesystem, detaching it from the directory tree. You **must** unmount before wiping a partition that is currently in use.

### What is `mount -a`?

Mounts all filesystems listed in `/etc/fstab` (that are not already mounted). Used here to verify no errors after unmounting `/xfs`.

### DOS MBR Signature (`55 aa`)

The bytes at offset `0x1FE` in a disk's MBR (Master Boot Record). If these 2 bytes are `55 AA`, the disk is recognized as having a DOS partition table. `wipefs` zeroes them to erase that recognition.

---
