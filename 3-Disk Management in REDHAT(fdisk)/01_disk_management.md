# 💽 Disk Management in Red Hat Enterprise Linux (RHEL)

---

## Overview

Disk management in RHEL involves partitioning, formatting, mounting, and managing logical volumes using tools like `fdisk`, `parted`, `LVM`, and `df/du`.

---

## Key Concepts

| Concept | Description |
|--------|-------------|
| **MBR** | Master Boot Record – legacy partition table (max 2TB, 4 primary partitions) |
| **GPT** | GUID Partition Table – modern standard (supports >2TB, 128 partitions) |
| **LVM** | Logical Volume Manager – flexible disk management layer |
| **XFS** | Default filesystem in RHEL 7/8/9 |
| **ext4** | Common alternative filesystem |

---

## Common Commands

### View Disk Info
```bash
lsblk                    # List block devices
fdisk -l                 # List partition tables
df -hT                   # Disk usage with filesystem type
du -sh /path             # Directory size
blkid                    # Show filesystem UUIDs
pvs / vgs / lvs          # LVM physical, volume group, logical volume info
```

### Partition a Disk (fdisk)
```bash
fdisk /dev/sdb
# Inside fdisk:
# n → new partition
# p → primary
# w → write and exit
```

### Partition a Disk (parted – GPT)
```bash
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary xfs 1MiB 100%
```

### Format a Partition
```bash
mkfs.xfs /dev/sdb1       # Format as XFS
mkfs.ext4 /dev/sdb1      # Format as ext4
```

### Mount a Partition
```bash
mkdir /mnt/data
mount /dev/sdb1 /mnt/data

# Persistent mount (add to /etc/fstab):
echo "/dev/sdb1  /mnt/data  xfs  defaults  0 0" >> /etc/fstab
mount -a    # Reload fstab
```

---

## LVM Management

```bash
# Create Physical Volume
pvcreate /dev/sdb1

# Create Volume Group
vgcreate vg_data /dev/sdb1

# Create Logical Volume (10G)
lvcreate -L 10G -n lv_data vg_data

# Format and Mount
mkfs.xfs /dev/vg_data/lv_data
mount /dev/vg_data/lv_data /mnt/data

# Extend Logical Volume
lvextend -L +5G /dev/vg_data/lv_data
xfs_growfs /mnt/data      # Grow XFS filesystem online
```

---

## Swap Management

```bash
mkswap /dev/sdb2          # Format as swap
swapon /dev/sdb2          # Enable swap
swapon --show             # Show active swap
echo "/dev/sdb2 swap swap defaults 0 0" >> /etc/fstab
```

---

## Automation Script

```bash
#!/bin/bash
# disk_manager.sh – Linux Admin Disk Automation Script
# Usage: sudo bash disk_manager.sh

set -euo pipefail
LOG="/var/log/disk_manager.log"
exec > >(tee -a "$LOG") 2>&1

echo "===== Disk Manager Script ====="
echo "Date: $(date)"
echo ""

# Function: Show disk usage summary
disk_summary() {
    echo "--- Disk Usage Summary ---"
    df -hT | grep -v tmpfs
    echo ""
    echo "--- Block Devices ---"
    lsblk
    echo ""
    echo "--- LVM Info ---"
    pvs 2>/dev/null || echo "No Physical Volumes found"
    vgs 2>/dev/null || echo "No Volume Groups found"
    lvs 2>/dev/null || echo "No Logical Volumes found"
}

# Function: Create and mount a new XFS partition via LVM
setup_lvm_volume() {
    local DISK="${1:-/dev/sdb}"
    local VG="${2:-vg_data}"
    local LV="${3:-lv_data}"
    local SIZE="${4:-5G}"
    local MOUNTPOINT="${5:-/mnt/data}"

    echo "--- Setting up LVM on $DISK ---"

    # Partition disk
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart primary 1MiB 100%
    partprobe "$DISK"
    sleep 2

    PART="${DISK}1"

    # LVM setup
    pvcreate "$PART"
    vgcreate "$VG" "$PART"
    lvcreate -L "$SIZE" -n "$LV" "$VG"

    # Format and mount
    mkfs.xfs "/dev/${VG}/${LV}"
    mkdir -p "$MOUNTPOINT"
    mount "/dev/${VG}/${LV}" "$MOUNTPOINT"

    # Add to fstab
    FSTAB_ENTRY="/dev/${VG}/${LV}  ${MOUNTPOINT}  xfs  defaults  0 0"
    grep -qF "$FSTAB_ENTRY" /etc/fstab || echo "$FSTAB_ENTRY" >> /etc/fstab

    echo "✅ Volume /dev/${VG}/${LV} mounted at ${MOUNTPOINT}"
}

# Function: Check for disks > 80% usage and alert
check_disk_alert() {
    echo "--- Checking Disk Usage Alerts (>80%) ---"
    df -h | awk 'NR>1 {gsub(/%/,""); if ($5+0 > 80) print "⚠️  ALERT: "$6" is at "$5"% usage"}'
}

# Function: Add swap space
add_swap() {
    local SWAPFILE="${1:-/swapfile}"
    local SIZE="${2:-2G}"
    echo "--- Creating Swap: $SWAPFILE ($SIZE) ---"
    fallocate -l "$SIZE" "$SWAPFILE"
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
    swapon "$SWAPFILE"
    grep -qF "$SWAPFILE" /etc/fstab || echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    echo "✅ Swap enabled: $(swapon --show)"
}

# MAIN MENU
echo "Choose an action:"
echo "1) Show disk summary"
echo "2) Setup LVM volume (auto: /dev/sdb, 5G, /mnt/data)"
echo "3) Check disk usage alerts"
echo "4) Add swap file (2G)"
echo "5) Run all checks"
read -rp "Enter choice [1-5]: " CHOICE

case $CHOICE in
    1) disk_summary ;;
    2) setup_lvm_volume ;;
    3) check_disk_alert ;;
    4) add_swap ;;
    5) disk_summary; check_disk_alert ;;
    *) echo "Invalid option" ;;
esac

echo ""
echo "===== Done. Log saved to $LOG ====="
```

---

## Best Practices

- Always use `lsblk` and `blkid` before modifying disks.
- Prefer **LVM** for flexibility in resizing.
- Use **XFS** for large files and high-performance workloads.
- Always add mount entries to `/etc/fstab` with `UUID=` (not device names) for reliability.
- Test `fstab` with `mount -a` before rebooting.
- Take snapshots with LVM before major changes: `lvcreate -s -n snap -L 1G /dev/vg/lv`
