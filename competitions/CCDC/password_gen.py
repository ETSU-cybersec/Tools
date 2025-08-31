import string
import random
import subprocess

# Generates random passwords and assigns them to a username
def generate_passwords(username_list):
    # Defines lists of symbols/characters. 
    symbols = "!@#$%^&*_.,"

    ccdcPassword_alphabet = list(string.ascii_letters + string.digits)
    normalPassword_alphabet = list(string.ascii_letters + string.digits + ''.join(symbols))
    password_dict = {}

    # Use a limited list for certain competitions
    print("Does the scope limit special symbols [y/n]")
    scope = input()
    if scope == "y" or scope == "Y":
        for username in username_list:
            finalPassword = ''.join(random.choice(ccdcPassword_alphabet) for _ in range(12))
            password_dict[username] = finalPassword
    else:
        for username in username_list:
            finalPassword = ''.join(random.choice(normalPassword_alphabet) for _ in range(12))
            password_dict[username] = finalPassword

    # Returns a dictionary binding a new password to a username
    return password_dict

# Runs a linux command that changes the password. MUST USE SUDO.
def change_password(username, password):

    command = f'echo "{username}:{password}" | sudo chpasswd'
    try:
        subprocess.run(command, shell=True, check=True)
        print(f"Success! New password is: {password}")
    except subproess.CalledProcessError as e:
        print(f"Failed! Are you root? {e}")

# main method
def main():
    # Declaring Variables for main thread
    userInput = ""
    username_list = []
    password_list = []

    # Reads the /etc/passwd file and sorts by :
    passwd = open("/etc/passwd", "r")
    print("Selecting Users....")

    for line in passwd:
        parts = line.strip().split(":")
        username = parts[0]
        userUID = int(parts[2])
    
        # Limits list to only users or root
        if userUID >= 1000 or userUID == 0:
            print(f"Current User: {username}")
            print("Do you want to give this user a password? [y/n]")
            userInput= input()
            if userInput == "y" or userInput == "Y":
                username_list.append(username)
                userInput = ""
    
    # Pulls passwords/usernames from the generate_passwords method
    password_dict = generate_passwords(username_list)

    # For every entry in our password dictionary, we change the password of that user.
    for username, password in password_dict.items():
        change_password(username, password)

print(r"""
 ██████ ██      ███████  █████  ███    ██ ██████   █████  ███████ ███████ 
██      ██      ██      ██   ██ ████   ██ ██   ██ ██   ██ ██      ██      
██      ██      █████   ███████ ██ ██  ██ ██████  ███████ ███████ ███████ 
██      ██      ██      ██   ██ ██  ██ ██ ██      ██   ██      ██      ██ 
 ██████ ███████ ███████ ██   ██ ██   ████ ██      ██   ██ ███████ ███████
 """)
print("Press enter to begin....")
input()
main()
