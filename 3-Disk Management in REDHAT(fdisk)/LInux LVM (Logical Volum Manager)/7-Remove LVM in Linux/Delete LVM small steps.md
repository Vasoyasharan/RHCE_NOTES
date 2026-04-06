

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

## 📌 Quick Cheat Sheet

```bash
# ─────────────────────────────────────────────────────────
# STEP 1: Unmount filesystems
# ─────────────────────────────────────────────────────────
umount /ext4
umount /xfs

# ─────────────────────────────────────────────────────────
# STEP 2: Wipe filesystem signatures from LVs
# ─────────────────────────────────────────────────────────
wipefs -a /dev/vg1/lv1
wipefs -a /dev/vg1/lv2

# ─────────────────────────────────────────────────────────
# STEP 3: Deactivate Logical Volumes
# ─────────────────────────────────────────────────────────
lvchange -an /dev/vg1/lv2
lvchange -an /dev/vg1/lv1

# ─────────────────────────────────────────────────────────
# STEP 4: Verify deactivation (look for missing 'a' in Attr)
# ─────────────────────────────────────────────────────────
lvs

# ─────────────────────────────────────────────────────────
# STEP 5: Remove Logical Volumes
# ─────────────────────────────────────────────────────────
lvremove /dev/vg1/lv1
lvremove /dev/vg1/lv2
# OR all at once: lvremove -f /dev/vg1

# ─────────────────────────────────────────────────────────
# STEP 6: Remove the Volume Group
# ─────────────────────────────────────────────────────────
vgremove vg1

# ─────────────────────────────────────────────────────────
# STEP 7: Verify VG is gone
# ─────────────────────────────────────────────────────────
vgs

# ─────────────────────────────────────────────────────────
# STEP 8: Remove Physical Volume labels
# ─────────────────────────────────────────────────────────
pvremove /dev/sda1
pvremove /dev/sda2
pvremove /dev/sdb1
pvremove /dev/sdb2

# ─────────────────────────────────────────────────────────
# STEP 9: Inspect remaining partitions
# ─────────────────────────────────────────────────────────
lsblk

# ─────────────────────────────────────────────────────────
# STEP 10: Delete disk partitions with fdisk (per disk)
# ─────────────────────────────────────────────────────────
fdisk /dev/sda   # → d, d, w
fdisk /dev/sdb   # → d, d, w
fdisk /dev/sdc   # → d, d, w

# ─────────────────────────────────────────────────────────
# FINAL: Verify everything is clean
# ─────────────────────────────────────────────────────────
lsblk
lvs
vgs
pvs
```

---

## 🔁 Complete Removal Flow Diagram

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                     BEFORE: LVM Active                          │
  │  /ext4 → lv1 → vg1 → sda1, sdb1                                │
  │  /xfs  → lv2 → vg1 → sda2, sdb2                                │
  └─────────────────────────────────────────────────────────────────┘
                              │
                    ① umount /ext4 /xfs
                              │
                    ② wipefs -a /dev/vg1/lv{1,2}
                              │
                    ③ lvchange -an /dev/vg1/lv{1,2}
                              │
                    ④ lvs  (confirm inactive)
                              │
                    ⑤ lvremove /dev/vg1/lv{1,2}
                              │
                    ⑥ vgremove vg1
                              │
                    ⑦ vgs  (confirm vg1 gone)
                              │
                    ⑧ pvremove /dev/sda{1,2} /dev/sdb{1,2}
                              │
                    ⑨ lsblk  (identify remaining partitions)
                              │
                    ⑩ fdisk /dev/sda → d → d → w
                       fdisk /dev/sdb → d → d → w
                       fdisk /dev/sdc → d → d → w
                              │
  ┌─────────────────────────────────────────────────────────────────┐
  │                     AFTER: Disks Clean 🎉                       │
  │  sda, sdb, sdc → empty raw disks (no partitions, no LVM)        │
  └─────────────────────────────────────────────────────────────────┘
```

---

