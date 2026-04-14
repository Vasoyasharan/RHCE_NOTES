# 🐧 Red Hat Linux — User Management

> **RHCSA Study Reference** | Complete guide to managing users and groups in Red Hat Enterprise Linux

---

## 1. Overview & Key Files

Every process and file in RHEL is owned by a user. User management controls **who can log in**, **what they can do**, and **how long their passwords last**.

|File|Purpose|
|---|---|
|`/etc/passwd`|User account info: username, UID, GID, home dir, shell|
|`/etc/shadow`|Encrypted passwords + password aging policy|
|`/etc/group`|Group names, GIDs, and member lists|
|`/etc/gshadow`|Encrypted group passwords and group admins|
|`/etc/login.defs`|Default policy for ALL new users (UID range, password aging)|
|`/etc/skel/`|Template files copied into every new home directory|

> 💡 **Key concept:** `/etc/passwd` is readable by everyone. `/etc/shadow` is readable only by **root** — that's where the real password hashes live.

---

## 2. /etc/passwd — User Database

Every line = one user account. 7 fields separated by colons `:`

```
username:password:UID:GID:GECOS:home_directory:shell
bob:x:1002:1002:Bob Smith:/home/bob:/bin/bash
```

|Field|Name|Example|Meaning|
|---|---|---|---|
|1|username|`bob`|Login name|
|2|password|`x`|`x` = hash stored in `/etc/shadow`|
|3|UID|`1002`|User ID number|
|4|GID|`1002`|Primary group ID|
|5|GECOS|`Bob Smith`|Full name / comment|
|6|home|`/home/bob`|Home directory path|
|7|shell|`/bin/bash`|Login shell|

### UID Ranges

|Range|Type|
|---|---|
|`0`|root (superuser)|
|`1–200`|Static system accounts (reserved by RHEL)|
|`201–999`|Dynamic system accounts (created by packages)|
|`1000+`|Regular (human) users|

---

## 3. /etc/shadow — Password Storage

Only **root** can read this file. 9 fields separated by colons `:`

```
bob:$6$rounds=100000$abc...xyz:20550:10:40:7:1:20550:
```

|Field|Name|Meaning|
|---|---|---|
|1|username|Login name|
|2|password hash|`$6$` = SHA-512. `!` or `*` = account locked|
|3|lastchange|Days since **Jan 1, 1970** when password was last changed|
|4|minage|Min days before user **can** change password (`chage -m`)|
|5|maxage|Max days password is valid (`chage -M`)|
|6|warn|Days of warning before expiry (`chage -W`)|
|7|inactive|Grace period (days) after expiry before locking (`chage -I`)|
|8|expire|Absolute account expiry in days from epoch (`chage -E`)|
|9|reserved|Unused|

### Password Hash Algorithms

|Prefix|Algorithm|
|---|---|
|`$1$`|MD5 (old, weak)|
|`$5$`|SHA-256|
|`$6$`|SHA-512 (default in RHEL)|
|`!`|Account locked|
|`*`|No password set / disabled|

---

## 4. /etc/group & /etc/gshadow

### /etc/group format

```
groupname:password:GID:member1,member2
devteam:x:2100:alice,bob,devops
```

|Field|Meaning|
|---|---|
|1|Group name|
|2|`x` = password in /etc/gshadow|
|3|GID (Group ID)|
|4|Comma-separated supplementary members|

> ⚠️ A user's **primary group** is set in `/etc/passwd` (field 4) — they do NOT appear in that group's member list in `/etc/group`. Only **supplementary** group members appear here.

---

## 5. /etc/login.defs — Default Policy

Controls defaults applied **only to new users**. Does NOT affect existing users.

```bash
# View the file
grep -v '^#' /etc/login.defs | grep -v '^$'
```

|Setting|Default|Meaning|
|---|---|---|
|`PASS_MAX_DAYS`|`99999`|Max days before password must change|
|`PASS_MIN_DAYS`|`0`|Min days between password changes|
|`PASS_WARN_AGE`|`7`|Warning days before expiry|
|`PASS_MIN_LEN`|`5`|Minimum password length|
|`UID_MIN`|`1000`|Lowest UID for regular users|
|`UID_MAX`|`60000`|Highest UID for regular users|
|`SYS_UID_MIN`|`201`|Lowest UID for system accounts|
|`GID_MIN`|`1000`|Lowest GID for regular groups|
|`CREATE_HOME`|`yes`|Auto-create home directory|
|`UMASK`|`077`|Default permission mask for new files|
|`ENCRYPT_METHOD`|`SHA512`|Password hashing algorithm|

