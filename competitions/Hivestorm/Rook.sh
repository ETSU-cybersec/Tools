#!/bin/bash
#Author: Kaiden Mix
#An automated auditing tool for Hivestorm 2024, designed with previouse writeups and pratice boxes in mind. It
#is configured to do auditing checks on Mint and Rocky 9 systems.

#Set Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PINK='\033[1;38;5;198m'
RESET='\033[0m'

#Set Config Variables
HomeSearch=0
UFWFirewall=0
IPv6Disable=0
Mint=0
Rocky=0

# Function to check if the terminal is real
check_terminal() {
    if [ -t 0 ]; then
        echo -e "${GREEN}This script is running in a real terminal.${RESET}"
    else
        echo -e "${RED}WARNING! This script is NOT running in a real terminal!${RESET}"
    fi
}

# Function to check for root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run with sudo permissions.${RESET}"
        exit
    fi
}

# Function to display welcome message and get OS selection
select_os() {
    echo -e "${BLUE}
    ▄▀▀▄▀▀▀▄  ▄▀▀▀▀▄   ▄▀▀▀▀▄   ▄▀▀▄ █
   █   █   █ █      █ █      █ █  █ ▄▀
   ▐  █▀▀█▀  █      █ █      █ ▐  █▀▄
    ▄▀    █  ▀▄    ▄▀ ▀▄    ▄▀   █   █
   █     █     ▀▀▀▀     ▀▀▀▀   ▄▀   █
   ▐     ▐                     █    ▐
                               ▐
By Kaiden Mix
${RESET}
${PINK}A blue team script for ${GREEN}Hivestorm 24${RESET}"

    read -p "Welcome to Rook, which box are you running?
[0]Linux Mint
[1]Rocky 9
" RESPONSE
    RESPONSE=$(echo "$RESPONSE" | tr '[:lower:]' '[:upper:]')
    if [ "$RESPONSE" = "0" ]; then
        Mint=1
        echo -e "${GREEN}Linux Mint Selected${RESET}"
    else
        Rocky=1
        echo -e "${GREEN}Rocky 9 Selected${RESET}"
    fi
}

#Set Home directory search configuration
set_home_search() {
    read -p "Would you like to search the entire home directory? If no it'll only show suspicous files. (Y/N): " RESPONSE
    RESPONSE=$(echo "$RESPONSE" | tr '[:lower:]' '[:upper:]')
    if [ "$RESPONSE" = "Y" ]; then
        HomeSearch=1
    else
        HomeSearch=0
    fi
}

#Set Firewall Configuration
set_firewall() {
    read -p "If Firewall if UFW, type Y to enable it. (Y/N): " RESPONSE
    RESPONSE=$(echo "$RESPONSE" | tr '[:lower:]' '[:upper:]')
    if [ "$RESPONSE" = "Y" ]; then
        UFWFirewall=1
    else
        UFWFirewall=0
    fi
}

# Function to set IPv6 configuration
set_ipv6() {
    read -p "Would you like to permanently disable IPv6? (Y/N): " RESPONSE
    RESPONSE=$(echo "$RESPONSE" | tr '[:lower:]' '[:upper:]')
    if [ "$RESPONSE" = "Y" ]; then
        IPv6Disable=1
    else
        IPv6Disable=0
    fi
}

# Function to enable firewall
enable_firewall() {
    if [ "$UFWFirewall" -eq 1 ]; then
        echo -e "${YELLOW}Enabling Firewall${RESET}"
        sudo ufw enable
    fi
}

# Function to list real user accounts
list_real_users() {
    echo -e "${YELLOW}List of Actual User Accounts:${RESET}"
    awk -F: '($3 >= 1000) && ($1 != "nobody") {print $1}' /etc/passwd
}

