# 💀 Linux RAID + LVM Disaster Recovery Lab

This lab simulates real-world storage failures and recovery scenarios using:

- RAID 0 (failure)
    
- RAID 1 (disk failure + rebuild)
    
- RAID 5 (degraded + disaster)
    
- LVM on RAID (corruption + recovery)
    

⚠️ **WARNING:** This lab intentionally destroys data. Do NOT run on production systems.

---

# ⚙️ LAB SETUP

## 📌 Disks Used

```
/dev/sdb
/dev/sdc
/dev/sdd
/dev/sde
```

## 📌 Partition All Disks

```bash
for i in b c d e; do
  parted /dev/sd$i --script mklabel gpt
  parted /dev/sd$i --script mkpart primary 1MiB 100%
done
```

✔ Creates GPT partition table  
✔ Creates full-size primary partition

---

# 🔥 PART 1 — RAID 0 (DATA LOSS TEST)

## Create RAID 0

```bash
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sdb1 /dev/sdc1
mkfs.xfs /dev/md0
mkdir /raid0
mount /dev/md0 /raid0
```

✔ RAID 0 = striping (NO redundancy)  
✔ Fast but unsafe

---

## Add Data

```bash
echo "IMPORTANT_DATA" > /raid0/data.txt
```

---

## 💣 Simulate Disk Failure

```bash
mdadm /dev/md0 --fail /dev/sdb1
```

---

## Verify Data

```bash
cat /raid0/data.txt
```

❌ Data corrupted/lost

---

## Cleanup

```bash
umount /raid0
wipefs -a /dev/md0
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sdb1 /dev/sdc1
```

---

# 🛡️ PART 2 — RAID 1 (MIRROR TEST)

## Create RAID 1

```bash
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1
mkfs.xfs /dev/md1
mkdir /raid1
mount /dev/md1 /raid1
```

✔ RAID 1 = mirroring (safe)

---

## Add Data

```bash
echo "SAFE_DATA" > /raid1/data.txt
```

---

## 💣 Fail One Disk

```bash
mdadm /dev/md1 --fail /dev/sdb1
mdadm /dev/md1 --remove /dev/sdb1
```

---

## Verify Data

```bash
cat /raid1/data.txt
```

✔ Data still available

---

## 🔁 Rebuild RAID

```bash
mdadm /dev/md1 --add /dev/sdb1
watch cat /proc/mdstat
```

✔ Rebuild process visible

---

## Cleanup

```bash
umount /raid1
wipefs -a /dev/md1
mdadm --stop /dev/md1
mdadm --zero-superblock /dev/sdb1 /dev/sdc1
```

---

# ⚙️ PART 3 — RAID 5 (ENTERPRISE TEST)

## Create RAID 5

```bash
mdadm --create /dev/md2 --level=5 --raid-devices=3 /dev/sdb1 /dev/sdc1 /dev/sdd1
mkfs.xfs /dev/md2
mkdir /raid5
mount /dev/md2 /raid5
```

✔ RAID 5 = striping + parity

---

## Add Data

```bash
echo "RAID5_DATA" > /raid5/data.txt
```

---

## 💣 Fail One Disk

```bash
mdadm /dev/md2 --fail /dev/sdc1
mdadm /dev/md2 --remove /dev/sdc1
```

---

## Verify Data

```bash
cat /raid5/data.txt
```

✔ Data survives

---

## 💀 Fail Second Disk (Disaster)

```bash
mdadm /dev/md2 --fail /dev/sdb1
```

---

## Verify Data

```bash
cat /raid5/data.txt
```

❌ Data lost

---

## Cleanup

```bash
umount /raid5
wipefs -a /dev/md2
mdadm --stop /dev/md2
mdadm --zero-superblock /dev/sdb1 /dev/sdc1 /dev/sdd1
```

---

# 🔍 Mdadm Verification Commands

## Check RAID Status

```bash
cat /proc/mdstat
```

---

## Detailed RAID Info

```bash
mdadm --detail /dev/md0
mdadm --detail /dev/md1
mdadm --detail /dev/md2
```

---

## Scan All RAID Devices

```bash
mdadm --detail --scan
```

---

## Examine Disk Metadata

```bash
mdadm --examine /dev/sdb1
mdadm --examine /dev/sdc1
```

---

## Check Active Arrays

```bash
lsblk
```

---

## Monitor RAID (Live)

```bash
watch cat /proc/mdstat
```

---

## Check Failed Devices

```bash
mdadm --detail /dev/md2 | grep -i failed
```

---

# ⚡ FINAL CONCLUSION

|RAID Type|Failure Result|
|---|---|
|RAID 0|💀 Data lost|
|RAID 1|✅ Safe|
|RAID 5 (1 disk)|✅ Safe|
|RAID 5 (2 disk)|💀 Lost|
|LVM Corruption|⚠️ Risky|

---

# 🚀 Key Learnings

- RAID is NOT backup
    
- Always verify before executing
    
- Disk failure ≠ data loss (depends on RAID)
    
- Corruption is worse than failure
    
- Recovery is NOT guaranteed
    

---

