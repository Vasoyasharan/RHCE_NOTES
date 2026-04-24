# 📌 PART 5: ADDING AND DELETING FIREWALL RULES

---

## 5.1 Understanding Runtime vs Permanent (CRITICAL CONCEPT)

Before adding any rules, you MUST understand this. It is the most common source of confusion.

**Runtime rules:**

- Applied immediately to the running firewall
- NO `--permanent` flag used
- Survive as long as firewalld is running
- LOST when you reload or restart firewalld or reboot
- Good for TESTING rules before making permanent

**Permanent rules:**

- Written to configuration files on disk
- Use `--permanent` flag
- NOT applied immediately — need `--reload` to activate
- Survive reboots and restarts
- This is what you use for production configuration

**The best workflow (used by professionals):**

```bash
# Step 1: Add runtime rule first (test it)
firewall-cmd --add-service=http

# Step 2: Test that it works (open browser, curl, etc.)

# Step 3: If it works, make it permanent
firewall-cmd --add-service=http --permanent

# Step 4: Reload to sync runtime with permanent
firewall-cmd --reload
```

**Or: Apply to both at once:**

```bash
# Add permanent rule
firewall-cmd --add-service=http --permanent

# Reload to apply permanent rules to runtime
firewall-cmd --reload
```

---

## 5.2 Allow a Service

```bash
# Allow HTTP in default zone (runtime only)
firewall-cmd --add-service=http

# Allow HTTP in default zone (permanent)
firewall-cmd --add-service=http --permanent

# Allow HTTP in specific zone (permanent)
firewall-cmd --zone=public --add-service=http --permanent

# Allow multiple services at once
firewall-cmd --add-service={http,https,ssh} --permanent
```

**Verify:**

```bash
firewall-cmd --list-services
```

---

## 5.3 Remove (Delete) a Service

```bash
# Remove HTTP from default zone (runtime only)
firewall-cmd --remove-service=http

# Remove HTTP permanently
firewall-cmd --remove-service=http --permanent

# Remove from specific zone permanently
firewall-cmd --zone=public --remove-service=http --permanent

# Apply the removal
firewall-cmd --reload
```

---

## 5.4 Allowing Common Services — Practical Examples

```bash
# ─── Web Services ───
firewall-cmd --add-service=http --permanent    # port 80/tcp
firewall-cmd --add-service=https --permanent   # port 443/tcp

# ─── SSH ───
firewall-cmd --add-service=ssh --permanent     # port 22/tcp

# ─── FTP ───
firewall-cmd --add-service=ftp --permanent     # port 21/tcp

# ─── Mail Services ───
firewall-cmd --add-service=smtp --permanent    # port 25/tcp
firewall-cmd --add-service=pop3 --permanent    # port 110/tcp
firewall-cmd --add-service=imap --permanent    # port 143/tcp

# ─── Database Services ───
firewall-cmd --add-service=mysql --permanent   # port 3306/tcp
firewall-cmd --add-service=postgresql --permanent  # port 5432/tcp

# ─── DNS ───
firewall-cmd --add-service=dns --permanent     # port 53/tcp+udp

# ─── Apply all changes ───
firewall-cmd --reload
```

---

