# 📋 LVM Operations — Step-by-Step Cheatsheet

> **Quick reference for Extend, Reduce & Migrate operations on RHEL 9.7**

---
## 🔼 Extend the LV

```
1️⃣  Check VG free space
      vgs

2️⃣  Extend the VG (only if VFree is not enough)
      pvcreate /dev/sdX1
      vgextend vg1 /dev/sdX1

3️⃣  Extend the LV by +3G
      lvextend -L +3G /dev/vg1/lv1

4️⃣  Resize the filesystem to use new space
      → For ext4:
          resize2fs /dev/vg1/lv1
      → For XFS:
          xfs_growfs /xfs/

5️⃣  Verify the new size
      df -h
```

---

## 🔽 Reduce the LV

> ⚠️ **ext4 ONLY** — XFS cannot be reduced. Device must be **unmounted** first.

```
1️⃣  Unmount the filesystem
      umount /xfs/

2️⃣  Force filesystem check (MANDATORY before resize)
      e2fsck -f /dev/vg1/lv1

3️⃣  Shrink the FILESYSTEM first (e.g. down to 5G)
      resize2fs /dev/vg1/lv1 5G

4️⃣  Shrink the LV to match
      lvreduce -L 5G /dev/vg1/lv1

5️⃣  Run filesystem check again to confirm
      e2fsck -f /dev/vg1/lv1

6️⃣  Re-mount the filesystem
      mount /dev/vg1/lv1 /xfs/

7️⃣  Verify the new size
      df -h
```

---

## 🔀 Migrate the LV (pvmove)

> Move all LV data from one PV to another — safely, without data loss.

```
1️⃣  Check which PVs hold the LV data
      pvs
      lsblk

2️⃣  Unmount the filesystem
      umount /xfs/

      → If "target is busy" error:
          fuser -cu /xfs/         ← find blocking process
          fuser -ck /xfs/         ← kill blocking process
          umount /xfs/            ← retry unmount

3️⃣  Add a new PV to receive the migrated data
      pvcreate /dev/sdb2
      vgextend vg1 /dev/sdb2

4️⃣  Move all data OFF the old PV → to new PV
      pvmove /dev/sdc1 /dev/sdb2

5️⃣  Verify data was moved (old PV should show PFree = full)
      pvs

6️⃣  Remove old PV from the VG
      vgreduce vg1 /dev/sdc1

7️⃣  Wipe LVM label from old PV (makes it a blank disk)
      pvremove /dev/sdc1

8️⃣  Re-mount the filesystem
      mount /dev/vg1/lv1 /xfs/

9️⃣  Verify data is intact and layout is correct
      ll /xfs/
      lsblk
```

---

## ➕ Extend the VG (Add new PV)

```
1️⃣  Initialize the new disk/partition as a PV
      pvcreate /dev/sdX1

2️⃣  Add the PV into the Volume Group
      vgextend vg1 /dev/sdX1

3️⃣  Verify VG now has more free space
      vgs
      pvs
```

---

## ➖ Reduce the VG (Remove a PV)

> ⚠️ The PV must be **empty** (no LV data) before removal.

```
1️⃣  Check which PVs have data
      pvs

2️⃣  Move all data OFF the PV you want to remove
      pvmove /dev/sdX1

3️⃣  Remove the empty PV from the VG
      vgreduce vg1 /dev/sdX1

4️⃣  Wipe the LVM label from the disk
      pvremove /dev/sdX1

5️⃣  Verify the VG no longer includes that PV
      pvs
      vgs
```

---

## 🧠 Golden Rules

|Operation|Rule|
|---|---|
|🔼 Extend LV|Extend LV first → then resize filesystem|
|🔽 Reduce LV|Resize filesystem first → then reduce LV|
|🔀 Migrate|`pvmove` data → `vgreduce` → `pvremove`|
|➕ Extend VG|`pvcreate` → `vgextend`|
|➖ Reduce VG|`pvmove` → `vgreduce` → `pvremove`|

---

