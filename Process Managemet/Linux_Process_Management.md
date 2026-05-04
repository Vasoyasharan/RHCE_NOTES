# 🐧 Linux Process Management — Complete Guide

> A beginner-friendly, comprehensive guide to understanding Linux processes, commands, and priorities — with real command outputs!

---

## 🔍 What is a Process?

A **process** is any program that is currently running on your Linux system. Every time you open a terminal, run a command, or start an application — Linux creates a **process** for it.

Each process gets:
- A unique **PID** (Process ID)
- A **PPID** (Parent Process ID — who created it)
- CPU and Memory allocation
- A **state** (running, sleeping, etc.)

---

## 🗂️ Types of Processes

Linux processes fall into **4 main categories**. Don't confuse them — here's a clear breakdown:

### 1. 🖥️ Interactive Processes
- Started **by the user** from a terminal or GUI
- Require **user input** to run (keyboard, mouse)
- Run in the **foreground** by default
- **Example:** `vim file.txt`, `python3 script.py`, `top`

```bash
[root@client1 ~]# vim myfile.txt
# This runs interactively — it waits for YOUR input
```

### 2. ⚙️ Automatic (Batch) Processes
- Run **without user interaction**
- Scheduled tasks — they wait in a **queue** and execute when system load is low
- **Managed by:** `cron`, `at`, `batch`
- **Example:** nightly backup scripts, log rotation

```bash
# Schedule a script to run every day at 2AM using cron
[root@client1 ~]# crontab -e
0 2 * * * /usr/local/bin/backup.sh
```

### 3. 🔄 Daemon Processes
- Run **in the background** — no terminal attached
- Start at **boot time** and keep running silently
- Provide **system services** (networking, logging, web serving)
- TTY column shows `?` (no terminal)
- **Example:** `sshd`, `httpd`, `crond`, `systemd`

```bash
[root@client1 ~]# ps aux | grep sshd
root    1234  0.0  0.0  sshd: /usr/sbin/sshd -D [listener]
#                 ↑ TTY is '?' — no terminal = daemon
```

### 4. 🐚 Shell/Bash Processes
- Started by your **shell (bash, sh, zsh)**
- Run commands you type in the terminal
- Every terminal window = one bash process

```bash
[root@client1 ~]# echo $$    # $$ gives current shell's PID
3512
[root@client1 ~]# ps -p 3512
  PID TTY          TIME CMD
 3512 pts/0    00:00:00 bash
```

---

## 👨‍👩‍👧 Parent & Child Processes

In Linux, **every process has a parent**. When a process creates another process, it becomes the **parent**, and the new one is the **child**.

```
systemd (PID 1)  ← The KING — parent of all processes
    └── sshd (PID 500)        ← daemon started by systemd
         └── bash (PID 1200)  ← your shell (child of sshd)
              └── ps (PID 1500) ← command you ran (child of bash)
```

### 🔑 systemd as the Root Parent

`systemd` is **PID 1** — the first process Linux starts. It is the **ancestor of all other processes**.

```bash
[root@client1 ~]# ps -e | head -5
  PID TTY          TIME CMD
    1 ?        00:00:04 systemd     ← PID 1 — the grandfather!
    2 ?        00:00:00 kthreadd
    3 ?        00:00:00 pool_workqueue_
    4 ?        00:00:00 kworker/R-rcu_g
```

### Viewing Parent-Child Relationships with `pstree`

```bash
[root@client1 ~]# pstree -p
systemd(1)─┬─sshd(500)───bash(1200)───pstree(1501)
           ├─crond(450)
           ├─httpd(600)─┬─httpd(601)
           │             └─httpd(602)
           └─...
```

### Checking PPID (Parent PID)

```bash
[root@client1 ~]# ps -o pid,ppid,cmd
  PID  PPID CMD
 1200   500 bash          ← bash's parent is sshd (500)
 1501  1200 ps -o pid...  ← ps's parent is bash (1200)
```

---

## 🖥️ System Info

### 📊 `cat /proc/meminfo` — Memory Information

This file shows **real-time RAM usage** statistics from the kernel.

```bash
[root@client1 admin]# cat /proc/meminfo
MemTotal:        3709256 kB   ← Total physical RAM (~3.5 GB)
MemFree:         1925480 kB   ← Completely unused RAM
MemAvailable:    2441392 kB   ← RAM available for new programs
Buffers:           58280 kB   ← RAM used for disk read buffers
Cached:           652844 kB   ← RAM used for file caching
SwapCached:            0 kB   ← Data in both swap and RAM
Active:           926060 kB   ← Recently used memory
Inactive:         335008 kB   ← Not recently used (can be reclaimed)
SwapTotal:       4194300 kB   ← Total swap space (~4 GB)
SwapFree:        4194300 kB   ← Swap not used (good!)
Slab:             208564 kB   ← Kernel data structures cache
```