> 💡 To apply new defaults to existing users, use `chage` or `usermod` — editing `login.defs` only affects future `useradd` calls.

---

## 6. /etc/skel — Skeleton Directory

When a new home directory is created, all files in `/etc/skel/` are **copied** into it automatically.

```bash
ls -la /etc/skel/
# .bash_logout   .bash_profile   .bashrc
```

### Use Cases

- Add a custom `.vimrc` → every new user gets it
- Add a `README.txt` with company policies
- Pre-configure shell aliases in `.bashrc`

```bash
# Example: add a custom alias for all future users
echo "alias ll='ls -lah'" >> /etc/skel/.bashrc
```

---

## 7. useradd — Create Users

Creates the user in `/etc/passwd`, `/etc/shadow`, `/etc/group`, and optionally creates a home directory.

### Syntax

```bash
useradd [options] <username>
```

### All Options

|Option|Example|Meaning|
|---|---|---|
|_(none)_|`useradd alice`|Create with all defaults from `/etc/login.defs`|
|`-s`|`-s /bin/bash`|Set login shell|
|`-d`|`-d /home/mydir`|Set custom home directory path|
|`-m`|`-m`|Create the home directory|
|`-M`|`-M`|Do NOT create home directory|
|`-u`|`-u 1500`|Set specific UID|
|`-g`|`-g devteam`|Set primary group (must exist)|
|`-G`|`-G wheel,docker`|Set supplementary groups|
|`-c`|`-c 'Full Name'`|Set GECOS / full name comment|
|`-e`|`-e 2026-12-31`|Set account expiry date (YYYY-MM-DD)|
|`-f`|`-f 30`|Inactive days after expiry before locking|
|`-r`|`-r`|Create a system account (UID < 1000)|
|`-p`|`-p 'hash'`|Set pre-hashed password (use `passwd` instead)|
|`-k`|`-k /etc/skel`|Specify skeleton directory|

### Examples

```bash
# Basic user with bash shell
useradd -s /bin/bash -m alice

# User with custom UID, primary group, supplementary groups, and full name
useradd -u 1500 -g devteam -G wheel,docker -c 'Alice Smith' alice

# Service account (no login shell, no home directory)
useradd -r -s /sbin/nologin -M apacheservice

# From your lab screenshots:
useradd -s /bin/python3 python        # create user 'python' with python3 shell
```

> ⚠️ Always set a password immediately after creating a user:
> 
> ```bash
> passwd alice
> ```

---

## 8. passwd — Manage Passwords

Sets or changes a user's password. **Root** can change any user's password. Regular users can only change their own.

### Syntax

```bash
passwd [options] [username]
```

### All Options

| Option       | Example           | Meaning                                                 |
| ------------ | ----------------- | ------------------------------------------------------- |
| _(none)_     | `passwd`          | Change YOUR OWN password                                |
| _(username)_ | `passwd alice`    | Change alice's password (root only)                     |
| `-l`         | `passwd -l alice` | **Lock** alice's account (prepend `!` to hash)          |
| `-u`         | `passwd -u alice` | **Unlock** alice's account (remove `!`)                 |
| `-S`         | `passwd -S alice` | Show password status                                    |

### Password Status Output

```bash
passwd -S alice
# alice PS 2026-04-07 10 40 7 -1
```

|Field|Meaning|
|---|---|
|`PS`|Password Set (normal)|
|`LK`|Locked (`!` in shadow)|
|`NP`|No Password set|

> ⚠️ **BAD PASSWORD warning:** If a password is shorter than 8 characters you'll see `BAD PASSWORD: The password is shorter than 8 characters` — but **root can still set it anyway**.

---

## 9. usermod — Modify Users

Modifies an existing user's account. Edits `/etc/passwd`, `/etc/shadow`, and `/etc/group`.

### Syntax

```bash
usermod [options] <username>
```

### All Options

|Option|Example|Meaning|
|---|---|---|
|`-l`|`-l newname oldname`|Rename login name (not home dir)|
|`-s`|`-s /bin/bash alice`|Change login shell|
|`-d`|`-d /new/home alice`|Change home dir path (does NOT move files)|
|`-d -m`|`-d /new/home -m alice`|Change home dir AND move existing files|
|`-u`|`-u 1600 alice`|Change UID|
|`-g`|`-g devteam alice`|Change primary group|
|`-G`|`-G wheel alice`|Set supplementary groups (**REPLACES** existing!)|
|`-aG`|`-aG wheel alice`|**Append** to supplementary groups (safe!)|
|`-c`|`-c 'Alice Smith' alice`|Change GECOS / full name|
|`-e`|`-e 2027-01-01 alice`|Set account expiry date|
|`-f`|`-f 30 alice`|Set inactive days after expiry|
|`-L`|`-L alice`|Lock account (adds `!` to shadow)|
|`-U`|`-U alice`|Unlock account (removes `!`)|
|`-p`|`-p 'hash' alice`|Set pre-hashed password|

