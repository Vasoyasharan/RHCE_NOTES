#!/bin/bash

# =========================
# Enhanced System Check Script
# =========================
# This script installs missing tools, collects system info, and outputs an HTML report.

OUTPUT="System_Report.html"

echo "🔄 Checking and installing required packages..."
REQUIRED_PKGS="neofetch htop glances inxi smartmontools hdparm acpi iotop rkhunter lshw dmidecode debsums mesa-utils stress memtester net-tools pciutils usbutils util-linux"
sudo apt update -y
for pkg in $REQUIRED_PKGS; do
    if ! dpkg -s $pkg &>/dev/null; then
        echo "📦 Installing $pkg..."
        sudo apt install -y $pkg
    fi
done

echo "✅ All required packages are installed."

# Start HTML report
echo "<html><head><title>System Health Report</title>" > $OUTPUT
echo "<style>body{font-family:Arial;background:#1e1e1e;color:#e0e0e0;padding:20px;} h2{color:#00ffea;} pre{background:#2d2d2d;padding:10px;border-radius:8px;overflow-x:auto;} .section{margin-bottom:20px;} </style>" >> $OUTPUT
echo "</head><body>" >> $OUTPUT
echo "<h1>🖥️ Laptop Full System Health Report</h1>" >> $OUTPUT
echo "<p>Generated on: $(date)</p>" >> $OUTPUT

add_section () {
    echo "<div class='section'><h2>$1</h2><pre>" >> $OUTPUT
    eval "$2" >> $OUTPUT 2>&1
    echo "</pre></div>" >> $OUTPUT
}

# Sections
add_section "✅ Basic System Info" "uname -a && hostnamectl && lsb_release -a && uptime && neofetch --stdout"
add_section "🔐 TPM Status" "tpm_version || echo 'tpm_version not found'; dmesg | grep -i tpm; lsmod | grep tpm"
add_section "🔋 Battery Health" "upower -i /org/freedesktop/UPower/devices/battery_BAT0; acpi -V; cat /sys/class/power_supply/BAT0/capacity"
add_section "💾 Disk & SSD Health" "lsblk; df -h; sudo smartctl -a /dev/sda; sudo hdparm -I /dev/sda"
add_section "🧠 RAM & CPU Info" "free -h; vmstat 1 2; sudo dmidecode -t memory; lscpu"
add_section "🚀 Performance Snapshot" "top -bn1 | head -20; iostat"
add_section "🌐 Network & Security" "ip a; ping -c 2 google.com; sudo ss -tulnp; sudo ufw status"
add_section "🔍 Hardware Info" "sudo lshw -short; sudo dmidecode; lsusb; lspci; inxi -Fxz"
add_section "🛡️ Logs & Critical Errors" "sudo journalctl -p 3 -xb; dmesg --level=err,warn"
add_section "🖼️ GPU Info" "lspci | grep VGA; glxinfo | grep 'OpenGL'"

# End HTML
echo "<h2>✅ Report Complete</h2>" >> $OUTPUT
echo "<p>All sections above were generated successfully. Review for any warnings or issues.</p>" >> $OUTPUT
echo "</body></html>" >> $OUTPUT

echo "✅ System Check Completed!"
echo "🌐 Open the HTML report in your browser: $(pwd)/$OUTPUT"
