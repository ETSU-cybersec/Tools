# Python
# Author: Kaiden Mix
# Wrapper for Rustscan and Dirsearch, it will run rustscan on the target. If it detects
# a common HTTP or HTTPS port it will then run dirsearch on that port.

import re
import subprocess
import sys

#Colors for outputs
RED = "\033[31m"
BLUE = "\033[34m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RESET = "\033[0m"

#Variables for checking if port exists
port80 = False
port8080 = False
port8000 = False
port8888 = False
port443 = False
port8443 = False
port4433 = False
port8444 = False

#Function for operating RustScan
def rustscan(target):
    global port80, port8888, port8088, port8000, port443, port4433, port8444, port8443
    #Rustscan Parameters
    command = ["rustscan", "-a", target]
    print(f"{YELLOW}Running rustscan on {target}{RESET}")
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, universal_newlines=True)
    log = ""
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
           break
        if output:
           print(output.strip())
           log += output


    #Make sure rustscan didnt break
    if process.returncode == 0:
        print(output)
        print(f"{YELLOW}Looking for an HTTP or HTTPS service...{RESET}\n")
        #print(process.stdout)
        #Checks for common http and https ports
        if re.search(r"80/tcp\s+open\s+http", log):
                port80 = True
                print(f"{GREEN}Found Port 80 running HTTP{RESET}")

        if re.search(r"8080/tcp\s+open\s+http", log):
                port8080 = True
                print(f"{GREEN}Found Port 8080 running HTTP{RESET}")

        if re.search(r"8000/tcp\s+open\s+http", log):
                port8000 = True
                print(f"{GREEN}Found Port 8000 running HTTP{RESET}")

        if re.search(r"8088/tcp\s+open\s+http", log):
                port8088 = True
                print(f"{GREEN}Found Port 8088 running HTTP{RESET}")

        if re.search(r"443/tcp\s+open\s+https", log):
                port443 = True
                print(f"{GREEN}Found Port 443 running HTTPS{RESET}")

        if re.search(r"8443/tcp\s+open\s+https", log):
                port8443 = True
                print(f"{GREEN}Found Port 8443 running HTTPS{RESET}")

        if re.search(r"4443/tcp\s+open\s+https", log):
                port4433 = True
                print(f"{GREEN}Found Port 4433 running HTTPS{RESET}")

        if re.search(r"8443/tcp\s+open\s+https", log):
                port8444 = True
                print(f"{GREEN}Found Port 8444 running HTTPS{RESET}")

    #Rustscan broke
    else:
        print(f"{RED}RustScan failed{RESET}")
        sys.exit(1)

#Function for operating dirsearch
def dirsearch(target, port):
    print(f"{YELLOW}Running dirsearch on {target} on port {port}{RESET}")
    command = ["dirsearch", "-u", target+":"+port]
    print(command)
    dirprocess = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            bufsize=0,
            close_fds=True
        )
    log = ""
    while True:
            output = dirprocess.stdout.readline()
            if output == '' and dirprocess.poll() is not None:
                print(f"{GREEN} \nDirsearch Complete{RESET}")
                break
            if output:
                line = output.strip()
                if '/' in line and not line.startswith('/'):
                    # Extract paths (strings containing '/')
                    paths = [word for word in line.split() if word.startswith('/')]
                    for path in paths:
                        print(f"{BLUE}"+path)
                        log += path + "\n"

    if dirprocess.returncode == 0:
       print(f"\n\nThank you for using Valkyrie :)")
    else:
        print(f"{RED}Dirsearch has failed{RESET}")
        sys.exit(1)

#Store header information
def titleCard():
    header = rf"""{BLUE}
     ___      ___ ________  ___       ___  __        ___    ___ ________  ___  _______
    |\  \    /  /|\   __  \|\  \     |\  \|\  \     |\  \  /  /|\   __  \|\  \|\  ___ \
    \ \  \  /  / | \  \|\  \ \  \    \ \  \/  /|_   \ \  \/  / | \  \|\  \ \  \ \   __/|
     \ \  \/  / / \ \   __  \ \  \    \ \   ___  \   \ \    / / \ \   _  _\ \  \ \  \_|/__
      \ \    / /   \ \  \ \  \ \  \____\ \  \\ \  \   \/  /  /   \ \  \\  \\ \  \ \  \_|\ \
       \ \__/ /     \ \__\ \__\ \_______\ \__\\ \__\__/  / /      \ \__\\ _\\ \__\ \_______\
        \|__|/       \|__|\|__|\|_______|\|__| \|__|\___/ /        \|__|\|__|\|__|\|_______|
                                                   \|___|/

    {RESET}{GREEN}By Kaiden Mix
    {RESET}"""
    return header

#Takes user input for rustscan and checks if it found HTTP/HTTPS services. If so pass it to dirsearch
def userMenu():
    print(titleCard())
    print(f"{RED}WARNING: Unauthorized use of this tool is illegal and unethical.\n"
    "Ensure explicit permission, written consent, and compliance with laws and regulations.\n"

    "USE THIS TOOL RESPONSIBLY AND ONLY FOR AUTHORIZED PENETRATION TESTING PURPOSES.")

    print(f"\n\n{BLUE}Welcome to Valkyrie")

    target = input(f"{YELLOW}Enter the target IP{RESET}\n")
    rustscan(target)

    #Yes I know i could have just made a list but this would require less debugging for me so im going with it
    if port80 == True:
        dirsearch(target, "80")
    if port8080 == True:
        dirsearch(target, "8080")
    if port8000 == True:
        dirsearch(target, "8000")
    if port8888 == True:
        dirsearch(target, "8888")
    if port443 == True:
        dirsearch(target, "443")
    if port8443 == True:
        dirsearch(target, "8443")
    if port4433 == True:
        dirsearch(target, "4433")
    if port8444 == True:
        dirsearch(target, "8444")

    if port443 == False and port80 == False and port443 == False and port80 == False and port443 == False and port80 == False and port443 == False and port80 == False:
            #Ask user to put in HTTP/HTTPS port if its been moved to an uncommon port
            print(f"{RED}No HTTP or HTTPS ports detected{RESET}\n{YELLOW}It may not be open or has been moved to a different port.")
            port = input(f"If its been moved, enter it here, or leave blank to cancel dirsearch scan\n{RESET}")
            if port.strip():
                dirsearch(target, port)

            else:
                print(f"Cancelling dirsearch")
#Runs userMenu upon launch
userMenu()
