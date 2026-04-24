# 📌 PART 8: BLOCK ICMP (PING)

---

## 8.1 Understanding ICMP

ICMP (Internet Control Message Protocol) is used for:

- **ping** — tests if a host is alive and measures round-trip time
- **traceroute** — maps the path packets take
- **Network error messages** — "destination unreachable", "TTL exceeded"

**Why block ping (ICMP)?**

- Security: Prevents attackers from discovering that your server exists
- Prevents ICMP flood attacks (ping of death, Smurf attack)
- Many organizations block ping on internet-facing servers for stealth

**Should you always block ping?** Not always. Ping is useful for troubleshooting. Many organizations block ping from internet but allow it from internal network.

---

## 8.2 View Available ICMP Types

```bash
# See all ICMP types you can block
firewall-cmd --get-icmptypes

# Output:
# address-unreachable bad-header beyond-scope communication-prohibited 
# destination-unreachable echo-reply echo-request ...
```

**Most important ICMP types:**

|ICMP Type|What it is|Common use|
|---|---|---|
|`echo-request`|Ping request (you are being pinged)|Block to stop ping|
|`echo-reply`|Ping reply (response to your ping)|Block to stop your pings working|
|`destination-unreachable`|"Host/port unreachable" error|Usually keep enabled|
|`time-exceeded`|TTL expired (used by traceroute)|Block to stop traceroute|

---

## 8.3 Block Ping (Disable Incoming Ping)

```bash
# Block ICMP echo-request (stops others from pinging YOU)
firewall-cmd --add-icmp-block=echo-request --permanent

# Block in specific zone
firewall-cmd --zone=public --add-icmp-block=echo-request --permanent

# Apply
firewall-cmd --reload
```

**Verify block is active:**

```bash
# Check what ICMP types are blocked
firewall-cmd --list-icmp-blocks
# Output: echo-request

# From another machine, try pinging
ping your-server-ip
# Output: Request timeout (no response)
```

---

## 8.4 Block All ICMP (Aggressive Block)

```bash
# Using icmp-block-inversion — INVERTS the logic
# Instead of specifying what to BLOCK, everything is blocked
# EXCEPT what you explicitly allow

# Step 1: Block all ICMP first by enabling inversion
firewall-cmd --add-icmp-block-inversion --permanent

# Now ALL ICMP is blocked unless you add icmp-blocks to ALLOW specific types

# Apply
firewall-cmd --reload
```

---

## 8.5 Allow Ping Back (Re-enable Ping)

```bash
# Remove the echo-request block (allow ping again)
firewall-cmd --remove-icmp-block=echo-request --permanent

# If inversion was enabled, disable it
firewall-cmd --remove-icmp-block-inversion --permanent

# Apply
firewall-cmd --reload

# Verify
firewall-cmd --list-icmp-blocks
# Should be empty now
```

---

## 8.6 Block Ping using Rich Rules (More Control)

```bash
# Block ping only from specific IP
firewall-cmd --add-rich-rule='rule family="ipv4" source address="1.2.3.4" icmp-type name="echo-request" drop' --permanent

# Block ping from everywhere except your monitoring server
firewall-cmd --add-icmp-block=echo-request --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.200" icmp-type name="echo-request" accept' --permanent

firewall-cmd --reload
```

---
