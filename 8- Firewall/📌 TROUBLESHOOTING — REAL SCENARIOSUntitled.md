# 📌  TROUBLESHOOTING — REAL SCENARIOS

---

## Scenario 1: SSH Not Working Due to Firewall

**Symptom:** You can't SSH into the server. Getting "Connection refused" or "Connection timed out."

```bash
# ─── On the SERVER (if you have console access) ───

# Step 1: Check if firewalld is running
systemctl status firewalld

# Step 2: Check if SSH service is allowed
firewall-cmd --list-services
# Is 'ssh' in the list?

# Step 3: Check if port 22 is open
firewall-cmd --list-ports
firewall-cmd --query-port=22/tcp

# Step 4: Check if SSH service is running on server
systemctl status sshd
ss -tlnp | grep :22    # check if sshd is listening

# Step 5: If SSH not in allowed services, add it
firewall-cmd --add-service=ssh --permanent
firewall-cmd --reload

# Step 6: Check rich rules — maybe your IP is blocked
firewall-cmd --list-rich-rules
# Check if any rule is DROPPING your IP

# Step 7: Check zone assignment
firewall-cmd --get-active-zones
# Make sure your interface is in a zone that allows SSH

# Step 8: Emergency — if locked out, add SSH to trusted zone
firewall-cmd --zone=trusted --add-service=ssh --permanent
firewall-cmd --reload

# Step 9: Verify with ss (socket status)
ss -tlnp | grep :22
# Should show: LISTEN 0 128 0.0.0.0:22

# From CLIENT side:
# Test with verbose SSH
ssh -v username@server-ip 2>&1 | head -30
# Verbose output shows exactly where connection fails
```

---

## Scenario 2: Website Not Opening (Port Blocked)

**Symptom:** Your web server is running (Apache/Nginx) but website doesn't load in browser.

```bash
# ─── DIAGNOSIS ───

# Step 1: Is the web server running?
systemctl status httpd    # Apache
systemctl status nginx    # Nginx

# Step 2: Is port 80 listening?
ss -tlnp | grep :80
# Should show Apache/Nginx listening

# Step 3: Check firewall allows port 80
firewall-cmd --list-services    # is http in list?
firewall-cmd --list-ports       # is 80/tcp in list?
firewall-cmd --query-service=http
firewall-cmd --query-port=80/tcp

# Step 4: Test locally (on the server itself)
curl -I http://localhost
# If this works, it's a firewall issue (not web server)

# ─── FIX ───

# Step 5: Open port 80
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --reload

# Step 6: Verify
firewall-cmd --query-service=http    # should return: yes

# Step 7: Test from outside
curl -I http://your-server-ip
# Should return: HTTP/1.1 200 OK

# Step 8: If still not working, check SELinux
sestatus
# If enforcing, check SELinux is allowing httpd
setsebool -P httpd_can_network_connect 1
```

---

## Scenario 3: Ping Not Working

**Symptom:** You can't ping the server. Ping times out.

```bash
# ─── DIAGNOSIS ───

# Step 1: Check if ICMP is blocked
firewall-cmd --list-icmp-blocks
# If echo-request is listed → ping is intentionally blocked

# Step 2: Check rich rules for ICMP
firewall-cmd --list-rich-rules
# Look for any icmp-related drop rules

# Step 3: Check if icmp-block-inversion is on
firewall-cmd --list-all | grep icmp-block-inversion

# ─── FIX ───

# Step 4: Remove the echo-request block
firewall-cmd --remove-icmp-block=echo-request --permanent
firewall-cmd --reload

# Step 5: Test
ping server-ip
# Should now respond

# Step 6: If you want to re-block later
firewall-cmd --add-icmp-block=echo-request --permanent
firewall-cmd --reload

# ─── If ping works locally but not from internet ───
# Check if your ISP or hosting provider blocks ICMP
# Some cloud providers (AWS, Azure) block ICMP at their security group level
# Check security groups/ACLs in cloud console
```

---

## Scenario 4: Firewall Rules Applied but Not Working

**Symptom:** You added a rule, reloaded, but traffic still getting through/blocked.

```bash
# Step 1: Verify the rule is in permanent config
firewall-cmd --list-all      # runtime rules
firewall-cmd --list-all --permanent   # permanent rules (disk)

# Are they different? Maybe you forgot --permanent or --reload

# Step 2: Check which zone the interface is in
firewall-cmd --get-active-zones
# Output shows zone → interface mapping

# Step 3: You might be checking wrong zone
firewall-cmd --zone=public --list-all      # public zone rules
firewall-cmd --zone=internal --list-all    # internal zone rules

# Step 4: Check if source-based zone override is happening
firewall-cmd --list-all-zones | grep -A5 sources
# An IP assigned to 'trusted' zone bypasses all other rules

# Step 5: Check for conflicting rich rules
firewall-cmd --list-rich-rules

# Step 6: Verify with a packet trace
# Install tcpdump
tcpdump -i ens33 -n port 80
# Watch for packets arriving and what happens to them

# Step 7: Check if another firewall (nftables directly, SELinux) is interfering
nft list ruleset      # see raw nftables rules
sestatus             # check SELinux status
```

---
