# 🔐 SUDO & Linux Privilege Management — Industry-Ready Notes

> **Audience:** SysAdmins, DevOps Engineers, Security Engineers  
> **Environment:** Production Linux (RHEL / CentOS / Ubuntu / Debian)  
> **Criticality:** HIGH — Misconfiguration can lead to full system compromise

---

## 📌 What is SUDO?

`sudo` (**S**uper **U**ser **DO** / **S**ubstitute **U**ser **DO**) allows a permitted user to execute commands as another user (typically `root`), based on rules defined in `/etc/sudoers`.

- Acts as a **controlled privilege escalation** mechanism
- Replaces the need to log in as `root` directly
- Every sudo action is **logged** — providing a full audit trail
- Follows the **Principle of Least Privilege (PoLP)**

### 🔎 How it Works — Step by Step

```
User types:   sudo fdisk -l
      │
      ▼
sudo checks /etc/sudoers
      │
      ├── Rule found? ──► YES ──► Prompts for USER's own password
      │                                  │
      │                           Password correct?
      │                                  │
      │                           YES ──► Runs: fdisk -l as root
      │                                         Logs to /var/log/secure
      │
      └── Rule NOT found? ──► "user is not in the sudoers file. This incident will be reported."
```

### 📋 Real Terminal Example

```bash
# As a regular user "alice" — without sudo
[alice@server ~]$ fdisk -l
fdisk: cannot open /dev/sda: Permission denied

# With sudo (alice has permission)
[alice@server ~]$ sudo fdisk -l
[sudo] password for alice:        ← asks for ALICE's password, not root's
Disk /dev/sda: 50 GiB, 53687091200 bytes ...

# What gets logged to /var/log/secure:
# Apr 13 10:22:01 server sudo: alice : TTY=pts/0 ; PWD=/home/alice ;
#   USER=root ; COMMAND=/sbin/fdisk -l
```

---

## ✅ DO's — Industry Best Practices

---

### 1. Always Use `visudo` to Edit the Sudoers File

```bash
# ✅ CORRECT way to edit sudoers
visudo

# ✅ Edit a drop-in file safely
visudo -f /etc/sudoers.d/developers

# ✅ Just validate syntax without editing
visudo -c
```

**What visudo does behind the scenes:**
- Opens `/etc/sudoers` in the editor defined by `$EDITOR` (usually `vi` or `nano`)
- Puts a **file lock** so no other user can edit simultaneously
- On save, **validates syntax** before writing
- If there's an error, it warns you:

```
visudo: >>> /etc/sudoers: syntax error near line 42 <<<
What now?
Options are:
  (e)dit sudoers file again
  e(x)it without saving changes to sudoers file
  (Q)uit and save changes to sudoers file (DANGER!)

What now? e       ← always choose 'e' to fix, never 'Q'
```

> 💡 **Real scenario:** A sysadmin at 2 AM edits sudoers directly with `vi`, accidentally deletes a closing bracket, and now no one on the 50-server fleet can use sudo. The fix requires physical/console access or rebooting into single-user mode. `visudo` would have caught this in 2 seconds.

---

### 2. Apply Least Privilege — Restrict Commands Per User/Role

Give users **only** the commands they need for their specific job function.

```bash
# ❌ BAD — intern has full root access
intern1    ALL=(ALL)    ALL

# ✅ GOOD — intern can only restart the web service they manage
intern1    ALL=(ALL)    /bin/systemctl restart nginx, /bin/systemctl status nginx
```

**Real-world job role mapping:**

```
# Junior Developer — can restart apps, read logs
jrdev    ALL=(ALL)    /bin/systemctl restart myapp, \
                      /usr/bin/tail /var/log/myapp.log, \
                      /usr/bin/journalctl -u myapp

# DBA — only database operations
dba1     ALL=(ALL)    /bin/systemctl restart mysql, \
                      /usr/bin/mysqldump, \
                      /bin/mkdir /var/backups/db

# Network Engineer — only network tools
neteng1  ALL=(ALL)    /sbin/ifconfig, /sbin/route, \
                      /bin/ping, /sbin/iptables -L
```

**Testing what a user CAN run:**
```bash
# Run as root to check alice's permissions
sudo -l -U alice

# Sample output:
# User alice may run the following commands on server01:
#     (ALL) /bin/systemctl restart nginx
#     (ALL) /usr/bin/tail /var/log/nginx/error.log
```

---

### 3. Use Command Aliases for Role-Based Access

Aliases let you define a named group of commands once and reuse it across multiple users/groups.

