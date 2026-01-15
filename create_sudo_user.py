import os
import subprocess
import sys

def run(cmd):
    print(f"\n▶ {cmd}")
    subprocess.run(cmd, shell=True, check=True)

if os.geteuid() != 0:
    print("Run as root: sudo python3 create_sudo_user.py")
    sys.exit(1)

print("""
========================================
 CREATE SUDO USER FOR DEPLOYMENT
========================================
""")

username = input("Enter new username: ").strip()

if not username:
    print("Username cannot be empty")
    sys.exit(1)

# Check if user exists
result = subprocess.run(f"id {username}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if result.returncode == 0:
    print("User already exists")
    sys.exit(1)

print("\nYou will be asked to set password for the user.")
run(f"adduser {username}")

print("\nAdding user to sudo group...")
run(f"usermod -aG sudo {username}")

print("""
========================================
  USER CREATED SUCCESSFULLY
========================================

Next Steps:

1. Logout from root:
   exit

2. Login with new user:
   ssh {username}@YOUR_VPS_IP

3. Then run vps_setup.py script as this user.
""".format(username=username))
