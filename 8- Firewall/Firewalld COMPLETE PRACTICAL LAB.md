
# COMPLETE PRACTICAL LAB

---

## Lab 1: Enable Firewall and Basic Setup

```bash
# Step 1: Install firewalld if needed
dnf install firewalld -y

# Step 2: Start and enable firewalld
systemctl enable --now firewalld

# Step 3: Verify it's running
systemctl status firewalld
firewall-cmd --state
# Expected: running

# Step 4: Check default zone
firewall-cmd --get-default-zone
# Expected: public

# Step 5: View current rules
firewall-cmd --list-all
```

---

## Lab 2: Allow SSH Safely

```bash
# Step 1: Check if SSH is currently allowed
firewall-cmd --query-service=ssh
# Expected: yes (SSH is usually allowed by default)

# Step 2: If not allowed, add it
firewall-cmd --add-service=ssh --permanent

# Step 3: For extra security, allow SSH only from your IP
# First remove general SSH
firewall-cmd --remove-service=ssh --permanent

# Add SSH for specific IP only
firewall-cmd --add-rich-rule='rule family="ipv4" source address="YOUR_IP_HERE" service name="ssh" accept' --permanent

# Step 4: Apply changes
firewall-cmd --reload

# Step 5: Test from your IP
ssh username@server-ip
# Should connect

# Step 6: Verify
firewall-cmd --list-all
```

---

## Lab 3: Open Port 80 (Web Server)

```bash
# Step 1: Open port 80 using service name
firewall-cmd --add-service=http --permanent

# OR using port number
firewall-cmd --add-port=80/tcp --permanent

# Step 2: Open port 443 for HTTPS
firewall-cmd --add-service=https --permanent

# Step 3: Apply
firewall-cmd --reload

# Step 4: Verify
firewall-cmd --list-services
firewall-cmd --list-ports
firewall-cmd --query-service=http

# Step 5: Test from browser or curl
curl -I http://your-server-ip
# Should return HTTP response headers
```

---

## Lab 4: Block Ping

```bash
# Step 1: First verify ping works (from another machine)
ping server-ip

# Step 2: Block ping on the server
firewall-cmd --add-icmp-block=echo-request --permanent

# Step 3: Apply
firewall-cmd --reload

# Step 4: Verify ping is blocked
firewall-cmd --list-icmp-blocks
# Should show: echo-request

# Step 5: Test from another machine
ping server-ip
# Should show: Request timeout (no response)

# Step 6: Allow ping from specific monitoring server
firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.0.200" icmp-type name="echo-request" accept' --permanent
firewall-cmd --reload
# Now 10.0.0.200 can ping, but nobody else can
```

---

## Lab 5: Remove (Clean Up) a Rule

```bash
# Step 1: View current rules
firewall-cmd --list-all

# Step 2: Remove a service
firewall-cmd --remove-service=http --permanent

# Step 3: Remove a port
firewall-cmd --remove-port=8080/tcp --permanent

# Step 4: Remove a rich rule
# First, get the exact rich rule text
firewall-cmd --list-rich-rules

# Then remove with exact text
firewall-cmd --remove-rich-rule='rule family="ipv4" source address="192.168.1.50" drop' --permanent

# Step 5: Remove ICMP block
firewall-cmd --remove-icmp-block=echo-request --permanent

# Step 6: Apply all removals
firewall-cmd --reload

# Step 7: Verify all removed
firewall-cmd --list-all
```

---

## Lab 6: Complete Web Server Firewall Setup (Production)

```bash
# This is a complete, production-ready firewall setup for a web server

# Step 1: Make sure firewalld is running
systemctl enable --now firewalld

# Step 2: Set default zone to public
firewall-cmd --set-default-zone=public

# Step 3: Remove all default allowed services (start fresh)
firewall-cmd --remove-service=dhcpv6-client --permanent
firewall-cmd --remove-service=cockpit --permanent

# Step 4: Allow only needed services
firewall-cmd --add-service=http --permanent        # port 80
firewall-cmd --add-service=https --permanent       # port 443

# Step 5: Allow SSH ONLY from your admin IP
firewall-cmd --remove-service=ssh --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" source address="YOUR_ADMIN_IP/32" service name="ssh" accept' --permanent

# Step 6: Block ping from internet
firewall-cmd --add-icmp-block=echo-request --permanent

# Step 7: Block common attack ports
firewall-cmd --add-rich-rule='rule family="ipv4" service name="mysql" drop' --permanent
firewall-cmd --add-rich-rule='rule family="ipv4" port port="3389" protocol="tcp" drop' --permanent

# Step 8: Log suspicious SSH attempts
firewall-cmd --add-rich-rule='rule family="ipv4" service name="ssh" log prefix="SSH-ATTEMPT: " level="warning"' --permanent

# Step 9: Apply all permanent rules
firewall-cmd --reload

# Step 10: Final verification
firewall-cmd --list-all
```

---
