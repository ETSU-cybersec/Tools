#!/bin/bash
#Author: Kaiden Mix
#Installation Script for ATAP Installer on a Linux Mint System
#Set Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${RESET}" 
   exit 1
fi
# Define the required directory path
DIR="/root/Documents"

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo -e "${YELLOW}Documents folder does not exist. Creating it...${RESET}"
    sudo mkdir -p "$DIR"
else
    echo -e "${GREEN}Documents folder already exists.${RESET}"
fi
# Download the PowerShell .deb package
echo -e "${YELLOW}Downloading PowerShell...${RESET}"
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/powershell_7.4.5-1.deb_amd64.deb

# Install the downloaded package
echo -e "${YELLOW}Installing PowerShell...${RESET}"
dpkg -i powershell_7.4.5-1.deb_amd64.deb

# Start PowerShell and install ATAPAuditor module
echo -e "${YELLOW}Starting PowerShell to install the ATAPAuditor module...${RESET}"
sudo pwsh -Command "Install-Module -Name ATAPAuditor -Force; exit" 
echo -e "${GREEN}PowerShell and ATAPAuditor installation complete!${RESET}"
#Runs a report for Ubuntu
echo -e "${YELLOW}Running ATAP for Ubuntu 22.04${RESET}"
sudo pwsh -Command "Save-ATAPHtmlReport -ReportName 'Ubuntu 22.04'"

# Clean up by removing the downloaded .deb file
echo -e "${YELLOW}Cleaning up...${RESET}"
rm powershell_7.4.5-1.deb_amd64.deb



