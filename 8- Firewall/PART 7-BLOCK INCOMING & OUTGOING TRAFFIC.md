# 📌 PART 7: BLOCK INCOMING / OUTGOING TRAFFIC

---

## 7.1 Rich Rules — Introduction

**Rich rules** are firewalld's way of writing MORE COMPLEX rules that go beyond just allowing/blocking services or ports. They let you:

- Block or allow based on SOURCE IP
- Block or allow based on DESTINATION
- Log traffic
- Set connection limits
- Combine multiple conditions

**Syntax:**

```
firewall-cmd --add-rich-rule='rule [family="ipv4/ipv6"] 
                                    [source address="IP/CIDR"] 
                                    [destination address="IP/CIDR"] 
                                    [service name="SERVICE"] 
                                    [port port="PORT" protocol="tcp/udp"] 
                                    [accept|drop|reject] 
                                    [log prefix="TEXT" level="info"]'
```

---

## 7.2 Source-Based Blocking (Block a Specific IP)

```bash
# Block all traffic FROM a specific IP address
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.50" drop' --permanent

# Block a specific IP range (subnet)
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" drop' --permanent

# Block an IP but send REJECT (vs DROP)
# DROP: Silently discard — attacker gets no response (appears as timeout)
# REJECT: Send back error — attacker knows the port is closed
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.50" reject' --permanent

firewall-cmd --reload
```

**DROP vs REJECT:**

|Feature|DROP|REJECT|
|---|---|---|
|Response to sender|None (silent)|ICMP error message|
|Attacker knowledge|Thinks port is filtered/down|Knows it's blocked|
|Good for|External attackers|Internal networks|
|Connection timeout|Long (waits for timeout)|Immediate error|

---

## 7.3 Allow ONLY a Specific IP (Whitelist)

```bash
# Allow SSH ONLY from IP 10.0.0.50
# First, remove the general SSH service
firewall-cmd --remove-service=ssh --permanent

# Add SSH only for trusted IP
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.50" service name="ssh" accept' --permanent

# Allow SSH from a whole subnet (office network)
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" service name="ssh" accept' --permanent

firewall-cmd --reload
```

---

## 7.4 Block Traffic Based on Source IP for a Specific Service

```bash
# Block MySQL access from a specific IP (even if MySQL port is open)
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.5.10" service name="mysql" reject' --permanent

# Allow HTTP from everywhere except one IP
firewall-cmd --add-service=http --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" source address="1.2.3.4" service name="http" drop' --permanent

firewall-cmd --reload
```

---

## 7.5 Block Based on Destination IP

```bash
# Block traffic going TO a specific IP (outgoing)
firewall-cmd --add-rich-rule='rule family="ipv4" destination address="8.8.8.8" drop' --permanent

# Block traffic going to a specific website/IP range
firewall-cmd --add-rich-rule='rule family="ipv4" destination address="203.0.113.0/24" drop' --permanent

firewall-cmd --reload
```

---

## 7.6 Rich Rules with Logging

Logging is essential for security monitoring. You can log traffic before dropping/accepting it.

```bash
# Log and drop traffic from suspicious IP
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.50" log prefix="BLOCKED-IP: " level="warning" drop' --permanent

# Log all SSH connection attempts
firewall-cmd --add-rich-rule='rule family="ipv4" service name="ssh" log prefix="SSH-ATTEMPT: " level="info" accept' --permanent

# Log and reject with limit (prevent log flooding)
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" log prefix="LAN-DROP: " level="notice" limit value="10/m" drop' --permanent
```

**View logs:**

```bash
journalctl -f | grep "BLOCKED-IP"
# or
tail -f /var/log/messages | grep "BLOCKED-IP"
```

---

## 7.7 Block an Entire Source IP Zone (Direct Approach)

```bash
# Add an IP directly to the 'drop' zone (drops all traffic from that IP)
firewall-cmd --zone=drop --add-source=192.168.1.50 --permanent

# Add an IP to 'trusted' zone (allow all traffic from that IP)
firewall-cmd --zone=trusted --add-source=10.0.0.0/24 --permanent

# Add an IP to 'block' zone (reject with ICMP error)
firewall-cmd --zone=block --add-source=192.168.5.100 --permanent

firewall-cmd --reload
```

---

## 7.8 Remove Rich Rules

```bash
# Remove a rich rule (use EXACT same rule text)
firewall-cmd --remove-rich-rule='rule family="ipv4" source address="192.168.1.50" drop' --permanent

# View all rich rules to get exact text
firewall-cmd --list-rich-rules

firewall-cmd --reload
```

---

