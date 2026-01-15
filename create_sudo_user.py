import os
import subprocess
import sys

def run(cmd):
    print(f"\n▶ {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def prompt(msg):
    print(msg, end="", flush=True)
    with open("/dev/tty") as tty:
        return tty.readline().strip()

if os.geteuid() != 0:
    print("❌ Run as root")
    sys.exit(1)

print("""
========================================
 CREATE SUDO USER FOR DEPLOYMENT
========================================
""")

username = prompt("Enter new username: ")
password = prompt("Enter password: ")

if not username or not password:
    print("❌ Username and password required")
    sys.exit(1)

# Check if user exists
result = subprocess.run(
    ["id", username],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)

if result.returncode == 0:
    print("❌ User already exists")
    sys.exit(1)

print("\nCreating user (non-interactive)...")
run(f"useradd -m -s /bin/bash {username}")

print("Setting password...")
run(f'echo "{username}:{password}" | chpasswd')

print("Adding user to sudo group...")
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

3. Then run VPS setup:
   curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/vps_setup.py | python3
""")