```bash
# In /etc/sudoers or /etc/sudoers.d/aliases

## ── COMMAND ALIASES ─────────────────────────────────────────
Cmnd_Alias NETWORKING  = /sbin/route, /sbin/ifconfig, /bin/ping, \
                         /sbin/dhclient, /sbin/iptables, /sbin/iwconfig

Cmnd_Alias WEB_OPS     = /bin/systemctl restart nginx, \
                         /bin/systemctl restart apache2, \
                         /usr/bin/apachectl

Cmnd_Alias DB_OPS      = /bin/systemctl restart mysql, \
                         /bin/systemctl restart postgresql, \
                         /usr/bin/mysqldump, \
                         /usr/bin/pg_dump

Cmnd_Alias PKG_MGMT    = /usr/bin/yum, /usr/bin/apt, /usr/bin/dnf, \
                         /usr/bin/pip, /usr/bin/npm

Cmnd_Alias LOG_ACCESS  = /usr/bin/tail /var/log/*, \
                         /bin/cat /var/log/*, \
                         /usr/bin/journalctl

## ── ROLE ASSIGNMENTS ────────────────────────────────────────
%webteam    ALL=(ALL)    WEB_OPS, LOG_ACCESS
%dbateam    ALL=(ALL)    DB_OPS, LOG_ACCESS
%netteam    ALL=(ALL)    NETWORKING
%devops     ALL=(ALL)    WEB_OPS, DB_OPS, PKG_MGMT, LOG_ACCESS
```

**Why this matters at scale:**

```bash
# Without aliases — adding a new web command means editing EVERY user line
webuser1    ALL=(ALL)    /bin/systemctl restart nginx, /bin/systemctl restart apache2
webuser2    ALL=(ALL)    /bin/systemctl restart nginx, /bin/systemctl restart apache2
webuser3    ALL=(ALL)    /bin/systemctl restart nginx, /bin/systemctl restart apache2
# Adding haproxy means 3 lines to update ← error-prone

# With aliases — one change propagates everywhere
Cmnd_Alias WEB_OPS = /bin/systemctl restart nginx, \
                     /bin/systemctl restart apache2, \
                     /usr/sbin/haproxy        ← add here, affects all 3 users
%webteam    ALL=(ALL)    WEB_OPS              ← no change needed here
```

---

### 4. Use Group-Based Sudo (Preferred over Per-User Rules)

```bash
# ── Create the groups ───────────────────────────────────────
groupadd sysadmins
groupadd developers
groupadd dbateam

# ── Add users to groups ─────────────────────────────────────
usermod -aG sysadmins alice
usermod -aG developers bob
usermod -aG developers charlie
usermod -aG dbateam dave

# ── /etc/sudoers.d/groups ───────────────────────────────────
%sysadmins   ALL=(ALL)    ALL
%developers  ALL=(ALL)    /usr/bin/git, /usr/bin/docker, \
                          /bin/systemctl restart myapp
%dbateam     ALL=(ALL)    DB_OPS
```

**Verify group membership:**
```bash
groups bob
# bob : bob developers

id bob
# uid=1002(bob) gid=1002(bob) groups=1002(bob),1005(developers)
```

**When someone leaves the team — one command removes all access:**
```bash
# Bob moves to a different team — remove from developers group
gpasswd -d bob developers
# No sudoers edit needed — group rule handles it automatically
```

---

### 5. Use Drop-in Files in `/etc/sudoers.d/`

Instead of a massive single sudoers file, split by team/function:

```bash
ls /etc/sudoers.d/
# developers   dbateam   netteam   ci-deploy   monitoring   readonly

# ── Create role files safely ────────────────────────────────
visudo -f /etc/sudoers.d/developers
visudo -f /etc/sudoers.d/ci-deploy
visudo -f /etc/sudoers.d/monitoring
```

**Example drop-in file — `/etc/sudoers.d/ci-deploy`:**
```bash
# CI/CD deploy user — only restart specific services, no password prompt
# Created: 2024-01-15 | Owner: DevOps Team | Reviewed: 2024-04-01
deploy_svc    ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp, \
                                  /bin/systemctl restart worker, \
                                  /usr/bin/docker pull myrepo/myapp:*, \
                                  /usr/bin/docker-compose up -d
```

**Example drop-in file — `/etc/sudoers.d/monitoring`:**
```bash
# Monitoring agent — read-only system access
# Created: 2024-02-01 | Owner: Infra Team
nagios    ALL=(ALL) NOPASSWD: /usr/lib/nagios/plugins/*, \
                              /bin/cat /proc/*, \
                              /usr/bin/tail /var/log/*
```

**Revoking access — instant and clean:**
```bash
# Remove a team's sudo access entirely — no file editing required
rm /etc/sudoers.d/contractors
# That's it — all contractor sudo access revoked
```

**Verify the main file includes the directory:**
```bash
grep includedir /etc/sudoers
# #includedir /etc/sudoers.d    ← must be present
```

---

### 6. Enable and Monitor Sudo Logs

**Default log locations:**
```bash
/var/log/secure        # RHEL / CentOS / Fedora
/var/log/auth.log      # Ubuntu / Debian
```

**Add a dedicated sudo log (in `/etc/sudoers`):**
```bash
Defaults logfile=/var/log/sudo.log
Defaults log_input                  # log what user types (stdin)
Defaults log_output                 # log what they see (stdout) — caution: large files
Defaults loglinelen=0               # don't wrap long log lines
```