> 💡 **Key Tip:** `MemAvailable` is more useful than `MemFree`. It includes reclaimable cache memory — it's what programs can **actually use**.

### ⚡ `cat /proc/cpuinfo` — CPU Information

This file shows detailed info about your CPU (one block per logical core).

```bash
[root@client1 admin]# cat /proc/cpuinfo
processor       : 0              ← Logical CPU number (starts at 0)
vendor_id       : GenuineIntel   ← CPU manufacturer
cpu family      : 6              ← Intel 6th gen architecture
model           : 154
model name      : 12th Gen Intel(R) Core(TM) i5-1240P   ← Full CPU name
stepping        : 3              ← CPU revision/revision level
cpu MHz         : 2112.000       ← Current clock speed
cache size      : 12288 KB       ← L3 cache size (12 MB)
physical id     : 0              ← Physical socket number
siblings        : 4              ← Logical CPUs on this physical chip
core id         : 0              ← Core number within the physical chip
cpu cores       : 4              ← Physical cores on this chip
fpu             : yes            ← Has floating point unit
```

> 💡 **Tip:** Count total logical CPUs with: `nproc` or `grep -c processor /proc/cpuinfo`

---

## 🔄 Process States

Every process is always in **one of these states**. Think of it like traffic lights:

| State | Symbol | Meaning |
|-------|--------|---------|
| 🟢 Running | `R` | Actively using CPU right now |
| 🟡 Sleeping (Interruptible) | `S` | Waiting, can be woken by a signal |
| 🟠 Waiting (Uninterruptible) | `D` | Waiting for hardware I/O — cannot be killed! |
| 🔴 Stopped | `T` | Paused (Ctrl+Z) or by debugger |
| 💀 Zombie | `Z` | Finished but parent hasn't acknowledged it yet |

### Detailed Explanation:

#### 🟢 R — Running
The process is **actively executing on the CPU**. Only one process runs per CPU core at any instant.

```bash
# See running processes right now
[root@client1 ~]# ps aux | awk '$8 == "R"'
USER       PID %CPU %MEM    VSZ   RSS TTY  STAT START   TIME COMMAND
root      3766  0.3  0.1 225944  4444 pts/0 R+  07:02  0:00 top
```

#### 🟡 S — Sleeping (Interruptible)
The process is **waiting for something** (keyboard input, network data, timer). It will **wake up** when what it's waiting for arrives.

```bash
# Most background processes are sleeping
[root@client1 ~]# ps aux | awk '$8 ~ /^S/'
root         1  0.1  0.5 176024 18688 ? Ss  07:02  0:04 /usr/lib/systemd/systemd
```

#### 🟠 D — Waiting (Uninterruptible Sleep)
Process is **waiting for disk or hardware I/O**. You **cannot kill** this process with `kill -9`! It will wake up when the I/O finishes.

```bash
# Usually seen briefly during heavy disk activity
[root@client1 ~]# ps aux | awk '$8 == "D"'
# (Typically appears briefly during large file copies or disk stress)
```

#### 🔴 T — Stopped
Process has been **paused**. This happens when you press `Ctrl+Z` in the terminal or a debugger stops it.

```bash
[root@client1 ~]# sleep 999    # start a process
^Z                              # Press Ctrl+Z to stop it
[1]+  Stopped   sleep 999

[root@client1 ~]# ps aux | grep sleep
root   4100  0.0  0.0  ... T  ... sleep 999   ← State is T (stopped)

[root@client1 ~]# fg           # Resume it with fg (foreground)
```

#### 💀 Z — Zombie
The process has **finished executing** but its parent hasn't called `wait()` to collect its exit status. The process is dead but its entry remains in the process table.

```bash
# Zombies show as 'Z' in STAT column and '<defunct>' in COMMAND
[root@client1 ~]# ps aux | grep defunct
root   5001  0.0  0.0    0    0 ?  Z  07:05  0:00 [myapp] <defunct>
```

> ⚠️ **Note:** A few zombies are harmless. Many zombies = buggy parent process not cleaning up its children.

---

## 🔧 The `ps` Command

`ps` = **Process Status** — your go-to tool for inspecting processes.

### `ps -e` — Every Process (Simple)

Shows **all processes** running on the system in a simple format.

```bash
[root@client1 admin]# ps -e
  PID TTY          TIME CMD
    1 ?        00:00:04 systemd
    2 ?        00:00:00 kthreadd
    3 ?        00:00:00 pool_workqueue_
    4 ?        00:00:00 kworker/R-rcu_g
    5 ?        00:00:00 kworker/R-sync_
   16 ?        00:00:00 ksoftirqd/0
   17 ?        00:00:00 rcu_preempt
   20 ?        00:00:00 migration/0
   21 ?        00:00:00 idle_inject/0
...
 3739 pts/0    00:00:00 ps
```

