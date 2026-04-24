# ⚙️ Linux Job Automation — Cron & At Commands

> **Topic:** Systemd Job Scheduling using `cron` and `at` commands  
> **Level:** Beginner to Intermediate  
> **OS:** Linux (Debian/Ubuntu/RHEL based)

---

## 🤔 What is Job Automation?

Job Automation means **scheduling tasks to run automatically** at a specific time or interval — without human intervention.

| Tool      | Purpose                                               |
| --------- | ----------------------------------------------------- |
| `cron`    | Runs tasks **repeatedly** at scheduled intervals      |
| `at`      | Runs a task **once** at a specific future time        |

---

## 🕐 Cron — The Time-Based Scheduler

`cron` is a **daemon** (background service) that reads schedule files called **crontabs** and executes commands at the defined times.

```bash
# Check if cron service is running
systemctl status cron          # Debian/Ubuntu
systemctl status crond         # RHEL/CentOS

# Output:
● cron.service - Regular background program processing daemon
     Loaded: loaded (/lib/systemd/system/cron.service; enabled)
     Active: active (running) since Mon 2024-01-15 09:00:00 UTC
```

```bash
# Start / Stop / Enable cron
sudo systemctl start cron
sudo systemctl stop cron
sudo systemctl enable cron     # Auto-start on boot
```

---

## 🧩 Crontab Syntax — Full Breakdown

Every cron job follows this **5-field time pattern** + command:

```
* * * * *  command_to_execute
│ │ │ │ │
│ │ │ │ └──── Day of Week   (0–7)  [0 & 7 = Sunday]
│ │ │ └────── Month         (1–12)
│ │ └──────── Day of Month  (1–31)
│ └────────── Hour           (0–23)
└──────────── Minute         (0–59)
```

### 🔢 Field Values — What's Allowed

| Field        | Range              | Special Values          |
| ------------ | ------------------ | ----------------------- |
| Minute       | 0–59               | `*` `,` `-` `/`         |
| Hour         | 0–23               | `*` `,` `-` `/`         |
| Day of Month | 1–31               | `*` `,` `-` `/` `?` `L` |
| Month        | 1–12 or JAN–DEC    | `*` `,` `-` `/`         |
| Day of Week  | 0–7 (0=Sun, 7=Sun) | `*` `,` `-` `/` `?` `L` |
### 🎯 Special Characters Explained

| Symbol | Name     | Meaning             | Example                        |
| ------ | -------- | ------------------- | ------------------------------ |
| `*`    | Asterisk | **Every** value     | `* * * * *` = every minute     |
| `,`    | Comma    | **List** of values  | `1,15,30` = at 1st, 15th, 30th |
| `-`    | Hyphen   | **Range** of values | `1-5` = 1,2,3,4,5              |
| `/`    | Slash    | **Step/interval**   | `*/5` = every 5 units          |
| `L`    | Last     | **Last** day        | `L` in DoM = last day of month |

---

### 📘 Crontab Examples — Every Pattern

```bash
# ── EVERY MINUTE ──────────────────────────────────────────
* * * * * echo "Runs every minute"

# ── EVERY 5 MINUTES ───────────────────────────────────────
*/5 * * * * /usr/bin/check_status.sh

# ── SPECIFIC TIME — 2:30 AM every day ─────────────────────
30 2 * * * /home/user/backup.sh

# ── EVERY HOUR (at minute 0) ──────────────────────────────
0 * * * * /scripts/hourly_report.sh

# ── EVERY DAY AT MIDNIGHT ─────────────────────────────────
0 0 * * * /scripts/daily_cleanup.sh

# ── EVERY MONDAY AT 8 AM ──────────────────────────────────
0 8 * * 1 /scripts/weekly_report.sh

# ── EVERY WEEKDAY (Mon–Fri) AT 9 AM ──────────────────────
0 9 * * 1-5 /scripts/workday_start.sh

# ── EVERY WEEKEND (Sat & Sun) ─────────────────────────────
0 10 * * 6,7 /scripts/weekend_task.sh

# ── 1ST OF EVERY MONTH AT MIDNIGHT ───────────────────────
0 0 1 * * /scripts/monthly_invoice.sh

# ── EVERY 15 MINUTES BETWEEN 9AM–5PM ON WEEKDAYS ─────────
*/15 9-17 * * 1-5 /scripts/monitor.sh

# ── SPECIFIC DATE — Dec 25 at 12:00 PM ────────────────────
0 12 25 12 * /scripts/xmas_greeting.sh

# ── MULTIPLE TIMES — At 8 AM and 8 PM every day ──────────
0 8,20 * * * /scripts/twice_daily.sh

# ── EVERY 2 HOURS ─────────────────────────────────────────
0 */2 * * * /scripts/every_2hrs.sh

# ── LAST DAY OF MONTH (using workaround) ──────────────────
0 0 28-31 * * [ "$(date +\%d -d tomorrow)" = "01" ] && /scripts/last_day.sh
```