**Sample log output — what you'll see:**
```
Apr 13 10:22:01 server sudo:   alice : TTY=pts/0 ; PWD=/home/alice ; USER=root ; COMMAND=/sbin/fdisk -l
Apr 13 10:45:17 server sudo:   bob : TTY=pts/1 ; PWD=/var/www ; USER=root ; COMMAND=/bin/systemctl restart nginx
Apr 13 11:03:44 server sudo:   mallory : TTY=pts/2 ; PWD=/home/mallory ; USER=root ; COMMAND=/bin/bash
Apr 13 11:03:44 server sudo:   mallory : command not allowed ; TTY=pts/2 ; COMMAND=/bin/bash
```

**Grep for actionable events:**
```bash
# All sudo actions today
grep "$(date '+%b %e')" /var/log/sudo.log

# Failed sudo attempts (possible brute force or misconfiguration)
grep "NOT in sudoers\|command not allowed\|incorrect password" /var/log/secure

# What a specific user has run via sudo
grep "sudo:.*alice" /var/log/secure | awk '{print $NF}'

# All sudo activity in the last hour
journalctl -u sudo --since "1 hour ago"
```

**SIEM alert rules to configure (Splunk/ELK examples):**
```
# Alert: sudo command not in sudoers (attempted privilege escalation)
"NOT in sudoers" → CRITICAL alert → PagerDuty

# Alert: sudo used outside business hours
sudo event AND (hour < 8 OR hour > 18) → MEDIUM alert → Slack

# Alert: root shell obtained via sudo
COMMAND=/bin/bash OR COMMAND=/bin/sh → HIGH alert → PagerDuty
```

---

### 7. Require Password Re-Entry After Timeout

```bash
# In /etc/sudoers:

# Default (5 min) — user not re-prompted if they used sudo recently
Defaults timestamp_timeout=5

# High-security server — always require password
Defaults timestamp_timeout=0

# Banking/PCI environment — 1 minute window only
Defaults timestamp_timeout=1

# Per-user override — alice always needs to re-enter (for admin actions)
Defaults:alice timestamp_timeout=0
```

**What this looks like for the user:**
```bash
# First sudo command — prompts for password
[alice@server ~]$ sudo systemctl restart nginx
[sudo] password for alice:          ← types password
Restarting nginx...

# Second command within timeout window — no prompt
[alice@server ~]$ sudo systemctl status nginx
● nginx.service - A high performance web server       ← runs immediately

# After timeout expires
[alice@server ~]$ sudo fdisk -l
[sudo] password for alice:          ← prompts again
```

---

### 8. Require TTY for Sudo (Prevent Script Abuse)

```bash
# /etc/sudoers
Defaults requiretty

# Allow specific automated users to bypass TTY requirement
Defaults:nagios     !requiretty
Defaults:deploy_svc !requiretty
```

**Why this matters — attack scenario:**
```bash
# ❌ Without requiretty — attacker injects sudo via cron or web shell
# Malicious cron job:
* * * * * echo "alice ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/backdoor

# ✅ With requiretty — this fails because there's no interactive terminal
# sudo: sorry, you must have a tty to run sudo
```

---

### 9. Use User Aliases for Grouped Users Across Teams

Useful when users from different OS groups need the same sudo permissions:

```bash
# In /etc/sudoers or /etc/sudoers.d/user-aliases

## ── USER ALIASES ────────────────────────────────────────────
User_Alias WEBTEAM     = alice, bob, charlie
User_Alias DBTEAM      = dave, eve
User_Alias ON_CALL     = alice, dave, frank    # mixed from different teams
User_Alias CONTRACTORS = vendor1, vendor2, vendor3

## ── ASSIGNMENTS ─────────────────────────────────────────────
WEBTEAM       ALL=(ALL)    WEB_OPS
DBTEAM        ALL=(ALL)    DB_OPS
ON_CALL       ALL=(ALL)    WEB_OPS, DB_OPS, LOG_ACCESS   # broader for on-call
CONTRACTORS   ALL=(ALL)    /usr/bin/tail /var/log/app.log  # read-only log access only
```

**Practical use — temporary elevated access for on-call rotation:**
```bash
# Monthly, update the ON_CALL alias with whoever is on-call this week
User_Alias ON_CALL = frank, grace    # updated for this week's rotation
ON_CALL    ALL=(ALL)    WEB_OPS, DB_OPS, NETWORKING, LOG_ACCESS
```

---

### 10. Restrict Sudo to Specific Hosts (Multi-Server Shared Sudoers)

When the same `/etc/sudoers` is distributed to many servers via Puppet/Ansible:

```bash
# alice can restart apache only on web servers
alice    webserver01,webserver02=(ALL)    /bin/systemctl restart apache2

# dave can run mysql commands only on db servers
dave     dbserver01,dbserver02=(ALL)      /bin/systemctl restart mysql

# frank can do anything — but only from the jump host
frank    jumphost01=(ALL)    ALL

# Host Alias for cleaner management
Host_Alias WEBSERVERS = webserver01, webserver02, webserver03
Host_Alias DBSERVERS  = dbserver01, dbserver02
Host_Alias JUMPHOSTS  = jumphost01

alice    WEBSERVERS=(ALL)    /bin/systemctl restart apache2
dave     DBSERVERS=(ALL)     DB_OPS
frank    JUMPHOSTS=(ALL)     ALL
```

