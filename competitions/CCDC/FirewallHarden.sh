#!/bin/bash

# ==========================
# Linux Firewall Hardening Script
# ==========================
# This script configures iptables firewall rules, ensures logging,
# and sets up persistence for a blue team competition like CCDC.
# ==========================

# ==========================
# VARIABLE INITIALIZATION
# ==========================
dc_ips=()  # Array to store Domain Controller IPs
team_ips=()  # Array to store team member IPs (trusted IPs)

# Define TCP and UDP ports required for Domain Controllers
linux_dc_ports_tcp=("53" "88" "135" "389" "445" "464" "636" "3268" "3269" "49152:65535")
dc_ports_udp=(53 88 123 389 464)

# Variable to check if the system is in a domain
in_domain=0

# ==========================
# GATHER USER INPUT
# ==========================
read -p "What is the hostname? " hostname  # Prompt user for hostname

# Check if the system is part of an Active Directory domain
if command -v adcli &> /dev/null; then 
    in_domain=1
else
    in_domain=0
fi

# If the system is in a domain, prompt for Domain Controller IPs
if [ "$in_domain" -eq 1 ]; then
    while true; do
        read -p "Enter a Domain Controller IP address (or type 'done' to finish): " ip
        if [ "$ip" == "done" ]; then
            break
        else
            dc_ips+=("$ip")  # Store entered IP in the array
        fi
    done
fi

# Prompt user to enter trusted team IPs
while true; do
    read -p "Enter a team IP address (or type 'done' to finish): " ip
    if [ "$ip" == "done" ]; then
        break
    else
        team_ips+=("$ip")  # Store entered IP in the array
    fi
done

# ==========================
# DETECT PACKAGE MANAGER
# ==========================
if command -v apk &> /dev/null; then
    package_manager="apk"
elif command -v yum &> /dev/null; then
    package_manager="yum"
elif command -v dnf &> /dev/null; then
    package_manager="dnf"
elif command -v apt-get &> /dev/null; then
    package_manager="apt"
elif command -v zypper &> /dev/null; then
    package_manager="zypper"
else
    echo "Unsupported package manager"
    exit 1
fi

# ==========================
# INSTALL REQUIRED PACKAGES
# ==========================
# Ensure iptables is installed
if ! command -v iptables &> /dev/null; then
    case $package_manager in
        "apk") apk add iptables ;;
        "yum") yum install -y iptables ;;
        "dnf") dnf install -y iptables ;;
        "apt") apt-get install -y iptables ;;
        "zypper") zypper install -y iptables ;;
    esac
fi

# Create iptables directory for storing rules
mkdir -p /etc/iptables

# ==========================
# SETUP FIREWALL PERSISTENCE
# ==========================
# Create restore script to reload iptables rules on boot
echo '#!/bin/bash'  > /etc/iptables/restore-iptables.sh
echo "# Restore iptables rules" >> /etc/iptables/restore-iptables.sh
echo "iptables-restore < /root/$hostname.rules" >> /etc/iptables/restore-iptables.sh
chmod 0500 /etc/iptables/restore-iptables.sh  # Secure the script

# Detect if the system uses systemd or OpenRC and configure accordingly
if command -v systemctl &> /dev/null; then
  # Systemd service for restoring iptables rules
  cat << 'EOF' > /etc/systemd/system/iptables-persistent.service
[Unit] 
Description=runs iptables restore on boot
ConditionFileIsExecutable=/etc/iptables/restore-iptables.sh
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /etc/iptables/restore-iptables.sh
TimeoutSec=10
RemainAfterExit=yes
GuessMainPID=no

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable iptables-persistent.service
else
  # OpenRC service for restoring iptables rules
  cat << 'EOF' > /etc/init.d/iptables-persistent
#!/sbin/openrc-run

depend() {
  need net
}

command="/bin/bash"
command_args="/etc/iptables/restore-iptables.sh"
pidfile="iptables-persistent.pid"
EOF
  chmod 0550 /etc/init.d/iptables-persistent
  rc-update add iptables-persistent default
fi

# ==========================
# INSTALL AND ENABLE LOGGING (RSYSLOG)
# ==========================
case $package_manager in
    "apk") apk add rsyslog ;;
    "yum") yum install -y rsyslog ;;
    "dnf") dnf install -y rsyslog ;;
    "apt") apt-get install -y rsyslog ;;
    "zypper") zypper install -y rsyslog ;;
esac

# ==========================
# FLUSH EXISTING IPTABLES RULES
# ==========================
iptables -F INPUT
iptables -F OUTPUT

# ==========================
# APPLY IPTABLES RULES
# ==========================
# Drop invalid traffic
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A OUTPUT -m conntrack --ctstate INVALID -j DROP

# Allow local traffic
iptables -A INPUT -s 127.0.0.0/8 -j ACCEPT
iptables -A OUTPUT -d 127.0.0.0/8 -j ACCEPT

# Allow ICMP (ping)
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# Allow SSH access only from team IPs
for ip in "${team_ips[@]}"; do
    iptables -A INPUT -p tcp --dport 22 -s "$ip" -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 22 -d "$ip" -m conntrack --ctstate ESTABLISHED -j ACCEPT
done

# If the system is in a domain, allow necessary DC communication
if [ "$in_domain" -eq 1 ]; then
  for ip in "${dc_ips[@]}"; do
    # Allow TCP traffic for domain controller services
    for port in "${linux_dc_ports_tcp[@]}"; do
        iptables -A INPUT -p tcp --sport "$port" -s "$ip" -j ACCEPT
        iptables -A OUTPUT -p tcp --dport "$port" -d "$ip" -j ACCEPT
    done
    # Allow UDP traffic for domain controller services
    for port in "${dc_ports_udp[@]}"; do
        iptables -A INPUT -p udp --sport "$port" -s "$ip" -j ACCEPT
        iptables -A OUTPUT -p udp --dport "$port" -d "$ip" -j ACCEPT
    done
  done
fi

# ==========================
# LOGGING & CRON JOBS
# ==========================
# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "[DROPPED_INPUT] "
iptables -A OUTPUT -j LOG --log-prefix "[DROPPED_OUTPUT] "

# Flush iptables rules every 5 minutes (potential reset mechanism)
echo "*/5 * * * * root iptables -F" >> /etc/crontabs/root
echo "*/5 * * * * root iptables -F" >> /etc/crontab

# ==========================
# FINAL DROP RULES & SAVE RULESET
# ==========================
echo "Adding drop rules. If you still have access to the machine, run finish.sh after this script ends"
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP

# Save the iptables rules to a file
iptables-save > /root/$hostname.rules