---

## 💻 Crontab Commands (crontab CLI)

The `crontab` command is how you **manage cron jobs** for users.

```bash
# ── VIEW your current crontab ─────────────────────────────
crontab -l

# Output (example):
# 0 2 * * * /home/alice/backup.sh
# */5 * * * * /scripts/monitor.sh

# ── EDIT your crontab (opens in default editor) ───────────
crontab -e

# ── REMOVE / DELETE all your cron jobs ────────────────────
crontab -r

# ── EDIT another user's crontab (root only) ───────────────
sudo crontab -u username -e

# ── VIEW another user's crontab ───────────────────────────
sudo crontab -u username -l

# ── DELETE another user's crontab ─────────────────────────
sudo crontab -u username -r

# ── INSTALL a crontab from a file ─────────────────────────
crontab /path/to/mycrons.txt
```

> ⚠️ **Warning:** `crontab -r` deletes ALL your cron jobs with NO confirmation! Be careful.

---

## 📁 Cron System Files — /etc Directory

These are the **important cron-related files and directories** under `/etc`:

```bash
# List all cron-related files in /etc
ls -la /etc/cron*

# Output:
# -rw-r--r-- 1 root root  722  /etc/crontab
# -rw-r--r-- 1 root root  102  /etc/cron.deny
# -rw-r--r-- 1 root root    0  /etc/cron.allow
# drwxr-xr-x 2 root root 4096  /etc/cron.d/
# drwxr-xr-x 2 root root 4096  /etc/cron.daily/
# drwxr-xr-x 2 root root 4096  /etc/cron.hourly/
# drwxr-xr-x 2 root root 4096  /etc/cron.monthly/
# drwxr-xr-x 2 root root 4096  /etc/cron.weekly/
```

---

## 🗂️ System-Wide Cron Files Explained

### 1️⃣ `/etc/crontab` — The Main System Crontab

This is the **master system crontab**. Unlike user crontabs, it has an **extra USERNAME field**.

```bash
cat /etc/crontab

# Output:
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# ┌───────── minute (0-59)
# │ ┌──────── hour (0-23)
# │ │ ┌────── day of month (1-31)
# │ │ │ ┌──── month (1-12)
# │ │ │ │ ┌── day of week (0-7) (Sunday=0 or 7)
# │ │ │ │ │
# * * * * * USER  command
  17 *  * * *  root  cd / && run-parts --report /etc/cron.hourly
  25 6  * * *  root  test -x /usr/sbin/anacron || run-parts --report /etc/cron.daily
  47 6  * * 7  root  test -x /usr/sbin/anacron || run-parts --report /etc/cron.weekly
  52 6  1 * *  root  test -x /usr/sbin/anacron || run-parts --report /etc/cron.monthly
```

> 🔑 **Key Difference:** `/etc/crontab` has **6 fields** — the 6th is the **username** that runs the command.

---

### 2️⃣ `/etc/cron.d/` — Drop-in Cron Directory

A **directory** where packages and admins drop individual cron files. Same format as `/etc/crontab` (includes username field).