---

## ❌ DON'Ts — What to Avoid in Production

---

### 1. Never Give Unrestricted `ALL` to Regular Users

```bash
# ❌ DANGEROUS
regularuser    ALL=(ALL)    ALL
intern1        ALL=(ALL)    ALL

# What this means in practice:
# They can run: sudo rm -rf /
# They can run: sudo cat /etc/shadow      (steal all password hashes)
# They can run: sudo useradd backdooruser (create hidden accounts)
# They can run: sudo crontab -e           (schedule malicious tasks)
```

**What to do instead — map to a real job role:**
```bash
# intern1 is a web developer — give only what they need
intern1    ALL=(ALL)    /bin/systemctl restart mywebapp, \
                        /usr/bin/journalctl -u mywebapp, \
                        /usr/bin/tail /var/log/mywebapp/error.log
```

---

### 2. Never Edit `/etc/sudoers` Directly with `vi` / `nano`

```bash
# ❌ NEVER do this
vi /etc/sudoers
nano /etc/sudoers
gedit /etc/sudoers
echo "alice ALL=(ALL) ALL" >> /etc/sudoers    # also dangerous
```

**Real consequence of a typo:**
```bash
# Typo: missing closing parenthesis
alice    ALL=(ALL    ALL      ← syntax error

# Result: ALL sudo commands fail for EVERY user on the system
sudo ls
# sudo: parse error in /etc/sudoers near line 45
# sudo: no valid sudoers sources found, quitting

# Recovery requires:
# 1. Reboot into single-user/recovery mode, OR
# 2. Physical console access, OR
# 3. Another root session already open
# — All painful at 3 AM on a production server
```

**visudo catches this BEFORE saving:**
```
visudo: >>> /etc/sudoers: syntax error near line 45 <<<
What now? e        ← fix it safely
```

---

### 3. Never Allow `sudo su` or `sudo bash` for Non-Admins

```bash
# ❌ These are root shell bypass tricks
user1    ALL=(ALL)    /bin/bash
user1    ALL=(ALL)    /bin/su
user1    ALL=(ALL)    /usr/bin/vim     # ← less obvious but also dangerous!
user1    ALL=(ALL)    /usr/bin/less    # ← can spawn shell with !bash
user1    ALL=(ALL)    /usr/bin/python  # ← python -c "import os; os.system('/bin/bash')"
```

**The "shell escape" problem — why editors and interpreters are dangerous:**
```bash
# User has: sudo vim /etc/nginx/nginx.conf
# Inside vim, they type:
:!/bin/bash
# Boom — they now have a full root shell, bypassing ALL restrictions

# Same with less:
sudo less /var/log/syslog
# Inside less, type:
!bash
# Full root shell again

# Python:
sudo python3
>>> import os
>>> os.system('/bin/bash')
# Root shell
```

**Safe alternative — use sudoedit for file editing:**
```bash
# ✅ sudoedit — opens the file as root but in the user's own editor process
# No shell escape possible
user1    ALL=(ALL)    sudoedit /etc/nginx/nginx.conf
```

---

### 4. Never Use `NOPASSWD` Without Strong Justification

```bash
# ❌ Extremely dangerous — no authentication at all
deploy    ALL=(ALL) NOPASSWD: ALL

# What an attacker can do if they get deploy's SSH key:
# sudo rm -rf /
# sudo useradd -m -s /bin/bash hacker
# sudo cat /etc/shadow
```

**The right way — scope tightly for CI/CD:**
```bash
# ✅ Acceptable — specific commands only, no shell, no package managers
# /etc/sudoers.d/ci-deploy
deploy_svc    ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp, \
                                  /bin/systemctl restart myworker, \
                                  /usr/bin/docker pull myrepo/myapp:latest, \
                                  /usr/bin/docker-compose -f /opt/myapp/docker-compose.yml up -d
```

**Real CI/CD pipeline example (GitHub Actions / Jenkins):**
```yaml
# GitHub Actions step that uses the deploy_svc account
- name: Deploy to server
  run: |
    ssh deploy_svc@server "sudo systemctl restart myapp"
    # ✅ This works with NOPASSWD scoped to only that command
    # ❌ ssh deploy_svc@server "sudo bash" would be blocked
```

---

### 5. Never Leave Commented Test Rules in Production

```bash
# ❌ Leftover test entries — a ticking time bomb
# ytuser    ALL=(ALL)    ALL    # TEMP - remove after testing   ← never removed
# %contractors ALL=(ALL) ALL   # for vendor access Dec 2023     ← it's now 2025
# frank ALL=(ALL) NOPASSWD: ALL  # emergency fix - TODO remove  ← still there 6 months later
```

**Enforce cleanup with a review comment header in each file:**
```bash
# /etc/sudoers.d/contractors
# ── REVIEW REQUIRED ─────────────────────────────────────────
# Created  : 2024-12-01
# Purpose  : Vendor XYZ onsite audit access
# Expires  : 2024-12-15
# Owner    : ops-team@company.com
# Ticket   : OPS-4421
# ────────────────────────────────────────────────────────────
vendor1    ALL=(ALL)    LOG_ACCESS
vendor2    ALL=(ALL)    LOG_ACCESS
```

