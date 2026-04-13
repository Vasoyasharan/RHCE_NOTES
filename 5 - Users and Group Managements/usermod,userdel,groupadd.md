Alright — I’m not going to sugarcoat this. You’re doing commands, but your understanding is still **fragmented**. Let’s clean this up properly so you actually _control the system_, not just type random commands. ⚡

---

# 🔹 1. `/etc/login.defs` (System-Level Policy)




This file = **global rules for user accounts**.

👉 It does NOT affect existing users automatically  
👉 It applies when creating NEW users

### Important parameters:

```
PASS_MAX_DAYS   99999   → max days before password expires
PASS_MIN_DAYS   0       → minimum days before changing password
PASS_WARN_AGE   7       → warning before expiry
UID_MIN         1000    → normal user UID start
```

💀 Brutal truth:

- Editing this file and expecting old users to change = WRONG
    
- You MUST use `chage` for existing users
    

---

# 🔹 2. `usermod` (Modify Existing User)

![Image](https://miro.medium.com/1%2AZUW4yA9Q50O66NReHyfWHA.png)

![Image](https://www.scaler.com/topics/images/change-a-username-on-linux-using-the-usermod-command.webp)

![Image](https://www.cyberciti.biz/media/new/images/faq/2007/01/usermod-groupmod-outputs.jpg)

![Image](https://b0olj48ynho64j26.public.blob.vercel-storage.com/oe_Pv_VI_ba9322d6f9.png)

You used it — but not cleanly.

### Common options:

```
usermod -l newname oldname      → rename user
usermod -d /home/user -m user   → change home + move files
usermod -s /bin/bash user       → change shell
usermod -G group user           → set secondary groups
usermod -aG group user          → append group (IMPORTANT)
```

💀 Your mistake:

```
usermod -G group user
```

👉 This **REMOVES all other groups**

✔ Correct:

```
usermod -aG group user
```

---

# 🔹 3. `chage` (Password Aging Control)

This controls `/etc/shadow`.

### Check user:

```
chage -l bob
```

### Set policy:

```
chage -M 40 bob   → max days
chage -m 10 bob   → min days
chage -W 7 bob    → warning days
chage -E 2026-04-10 → account expiry
```

![Image](https://i.sstatic.net/7fPF3.png)

### Your screenshot analysis:

- Initially → `99999` (no expiry)
    
- Later → you changed values manually (bad idea ⚠️)
    

💀 Brutal truth:  
👉 Editing `/etc/shadow` manually = **dangerous + stupid in real environments**

✔ Use:

```
chage
passwd
```

---

# 🔹 4. `userdel -rf tom`

![Image](https://www.cyberciti.biz/media/new/faq/2011/06/Linux-delete-user-command-demo.png)
### Meaning:

```
userdel -r tom   → delete user + home directory
userdel -f tom   → force delete (even if logged in)
```

👉 Combined:

```
userdel -rf tom
```

💀 Reality:

- `-f` can break things (active processes)
    
- Use only if necessary
    

---

# 🔹 5. `groupadd`

![Image](https://www.howtoforge.com/images/command-tutorial/adduser-basic1.png)

### Syntax:

```
groupadd groupname
```

### Options:

```
-g 1005      → specify GID
-r           → system group
```

Example:

```
groupadd -g 3000 devops
```

---

# 🔹 6. `usermod -G` vs `-aG` (CRITICAL ⚠️)

You NEED to understand this or you will break systems.

```
usermod -G devops user
```

👉 adds to group ✔

---

# 🔹 7. `gpasswd`

![Image](https://eu-images.contentstack.com/v3/assets/blt07f68461ccd75245/blt7e48d65e6e9057dc/66507e0ab5494125ac7b61d4/image011_0.png)

### Add single user:

```
gpasswd -a user group
```

### Remove:

```
gpasswd -d user group
```

### Add multiple users:

```
gpasswd -M user1,user2,user3 group
```

💀 Important:

- `-M` overwrites entire group list
    

---

# 🔥 YOUR TERMINAL WORK — REAL ANALYSIS

### Good things you did:

✔ Created user with custom shell  
✔ Renamed user  
✔ Changed shell correctly  
✔ Used `chage`

---

### Mistakes / Weak Areas:

❌ Created python shell user → not practical for real admin  
❌ Manual editing of `/etc/shadow` → risky  
❌ Confused home directory creation  
❌ Didn’t use `-aG` awareness  
❌ No understanding of when configs apply (login.defs vs chage)

---

# ⚡ CLEAN CHEAT SHEET (NO BS)

### Create user

```
useradd -m -s /bin/bash devops
passwd devops
```

### Modify user

```
usermod -l newname oldname
usermod -d /home/newname -m newname
usermod -s /bin/bash newname
```

### Groups

```
groupadd devops
usermod -aG devops user
gpasswd -M user1,user2 devops
```

### Password aging

```
chage -M 40 -m 10 -W 7 user
chage -l user
```

### Delete

```
userdel -r user
```

---

# 🧠 Final Reality Check

You’re at **“command memorization” stage**, not **“system understanding” stage**.

👉 Until you understand:

- `/etc/passwd` vs `/etc/shadow`
    
- login.defs vs chage
    
- group overwrite vs append
    

You will keep making silent mistakes.

---

If you want, next step I’ll:  
👉 Give you **INTERVIEW LEVEL QUESTIONS based on THIS exact topic**  
👉 Or make you do a **real admin lab challenge** (no spoon-feeding) 💀