### Examples from Lab Screenshots

```bash
useradd -s /bin/python3 python        # create user named 'python' with python3 shell
usermod -l devops python              # rename user 'python' → 'devops'
usermod -d /home/devops devops        # update home directory path
usermod -s /bin/bash devops           # change shell from python3 → bash
```

> 🚨 **CRITICAL — -G vs -aG:**
> 
> ```bash
> usermod -G docker alice      # ❌ REPLACES all groups — alice now ONLY in docker!
> usermod -aG docker alice     # ✅ APPENDS — alice keeps existing groups + adds docker
> ```

---

## 10. userdel — Delete Users

Removes a user account. Be **extremely careful** — file deletion is permanent.

### Syntax

```bash
userdel [options] <username>
```

### Options

|Option|Example|Meaning|
|---|---|---|
|_(none)_|`userdel alice`|Remove account only. Home dir `/home/alice` stays on disk (orphaned).|
|`-r`|`userdel -r alice`|Remove account + home directory + mail spool|
|`-f`|`userdel -f alice`|Force delete even if user is currently logged in|
|`-rf`|`userdel -rf alice`|Force delete + remove home dir + mail. **IRREVERSIBLE.**|

> 💣 **DANGER:** `userdel -rf alice` permanently destroys the home directory and all files. **No undo.** Always double-check the username!

### After Deleting a User — Find Orphaned Files

```bash
# Find files owned by a UID that no longer exists
find / -nouser 2>/dev/null
find / -nogroup 2>/dev/null

# Find both at once
find / -nouser -o -nogroup 2>/dev/null
```

---

## 11. chage — Password Aging

Manages per-user password aging policy stored in `/etc/shadow`. More granular than `/etc/login.defs`.

### Syntax

```bash
chage [options] <username>
```

### All Options

|Option|Example|Meaning|
|---|---|---|
|`-l`|`chage -l alice`|**List** all aging info (view only)|
|`-M`|`chage -M 40 alice`|Maximum days between password changes|
|`-m`|`chage -m 10 alice`|Minimum days before can change password|
|`-W`|`chage -W 7 alice`|Warning days before expiry|
|`-I`|`chage -I 1 alice`|Inactive grace period after expiry before account locked|
|`-E`|`chage -E 2026-12-31 alice`|Absolute account expiry date (YYYY-MM-DD)|
|`-E -1`|`chage -E -1 alice`|Remove account expiry (never expires)|
|`-d 0`|`chage -d 0 alice`|Force password change at **next login**|
|`-d -1`|`chage -d -1 alice`|Remove password aging (disable aging entirely)|
|_(interactive)_|`chage alice`|Enter interactive mode with prompts|

### View Password Aging Info

```bash
chage -l bob
```

```
Last password change          : Apr 07, 2026
Password expires              : May 17, 2026
Password inactive             : Apr 09, 2026
Account expires               : Mar 15, 2026
Minimum number of days        : 10
Maximum number of days        : 40
Number of days of warning     : 7
```

### chage vs /etc/shadow Fields

|chage option|Shadow field #|Meaning|
|---|---|---|
|`-d` (lastchange)|3|Days since epoch of last change|
|`-m`|4|Min days|
|`-M`|5|Max days|
|`-W`|6|Warn days|
|`-I`|7|Inactive days|
|`-E`|8|Account expiry|

> 💡 **Force password reset on first login:**
> 
> ```bash
> chage -d 0 alice
> ```
> 
> This sets "last changed" to day 0 (Jan 1, 1970), making the password immediately expired.

---

## 12. groupadd — Create Groups

Groups allow multiple users to share file access and permissions.

### Syntax

```bash
groupadd [options] <group-name>
```

### All Options

|Option|Example|Meaning|
|---|---|---|
|_(none)_|`groupadd devteam`|Create group with next available GID|
|`-g`|`-g 2100 devteam`|Set a specific GID manually|
|`-r`|`-r sysgroup`|Create a system group (GID < 1000)|
|`-f`|`-f devteam`|Force — no error if group already exists|
|`-o`|`-o -g 1002 grp`|Allow non-unique (duplicate) GID|
|`-K`|`-K GID_MIN=500`|Override `/etc/login.defs` value|