```bash
ls /etc/cron.d/

# Output:
# php        sysstat    anacron    popularity-contest

cat /etc/cron.d/sysstat

# Output:
# /etc/cron.d/sysstat: crontab for the sysstat package
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Activity reports every 10 minutes
*/10 * * * * root command -v debian-sa1 > /dev/null && debian-sa1 1 1
# Summary every day at 23:53
53 23 * * * root command -v debian-sa1 > /dev/null && debian-sa1 60 2
```

> 💡 Use `/etc/cron.d/` to add **system-wide jobs** without editing `/etc/crontab` directly.

---

### 3️⃣ `/etc/cron.hourly/` — Scripts Run Every Hour

Drop a **script file** here and it runs **every hour** automatically (at minute 17 by default).

```bash
ls /etc/cron.hourly/

# Output:
# 0anacron

# Add your own hourly script
sudo cp myscript.sh /etc/cron.hourly/
sudo chmod +x /etc/cron.hourly/myscript.sh

# Run manually to test
run-parts --report /etc/cron.hourly
```

> ⚠️ Files here must be **executable** and must **NOT have a dot (.) in the name** — e.g., `backup.sh` ❌ → use `backup` ✅

---

### 4️⃣ `/etc/cron.daily/` — Scripts Run Every Day

Scripts here run **once per day** (around 6:25 AM by default on Ubuntu).

```bash
ls /etc/cron.daily/

# Output:
# apt-compat   dpkg   logrotate   man-db   passwd   ubuntu-advantage-tools

# View what logrotate does daily
cat /etc/cron.daily/logrotate

# Add a custom daily job
sudo nano /etc/cron.daily/my_daily_cleanup
# ↓ inside the file:
#!/bin/bash
find /tmp -type f -mtime +7 -delete
echo "Cleaned /tmp on $(date)" >> /var/log/cleanup.log

sudo chmod +x /etc/cron.daily/my_daily_cleanup
```

---

### 5️⃣ `/etc/cron.allow` — Whitelist (Who CAN use cron)

```bash
cat /etc/cron.allow

# Output:
# alice
# bob
# deploy

# If this file EXISTS — ONLY listed users can use crontab
# To add a user:
echo "charlie" | sudo tee -a /etc/cron.allow
```

---

### 8️⃣ `/etc/cron.deny` — Blacklist (Who CANNOT use cron)

```bash
cat /etc/cron.deny

# Output:
# guest
# testuser

# If this file EXISTS — listed users are BLOCKED from using crontab
# To block a user:
echo "baduser" | sudo tee -a /etc/cron.deny
```

### 🔐 Access Control Logic

```
┌─────────────────────────────────────────────────────────┐
│           CRON ACCESS CONTROL RULES                      │
├─────────────────────────────────────────────────────────┤
│ /etc/cron.allow EXISTS → ONLY users in it can use cron  │
│ /etc/cron.deny EXISTS  → All EXCEPT listed users can    │
│ BOTH exist             → cron.allow takes priority       │
│ NEITHER exists         → ONLY root can use cron          │
│ root                   → ALWAYS has access               │
└─────────────────────────────────────────────────────────┘
```

---

## 👤 User-Level vs System-Level Cron

|Feature|User Crontab (`crontab -e`)|System Crontab (`/etc/crontab`, `/etc/cron.d/`)|
|---|---|---|
|Location|`/var/spool/cron/crontabs/username`|`/etc/crontab` or `/etc/cron.d/`|
|Username field|❌ Not needed (auto = logged-in user)|✅ Required (6th field)|
|Who edits|Individual user|root only|
|Scope|Per-user jobs|System-wide jobs|

```bash
# Where user crontabs are stored (don't edit these directly!)
ls /var/spool/cron/crontabs/

# Output:
# alice   root   bob
```

---

## 🌍 Environment Variables in Cron

Cron runs with a **minimal environment** — much less than your shell. Always define variables explicitly.

```bash
# Set environment variables at the top of your crontab
crontab -e

# Now your jobs
0 2 * * * cal > /dev/pts/2

# Silence all output (no emails):
0 2 * * * /home/alice/backup.sh > /dev/null 2>&1

# Log output to a file:
0 2 * * * /home/alice/backup.sh >> /var/log/backup.log 2>&1
```

