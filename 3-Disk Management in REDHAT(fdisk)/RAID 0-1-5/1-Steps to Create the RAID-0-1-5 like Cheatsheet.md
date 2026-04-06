

---

# 💀 RAID 0 — Steps (Striping)

```bash
# 1. Create RAID 0
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sdb1 /dev/sdc1

# 2. Create filesystem
mkfs.xfs /dev/md0

# 3. Create mount point
mkdir /raid0

# 4. Mount
mount /dev/md0 /raid0

# 5. Add test data
echo "TEST" > /raid0/file.txt

# 6. (Optional) Fail disk
mdadm /dev/md0 --fail /dev/sdb1

# 7. Cleanup
umount /raid0
wipefs -a /dev/md0
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sdb1 /dev/sdc1
```

---

# 🛡️ RAID 1 — Steps (Mirror)

```bash
# 1. Create RAID 1
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1

# 2. Create filesystem
mkfs.xfs /dev/md1

# 3. Create mount point
mkdir /raid1

# 4. Mount
mount /dev/md1 /raid1

# 5. Add test data
echo "TEST" > /raid1/file.txt

# 6. Fail one disk
mdadm /dev/md1 --fail /dev/sdb1
mdadm /dev/md1 --remove /dev/sdb1

# 7. Add disk back (rebuild)
mdadm /dev/md1 --add /dev/sdb1

# 8. Cleanup
umount /raid1
wipefs -a /dev/md1
mdadm --stop /dev/md1
mdadm --zero-superblock /dev/sdb1 /dev/sdc1
```

---

# ⚙️ RAID 5 — Steps (Parity)

```bash
# 1. Create RAID 5
mdadm --create /dev/md2 --level=5 --raid-devices=3 /dev/sdb1 /dev/sdc1 /dev/sdd1

# 2. Create filesystem
mkfs.xfs /dev/md2

# 3. Create mount point
mkdir /raid5

# 4. Mount
mount /dev/md2 /raid5

# 5. Add test data
echo "TEST" > /raid5/file.txt

# 6. Fail one disk
mdadm /dev/md2 --fail /dev/sdc1
mdadm /dev/md2 --remove /dev/sdc1

# 7. Add disk back (rebuild)
mdadm /dev/md2 --add /dev/sdc1

# 8. Cleanup
umount /raid5
wipefs -a /dev/md2
mdadm --stop /dev/md2
mdadm --zero-superblock /dev/sdb1 /dev/sdc1 /dev/sdd1
```

---
# Mdadm Verification Commands

## Check RAID Status

```
cat /proc/mdstat
```

---

## Detailed RAID Info

```
mdadm --detail /dev/md0
mdadm --detail /dev/md1
mdadm --detail /dev/md2
```

---

## Scan All RAID Devices

```
mdadm --detail --scan
```

---

## Examine Disk Metadata

```
mdadm --examine /dev/sdb1
mdadm --examine /dev/sdc1
```

---

## Check Active Arrays

```
lsblk
```

---

## Monitor RAID (Live)

```
watch cat /proc/mdstat
```
---