### Examples

```bash
groupadd devteam               # auto GID
groupadd -g 2100 devteam       # specific GID
groupadd -r sysgroup           # system group
```

---

## 13. groupmod — Modify Groups

```bash
groupmod [options] <group-name>
```

|Option|Example|Meaning|
|---|---|---|
|`-n`|`groupmod -n newteam devteam`|Rename the group|
|`-g`|`groupmod -g 2200 devteam`|Change the GID|
|`-o`|`groupmod -o -g 1002 devteam`|Allow duplicate GID|

### Examples

```bash
groupmod -n backend devteam    # rename devteam → backend
groupmod -g 2500 backend       # change GID to 2500
```

---

## 14. groupdel — Delete Groups

```bash
groupdel <group-name>
```

> ⚠️ You **cannot** delete a group that is the **primary group** of any user. Reassign those users first with `usermod -g newgroup username`.

---

## 15. gpasswd — Group Membership Management

The `gpasswd` command manages group passwords and member lists.

### Syntax

```bash
gpasswd [options] <group-name>
```

### All Options

|Option|Example|Meaning|
|---|---|---|
|_(none)_|`gpasswd devteam`|Set a password for the group|
|`-a`|`gpasswd -a alice devteam`|**Add** alice to devteam (safe — keeps existing members)|
|`-d`|`gpasswd -d alice devteam`|**Remove** alice from devteam|
|`-M`|`gpasswd -M alice,bob devteam`|Set **full member list** (replaces existing!)|
|`-A`|`gpasswd -A alice devteam`|Make alice a **group administrator**|
|`-r`|`gpasswd -r devteam`|Remove group password|
|`-R`|`gpasswd -R devteam`|Restrict — only members can use `newgrp`|

---

## 16. su — Switch User

Allows you to switch to another user account without logging out.

### Syntax

```bash
su [options] [username]
```

### Options