**Columns:**
- `PID` — Process ID
- `TTY` — Terminal (`?` = no terminal = daemon/kernel thread)
- `TIME` — Total CPU time used
- `CMD` — Command name

---

### `ps aux` — Detailed Snapshot (BSD Style)

The most **commonly used** ps command. Shows everything about all processes.

```bash
[root@client1 admin]# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY  STAT START   TIME COMMAND
root         1  0.1  0.5 176024 18688 ?    Ss   07:02   0:04 /usr/lib/systemd/systemd
root         2  0.0  0.0      0     0 ?    S    07:02   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?    S    07:02   0:00 [pool_workqueue_]
root         4  0.0  0.0      0     0 ?    I<   07:02   0:00 [kworker/R-rcu_g]
admin     2419  0.3  1.1 388948 40768 ?    Ss   07:02   0:05 vmtoolsd
root      3766  0.3  0.1 225944  4444 pts/0 R+  --     0:00 top
```

---

### `ps -eo user,comm` — Custom Output Format

Show only the columns **you choose**.

```bash
[root@client1 admin]# ps -eo user,comm
USER     COMMAND
root     systemd
root     kthreadd
root     pool_workqueue_
root     kworker/R-rcu_g
root     kworker/R-sync_
root     ksoftirqd/0
root     rcu_preempt
root     migration/0
admin    vmtoolsd
root     top
```

> 💡 You can customize any columns: `ps -eo pid,ppid,user,%cpu,%mem,stat,comm`

---

## 📋 ps Column Reference

Here's what **every column means** in `ps aux`:

| Column | Full Name | What it Means | Example |
|--------|-----------|---------------|---------|
| `USER` | Username | Who owns/started this process | `root`, `admin` |
| `PID` | Process ID | Unique number for this process | `2419` |
| `%CPU` | CPU Usage | % of CPU this process is using right now | `0.3` |
| `%MEM` | Memory Usage | % of total RAM this process uses | `1.1` |
| `VSZ` | Virtual Memory Size | Total virtual memory (including not loaded) in KB | `388948` |
| `RSS` | Resident Set Size | **Actual RAM** currently used in KB | `40768` |
| `TTY` | Terminal | Which terminal it's attached to (`?` = none) | `pts/0`, `?` |
| `STAT` | State | Process state code (see Process States) | `S`, `R`, `Z` |
| `START` | Start Time | When the process started | `07:02` |
| `TIME` | CPU Time | Total CPU time consumed | `0:05` |
| `COMMAND` | Command | Full command with arguments | `/usr/sbin/sshd -D` |

### STAT Column Extra Characters:

| Extra | Meaning |
|-------|---------|
| `s` | Session leader (e.g., bash, sshd) |
| `+` | In the foreground process group |
| `<` | High priority (not nice to others) |
| `N` | Low priority (nice) |
| `l` | Multi-threaded |
| `I` | Idle kernel thread |

---

## 🛠️ All ps Options Reference

### Selection Options

| Option | Description | Example |
|--------|-------------|---------|
| `-e` / `-A` | Show ALL processes | `ps -e` |
| `-a` | All processes with a terminal (excludes session leaders) | `ps -a` |
| `a` | All processes including other users' (BSD) | `ps aux` |
| `x` | Include processes without a terminal | `ps aux` |
| `-u user` | Processes owned by a specific user | `ps -u admin` |
| `-p PID` | Show specific PID | `ps -p 1234` |
| `--ppid PID` | Show children of a PID | `ps --ppid 1` |
| `-C name` | Filter by command name | `ps -C sshd` |

### Output Format Options

| Option | Description | Example |
|--------|-------------|---------|
| `u` | User-oriented format (BSD) — shows %CPU, %MEM | `ps aux` |
| `-f` | Full format — shows PPID, UID | `ps -ef` |
| `-l` | Long format — shows priority, nice | `ps -el` |
| `j` | Jobs format — shows PGID, SID | `ps -j` |
| `-o` | Custom output columns | `ps -eo pid,comm,%cpu` |
| `--forest` | Show process tree (ASCII art) | `ps --forest` |

### Sorting Options

| Option | Description | Example |
|--------|-------------|---------|
| `--sort=-%cpu` | Sort by CPU (highest first) | `ps aux --sort=-%cpu` |
| `--sort=-%mem` | Sort by Memory (highest first) | `ps aux --sort=-%mem` |
| `--sort=pid` | Sort by PID | `ps -e --sort=pid` |
| `k -vsz` | Sort by Virtual memory descending | `ps aux k -vsz` |

### Useful Real-World Combinations

