import os
import subprocess
import sys

def run(cmd):
    print(f"\n▶ {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def prompt(msg):
    # Always read from real terminal, even if piped
    return input(msg) if sys.stdin.isatty() else open("/dev/tty").readline().strip()

if os.geteuid() != 0:
    print("Run as root")
    sys.exit(1)

print("""
========================================
 CREATE SUDO USER FOR DEPLOYMENT
========================================
""")

print("Enter new username:")
username = prompt("> ").strip()

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

print(f"""
========================================
  USER CREATED SUCCESSFULLY
========================================

Next Steps:

1. Logout from root:
   exit

2. Login with new user:
   ssh {username}@YOUR_VPS_IP

3. Then run vps_setup.py script as this user.
""")
