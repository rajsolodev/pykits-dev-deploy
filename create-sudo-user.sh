#!/bin/bash
set -e

echo "========================================"
echo " CREATE SUDO USER FOR DEPLOYMENT"
echo "========================================"
echo ""

# ---- Root Check ----
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

TTY=/dev/tty

# ---- Input (TTY SAFE) ----
read -p "Enter new username: " USERNAME < $TTY
read -s -p "Enter password: " PASSWORD < $TTY
echo "" > $TTY
read -s -p "Confirm password: " PASSWORD2 < $TTY
echo "" > $TTY

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "❌ Username and password required"
  exit 1
fi

if [ "$PASSWORD" != "$PASSWORD2" ]; then
  echo "❌ Passwords do not match"
  exit 1
fi

# ---- Check if user exists ----
if id "$USERNAME" >/dev/null 2>&1; then
  echo "❌ User already exists: $USERNAME"
  exit 1
fi

# ---- Create User ----
echo ""
echo "▶ Creating user..."
useradd -m -s /bin/bash "$USERNAME"

echo "▶ Setting password..."
echo "$USERNAME:$PASSWORD" | chpasswd

echo "▶ Adding user to sudo group..."
usermod -aG sudo "$USERNAME"

# ---- Done ----
echo ""
echo "========================================"
echo " ✅ USER CREATED SUCCESSFULLY"
echo "========================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. Logout from root:"
echo "   exit"
echo ""
echo "2. Login with new user:"
echo "   ssh $USERNAME@YOUR_VPS_IP"
echo ""
echo "3. Then run VPS setup:"
echo "   curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/vps-base-setup.sh | bash"
echo ""
