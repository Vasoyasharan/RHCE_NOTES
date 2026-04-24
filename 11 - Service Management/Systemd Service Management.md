# 🐧 Managing Services with `systemd` & `systemctl` on RHEL

> A complete, beginner-friendly guide to understanding and managing Linux services using `systemctl`.

---

## 📌 What is `systemd`?

`systemd` is the **init system** used in modern Linux distributions (RHEL, CentOS, Fedora, Ubuntu, etc.).  
It is responsible for **starting, stopping, and managing services** (also called _units_) on your system.

The main tool you use to interact with `systemd` is:

```bash
systemctl
```

---

## 🗂️ Understanding Service States — Keywords You Must Know

When you list or check services, you'll see these columns:

|Column|Meaning|
|---|---|
|**LOAD**|Was the unit file loaded properly?|
|**ACTIVE**|High-level state (active / inactive)|
|**SUB**|Low-level/detailed state|

### 🔑 Key SUB-state Keywords

|Keyword|Meaning|
|---|---|
|`running`|✅ Service is actively running right now|
|`exited`|✅ Service ran successfully and then exited (one-shot jobs)|
|`waiting`|⏳ Service is active but waiting for something (e.g., a socket)|
|`dead`|❌ Service is not running|
|`inactive`|❌ Service is not active|

### 🔑 Enable/Disable States (from `list-unit-files`)

|Keyword|Meaning|
|---|---|
|`enabled`|🟢 Will auto-start at boot|
|`disabled`|🔴 Will NOT auto-start at boot|
|`static`|⚪ Cannot be enabled/disabled directly; used by other units|
|`masked`|🚫 Completely blocked — cannot be started at all|

---

## 📋 Listing Services

### 1️⃣ List Only Active/Running Services

```bash
systemctl --type=service
```

**Output (from Image 1):**

```
UNIT                          LOAD    ACTIVE  SUB     DESCRIPTION
accounts-daemon.service       loaded  active  running Accounts Service
alsa-state.service            loaded  active  running Manage Sound Card State
atd.service                   loaded  active  running Deferred execution scheduler
auditd.service                loaded  active  running Security Auditing Service
chronyd.service               loaded  active  running NTP client/server
crond.service                 loaded  active  running Command Scheduler
cups.service                  loaded  active  running CUPS Scheduler
firewalld.service             loaded  active  running firewalld - dynamic firewall daemon
sshd.service                  loaded  active  running OpenSSH server daemon
...
65 loaded units listed.
```

> 💡 This shows only **loaded and active** services by default.

---

### 2️⃣ List ALL Services (including inactive/dead)

```bash
systemctl --type=service --all
# OR
systemctl list-units --type=service --all
```

**Output (from Image 2 & 4):**

```
UNIT                          LOAD       ACTIVE   SUB     DESCRIPTION
accounts-daemon.service       loaded     active   running Accounts Service
alsa-restore.service          loaded     inactive dead    Save/Restore Sound Card State
auto-cpufreq.service          not-found  inactive dead    auto-cpufreq.service
autofs.service                not-found  inactive dead    autofs.service
avahi-daemon.service          loaded     active   running Avahi mDNS/DNS-SD Stack
blk-availability.service      loaded     inactive dead    Availability of block devices
chronyd.service               loaded     active   running NTP client/server
cpupower.service              loaded     inactive dead    Configure CPU power related settings
...
163 loaded units listed.
```

> 💡 Notice:
> 
> - `not-found` in LOAD = unit file doesn't exist on this system (shown with 🔴 dot)
> - `inactive dead` = service exists but is not running

---

### 3️⃣ List Unit Files (Installed Services + Their Boot State)

```bash
systemctl list-unit-files --type=service
```

**Output (from Image 5):**

```
UNIT FILE                              STATE     PRESET
accounts-daemon.service                enabled   enabled
alsa-restore.service                   static    -
alsa-state.service                     static    -
arp-ethers.service                     disabled  disabled
atd.service                            enabled   enabled
auditd.service                         enabled   enabled
bluetooth.service                      enabled   enabled
chronyd.service                        enabled   enabled
...
```

> 💡 Use this to see **which services are set to start at boot** vs which are disabled.

---

### 🔍 Filter with `grep`

```bash
systemctl list-unit-files --type=service | grep sshd
```

**Output (from Image 5):**