**Automate expiry checks (cron job):**
```bash
#!/bin/bash
# /etc/cron.weekly/check-sudoers-expiry
grep -r "Expires" /etc/sudoers.d/ | while read line; do
  expiry=$(echo $line | grep -oP '\d{4}-\d{2}-\d{2}')
  if [[ $(date -d "$expiry" +%s) -lt $(date +%s) ]]; then
    echo "EXPIRED sudoers rule: $line" | mail -s "Sudoers Expiry Alert" ops-team@company.com
  fi
done
```

---

### 6. Never Ignore Sudo Log Alerts

**What a brute-force attempt looks like in logs:**
```bash
grep "incorrect password\|authentication failure" /var/log/secure

# Output — 47 failures in 30 seconds = automated attack
Apr 13 03:14:22 server sudo: pam_unix(sudo:auth): authentication failure; user=www-data
Apr 13 03:14:23 server sudo: pam_unix(sudo:auth): authentication failure; user=www-data
Apr 13 03:14:24 server sudo: pam_unix(sudo:auth): authentication failure; user=www-data
# ... 44 more lines ...
```

**What unauthorized command attempts look like:**
```bash
Apr 13 11:03:44 server sudo: mallory : command not allowed ; TTY=pts/2 ;
  USER=root ; COMMAND=/bin/bash
Apr 13 11:03:51 server sudo: mallory : command not allowed ; TTY=pts/2 ;
  USER=root ; COMMAND=/usr/bin/passwd root
# Mallory is probing for privilege escalation paths
```

**Quick bash one-liner to summarize today's sudo activity:**
```bash
grep "$(date '+%b %e')" /var/log/secure | grep sudo | \
  awk '{print $6, $NF}' | sort | uniq -c | sort -rn

# Output:
#   23 alice COMMAND=/bin/systemctl
#    8 bob COMMAND=/usr/bin/tail
#    3 mallory command not allowed
#    1 mallory COMMAND=/bin/bash    ← investigate this
```

---

### 7. Never Share Root Passwords as a Substitute for Sudo

**The audit trail problem:**
```bash
# With shared root password — log shows:
Apr 13 10:00:00 server sshd: Accepted password for root from 10.0.1.55
Apr 13 10:05:00 server sshd: Accepted password for root from 10.0.1.22
# Someone deleted /var/lib/mysql at 10:03 — was it the person from .55 or .22?
# You'll NEVER know.

# With sudo — log shows exactly who did what:
Apr 13 10:03:14 server sudo: alice : COMMAND=/bin/rm -rf /var/lib/mysql
# Unambiguous. alice did it.
```

**Disabling direct root SSH login:**
```bash
# /etc/ssh/sshd_config
PermitRootLogin no           # Block root SSH entirely
# or
PermitRootLogin without-password    # Allow root only with SSH key (not password)

# Apply:
systemctl restart sshd
```

---

### 8. Never Allow Wildcard Paths in Commands

```bash
# ❌ Wildcard in directory = attacker controls what runs
ytuser    ALL=(ALL)    /usr/bin/*
ytuser    ALL=(ALL)    /scripts/*

# Exploitation example:
# Attacker creates /scripts/rootkit and runs: sudo /scripts/rootkit
# → full root execution of their malicious script
```

**Argument wildcards are also risky:**
```bash
# ❌ Allows reading ANY file on the system
user1    ALL=(ALL)    /bin/cat *
# sudo cat /etc/shadow    ← steals all password hashes

# ✅ Restrict to specific log directory only
user1    ALL=(ALL)    /bin/cat /var/log/myapp/*.log
```

**Safe use of wildcards — only when truly necessary:**
```bash
# ✅ Acceptable — wildcard only for docker image tags
deploy    ALL=(ALL) NOPASSWD: /usr/bin/docker pull myrepo/myapp:*
# Only allows pulling from YOUR repo with ANY tag — not arbitrary commands
```

---

## 🔑 Quick Reference — Sudoers Syntax

```
WHO    WHERE=(AS_WHOM)    WHAT
```

| Field | Examples | Meaning |
|-------|----------|---------|
| `WHO` | `alice`, `%developers`, `User_Alias` | Who gets the permission |
| `WHERE` | `ALL`, `webserver01`, `Host_Alias` | Which machine(s) |
| `AS_WHOM` | `ALL`, `root`, `(root:wheel)` | Which user to run as |
| `WHAT` | `ALL`, `/sbin/fdisk`, `Cmnd_Alias` | Which commands |