# Function to find users with sudo permissions
find_sudo_users() {
    echo -e "${YELLOW}Users with Sudo Permissions:${RESET}"
    if getent group sudo > /dev/null; then
        echo "Members of the 'sudo' group:"
        getent group sudo | cut -d: -f4 | tr ',' '\n'
    else
        echo -e "${RED}No 'sudo' group found.${RESET}"
    fi

    echo -e "${YELLOW}Users with explicit sudo permissions from /etc/sudoers:${RESET}"
    awk -F: '/^[^#]/ { print $1 }' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sort | uniq
}

# Function to compare users in passwd and group files
compare_passwd_group() {
    echo -e "${YELLOW}Users in /etc/passwd but not in /etc/group:${RESET}"
    local passwd_users=$(cut -d: -f1 /etc/passwd)
    local group_users=$(cut -d: -f1 /etc/group)
    local IFS=$'\n'
    local passwd_array=($passwd_users)
    local group_array=($group_users)

    for user in "${passwd_array[@]}"; do
        if ! [[ " ${group_array[*]} " =~ " $user " ]]; then
            echo -e "${RED}$user${RESET}"
        fi
    done
}

# Function to check IPv6 status and disable it if needed
check_ipv6() {
    ipv6_status=$(sysctl net.ipv6.conf.all.disable_ipv6)
    echo -e "${BLUE}Current IPv6 status: $ipv6_status${RESET}"
    if [ "$IPv6Disable" -eq 1 ]; then
        echo -e "${YELLOW}Disabling IPv6...${RESET}"
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
        echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        echo "IPv6 has been disabled."
    fi
}

# Function to list users with /bin/bash as their shell
list_bash_users() {
    echo -e "${YELLOW}Users with /bin/bash as their shell:${RESET}"
    if [ "$Mint" -eq 1 ]; then
        awk -F: '$7 == "/usr/bin/bash" {print $1}' /etc/passwd
    else
        awk -F: '$7 == "/bin/bash" {print $1}' /etc/passwd
    fi
}

# Function to check NOPASSWD and !authenticate entries in /etc/sudoers
check_sudo_entries() {
    echo -e "${YELLOW}Checking for NOPASSWD or !authenticate entries in /etc/sudoers...${RESET}"
    if grep -q "NOPASSWD" /etc/sudoers; then
        echo -e "${RED}Found NOPASSWD entries in /etc/sudoers:${RESET}"
        grep "NOPASSWD" /etc/sudoers
    else
        echo -e "${GREEN}Did not find any NOPASSWD entries found in /etc/sudoers.${RESET}"
    fi
    if grep -q "!authenticate" /etc/sudoers; then
        echo -e "${RED}Found !authenticate entries in /etc/sudoers:${RESET}"
        grep "!authenticate" /etc/sudoers
    else
        echo -e "${GREEN}Did not find any !authenticate entries found in /etc/sudoers.${RESET}"
    fi
}

# Function to display source repositories
display_repos() {
    echo -e "${YELLOW}Displaying source repos:${RESET}"
    if [ "$Mint" -eq 1 ]; then
        cat /etc/apt/sources.list.d
    else
        cat /etc/yum.repos.d/
    fi
}

# Function to check syslog configuration in /etc/sudoers
check_syslog_config() {
    echo -e "${YELLOW}Checking for syslog configuration in /etc/sudoers...${RESET}"
    if sudo grep -qi 'syslog' /etc/sudoers; then
        echo "Syslog is configured for sudoers."
    else
        echo -e "${RED}No syslog configuration found for sudoers in /etc/sudoers. Include syslog=authpriv in the Defaults line.${RESET}"
    fi
}

# Function to check if bogus error responses are being ignored
check_bogus_error_responses() {
    echo -e "${YELLOW}Checking to see if bogus error responses are being ignored...${RESET}"
    if grep -q '^net.ipv4.icmp_ignore_bogus_error_responses[[:space:]]*=[[:space:]]*1' /etc/sysctl.conf; then
        echo -e "${GREEN}The setting net.ipv4.icmp_ignore_bogus_error_responses is correctly set to 1.${RESET}"
    else
        echo -e "${RED}The setting net.ipv4.icmp_ignore_bogus_error_responses is not set to 1 or is missing. Set it to 1 in /etc/sysctl.conf${RESET}"
    fi
}