> 📧 **MAILTO=""** — Set this to empty string to suppress all email output.

---

## ⏰ The `at` Command — One-Time Scheduling

`at` schedules a command to run **once** at a specific future time (unlike cron which repeats).

```bash
# Install at (if not present)
sudo apt install at         # Ubuntu/Debian
sudo yum install at         # RHEL/CentOS
sudo systemctl enable --now atd

# ── BASIC USAGE ───────────────────────────────────────────
at 10:30
# Prompt appears: at>
# Type your command:
at> /home/user/backup.sh
at> <Ctrl+D to save>

# Output:
# job 1 at Mon Jan 15 10:30:00 2024

# ── SCHEDULE FOR SPECIFIC DATE/TIME ───────────────────────
at 2:00 PM tomorrow
at 10:00 AM Jan 25
at 9:30 AM next Monday
at now + 2 hours
at now + 30 minutes
at now + 3 days
at midnight tomorrow

# ── ONE-LINER (using echo pipe) ───────────────────────────
echo "/scripts/deploy.sh" | at 3:00 AM tomorrow
echo "reboot" | at now + 5 minutes

# ── LIST PENDING at JOBS ──────────────────────────────────
atq
# Output:
# 1    Mon Jan 15 10:30:00 2024 a alice
# 2    Tue Jan 16 03:00:00 2024 a alice

# ── VIEW CONTENT of a specific job ────────────────────────
at -c 1      # Shows job #1's commands

# ── REMOVE/DELETE an at job ───────────────────────────────
atrm 1       # Removes job number 1
atrm 2 3     # Removes jobs 2 and 3
```

### `at` Time Format Options

```bash
at now + 10 minutes     # 10 minutes from now
at now + 2 hours        # 2 hours from now
at now + 3 days         # 3 days from now
at 15:30                # Today at 3:30 PM (or tomorrow if past)
at 3pm                  # Today at 3 PM
at midnight             # Tonight at midnight
at noon tomorrow        # Tomorrow at 12 PM
at 08:00 next week      # Next week Monday at 8 AM
at 10:00 AM Jul 4       # July 4th at 10 AM
```

---

## 🌐 Real-World Examples

### 🔒 Backup Script

```bash
# Daily backup at 2:00 AM
0 2 * * * /home/alice/backup.sh >> /var/log/backup.log 2>&1

# backup.sh content:
#!/bin/bash
DATE=$(date +%Y%m%d)
tar -czf /backup/home_$DATE.tar.gz /home/alice/*
rsync -xvzrh /backup/home_$DATE.tar.gz rroot@192.168.68.120:/root/backup_files
echo "Backup and Transfer is done: $DATE"

```

### 🗑️ Auto-Clean Temp Files

```bash
# Every Sunday at 3 AM, delete files older than 7 days in /tmp
0 3 * * 0 find /tmp -type f -mtime +7 -delete
```

### 📊 System Health Monitor

```bash
# Every 5 minutes, log CPU and memory usage
*/5 * * * * echo "$(date): CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')% MEM=$(free -m | awk 'NR==2{print $3}')MB" >> /var/log/syshealth.log
```

### 🔄 Auto Restart a Service

```bash
# Check if nginx is running every minute, restart if down
* * * * * systemctl is-active --quiet nginx || systemctl restart nginx
```

### 📧 Weekly Email Report

```bash
# Every Friday at 5 PM
0 17 * * 5 df -h | mail -s "Weekly Disk Report" admin@company.com
```

### 🔁 Database Dump

```bash
# MySQL dump every day at 1 AM
0 1 * * * mysqldump -u root -pPASSWORD mydb > /backup/db_$(date +\%Y\%m\%d).sql
```

---

## 🔍 Cron Logs & Troubleshooting