```bash
## ── FULL SYNTAX EXAMPLES ────────────────────────────────────

# Full root access for one user
alice         ALL=(ALL)    ALL

# Full root access for a group (note the % prefix)
%sysadmins    ALL=(ALL)    ALL

# One specific command, must enter password
bob           ALL=(root)   /usr/bin/systemctl restart nginx

# Multiple commands, no password (for automation)
deploy_svc    ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp, /usr/bin/docker pull

# Run as a specific non-root user (e.g., run as the 'postgres' user)
dba1          ALL=(postgres)   /usr/bin/psql

# Deny a specific command even if other rules allow it (! = deny)
%developers   ALL=(ALL)    ALL, !/bin/bash, !/bin/sh, !/usr/bin/python3

## ── ALIAS DEFINITIONS ───────────────────────────────────────
User_Alias  ADMINS    = alice, bob
Host_Alias  WEBSERVERS = web01, web02, web03
Cmnd_Alias  RESTART   = /bin/systemctl restart *, /bin/systemctl stop *
Runas_Alias WEBUSERS  = www-data, nginx

## ── DEFAULTS ────────────────────────────────────────────────
Defaults    logfile=/var/log/sudo.log        # Custom log file
Defaults    timestamp_timeout=5              # Password cache (minutes)
Defaults    requiretty                       # Interactive terminal required
Defaults    mail_badpass                     # Email on bad password attempt
Defaults    passwd_tries=3                   # Max password attempts
Defaults:alice    timestamp_timeout=0        # Per-user override
```

---

## 🧪 Lab Summary — What Each Lab Teaches

| Lab | Task | Real-World Equivalent |
|-----|------|-----------------------|
| Lab 1 | Give user `ytuser` full sudo | Onboarding a new sysadmin to a server |
| Lab 2 | Give group `ytgroup` full sudo | Creating a sysadmin team group |
| Lab 3 | Restrict `ytuser` to `fdisk` + `parted` only | Giving a junior admin disk management — nothing else |
| Lab 4 | Restrict `ytgroup` to networking commands | NetOps team access on a network appliance/server |
| Lab 5 | Custom alias `CUSTOM` + `NETWORKING` for group | DevOps team needing both infra and package management |
| Lab 6 | User alias `YTADMIN` with mixed users | Cross-team on-call rotation with elevated access |

### 🖥️ Running the Labs — Exact Commands

```bash
## LAB 1 — Full access for ytuser
# Step 1: Try without sudo first — see the denial
[ytuser@server ~]$ fdisk -l
fdisk: cannot open /dev/sda: Permission denied

# Step 2: Add rule
visudo
# Add this line:
ytuser    ALL=(ALL)    ALL

# Step 3: Test
[ytuser@server ~]$ sudo fdisk -l
[sudo] password for ytuser:
Disk /dev/sda: 50 GiB ...        ← success

## LAB 3 — Restrict to fdisk and parted only
visudo
# Change the line to:
ytuser    ALL=(ALL)    /sbin/fdisk, /sbin/parted

# Test the restriction:
[ytuser@server ~]$ sudo useradd testuser
Sorry, user ytuser is not allowed to execute '/usr/sbin/useradd testuser' as root
# ✅ Restriction working

[ytuser@server ~]$ sudo fdisk -l
Disk /dev/sda: 50 GiB ...
# ✅ Allowed command still works

## LAB 6 — User alias test
visudo
# Add:
User_Alias YTADMIN = yogesh, ytuser, amit
YTADMIN    ALL=(ALL)    CUSTOM, /sbin/parted

# Test as yogesh:
[yogesh@server ~]$ sudo parted /dev/sda print
# ✅ Works

[yogesh@server ~]$ sudo fdisk -l
Sorry, user yogesh is not allowed to execute '/sbin/fdisk -l' as root
# ✅ fdisk not in CUSTOM or the parted rule — correctly blocked
```

---

## 🏭 Real-World Role-Based Sudo Design Example

Complete production-ready sudoers setup for a mid-size company:

```bash
## ════════════════════════════════════════════════════════════
## /etc/sudoers.d/00-aliases
## Central alias definitions — edit this file to add commands
## Owner: infra-team | Last reviewed: 2024-04-01
## ════════════════════════════════════════════════════════════

# ── Host Aliases ─────────────────────────────────────────────
Host_Alias  WEBSERVERS   = web01, web02, web03
Host_Alias  DBSERVERS    = db01, db02
Host_Alias  APPSERVERS   = app01, app02, app03
Host_Alias  ALL_SERVERS  = WEBSERVERS, DBSERVERS, APPSERVERS

# ── Command Aliases ──────────────────────────────────────────
Cmnd_Alias  NETWORK_OPS  = /sbin/ifconfig, /sbin/route, /bin/ping, \
                           /sbin/iptables, /sbin/ip, /sbin/ss

Cmnd_Alias  SERVICE_OPS  = /bin/systemctl start *, \
                           /bin/systemctl stop *, \
                           /bin/systemctl restart *, \
                           /bin/systemctl reload *

Cmnd_Alias  DISK_OPS     = /sbin/fdisk, /sbin/parted, /sbin/mkfs, \
                           /bin/mount, /bin/umount, /sbin/lsblk

Cmnd_Alias  PKG_OPS      = /usr/bin/yum, /usr/bin/dnf, /usr/bin/apt

Cmnd_Alias  LOG_READ     = /usr/bin/tail /var/log/*, \
                           /bin/cat /var/log/*, \
                           /usr/bin/journalctl, \
                           /usr/bin/grep * /var/log/*

Cmnd_Alias  DOCKER_OPS   = /usr/bin/docker pull *, \
                           /usr/bin/docker ps, \
                           /usr/bin/docker logs *, \
                           /usr/bin/docker-compose up -d, \
                           /usr/bin/docker-compose restart *

Cmnd_Alias  DB_OPS       = /bin/systemctl restart mysql, \
                           /bin/systemctl restart postgresql, \
                           /usr/bin/mysqldump, /usr/bin/pg_dump

# ── User Aliases ─────────────────────────────────────────────
User_Alias  SYSADMINS    = alice, bob
User_Alias  NETADMINS    = charlie, dave
User_Alias  DEVELOPERS   = eve, frank, grace, henry
User_Alias  DBAS         = isabel, jake
User_Alias  SUPPORT_L1   = helpdesk1, helpdesk2, helpdesk3
User_Alias  ON_CALL      = alice, isabel    # update monthly for rotation
User_Alias  CI_AGENTS    = jenkins_svc, github_actions_svc, deploy_svc
```