# Function to check if secure redirects are disabled
check_secure_redirects() {
    echo -e "${YELLOW}Checking to see if secure redirects are disabled...${RESET}"
    if grep -q '^net.ipv4.conf.all.secure_redirects[[:space:]]*=[[:space:]]*0' /etc/sysctl.conf; then
        echo -e "${GREEN}The setting net.ipv4.conf.all.secure_redirects is correctly set to 0.${RESET}"
    else
        echo -e "${RED}The setting net.ipv4.conf.all.secure_redirects is not set to 0 or is missing. Set it to 0 in /etc/sysctl.conf${RESET}"
    fi
}

# Function to check if authfail is configured in PAM
check_authfail_configuration() {
    echo -e "${YELLOW}Checking to see if authfail is configured...${RESET}"
    if [[ $Mint = 1 ]]; then
        if grep -q 'authfail' /etc/pam.d/common-auth; then
            echo -e "${GREEN}The 'authfail' setting is present in /etc/pam.d/common-auth.${RESET}"
        else
            echo -e "${RED}The 'authfail' setting is NOT present in /etc/pam.d/common-auth.${RESET}"
        fi
    fi
    if [[ $Rocky = 1 ]]; then
        if grep -q 'authfail' /etc/pam.d/system-auth; then
            echo -e "${GREEN}The 'authfail' setting is present in /etc/pam.d/system-auth.${RESET}"
        else
            echo -e "${RED}The 'authfail' setting is NOT present in /etc/pam.d/system-auth.${RESET}"
        fi
    fi
}

# Function to check for secure hashing algorithms in PAM
check_secure_hashing_algorithm() {
    echo -e "${YELLOW}Checking to see if secure hashing algorithm is being used...${RESET}"
    if [[ $Mint = 1 ]]; then
        if grep -E 'pam_unix.*(yescrypt|sha512)' /etc/pam.d/common-password > /dev/null; then
            echo -e "${GREEN}Secure hashing algorithm (yescrypt or sha512) is used for pam_unix.${RESET}"
        else
            echo -e "${RED}No secure hashing algorithm (yescrypt or sha512) is found for pam_unix. Edit /etc/pam.d/common-password to:"
            echo -e "password   requisite  pam_unix.so obscure yescrypt"
            echo -e "OR"
            echo -e "password   requisite  pam_unix.so obscure sha512${RESET}"
        fi
    fi
    if [[ $Rocky = 1 ]]; then
        if grep -E 'pam_unix.*(yescrypt|sha512)' /etc/pam.d/password-auth > /dev/null; then
            echo -e "${GREEN}Secure hashing algorithm (yescrypt or sha512) is used for pam_unix.${RESET}"
        else
            echo -e "${RED}No secure hashing algorithm (yescrypt or sha512) is found for pam_unix. Edit /etc/pam.d/system-auth to:"
            echo -e "password   sufficient  pam_unix.so obscure yescrypt"
            echo -e "OR"
            echo -e "password   sufficient  pam_unix.so obscure sha512${RESET}"
        fi
    fi
}

