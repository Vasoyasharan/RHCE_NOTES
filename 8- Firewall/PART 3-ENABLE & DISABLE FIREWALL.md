# 📌 PART 3: ENABLE / DISABLE FIREWALL

---

## 3.1 Install firewalld (if not installed)

```bash
# RHEL/CentOS/Rocky/AlmaLinux
dnf install firewalld -y

# Ubuntu/Debian
apt install firewalld -y
```

---

## 3.2 Start and Stop firewalld

```bash
# Start firewalld (runs now, but may not survive reboot)
systemctl start firewalld
```

**What it does:** Starts the firewalld daemon. Firewall is now active and rules are applied.

```bash
# Stop firewalld (disables firewall immediately — DANGEROUS on production)
systemctl stop firewalld
```

**What it does:** Stops the daemon. ALL firewall rules are removed. Any port becomes accessible.

```bash
# Restart firewalld (stop then start — brief moment with no rules)
systemctl restart firewalld
```

**What it does:** Full restart. Use only when firewalld is having serious issues.

```bash
# Reload firewalld (apply permanent rules to runtime — NO restart)
firewall-cmd --reload
```

**What it does:** This is the PREFERRED way to apply permanent changes. Reads all permanent rules and applies them to the running firewall. Does NOT drop existing connections.

---

## 3.3 Enable and Disable (Boot Persistence)

```bash
# Enable firewalld (auto-start at every boot)
systemctl enable firewalld
```

**What it does:** Creates a systemd symlink so firewalld starts automatically when the server boots.

```bash
# Disable firewalld (don't start at boot)
systemctl disable firewalld
```

**What it does:** Removes the boot symlink. firewalld won't start at next reboot (but is still running NOW if started).

```bash
# Enable AND start in one command
systemctl enable --now firewalld
```

```bash
# Disable AND stop in one command
systemctl disable --now firewalld
```

---

## 3.4 Check Status

```bash
# Full detailed status (most useful)
systemctl status firewalld
```

**Output explained:**

```
● firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; ...)
      ↑ service file found                                          ↑ starts at boot

     Active: active (running) since Mon 2024-04-15 10:00:00 IST; 2h 30min ago
      ↑ currently running

   Main PID: 876 (firewalld)
     CGroup: /system.slice/firewalld.service
             └─876 /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid
```

```bash
# Simple running check
systemctl is-active firewalld
# Output: active or inactive

# Simple boot-enabled check
systemctl is-enabled firewalld
# Output: enabled or disabled

# Quick firewall state check
firewall-cmd --state
# Output: running or not running
```

---