```
sshd-keygen@.service    disabled   disabled
sshd.service            enabled    enabled      ← highlighted in green
sshd@.service           static     -
```

---

## 🔎 Checking Status of a Specific Service

```bash
systemctl status <service_name>
```

**Example:**

```bash
systemctl status upower.service
```

**Output (from Image 3):**

```
● upower.service - Daemon for power management
     Loaded: loaded (/usr/lib/systemd/system/upower.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-04-22 07:01:43 IST; 42min ago
   Main PID: 930 (upowerd)
      Tasks: 3 (limit: 22765)
     Memory: 1.6M (peak: 2.2M)
        CPU: 66ms
     CGroup: /system.slice/upower.service
             └─930 /usr/libexec/upowerd

Apr 22 07:01:43 client1.iforward.in systemd[1]: Starting Daemon for power management...
Apr 22 07:01:43 client1.iforward.in systemd[1]: Started Daemon for power management.
```

### 🧾 How to Read `systemctl status` Output

|Field|Meaning|
|---|---|
|`●` (green dot)|Service is running|
|`○` (white dot)|Service is stopped|
|`Loaded:`|Where the unit file is + whether enabled/disabled|
|`Active:`|Current running state + since when|
|`Main PID:`|The process ID of the service|
|`Tasks:`|Number of threads/tasks|
|`Memory:`|RAM used|
|`CGroup:`|Control group (process hierarchy)|
|Log lines|Recent journal logs for this service|

---

## ⚙️ Start, Stop, Restart, Reload a Service

### ▶️ Start a Service

```bash
systemctl start sshd
```

### ⏹️ Stop a Service

```bash
systemctl stop sshd
```

### 🔁 Restart a Service (stop + start)

```bash
systemctl restart sshd
```

### 🔄 Reload a Service (reload config without full restart)

```bash
systemctl reload sshd
```

> 💡 Use `reload` when you've changed a config file and want to apply it **without interrupting** the service.

---

## 🔌 Enable & Disable Services at Boot

### ✅ Enable (auto-start at boot)

```bash
systemctl enable sshd
```

**Output:**

```
Created symlink /etc/systemd/system/multi-user.target.wants/sshd.service → /usr/lib/systemd/system/sshd.service.
```

### ❌ Disable (don't auto-start at boot)

```bash
systemctl disable sshd
```

### ✅ Enable AND start immediately (most useful!)

```bash
systemctl enable sshd --now
```

### ❌ Disable AND stop immediately

```bash
systemctl disable sshd --now
```

> 💡 `--now` combines the enable/disable action with an immediate start/stop. Very handy!

---

## 🔗 Viewing Service Dependencies

```bash
systemctl list-dependencies cups
```

**Output (from Image 6):**

```
cups.service
● ├─cups.path
● ├─cups.socket
● ├─system.slice
● └─sysinit.target
●   ├─dev-hugepages.mount
●   ├─dev-mqueue.mount
●   ├─dracut-shutdown.service
○   ├─iscsi-onboot.service
●   ├─kmod-static-nodes.service
●   ├─lvm2-monitor.service
○   ├─multipathd.service
●   ├─plymouth-read-write.service
●   ├─plymouth-start.service
●   ├─systemd-journald.service
...
```

> 💡 Green `●` = dependency is active. White `○` = dependency is inactive. This shows what other services/units **must be running** before `cups` can start.

---

## 🚫 Masking a Service (Nuclear Option!)

**Masking** creates a symlink to `/dev/null`, making it **impossible** to start the service — even manually or by another service.

```bash
systemctl mask sshd
```

**Output (from Image 7):**

```
Created symlink /etc/systemd/system/sshd.service → /dev/null.
```

Now check its status:

```bash
systemctl status sshd
```

```
● sshd.service
     Loaded: masked (Reason: Unit sshd.service is masked.)
     Active: active (running) since Wed 2026-04-22 08:18:00 IST; 10min ago
```

> ⚠️ Note: If the service was already running, masking does NOT stop it immediately. You need to stop it manually.

### Trying to start a masked service fails:

```bash
systemctl start sshd
```

```
Failed to start sshd.service: Unit sshd.service is masked.
```

```bash
systemctl enable sshd
```

```
Failed to enable unit: Unit file /etc/systemd/system/sshd.service is masked.
```

---

## ✅ Unmasking a Service