# Function to search for common hacking tools and malware
maltools_finder() {
    declare -a tools=(
        "nmap"        # Network scanning tool
        "netcat"      # Networking utility
        "wireshark"   # Network protocol analyzer
        "tcpdump"     # Network packet analyzer
        "metasploit"  # Penetration testing framework
        "sqlmap"      # SQL injection tool
        "aircrack-ng" # Wireless network cracking tool
        "john"        # Password cracker
        "hashcat"     # Password recovery tool
        "curl"        # Data transfer tool
        "enum4linux"  # Enumeration tool
        "os-prober"   # Can contain passwords
        "dnsniff"
        "rfdump"
    )

    declare -a malware=(
        "strace"        # Network scanning tool
        "postfix"      # Networking utility
        "remmina"   # Network protocol analyzer
        "autopsy"     # Network packet analyzer
        "socat"  # Penetration testing framework
    )

    echo -e "${YELLOW}Searching for common hacking tools${RESET}"

    # Check for each tool in the system
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            tool_path=$(command -v "$tool")  # Get the path of the tool
            echo -e "${RED}Found: $tool at $tool_path${RESET}"

        else
            echo -e "${GREEN}Not found: $tool${RESET}"
        fi
    done

    echo -e "${YELLOW}Searching for common malware...${RESET}"
    echo -e "${BLUE}NOTE: Just because it does appear doesn't mean it defintely malicous.
    check the version and running procceses. This list was compiled from previous backdoor hivestorm writeups.${RESET}"

    for malware in "${malware[@]}"; do
        if command -v "$malware" &> /dev/null; then
            malware_path=$(command -v "$malware")  # Get the path of the malware
            echo -e "${RED}Found: $malware at $malware_path${RESET}"

        else
            echo -e "${GREEN}Not found: $malware${RESET}"
        fi
    done

    # Searching for suspicious files
    echo -e "${YELLOW}Searching for suspicious files in common directories..${RESET}"

    # Directories to search
    directories=("/etc" "/usr/bin" "/usr/local/bin" "/tmp" "/var/tmp")

    for dir in "${directories[@]}"; do
        # Find files with suspicious extensions or names
        find "$dir" -type f \( -iname "*.mp4" -o -iname "*.mp3" -o -iname "*.pdf" -o -iname "*.sh" -o -iname "*.py" -o -iname "*.pl" -o -iname "*.exe" -o -iname "*game*" \) -exec ls -lh {} \;
    done

    # Check for unusual cron jobs
    echo -e "${YELLOW}Checking for unusual cron jobs..${RESET}"
    crontab -l 2>/dev/null

    # Check for network activity
    echo -e "${YELLOW}Checking for active network connections...${RESET}"
    ss -tuln

    echo -e "${GREEN}Scan completed.${RESET}"

}

# Function to display files in the Home directory
display_home_files() {
        echo -e "${YELLOW}Displaying files in Home:${RESET}"

        # Define an array of common suspicious or non-work-related file patterns
        declare -a suspicious_patterns=(
            "*.sh"   # Shell scripts
            "*.py"   # Python scripts
            "*.pl"   # Perl scripts
            "*.exe"  # Executable files
            ".*"     # Hidden files (dot files)
            "*.mp4"   # Video files
            "*.mp3"   # Audio files
            "*.pdf"   # Document files
        )

        # Create a find command with multiple patterns
        find_command="find /home/ -type f"

        # Add patterns to the find command for each suspicious pattern
        for pattern in "${suspicious_patterns[@]}"; do
            find_command+=" -o -name '${pattern}'"
        done

        # Execute the find command
        eval "$find_command" | while read -r FILE; do
            # Check if the file matches any suspicious patterns
            if [[ "$FILE" == *.sh || "$FILE" == *.py || "$FILE" == *.pl || "$FILE" == *.exe || "$FILE" == .* ]]; then
                echo -e "${RED}${FILE}${RESET}"  # Mark suspicious files in red
            else
                if [ "$HomeSearch" -eq 1 ]; then
                    echo "${FILE}"  # Display other files normally
                fi
            fi
        done

}

# Function to display currently running services
display_running_services() {
    echo -e "${YELLOW}Currently Running Services:${RESET}"

    # Check if systemctl is available (for systemd systems)
    if command -v systemctl &> /dev/null; then
        # Display services using systemctl
        systemctl list-units --type=service --state=running
    elif command -v service &> /dev/null; then
        # For systems using init.d or older service command
        service --status-all 2>/dev/null | grep '+' || echo -e "${RED}No service management command found.${RESET}"
    else
        echo -e "${RED}No service management command found.${RESET}"
    fi
}

