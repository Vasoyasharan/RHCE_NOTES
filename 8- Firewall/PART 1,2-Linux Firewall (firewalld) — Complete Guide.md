
# 📌 PART 1: WHAT IS A FIREWALL?

---

## 1.1 Definition

A firewall is a security system — either hardware, software, or both — that monitors and controls incoming and outgoing network traffic based on predefined security rules.

Think of it as a **security guard** standing at the entrance of a building. The security guard has a rulebook. Anyone who matches the allowed criteria can enter. Anyone who doesn't match gets stopped.

**Technical definition:** A firewall sits between your Linux system and the network, inspecting every packet that tries to enter or leave. Based on rules you configure, it either allows (ACCEPT) or blocks (DROP/REJECT) that traffic.

---

## 1.2 Purpose of a Firewall

|Purpose|Explanation|
|---|---|
|Block unauthorized access|Stop hackers from connecting to your server|
|Allow only needed services|Only port 22 (SSH), 80 (HTTP), 443 (HTTPS) should be open|
|Protect sensitive services|Database ports (3306, 5432) should NEVER be open to the internet|
|Rate limiting / DDoS protection|Reduce impact of attack floods|
|Zone-based access control|Trust office network more than public internet|
|Log suspicious activity|Track who tried to connect and when|

---

## 1.3 Real-Life Examples

**Example 1 — Web Server:** Your web server should only allow:

- Port 80 (HTTP) from everyone
- Port 443 (HTTPS) from everyone
- Port 22 (SSH) ONLY from your office IP
- Port 3306 (MySQL) — BLOCKED from everyone outside

**Example 2 — Office Network:**

- Employees can browse internet (outgoing port 80/443 allowed)
- Nobody from internet can connect to internal servers
- VoIP phones can use specific UDP ports

**Example 3 — Home Router:** Your home router acts as a firewall — it blocks all incoming connections from the internet but allows your devices inside to browse freely.

---

# 📌 PART 2: firewalld IN LINUX

---

## 2.1 What is firewalld?

`firewalld` is the **default firewall management service** in modern Red Hat-based Linux systems (RHEL 7+, CentOS 7+, Fedora, Rocky Linux, AlmaLinux). It is also available on Ubuntu/Debian.

**What makes firewalld special:**

- It is a **dynamic** firewall — you can add/remove rules WITHOUT restarting the entire firewall
- It uses the concept of **zones** — different trust levels for different networks
- It provides both command-line (`firewall-cmd`) and GUI tools
- It works as a **frontend** to netfilter (the actual kernel-level packet filtering engine)
- Rules can be **Runtime** (temporary) or **Permanent** (survive reboots)

**Architecture:**

```
You (admin)
    ↓
firewall-cmd / firewall-config (GUI) / D-Bus API
    ↓
firewalld daemon (service running in background)
    ↓
nftables / iptables (kernel-level rule engine)
    ↓
netfilter (Linux kernel subsystem)
    ↓
Network packets (allowed or blocked)
```

---

## 2.2 Difference Between iptables and firewalld

This is a very common interview question. Let's understand both clearly.

**iptables:**

- The OLD way of managing Linux firewall rules
- Directly writes rules to the kernel's netfilter tables
- Rules are applied all at once — you have to reload the entire ruleset to make changes
- No concept of zones — you manage everything with chains (INPUT, OUTPUT, FORWARD)
- Not dynamic — reloading disconnects existing connections
- Configuration requires deep knowledge of chains and tables

**firewalld:**

- The NEW way — introduced in RHEL 7 (2014)
- Works as a MANAGER on top of nftables (or iptables as backend)
- Dynamic — add/remove individual rules without touching others
- Zone-based — assign different trust levels to interfaces
- Supports both simple rules (services, ports) and complex rules (rich rules)
- Automatically handles rule reload without dropping existing connections

|Feature|iptables|firewalld|
|---|---|---|
|Rule application|All at once (batch)|Individual rules dynamically|
|Connection impact on reload|Drops existing connections|No disruption|
|Zones concept|No|Yes|
|Simplicity|Complex syntax|Easier with services|
|Dynamic update|No|Yes|
|Default in RHEL 7+|No|Yes|
|Backend|netfilter directly|nftables/iptables|
|Persistence|iptables-save/restore|--permanent flag|
|GUI available|iptables-frontend tools|firewall-config|

**Can they coexist?** No. You should use EITHER firewalld OR iptables, not both. Running both can cause conflicts and unpredictable behavior.

---

## 2.3 Zones — The Core Concept of firewalld

Zones are the most important concept in firewalld. A zone is a **predefined trust level** that you assign to a network interface or source IP. Different zones have different default rules.

**Simple analogy:**

- **Public zone** = Standing in a crowded marketplace. You don't trust anyone. Only accept connections for what you've explicitly said is OK.
- **Trusted zone** = You're at home with family. You trust everyone. All connections are allowed.
- **Work zone** = Office environment. Some trust. Accept most things but be careful.

