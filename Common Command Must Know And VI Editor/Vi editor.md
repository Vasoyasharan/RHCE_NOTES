![](https://cdn.thenewstack.io/media/2020/01/39106fcb-vi.jpg)

---

# 🧠 VI Editor — Commands by Modes

## 🔵 1. NORMAL MODE (Default Mode — Most Important)

👉 You spend **80% of time here**. If you’re weak here, you’re slow. Period.

### 🔹 Movement

- `h` ← left
    
- `l` → right
    
- `j` ↓ down
    
- `k` ↑ up
    
- `w` → next word
    
- `b` → previous word
    
- `0` → start of line
    
- `$` → end of line
    
- `gg` → top of file
    
- `G` → bottom of file
    
- `:n` → go to line n
    

---

### 🔹 Editing

- `x` → delete character
    
- `dd` → delete line
    
- `D` → delete till end of line
    
- `dw` → delete word
    
- `u` → undo
    
- `Ctrl + r` → redo
    

---

### 🔹 Copy / Paste

- `yy` → copy line
    
- `p` → paste below
    
- `P` → paste above
    

---

### 🔹 Replace

- `r` → replace 1 char
    
- `R` → replace multiple chars
    

---

### 🔹 Search

- `/text` → search forward
    
- `?text` → search backward
    
- `n` → next result
    
- `N` → previous
    

---

## 🟢 2. INSERT MODE (Typing Mode)

👉 You ONLY type here. Nothing else.

### 🔹 Enter Insert Mode

- `i` → before cursor
    
- `a` → after cursor
    
- `I` → start of line
    
- `A` → end of line
    
- `o` → new line below
    
- `O` → new line above
    

---

### 🔹 Exit Insert Mode

- `Esc` → back to normal mode (MOST IMPORTANT KEY 🔥)
    

---

## 🟣 3. COMMAND MODE (Last Line Mode)

👉 This is where file control happens.

### 🔹 Save / Quit

- `:w` → save
    
- `:q` → quit
    
- `:wq` → save + quit
    
- `:q!` → force quit
    
- `:w!` → force save
    

---

### 🔹 File Operations

- `:e filename` → open file
    
- `:w filename` → save as new file
    

---

### 🔹 Line Operations

- `:set number` → show line numbers
    
- `:set nonumber` → hide numbers
    

---

### 🔹 Search & Replace (VERY IMPORTANT)

```bash
:%s/old/new/g
```

- Replace all “old” with “new”
    

---

## 🟡 4. VISUAL MODE (Selection Mode)

👉 Most people ignore this → mistake.

### 🔹 Enter Visual Mode

- `v` → character selection
    
- `V` → line selection
    
- `Ctrl + v` → block selection
    

---

### 🔹 Actions in Visual Mode

- `d` → delete selected
    
- `y` → copy selected
    
- `>` → indent
    
- `<` → unindent
    

---

## ⚡ Advanced Combos (This is where skill shows)

- `5dd` → delete 5 lines
    
- `3yy` → copy 3 lines
    
- `10j` → move down 10 lines
    
- `ciw` → change word
    
- `gg=G` → auto-indent entire file
    

---

## 💣 Brutal Truth

- If you only know `i`, `:wq`, you’re a beginner 🤡
    
- Real admins use:
    
    - `dd`, `yy`, `/search`, `:%s`, navigation
        
- Mouse usage = weakness in server environment
    

---

## 🚀 What You Should Do Next

Stop reading. Practice this:

```bash
vi practice.txt
```

Then:

- Write text
    
- Delete lines
    
- Copy/paste
    
- Search something
    
- Replace something
    

If you hesitate → you don’t know vi yet. 😤

---

# 🧠 `:x` vs `:X` in VI (No confusion version)

## ✅ `:x` → Save **and** Quit (ONLY if changed)

- Works like `:wq`, but smarter
    
- It **writes only if file is modified**
    

👉 Example:

```bash
:x
```

✔ If changes → saved + exit  
✔ If no changes → just exit

👉 Compare:

- `:wq` → always writes + exits
    
- `:x` → writes **only if needed**
    

---

## ⚠️ `:X` → Encryption (NOT just password save)

This is where you’re wrong 👇

👉 `:X` does **NOT simply “add password and save”**

👉 It:

- Prompts you to set a password 🔐
    
- Encrypts the file (old weak vi encryption — not secure in real world)
    

---

### 🔹 What actually happens:

When you type:

```bash
:X
```

You’ll see:

```
Enter encryption key:
```

Then:

- File becomes encrypted
    
- You still need to save (`:w`) or quit (`:wq`)
    

---

## ❌ Your misunderstanding (fixed)

You said:

> ":X is password and save"

👉 WRONG ❌

- `:X` = only sets encryption
    
- It does NOT save automatically
    

---

## ⚡ Correct Flow for `:X`

```bash
:X        # set password
:wq       # then save and quit
```

---

## 💣 Brutal Truth

- Nobody serious uses `:X` anymore
    
- It’s outdated and insecure
    
- Use proper tools like:
    
    - `gpg`
        
    - encrypted file systems
        

👉 Using `:X` in real cybersecurity work = rookie move 😬

---

## 🧪 Quick Test (Do it)

1. Create file:
    

```bash
vi test.txt
```

2. Type something → press `Esc`
    
3. Run:
    

```
:X
```

4. Set password → then:
    

```
:wq
```

5. Open again:
    

```bash
vi test.txt
```

👉 It will ask password

---

## 🔥 Final Summary

- `:x` → save & quit (smart) ✅
    
- `:X` → set encryption (not save) ⚠️
    

---

If you want next level:  
👉 I’ll show you **vi tricks used in real Linux admin interviews** (not basic crap) 💻🔥