# Function to check /etc/login.defs for insecure settings
login_defs() {
    # Define the file path for /etc/login.defs
    LOGIN_DEFS="/etc/login.defs"

    # Function to check if a parameter is set correctly
    check_param() {
        PARAM=$1
        EXPECTED_VALUE=$2
        DESCRIPTION=$3

        # Extract the parameter's current value from /etc/login.defs
        CURRENT_VALUE=$(grep "^$PARAM" $LOGIN_DEFS | awk '{print $2}')

        if [ -z "$CURRENT_VALUE" ]; then
            echo -e "${RED}Warning: $PARAM is not set. $DESCRIPTION${RESET}"
        elif [ "$CURRENT_VALUE" != "$EXPECTED_VALUE" ]; then
            echo -e "${RED}Warning: $PARAM is set to $CURRENT_VALUE but should be $EXPECTED_VALUE. $DESCRIPTION${RESET}"
        else
            echo -e "${GREEN}$PARAM is set correctly to $CURRENT_VALUE.${RESET}"
        fi
    }

    # Check for password aging policy
    echo -e "${YELLOW}Checking /etc/login.defs for bad policies.${RESET}"

    check_param "PASS_MAX_DAYS" "90" "Recommended to set maximum password age to 90 days."
    check_param "PASS_MIN_DAYS" "7" "Recommended to set minimum password age to 7 days."
    check_param "PASS_WARN_AGE" "7" "Recommended to set password warning age to at least 7 days."

    # Check UID and GID range for regular users
    echo -e "${YELLOW}Checking UID/GID ranges...${RESET}"

    check_param "UID_MIN" "1000" "Recommended to set minimum UID for user accounts to 1000."
    check_param "UID_MAX" "60000" "Recommended to set maximum UID for user accounts below 60000."
    check_param "GID_MIN" "1000" "Recommended to set minimum GID for group accounts to 1000."
    check_param "GID_MAX" "60000" "Recommended to set maximum GID for group accounts below 60000."

    # Check for other important security settings
    echo -e "${YELLOW}Checking other security settings...${RESET}"

    check_param "LOGIN_RETRIES" "5" "Recommended to set maximum login retries to 5."
    check_param "LOGIN_TIMEOUT" "60" "Recommended to set login timeout to 60 seconds."
    check_param "UMASK" "077" "Recommended to set UMASK to 077 for maximum file permission security."

    # Check if user accounts should lock after inactivity (if defined)
    INACTIVE=$(grep "^INACTIVE" $LOGIN_DEFS | awk '{print $2}')
    if [ -z "$INACTIVE" ]; then
        echo -e "${RED}Warning: INACTIVE is not set. It's recommended to lock inactive accounts.${RESET}"
    else
        echo -e "${GREEN}INACTIVE is set correctly to $INACTIVE.${RESET}"
    fi

}

#Terminal is real....right?
check_terminal
#Are we running as root?
check_root
#Select OS
select_os
set_home_search
#If UFW is the default firewall we should enable it
set_firewall
#Do we want to disable ipv6? If so it does it permanetley
set_ipv6

#Now lets begin auditing.
#Lets start with user checks
echo -e "${PINK}
################################################
#---------------) User Checks (----------------#
################################################${RESET}"
list_real_users
echo ""
find_sudo_users
echo ""
compare_passwd_group
echo ""
list_bash_users
echo ""
echo -e "${PINK}
##################################################
#---------------) System Checks (----------------#
##################################################${RESET}"
enable_firewall
echo ""
display_repos
echo ""
check_syslog_config
echo ""
check_bogus_error_responses
echo ""
check_secure_redirects
echo ""
check_ipv6
echo ""

echo -e "${PINK}
##################################################
#---------------) Policy Checks (----------------#
##################################################${RESET}"
check_sudo_entries
echo ""
check_authfail_configuration
echo ""
check_secure_hashing_algorithm
echo ""
login_defs
echo ""

echo -e "${PINK}
###################################################
#---------------) Service Checks (----------------#
###################################################${RESET}"
display_running_services
echo ""

echo -e "${PINK}
###################################################################
#---------------) Unauthorized Software & Malware(----------------#
###################################################################${RESET}"
maltools_finder
echo ""
display_home_files
