
# 📌 PART 4: VIEW EXISTING FIREWALL RULES

---

## 4.1 View All Rules for the Default Zone

```bash
firewall-cmd --list-all
```

**Complete output explained line by line:**

```
public (active)                    ← zone name and status
  target: default                  ← what to do with unmatched packets (default = reject)
  icmp-block-inversion: no         ← ICMP blocking mode
  interfaces: ens33                ← which NIC is in this zone
  sources:                         ← IPs assigned to this zone (empty = none)
  services: cockpit dhcpv6-client ssh   ← allowed services
  ports:                           ← allowed ports (none added yet)
  protocols:                       ← allowed protocols
  forward: yes                     ← IP forwarding enabled/disabled
  masquerade: no                   ← NAT masquerading off
  forward-ports:                   ← port forwarding rules
  source-ports:                    ← source port rules
  icmp-blocks:                     ← blocked ICMP types
  rich rules:                      ← complex rules
```

---

## 4.2 View All Zones

```bash
# List all available zones
firewall-cmd --get-zones
# Output: block dmz drop external home internal public trusted work

# List all zones with their full details
firewall-cmd --list-all-zones

# View a specific zone's details
firewall-cmd --zone=public --list-all
firewall-cmd --zone=home --list-all
firewall-cmd --zone=trusted --list-all
```

---

## 4.3 View Allowed Services

```bash
# Services allowed in default zone
firewall-cmd --list-services

# Services in a specific zone
firewall-cmd --zone=public --list-services

# Output example:
# cockpit dhcpv6-client ssh
```

**What are services?** A "service" in firewalld is a predefined name that maps to one or more ports. Instead of remembering port numbers, you use service names.

```bash
# See all available predefined services
firewall-cmd --get-services

# Output includes: http https ssh ftp smtp mysql postgresql etc.

# See what ports a service uses
firewall-cmd --info-service=http
# Output: http: ports: 80/tcp
```

---

## 4.4 View Allowed Ports

```bash
# Ports allowed in default zone
firewall-cmd --list-ports

# Ports in specific zone
firewall-cmd --zone=public --list-ports

# Output example:
# 8080/tcp 3000/tcp 9090/udp
```

---

## 4.5 View All in One with More Detail

```bash
# View interfaces in a zone
firewall-cmd --list-interfaces
firewall-cmd --zone=public --list-interfaces

# View rich rules
firewall-cmd --list-rich-rules
firewall-cmd --zone=public --list-rich-rules

# View ICMP blocks
firewall-cmd --list-icmp-blocks
firewall-cmd --zone=public --list-icmp-blocks

# Check if masquerading is enabled
firewall-cmd --query-masquerade

# Check if a specific service is allowed
firewall-cmd --query-service=ssh
# Output: yes or no
```

---