```bash
# View cron execution logs
grep CRON /var/log/syslog                    # Ubuntu/Debian
grep CRON /var/log/cron                      # RHEL/CentOS
journalctl -u cron                           # systemd systems
journalctl -u cron --since "1 hour ago"      # Last 1 hour

# Output example:
# Jan 15 02:00:01 server CRON[12345]: (alice) CMD (/home/alice/backup.sh)
# Jan 15 02:00:01 server CRON[12345]: (CRON) info (No MTA installed)

# Watch cron log in real-time
tail -f /var/log/syslog | grep CRON

# Test a script manually before adding to cron
bash -x /home/alice/backup.sh               # Debug mode (-x shows each step)

# Always use FULL PATHS in cron (cron has minimal PATH)
# ❌ BAD:
* * * * * python3 script.py

# ✅ GOOD:
* * * * * /usr/bin/python3 /home/user/script.py
```

### 🐛 Common Cron Problems & Fixes

|Problem|Cause|Fix|
|---|---|---|
|Job doesn't run|Wrong permissions|`chmod +x script.sh`|
|Command not found|PATH issue|Use full path `/usr/bin/python3`|
|Works manually, not in cron|Environment difference|Add `PATH=` to crontab|
|% sign not working|`%` is newline in cron|Escape it as `\%`|
|No email output|No MTA installed|Redirect to log file instead|
|Job runs but fails silently|No error logging|Add `2>&1 >> /log/file.log`|

---

## 📋 Quick Reference Cheat Sheet

```
╔═══════════════════════════════════════════════════════════════╗
║                  CRONTAB SYNTAX                               ║
║   MIN  HR  DOM  MON  DOW   USER(sys only)  COMMAND            ║
║    *    *   *    *    *                     command            ║
╠═══════════════════════════════════════════════════════════════╣
║  SPECIAL CHARS:                                               ║
║   *  = every       ,  = list     -  = range    /  = step      ║
╠═══════════════════════════════════════════════════════════════╣
║  SHORTCUTS:                                                   ║
║   @reboot  @hourly  @daily  @weekly  @monthly  @yearly        ║
╠═══════════════════════════════════════════════════════════════╣
║  CRONTAB COMMANDS:                                            ║
║   crontab -l          list your cron jobs                     ║
║   crontab -e          edit your cron jobs                     ║
║   crontab -r          remove ALL your cron jobs               ║
║   crontab -u user -l  list another user's cron jobs           ║
╠═══════════════════════════════════════════════════════════════╣
║  KEY /etc FILES:                                              ║
║   /etc/crontab        system crontab (has username field)     ║
║   /etc/cron.d/        drop-in system cron files               ║
║   /etc/cron.hourly/   scripts run every hour                  ║
║   /etc/cron.daily/    scripts run every day                   ║
║   /etc/cron.weekly/   scripts run every week                  ║
║   /etc/cron.monthly/  scripts run every month                 ║
║   /etc/cron.allow     whitelist (ONLY these users)            ║
║   /etc/cron.deny      blacklist (BLOCK these users)           ║
╠═══════════════════════════════════════════════════════════════╣
║  AT COMMANDS:                                                 ║
║   at 10:30            schedule one-time job                   ║
║   atq                 list pending at jobs                    ║
║   atrm 1              remove at job #1                        ║
║   at now + 2 hours    run 2 hours from now                    ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## 📌 Summary — Key Rules to Remember

- ✅ Always use **full absolute paths** in cron commands
- ✅ Make scripts **executable** (`chmod +x script.sh`)
- ✅ Set **SHELL** and **PATH** variables at the top of crontab
- ✅ Redirect output: `>> /log/file.log 2>&1` for logging
- ✅ `/etc/crontab` and `/etc/cron.d/` need a **username** field
- ✅ `/etc/cron.hourly|daily|weekly|monthly/` files must have **no dot extension**
- ✅ Escape `%` signs in cron as `\%`
- ✅ Use `@reboot` for startup tasks
- ✅ Use `at` for **one-time** tasks, `cron` for **recurring** tasks
- ⚠️ `crontab -r` deletes ALL jobs with no confirmation!

---

_📝 Document covers: cron daemon, crontab syntax, /etc cron files, at command, access control, real-world examples, and troubleshooting._