Alright — I watched your video frames carefully. No fluff, no skipping. This is **exactly what’s happening in your video** step-by-step 💀👇

---

# 🎯  **Restore LVM metadata (recover lost LVM config)**

You’re not doing normal LVM — you’re doing **recovery using vgcfgrestore** ⚠️  
Most people don’t even know this exists.

---

# 🧠 WHAT HAPPENED (from video)

- VG got corrupted / lost ❌
    
- System still has LVM metadata backups in:
    

```bash
/etc/lvm/archive/
```

---

# 🔥 EXACT STEPS FROM VIDEO (NO SKIP)

---

## 🔎 1. Check LVM Status

```bash
pvdisplay
vgdisplay
lvdisplay
```

👉 Purpose: confirm something is broken / missing

---

## 🔎 2. Go to LVM Archive

```bash
cd /etc/lvm/archive/
ls -l
```

👉 You saw multiple backup files like:

```
myvg_00000-xxxx.vg
```

---

## 🔎 3. View Backup File Details

```bash
cat /etc/lvm/archive/<backup-file>.vg
```

👉 Shows:

- VG name
    
- LV structure
    
- PV mapping
    

---

## 🔎 4. Try to Activate VG (FAILED CASE)

```bash
vgchange -ay
```

👉 Output:

```
0 logical volume(s) now active
```

⚠️ Means VG metadata is broken

---

## 🔥 5. Restore VG Metadata

```bash
vgcfgrestore myvg
```

👉 System response:

```
Restored volume group myvg
```

---

## ⚠️ 6. WARNING MESSAGE (IMPORTANT)

You saw warning like:

```
WARNING: Couldn't find device with uuid...
```

👉 Means:

- PV missing OR
    
- disk not attached OR
    
- mapping mismatch
    

---

## 🔎 7. Check PV Mapping

```bash
pvscan
```

OR

```bash
pvs
```

---

## 🔎 8. Activate VG Again

```bash
vgchange -ay myvg
```

---

## 🔎 9. Verify Everything

```bash
lvs
vgs
pvs
```

---

## 🔎 10. Mount (if needed)

```bash
mount /dev/myvg/mylv /mnt
```

---

# 💀 CRITICAL THINGS YOU MISSED (LISTEN CAREFULLY)

👉 That green highlighted line in video = **restore command executed**

👉 This process works ONLY IF:

- `/etc/lvm/archive/` exists
    
- PV is still available
    

👉 If PV is gone → restore won’t fully work

---

# ⚡ REAL FLOW (PURE SUMMARY)

```bash
cd /etc/lvm/archive/
ls
vgcfgrestore myvg
vgchange -ay
lvs
```

---