```bash
systemctl unmask sshd
```

**Output (from Image 9):**

```
Removed "/etc/systemd/system/sshd.service".
```

> 💡 After unmasking, you can start and enable the service normally again.

---

## 📊 Quick Reference Cheat Sheet

```
┌─────────────────────────────────────────────────────────────────────┐
│                    systemctl Cheat Sheet                            │
├──────────────────────────────────┬──────────────────────────────────┤
│ COMMAND                          │ WHAT IT DOES                     │
├──────────────────────────────────┼──────────────────────────────────┤
│ systemctl --type=service         │ List active services             │
│ systemctl --type=service --all   │ List ALL services (incl. dead)   │
│ systemctl list-unit-files        │ Show boot enable/disable state   │
│ systemctl status <svc>           │ Detailed status of a service     │
│ systemctl start <svc>            │ Start a service now              │
│ systemctl stop <svc>             │ Stop a service now               │
│ systemctl restart <svc>          │ Restart a service                │
│ systemctl reload <svc>           │ Reload config (no full restart)  │
│ systemctl enable <svc>           │ Enable at boot                   │
│ systemctl disable <svc>          │ Disable at boot                  │
│ systemctl enable <svc> --now     │ Enable + start immediately       │
│ systemctl disable <svc> --now    │ Disable + stop immediately       │
│ systemctl list-dependencies <svc>│ Show service dependencies        │
│ systemctl mask <svc>             │ Block service completely         │
│ systemctl unmask <svc>           │ Unblock a masked service         │
└──────────────────────────────────┴──────────────────────────────────┘
```

---

## 🧠 Common Confusions — Cleared!

### ❓ What's the difference between `enable` and `start`?

|Action|Effect|
|---|---|
|`start`|Starts the service **right now** (doesn't survive reboot)|
|`enable`|Makes service start **automatically at next boot** (doesn't start now)|
|`enable --now`|Does **both** — starts now AND enables for boot ✅|

---

### ❓ What's the difference between `disable` and `mask`?

| Action    | Can be started manually?  | Auto-starts at boot? |
| --------- | ------------------------- | -------------------- |
| `disable` | ✅ Yes                     | ❌ No                 |
| `mask`    | ❌ No (completely blocked) | ❌ No                 |

> Use `mask` only when you want to **permanently prevent** a service from running under any circumstance.

---

### ❓ What does `active (exited)` mean?

It means the service **ran successfully and finished** its job. It's not an error!  
Example: `dracut-shutdown.service` runs once at shutdown and then exits — that's normal.

---

### ❓ What does `not-found` in LOAD column mean?

It means the unit file for that service **doesn't exist** on this system. The service was referenced somewhere but was never installed.

---

## 🗺️ Visual Flow: Service Lifecycle

```
  INSTALLED (unit file exists)
        │
        ▼
  ┌─────────────┐
  │  disabled   │ ← won't start at boot
  └──────┬──────┘
         │  systemctl enable
         ▼
  ┌─────────────┐
  │   enabled   │ ← will start at boot
  └──────┬──────┘
         │  systemctl start / reboot
         ▼
  ┌─────────────┐
  │   running   │ ← active (running)
  └──────┬──────┘
         │  systemctl stop
         ▼
  ┌─────────────┐
  │  inactive   │ ← active (dead)
  └──────┬──────┘
         │  systemctl mask
         ▼
  ┌─────────────┐
  │   masked    │ ← BLOCKED, cannot start
  └─────────────┘
         │  systemctl unmask
         ▼
       (back to enabled/disabled state)
```

---

## 📝 Practice Commands to Try

```bash
# 1. See all running services
systemctl --type=service

# 2. See ALL services including stopped ones
systemctl list-units --type=service --all

# 3. Check if sshd is enabled at boot
systemctl list-unit-files --type=service | grep sshd

# 4. Get full details of a service
systemctl status chronyd.service

# 5. View what cups depends on
systemctl list-dependencies cups

# 6. Start and enable sshd in one command
systemctl enable sshd --now

# 7. Stop sshd and check its status
systemctl stop sshd
systemctl status sshd

# 8. Mask a service (prevent it from running)
systemctl mask sshd

# 9. Unmask it
systemctl unmask sshd
```

---

_📅 Notes created on: April 22, 2026 | System: RHEL / CentOS with systemd_