```bash
## ════════════════════════════════════════════════════════════
## /etc/sudoers.d/01-roles
## Role-to-permission mappings
## ════════════════════════════════════════════════════════════

# ── SysAdmins — full access ──────────────────────────────────
SYSADMINS    ALL_SERVERS=(ALL)    ALL

# ── NetAdmins — network + service management ────────────────
NETADMINS    ALL_SERVERS=(ALL)    NETWORK_OPS, SERVICE_OPS

# ── Developers — app ops + logs, no system changes ──────────
DEVELOPERS   APPSERVERS=(ALL)     SERVICE_OPS, DOCKER_OPS, LOG_READ

# ── DBAs — database ops only ────────────────────────────────
DBAS         DBSERVERS=(ALL)      DB_OPS, LOG_READ

# ── Support L1 — read-only log access ───────────────────────
SUPPORT_L1   ALL_SERVERS=(ALL)    LOG_READ

# ── On-call — broad access for emergencies ──────────────────
ON_CALL      ALL_SERVERS=(ALL)    SERVICE_OPS, DOCKER_OPS, DB_OPS, \
                                  NETWORK_OPS, LOG_READ, DISK_OPS

# ── CI/CD Agents — no password, scoped commands ─────────────
CI_AGENTS    APPSERVERS=(ALL) NOPASSWD: SERVICE_OPS, DOCKER_OPS

# ── Global Defaults ──────────────────────────────────────────
Defaults    logfile=/var/log/sudo.log
Defaults    timestamp_timeout=5
Defaults    requiretty
Defaults    passwd_tries=3
Defaults    mail_badpass
# Override TTY requirement for CI agents
Defaults:CI_AGENTS    !requiretty
```

---

## 🔍 Audit Commands — Know Your Environment

```bash
## ── CHECK PERMISSIONS ───────────────────────────────────────

# What can the current user run?
sudo -l
# Sample output:
# User alice may run the following commands on server01:
#     (ALL) /bin/systemctl restart nginx
#     (ALL) /usr/bin/journalctl -u nginx

# What can a specific user run? (run as root)
sudo -l -U bob
sudo -l -U deploy_svc

# List all users with sudo access
grep -v '^#\|^$\|Defaults\|Cmnd_Alias\|User_Alias\|Host_Alias' /etc/sudoers
grep -r -v '^#\|^$\|Defaults\|Cmnd_Alias\|User_Alias\|Host_Alias' /etc/sudoers.d/

## ── VALIDATE SYNTAX ─────────────────────────────────────────

# Check main sudoers file
visudo -c
# visudo: /etc/sudoers: parsed OK

# Check a specific drop-in file
visudo -c -f /etc/sudoers.d/developers
# visudo: /etc/sudoers.d/developers: parsed OK

# Check ALL drop-in files at once
for f in /etc/sudoers.d/*; do
  echo -n "Checking $f: "
  visudo -c -f "$f" 2>&1
done

## ── INVESTIGATE ACTIVITY ────────────────────────────────────

# All sudo actions today
grep "$(date '+%b %e')" /var/log/secure | grep sudo

# Everything a specific user has done via sudo
grep "sudo:.*alice" /var/log/secure

# Failed sudo attempts (potential intrusion)
grep "NOT in sudoers\|command not allowed\|authentication failure" /var/log/secure

# How many times each user used sudo this month
grep "COMMAND=" /var/log/sudo.log | awk -F: '{print $6}' | \
  awk '{print $1}' | sort | uniq -c | sort -rn

# What commands were run as root via sudo (top 10)
grep "COMMAND=" /var/log/sudo.log | awk -F'COMMAND=' '{print $2}' | \
  sort | uniq -c | sort -rn | head 10

## ── RUN AS DIFFERENT USER ───────────────────────────────────

# Run a command as a specific non-root user
sudo -u postgres psql -c "\l"          # run psql as postgres user
sudo -u www-data php artisan migrate   # run Laravel migration as web user
sudo -u jenkins /opt/deploy.sh         # run deploy script as jenkins user

# Open an interactive shell as another user (be careful — for admins only)
sudo -u postgres -i     # interactive login shell as postgres
sudo -i                 # interactive root shell (if you're a full admin)
```

