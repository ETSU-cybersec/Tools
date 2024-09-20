# Python
# Author: Kaiden Mix
# Wrapper for Rustscan and Dirsearch, it will run rustscan on the target. If it detects
# a common HTTP or HTTPS port it will then run dirsearch on that port.


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
    print(f"{YELLOW}Running rustscan on {target}{RESET}")
    result = subprocess.run(
        #Rustscan Parameters
        ["rustscan", "-a", target],
        capture_output=True,
        text=True
    )
    #Make sure rustscan didnt break
    if result.returncode == 0:
        print("Rustscan Output:\n")
        print(result.stdout)
        #Checks for common http and https ports
        if "80/tcp open  http" in result.stdout:
                port80 = True
                print(f"{GREEN}Found Port 80 running HTTP{RESET}")

        if "8080/tcp open  http" in result.stdout:
                port8080 = True
                print(f"{GREEN}Found Port 8080 running HTTP{RESET}")

        if "8000/tcp open  http" in result.stdout:
                port8000 = True
                print(f"{GREEN}Found Port 8000 running HTTP{RESET}")

        if "8088/tcp open  http" in result.stdout:
                port8088 = True
                print(f"{GREEN}Found Port 8088 running HTTP{RESET}")

        if "443/tcp open  https" in result.stdout:
                port443 = True
                print(f"{GREEN}Found Port 443 running HTTPS{RESET}")

        if "8443/tcp open  https" in result.stdout:
                port8443 = True
                print(f"{GREEN}Found Port 8443 running HTTPS{RESET}")

        if "4433/tcp open  https" in result.stdout:
                port4433 = True
                print(f"{GREEN}Found Port 4433 running HTTPS{RESET}")

        if "8444/tcp open  https" in result.stdout:
                port8444 = True
                print(f"{GREEN}Found Port 8444 running HTTPS{RESET}")

    #Rustscan broke
    else:
        print(f"{RED}RustScan failed{RESET}\n{YELLOW}Displaying Rustscan Output:{RESET}\n\n"+ result.stdout)
        sys.exit(1)

#Function for operating dirsearch
def dirsearch(target, port):
    print(f"{YELLOW}Running dirsearch on {target} on port {port}{RESET}")
    result = subprocess.run(
        ["python3", "dirsearch", "-u", target, port],
        capture_output=True,
        text=True
    )
    print(result.stdout)

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
    {RESET}"""
    return header

#Takes user input for rustscan and checks if it found HTTP/HTTPS services. If so pass it to dirsearch
def userMenu():
    print(titleCard())
    print(f"Welcome to Valykrie, please read documentation for use case")
    target = input(f"{YELLOW}Enter the target IP{RESET}\n")
    rustscan(target)

    #Yes I know i could have just made a list but this would require less debugging for me so im going with it
    if port80 == True:
        dirsearch(target, 80)
    if port8080 == True:
        dirsearch(target, 8080)
    if port8000 == True:
        dirsearch(target, 8000)
    if port8888 == True:
        dirsearch(target, 8888)
    if port443 == True:
        dirsearch(target, 443)
    if port8443 == True:
        dirsearch(target, 8443)
    if port4433 == True:
        dirsearch(target, 4433)
    if port8444 == True:
        dirsearch(target, 8444)

    if port443 == False and port80 == False and port443 == False and port80 == False and port443 == False and port80 == False and port443 == False and port80 == False:
            #Ask user to put in HTTP/HTTPS port if its been moved to an uncommon port
            print(f"{RED}No HTTP or HTTPS ports detected{RESET}\n{YELLOW}It may not be open or has been moved to a different port.")
            user_input = input(f"If its been moved, enter it here, or leave blank to cancel dirsearch scan{RESET}")
            if user_input.strip():
                dirsearch(target, user_input)

            else:
                print(f"Cancelling dirsearch")
#Runs userMenu upon launch
userMenu()
