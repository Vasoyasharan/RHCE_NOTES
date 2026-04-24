# 📌 PART 6: ADDING AND REMOVING PORTS

---

## 6.1 Open a Specific Port (TCP)

```bash
# Syntax:
firewall-cmd --add-port=PORT/PROTOCOL --permanent

# Examples:
# Open port 80 (HTTP) - TCP
firewall-cmd --add-port=80/tcp --permanent

# Open port 443 (HTTPS) - TCP
firewall-cmd --add-port=443/tcp --permanent

# Open port 22 (SSH) - TCP
firewall-cmd --add-port=22/tcp --permanent

# Open port 8080 (alternate HTTP) - TCP
firewall-cmd --add-port=8080/tcp --permanent

# Open a range of ports (5000-5010)
firewall-cmd --add-port=5000-5010/tcp --permanent

# In specific zone
firewall-cmd --zone=public --add-port=3000/tcp --permanent

# Apply changes
firewall-cmd --reload
```

---

## 6.2 Open a UDP Port

```bash
# Open port 53 (DNS) - UDP
firewall-cmd --add-port=53/udp --permanent

# Open port 67-68 (DHCP) - UDP
firewall-cmd --add-port=67-68/udp --permanent

# Open port 161 (SNMP) - UDP
firewall-cmd --add-port=161/udp --permanent

firewall-cmd --reload
```

---

## 6.3 Close (Remove) a Port

```bash
# Close port 80/tcp permanently
firewall-cmd --remove-port=80/tcp --permanent

# Close port 8080/tcp from specific zone
firewall-cmd --zone=public --remove-port=8080/tcp --permanent

# Apply
firewall-cmd --reload
```

---

## 6.4 Verify Port Rules

```bash
# List all open ports
firewall-cmd --list-ports
firewall-cmd --zone=public --list-ports

# Check if a specific port is open
firewall-cmd --query-port=80/tcp
# Output: yes or no

firewall-cmd --query-port=3306/tcp
# Output: no (not open)
```

---

## 6.5 Common Port Reference Table

|Service|Port|Protocol|Should be open on public server?|
|---|---|---|---|
|SSH|22|TCP|Only from trusted IPs|
|HTTP|80|TCP|Yes|
|HTTPS|443|TCP|Yes|
|FTP|21|TCP|If FTP server|
|MySQL|3306|TCP|NO — only on internal|
|PostgreSQL|5432|TCP|NO — only on internal|
|MongoDB|27017|TCP|NO — only on internal|
|Redis|6379|TCP|NO — only on internal|
|DNS|53|TCP+UDP|Only if DNS server|
|SMTP|25|TCP|Only if mail server|
|RDP|3389|TCP|NO — very dangerous|

---