---

## 🚨 Security Hardening Checklist

```bash
## Run these checks on any server to audit sudo configuration:

# 1. Verify no direct root SSH
grep "PermitRootLogin" /etc/ssh/sshd_config
# Expected: PermitRootLogin no

# 2. Check for overly permissive sudo rules (any ALL=(ALL) ALL for non-admins)
grep -r "ALL=(ALL)\s*ALL" /etc/sudoers /etc/sudoers.d/ | grep -v "^#\|%sysadmin\|%wheel"

# 3. Check for NOPASSWD rules
grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/

# 4. Verify sudo logging is configured
grep -r "logfile\|log_input\|log_output" /etc/sudoers /etc/sudoers.d/

# 5. Check for shell/interpreter access via sudo (dangerous)
grep -r "bash\|/bin/sh\|python\|perl\|vim\|less\|more\|awk\|find" \
  /etc/sudoers /etc/sudoers.d/ | grep -v "^#"

# 6. List all files in sudoers.d and check permissions
ls -la /etc/sudoers.d/
stat /etc/sudoers                # Should be: 440 root:root
```

**Checklist:**
- [ ] All privileged users use sudo — **no direct root login**
- [ ] `PermitRootLogin no` set in `/etc/ssh/sshd_config`
- [ ] All sudoers rules follow **Principle of Least Privilege**
- [ ] No blanket `ALL` permissions for non-admin users
- [ ] `NOPASSWD` used only for automation, scoped to specific commands
- [ ] No shell/interpreter (`bash`, `python`, `vim`) allowed via sudo for regular users
- [ ] Sudo logs shipped to centralized logging / SIEM
- [ ] `/etc/sudoers.d/` used for modular role-based rules
- [ ] Sudoers changes managed via **IaC** (Ansible / Puppet / Chef)
- [ ] Regular **access review** — quarterly at minimum
- [ ] `visudo -c` run in CI/CD pipeline before deploying sudoers changes
- [ ] `requiretty` enabled where automation does not require sudo
- [ ] Wildcard paths reviewed and minimized
- [ ] Drop-in files have metadata comments (owner, created, purpose, expiry)

---

## ⚠️ Common Mistakes That Cause Incidents

| Mistake | Real Impact | Detection | Fix |
|---------|-------------|-----------|-----|
| Syntax error via direct `vi /etc/sudoers` | All sudo breaks on server — outage | `sudo: parse error` in logs | Always use `visudo` |
| `NOPASSWD: ALL` for service account | Full root if account is compromised | `grep NOPASSWD /etc/sudoers.d/*` | Scope to minimum commands |
| `sudo bash` granted to developer | Unrestricted root shell, bypasses all controls | `grep bash /etc/sudoers.d/*` | Remove; use `sudoedit` instead |
| Shared root password | No audit trail — can't attribute actions during incident | No individual usernames in `/var/log/secure` | Enforce sudo-only, disable root login |
| Test rules never removed | Unintended escalation discovered months later | Regular sudoers audit / expiry comments | Review sudoers every change cycle |
| Not monitoring sudo logs | Breach/escalation goes undetected for weeks | No SIEM alerts | Set up log forwarding + alerting |
| Wildcard path `/scripts/*` | Attacker drops script in dir, runs as root | `grep '\*' /etc/sudoers*` | Specify exact binary paths |
| `sudo vim` on config file | User escapes to root shell with `:!/bin/bash` | Audit sudo commands including editors | Use `sudoedit` for file editing |

---

## 🔧 Ansible — Managing Sudoers at Scale

Don't manage sudoers manually across 100 servers. Use Ansible:

```yaml
# roles/sudo/tasks/main.yml
---
- name: Ensure sudoers.d directory exists
  file:
    path: /etc/sudoers.d
    state: directory
    mode: '0750'
    owner: root
    group: root

- name: Deploy role-based sudoers rules
  template:
    src: "{{ item }}.j2"
    dest: "/etc/sudoers.d/{{ item }}"
    owner: root
    group: root
    mode: '0440'
    validate: 'visudo -cf %s'    # ← validate BEFORE deploying
  loop:
    - 00-aliases
    - 01-roles
    - 02-ci-deploy

- name: Remove old/expired sudoers files
  file:
    path: "/etc/sudoers.d/contractors"
    state: absent
```

```yaml
# roles/sudo/templates/01-roles.j2
# Managed by Ansible — DO NOT EDIT MANUALLY
# Last deployed: {{ ansible_date_time.date }}

SYSADMINS    ALL_SERVERS=(ALL)    ALL
{% for user in developers %}
{{ user }}    APPSERVERS=(ALL)    SERVICE_OPS, DOCKER_OPS, LOG_READ
{% endfor %}
```

---

*Notes compiled for production Linux environments. Always test sudoers changes in a staging environment before applying to production. Use configuration management tools (Ansible, Puppet) to version-control and deploy sudoers rules.*
