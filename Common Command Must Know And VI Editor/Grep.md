
---
# 🧠 GREP (Global Regular Expression Print)

👉 Used to **search text inside files**  
👉 Works with logs, configs, scripts — everywhere

- Grep, short for “**global regular expression print**”, is a command used for searching and matching text patterns in files contained in the regular expressions

---

# 🔥 BASIC SYNTAX

```bash
grep [options] "pattern" file
```

---

# 🟢 1. BASIC SEARCH

```bash
grep "error" file.txt
```

👉 Finds lines containing **error**

---

# 🔵 2. CASE HANDLING

- `-i` → ignore case
    

```bash
grep -i "error" file.txt
```

- `-v` → invert match (NOT match)
    

```bash
grep -v "error" file.txt
```

---

# 🟣 3. COUNT & DISPLAY CONTROL

- `-c` → count matches
    

```bash
grep -c "error" file.txt
```

- `-n` → show line number
    

```bash
grep -n "error" file.txt
```

- `-l` → show file names only
    

```bash
grep -l "error" *.txt
```

---

# 🟡 4. RECURSIVE SEARCH (IMPORTANT 🔥)

- `-r` → search in directories
    

```bash
grep -r "error" /var/log
```

---

# 🔴 5. EXACT WORD MATCH

- `-w` → match whole word
    

```bash
grep -w "root" file.txt
```

---

# ⚫ 6. REGEX POWER (REAL SKILL)

- `.` → any character
    
- `^` → start of line
    
- `$` → end of line
    

```bash
grep "^root" file.txt     # starts with root
grep "error$" file.txt    # ends with error
```

---

# 🟠 7. MULTIPLE PATTERNS

- `-e` → multiple search
    

```bash
grep -e "error" -e "fail" file.txt
```

---

# 🟤 8. EXTENDED REGEX

- `-E` → advanced regex
    

```bash
grep -E "error|fail" file.txt
```

👉 Same as:

```bash
egrep "error|fail" file.txt
```

---

# ⚪ 9. SHOW CONTEXT (VERY USEFUL)

- `-A` → after lines
    
- `-B` → before lines
    
- `-C` → both
    

```bash
grep -A 2 "error" file.txt
grep -B 2 "error" file.txt
grep -C 2 "error" file.txt
```

---

# 🟢 10. ONLY MATCH OUTPUT

- `-o` → print only matched text
    

```bash
grep -o "error" file.txt
```

---

# 🔵 11. FILE FILTERING

- `--include`
    

```bash
grep -r "error" --include="*.log" .
```

- `--exclude`
    

```bash
grep -r "error" --exclude="*.txt" .
```

---

# 🟣 12. IGNORE BINARY FILES

```bash
grep -I "text" file
```

---

# 🟡 13. FIXED STRING (FASTER)

- `-F` → no regex (exact match)
    

```bash
grep -F "error" file.txt
```

---

# 🔥 REAL WORLD EXAMPLES

### 🔍 Find failed login attempts

```bash
grep "Failed password" /var/log/auth.log
```

---

### 🔍 Count errors in logs

```bash
grep -c "error" app.log
```

---

### 🔍 Find root user activity

```bash
grep "^root" /etc/passwd
```

---

### 🔍 Search multiple logs

```bash
grep -r "panic" /var/log
```

---

# 💣 Brutal Truth

- If you only use `grep "word"` → you’re a beginner 🤡
    
- Real skill = **regex + recursive + filtering**
    
- Logs analysis without grep = impossible
    

---

# ⚡ What You SHOULD Practice

Run this:

```bash
grep -rin "error" /var/log
```

Then try:

- Add `-C 3`
    
- Add `--include`
    
- Add regex
    

If you can’t combine options → you don’t know grep yet 😤

---

# 🚀 Interview One-Liner

👉 “grep is used to search patterns in files using regular expressions, with options for recursion, filtering, and context-based output.”

---

# 🧠 Correct Usage of `-n`, `-A`, `-B`

## ✅ `-n` → show line numbers

## ✅ `-A 2` → show **2 lines After**

## ✅ `-B 2` → show **2 lines Before**

👉 These are **separate options**, not a combined `=`

---
## 🔹 After 2 lines + line number

```bash
grep -n -A 2 "error" file.txt
```

---

## 🔹 Before 2 lines + line number

```bash
grep -n -B 2 "error" file.txt
```

---

## 🔹 Shortcut (combined flags)

```bash
grep -nA2 "error" file.txt
grep -nB2 "error" file.txt
```

👉 This works because:

- `-nA2` = `-n` + `-A 2`
    
- NO `=` needed
    

---

# 🔥 Example Output

```bash
grep -nA2 "error" file.txt
```

Output:

```
10:error found
11-next line
12-next line
```

---

# ⚡ Bonus (Most people forget this)

## 🔹 Both before & after

```bash
grep -nC2 "error" file.txt
```

👉 Shows 2 lines before + 2 after

---

# 💣 Brutal Truth

- `=` is **NOT used** here → stop guessing syntax 😑
    
- Either:
    
    - `-A 2` (space)
        
    - or `-A2` (no space)
        

👉 Nothing else

---

# 🚀 What You Should Do

Run this and actually see output:

```bash
grep -nC3 "root" /etc/passwd
```

If you can’t predict output → you’re still guessing, not understanding 😤

---

If you want next level:  
👉 I’ll show you **grep + awk + cut combo (real log analysis skills)** 💻🔥