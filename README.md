# 🧪 RHCE Lab Setup (RHEL 9.7)

This document describes the lab environment setup for practicing **Red Hat Certified Engineer (RHCE)** concepts using a virtual machine.

---

## 📥 RHEL 9.7 ISO Download

Download the official ISO from Red Hat Developer Portal:

👉 https://developers.redhat.com/products/rhel/download#getredhatenterpriselinux7163

> ⚠️ Note: Requires a free Red Hat Developer account.

---

## 💻 Virtualization Platform

- Hypervisor: VMware Workstation
- Guest OS: RHEL 9.7 (GUI Installation)

---

## ⚙️ System Configuration

### 🧠 Hardware

| Resource        | Configuration |
|----------------|--------------|
| RAM            | 5120 MB (5 GB) |
| CPU            | 1 Processor |
| Cores          | 4 Cores per Processor |

---

### 💾 Disk Partitioning

| Mount Point | Size   | Description |
|------------|--------|-------------|
| `/`        | 80 GiB | Root partition (main system storage) |
| `/boot`    | 1 GiB  | Boot files |
| `/boot/efi`| 1 GiB  | EFI partition for UEFI boot |
| `swap`     | 4 GiB  | Swap memory |

---

### 🌐 Network Configuration

| Setting   | Value |
|----------|-------|
| Hostname | Server1.iforward.in |
| IP       | DHCP (Dynamic) |

> ⚠️ For RHCE practice, it is recommended to configure a **Static IP Address**.

---

## 🔧 Recommended Post-Installation Steps

1️⃣ Set Static IP (Recommended)

```bash
nmtui
```
*   Edit connection → IPv4 → Manual
*   Assign:
    *   IP Address
    *   Gateway
    *   DNS (e.g., 8.8.8.8)
        
Apply changes:
```bash
systemctl restart NetworkManager
```

2️⃣ Register System (Required for Package Installation)
```bash
subscription-manager register
subscription-manager attach --auto
```
Enable repositories:
```bash
subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
```

3️⃣ Update System
```bash
dnf update -y
```

4️⃣ Install Basic Tools
```bash
dnf install -y vim net-tools bash-completion wget curl
```

5️⃣ Enable SSH
```bash
systemctl enable --now sshd
```

### 👨‍💻 Author

Sharan, Avadh, Hit

Cybersecurity Students | RHCE Aspirants