```bash
# Top 5 CPU-hungry processes
ps aux --sort=-%cpu | head -6

# Top 5 memory-hungry processes
ps aux --sort=-%mem | head -6

# All processes for a specific user
ps -u admin -f

# Show process tree
ps --forest -e

# Show process with its parent
ps -ef | grep apache

# Custom columns: PID, Parent PID, User, CPU, Memory, Command
ps -eo pid,ppid,user,%cpu,%mem,comm

# Find a specific process
ps -C nginx
ps -e | grep nginx

# Show threads of a process
ps -eLf | grep 2419
```

---

## ⚖️ Process Priority & `nice`

### What is Priority?

Linux decides **which process gets CPU time** using a priority number. Lower number = higher priority = gets more CPU.

```
Priority Scale:
-20 ←————————————— 0 ————————————→ +19
Highest Priority   Default    Lowest Priority
(Greedy)                      (Most Polite)
```

### What is `nice`?

`nice` is a **"politeness" value** you set when starting a process. It tells the kernel: *"This process is OK with getting less CPU time."*

- **Range:** -20 (least nice / most greedy) to +19 (most nice / least greedy)
- **Default:** 0
- **Only root** can set negative nice values (increase priority)

### How Priority & Nice Relate

```
Priority (PR) = Base Priority (20) + Nice Value (NI)

Nice = 0  →  PR = 20  (normal)
Nice = 19 →  PR = 39  (very low priority)
Nice = -20 → PR = 0   (very high priority)
```

### `nice` — Start a Process with a Priority

```bash
# Start sleep with nice value of 19 (lowest priority)
[root@client1 ~]# nice -n 19 sleep 1000&
[1] 4234

# Verify its nice value
[root@client1 ~]# ps -ely | grep sleep
S    0   4234   2818  0  99  19  1952 55241 hrtime pts/0   00:00:00 sleep
#                              ↑  ↑
#                              PR NI (nice = 19!)
```

### `renice` — Change Priority of a Running Process

```bash
# Change PID 4234's nice value to 10
[root@client1 ~]# renice -n 10 -p 4234
4234 (process ID) old priority 19, new priority 10

# Change all processes of a user
[root@client1 ~]# renice -n 5 -u admin
```

### `pgrep` — Find Process by Name

```bash
# Find PID of sleep
[root@client1 ~]# pgrep sleep
4234

# Find PID of a specific PID (confirm it exists)
[root@client1 ~]# pgrep 4234
4234
```

### Viewing Priority in `top`

From the `top` output (Image 4):

```
Tasks: 312 total,   1 running, 311 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.7 us,  0.2 sy,  0.0 ni, 98.8 id,  0.0 wa

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 2419 admin     20   0  388948  40768  33452 S   0.3   1.1   0:05.95 vmtoolsd
 3766 root      20   0  225944   4444   3472 R   0.3   0.1   0:00.09 top
    1 root      20   0  176024  18688  11188 S   0.0   0.5   0:04.15 systemd
```

| Column | Meaning |
|--------|---------|
| `PR` | Actual kernel priority (20 = default, lower is higher priority) |
| `NI` | Nice value set by user |

> 💡 `rt` in the PR column means **Real-Time** priority — higher than everything else.

### Summary: nice Cheat Sheet

```bash
# Run a program at lowest priority (background jobs, backups)
nice -n 19 ./backup.sh

# Run at high priority (only root can use negative values)
sudo nice -n -10 ./important_service

# Change priority of running process
renice -n 5 -p 1234       # by PID
renice -n 5 -u username    # all processes of a user

# Find processes with their nice values
ps -eo pid,ni,comm | sort -k2 -n

# Check nice value of current shell
nice
```

---

## 🧩 Quick Reference Summary

```
PROCESS TYPES:
  Interactive  → User runs it, needs input (vim, python)
  Automatic    → Scheduled, no input needed (cron jobs)
  Daemon       → Background service, starts at boot (sshd, httpd)
  Shell/Bash   → Your terminal commands

PROCESS STATES:
  R = Running   (on CPU now)
  S = Sleeping  (waiting, can be woken)
  D = Waiting   (I/O wait, can't be killed)
  T = Stopped   (Ctrl+Z paused)
  Z = Zombie    (dead but not cleaned up)

KEY COMMANDS:
  ps -e              → All processes (simple)
  ps aux             → All processes (detailed)
  ps -ef             → All processes (with PPID)
  ps -eo pid,comm    → Custom columns
  ps --forest        → Tree view
  nice -n 19 cmd     → Start with low priority
  renice -n 5 -p PID → Change running process priority
  pgrep name         → Find PID by name
  cat /proc/meminfo  → RAM info
  cat /proc/cpuinfo  → CPU info
```

---

*📝 Notes based on live system: Red Hat / CentOS Linux | CPU: Intel i5-1240P | RAM: ~3.5 GB | Swap: 4 GB*
