
---

# ⚡ 1. `uname` (System Info)

```bash
uname -a      # all info
uname -r      # kernel version
uname -n      # hostname
uname -m      # architecture
uname -s      # OS name
```

👉 Use `-a` most of the time

---

# ⚡ 2. `pwd` (Print Working Directory)(Current Directory)

```bash
pwd           # normal
pwd -P        # real path (resolves symlinks)
```

---

# ⚡ 3. `cd` (Change Directory)

```bash
cd /etc       # absolute path
cd ..         # go back
cd ~          # home
cd -          # previous directory
```

👉 `cd -` is underrated 💯

---

# ⚡ 4. `ls` (List Files)

```bash
ls            # basic
ls -l         # long format
ls -a         # hidden files
ls -lh        # human readable size
ls -lt        # sort by time
ls -R         # recursive
```

👉 Best combo:

```bash
ls -lah
```

---

# ⚡ 5. `who` (Logged-in Users)

```bash
who           # basic
who -a        # all info
who am i      # current session
```

---

# ⚡ 6. `w` (User Activity)

```bash
w             # default (best)
w -h          # no header
```

👉 Shows:

- users
    
- what they’re doing
    
- load
    

---

# ⚡ 7. `tree` (Directory Structure)

```bash
tree
tree -L 2     # limit depth
tree -a       # include hidden
tree -d       # only directories
```

---

# ⚡ 8. `tty` (Terminal Info)

```bash
tty           # current terminal
```

👉 No real options needed

---

# ⚡ 9. `uptime` (System Running)

```bash
uptime        # full output
uptime -p     # pretty format
uptime -s     # start time
```

---

# ⚡ 10. `echo $SHELL`

```bash
echo $SHELL   # current shell
echo $HOME    # home dir
echo $PATH    # environment paths
```

---

# ⚡ 11. Paths (IMPORTANT)

## Absolute Path

```bash
cd /home/user1/Desktop
```

👉 Starts from `/`

---

## Relative Path

```bash
cd Desktop
cd ../Downloads
```

👉 Based on current location

---

# ⚡ 12. `cat` (View File)

```bash
cat file.txt          # display
cat -n file.txt       # line numbers
cat -b file.txt       # number non-empty lines
cat -A file.txt       # show hidden chars
```

👉 Don’t use for big files → use `less`

---

# ⚡ 13. `cp` (Copy)

```bash
cp file1 file2              # copy file
cp -r dir1 dir2             # directory copy
cp -v file1 dir/            # verbose
cp -i file1 dir/            # ask before overwrite
cp -p file1 dir/            # preserve attributes
```

👉 Best combo:

```bash
cp -rvp source dest
```

---

# ⚡ 14. `mv` (Move / Rename)

```bash
mv file1 file2              # rename
mv file1 /tmp/              # move
mv -i file1 /tmp/           # ask before overwrite
mv -v file1 /tmp/           # verbose
mv -n file1 /tmp/           # no overwrite
```

---

# 🚨 Brutal Reality

If you:

- only memorize commands ❌
    
- ignore options ❌
    
- don’t practice combinations ❌
    

👉 You’ll fail real tasks instantly

---

# 💯 What Actually Matters

You should be able to do this without thinking:

```bash
cp -rvp project/ backup/
mv -i file.txt /tmp/
ls -lah
cat -n file.txt
```

---

# ⚡ Challenge (Do This Now)

1. Create folder + files
    
2. Copy it
    
3. Rename files
    
4. Show structure
    

---