|Command|Meaning|
|---|---|
|`su alice`|Switch to alice (keeps current `$PATH` and environment)|
|`su - alice`|Switch to alice with **full login shell** (loads alice's environment)|
|`su -`|Switch to root with full login shell (same as `su - root`)|
|`su -c 'command' alice`|Run one command as alice without fully switching|
|`exit`|Return to previous user|

> 💡 **Always use `su -` (with the dash)** to get the proper login environment. Without the dash, `$PATH` and other variables may not be set correctly.

---
## 18. Login Shells

The login shell is the program started when a user logs in. Set in field 7 of `/etc/passwd`.

### Common Shells

| Shell   | Path            | Notes                                               |
| ------- | --------------- | --------------------------------------------------- |
| Bash    | `/bin/bash`     | Default for most users in RHEL                      |
| Sh      | `/bin/sh`       | Basic POSIX shell                                   |
| Zsh     | `/bin/zsh`      | Must be installed separately                        |
| Python  | `/bin/python3`  | Can use Python as shell (seen in your lab!)         |
| nologin | `/sbin/nologin` | **Blocks interactive login** — for service accounts |
| false   | `/bin/false`    | Blocks login and returns failure exit code          |

### Changing a User's Shell

```bash
usermod -s /bin/bash alice         # using usermod
chsh -s /bin/bash alice            # using chsh (change shell)
```

### Viewing Available Shells

```bash
cat /etc/shells
```

> 🔒 **Security best practice:** Service accounts (like `apache`, `mysql`, `nginx`) should always use `/sbin/nologin`. This prevents someone from using that account to get an interactive shell.

---

## 19. Account Locking & Security

### Locking and Unlocking

|Command|Meaning|
|---|---|
|`usermod -L alice`|Lock alice (adds `!` before hash in shadow)|
|`usermod -U alice`|Unlock alice (removes `!`)|
|`passwd -l alice`|Lock alice's password (same as usermod -L)|
|`passwd -u alice`|Unlock alice (same as usermod -U)|
|`chage -E 0 alice`|Expire account immediately (day 0 = Jan 1, 1970)|
|`chage -E -1 alice`|Remove account expiry (never expires)|

> ⚠️ **Locking** (`usermod -L`) only blocks **password authentication**. A user with SSH keys may still log in via SSH. For **full lockout**, combine account lock + account expiry:
> 
> ```bash
> usermod -L alice
> chage -E 0 alice
> ```

### Password Policy Best Practices

|Policy|Command|
|---|---|
|Force 90-day password rotation|`chage -M 90 alice`|
|Warn 14 days before expiry|`chage -W 14 alice`|
|Lock account 7 days after expiry|`chage -I 7 alice`|
|Force reset on first login|`chage -d 0 alice`|
|Min 1 day between changes|`chage -m 1 alice`|
|Set system-wide defaults|Edit `/etc/login.defs`|

### Checking Password Status

```bash
passwd -S alice
# alice PS 2026-04-07 10 90 14 7

grep ^alice /etc/shadow    # view raw shadow entry
chage -l alice             # view human-readable aging info
```

---

## 20. Viewing User & Group Info

### Read-Only Inspection Commands

|Command|Meaning|
|---|---|
|`id alice`|Show UID, primary GID, and all group memberships|
|`id`|Show your own UID/GID/groups|
|`groups alice`|List all groups alice belongs to|
|`whoami`|Show your current username|
|`who`|Show all currently logged-in users|
|`w`|Show logged-in users and what they're running|
|`last`|Show login history from `/var/log/wtmp`|
|`lastlog`|Show last login time for all users|
|`getent passwd alice`|Look up alice in passwd (works with LDAP/NIS too)|
|`getent group devteam`|Look up devteam in group database|
|`finger alice`|Show user info (if finger package installed)|

### Verifying Changes — Always Do This!

```bash
tail /etc/passwd              # check last user entries
tail /etc/shadow              # check shadow file
tail /etc/group               # check group entries
grep ^alice /etc/passwd       # check specific user
grep ^alice /etc/shadow       # check specific user's shadow entry
grep ^devteam /etc/group      # check specific group
ll /home/                     # verify home dirs and ownership
id alice                      # verify UID/GID/groups
chage -l alice                # verify password aging policy
```

---

## 21. Quick Reference Cheat Sheet

### User Lifecycle

```bash
# Create
useradd -s /bin/bash -m alice
passwd alice

# Modify
usermod -aG wheel alice          # add to group (SAFE)
usermod -s /bin/bash alice       # change shell
usermod -l newname alice         # rename user
usermod -d /new/home -m alice    # change + move home dir

# Password aging
chage -M 90 -m 1 -W 14 -I 7 alice
chage -d 0 alice                 # force reset on next login

# Lock / Unlock
usermod -L alice                 # lock
usermod -U alice                 # unlock

# Delete
userdel -r alice                 # remove user + home dir
```

### Group Lifecycle

```bash
# Create
groupadd devteam
groupadd -g 2100 devteam         # specific GID

# Add/remove members
usermod -aG devteam alice        # add (SAFE)
gpasswd -a alice devteam         # add (SAFE, same result)
gpasswd -d alice devteam         # remove

# Set full member list (REPLACES)
gpasswd -M alice,bob,devops devteam

# Rename / change GID
groupmod -n backend devteam
groupmod -g 2500 backend

# Delete
groupdel backend
```

### Dangerous vs Safe Commands

|❌ Dangerous|✅ Safe Alternative|
|---|---|
|`usermod -G docker alice`|`usermod -aG docker alice`|
|`gpasswd -M alice devteam`|`gpasswd -a alice devteam`|
|`userdel -rf alice`|`userdel -r alice` (still check first!)|
|Direct edit of `/etc/sudoers`|`visudo`|
|Direct edit of `/etc/shadow`|`chage` commands|

---

## 📝 Notes from Lab Practice

Based on the terminal screenshots, here are key things observed:

```bash
# From Image 1 — Full user rename workflow:
which python3                          # /bin/python3
useradd -s /bin/python3 python         # create user with python shell
usermod -l devops python               # rename: python → devops
usermod -d /home/devops devops         # set new home path
usermod -s /bin/bash devops            # change shell → bash
passwd devops                          # set password
mkdir /home/devops                     # create home dir manually
tail /etc/passwd                       # verify

# From Image 2 — /etc/shadow structure visible:
# bob entry highlighted: sha-512 hash + aging fields all visible

# From Images 3 & 4 — chage in action:
chage -l bob                           # view aging before
# nano /etc/shadow                     # manually edited fields
chage -l bob                           # verify fields changed correctly
# Sequence shows: lastchange, min, max, warn, inactive, expiry all modified
```

---

## 🔗 Related Files & Commands

```
/etc/passwd         /etc/shadow         /etc/group          /etc/gshadow
/etc/login.defs     /etc/skel/          /etc/sudoers        /etc/shells

useradd   usermod   userdel   passwd   chage
groupadd  groupmod  groupdel  gpasswd
su        sudo      visudo    id       groups   who   last
```

---

_Red Hat Enterprise Linux — User Management Reference | RHCSA Study Material | 2026_