**All default zones in firewalld:**

|Zone Name|Trust Level|Default Behavior|Use Case|
|---|---|---|---|
|`drop`|Lowest|Drop ALL incoming. No reply|Block everything|
|`block`|Very Low|Reject incoming with ICMP unreachable|Block with notification|
|`public`|Low|Accept only selected services|Internet-facing interfaces|
|`external`|Low|Like public but with masquerading (NAT)|Router/gateway|
|`dmz`|Medium-Low|Only accepted services|DMZ servers|
|`work`|Medium|Trust colleagues, accept more|Work interfaces|
|`home`|Medium-High|Trust home devices|Home network|
|`internal`|High|Trust internal network|Internal server network|
|`trusted`|Highest|Accept ALL connections|Fully trusted network|

**Default zone:** When you don't specify a zone, firewalld uses the **default zone** — which is `public` on most systems.

```bash
# Check current default zone
firewall-cmd --get-default-zone

# Change default zone
firewall-cmd --set-default-zone=home
```

**Zone assignment:** An interface can only belong to ONE zone at a time. A zone can have MULTIPLE interfaces.

```
                           INTERNET
                               ↓
                    [ens33 → public zone]
                               ↓
                        Linux Server
                               ↓
                    [ens34 → internal zone]
                               ↓
                       INTERNAL NETWORK
```

---





# 📌 PART 12: INTERVIEW PREPARATION

---

## 12.1 Short Interview Answers

**Q: What is firewalld?**

> firewalld is a dynamic firewall management daemon in Linux that provides a zone-based firewall using nftables/iptables as its backend. It allows adding and removing rules without interrupting existing connections, unlike traditional iptables where rules had to be reloaded completely.

**Q: What is the difference between runtime and permanent rules?**

> Runtime rules apply immediately but are lost on firewall reload or system reboot. Permanent rules are written to disk and survive reboots but require `firewall-cmd --reload` to become active. Best practice is to test rules at runtime, then make them permanent with `--permanent` flag and `--reload`.

**Q: What is a zone in firewalld?**

> A zone is a predefined trust level applied to a network interface or source IP. Each zone has its own set of allowed services, ports, and rules. For example, the `public` zone is for untrusted networks and only allows explicitly permitted traffic, while the `trusted` zone allows all traffic. A single interface can only belong to one zone at a time.

**Q: What's the difference between DROP and REJECT?**

> DROP silently discards packets with no reply to the sender — the sender experiences a connection timeout. REJECT discards packets but sends an ICMP error back, immediately notifying the sender. DROP is better for external attackers (hides your server's existence), REJECT is better for internal troubleshooting.

**Q: How do you allow SSH only from a specific IP?**

```bash
firewall-cmd --remove-service=ssh --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.50" service name="ssh" accept' --permanent
firewall-cmd --reload
```

**Q: How do you block ping?**

```bash
firewall-cmd --add-icmp-block=echo-request --permanent
firewall-cmd --reload
```

**Q: How do you check if a port is open?**

```bash
firewall-cmd --query-port=80/tcp
firewall-cmd --query-service=http
firewall-cmd --list-all
```

**Q: How do you apply permanent rules without restarting?**

```bash
firewall-cmd --reload
# This reads permanent config and applies to runtime without dropping connections
```

---
## 12.2 Quick Command Reference Card

```bash
# ═══ STATUS ═══
firewall-cmd --state                        # running?
systemctl status firewalld                  # full status
firewall-cmd --get-default-zone             # default zone?
firewall-cmd --get-active-zones             # active zones + interfaces
firewall-cmd --list-all                     # all rules in default zone
firewall-cmd --list-all --zone=public       # specific zone

# ═══ SERVICES ═══
firewall-cmd --list-services                # list allowed services
firewall-cmd --add-service=http --permanent # allow service
firewall-cmd --remove-service=http --permanent # remove service
firewall-cmd --query-service=ssh            # is service allowed?

# ═══ PORTS ═══
firewall-cmd --list-ports                   # list open ports
firewall-cmd --add-port=8080/tcp --permanent # open port
firewall-cmd --remove-port=8080/tcp --permanent # close port
firewall-cmd --query-port=80/tcp            # is port open?

# ═══ RICH RULES ═══
firewall-cmd --list-rich-rules              # list rich rules
firewall-cmd --add-rich-rule='rule family="ipv4" source address="IP" drop' --permanent
firewall-cmd --remove-rich-rule='rule ...' --permanent

# ═══ ICMP / PING ═══
firewall-cmd --list-icmp-blocks             # blocked ICMP types
firewall-cmd --add-icmp-block=echo-request --permanent # block ping
firewall-cmd --remove-icmp-block=echo-request --permanent # allow ping

# ═══ APPLY CHANGES ═══
firewall-cmd --reload                       # apply permanent to runtime
systemctl restart firewalld                 # full restart (last resort)
```

---

