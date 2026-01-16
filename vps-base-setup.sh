#!/bin/bash
set -e

echo "========================================"
echo " VPS BASE SETUP (Ubuntu Only)"
echo "========================================"

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do NOT run as root. Use sudo user."
  exit 1
fi

. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
  echo "❌ Only Ubuntu is supported. Detected: $PRETTY_NAME"
  exit 1
fi

confirm () {
  read -p "$1 (y/n): " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

run () {
  echo -e "\n▶ $1"
  sudo bash -c "$1"
}

# ---- System Update ----
if confirm "Run system update & upgrade?"; then
  run "DEBIAN_FRONTEND=noninteractive apt update && apt upgrade -y"
fi

# ---- Basic Tools ----
if confirm "Install git, curl, ufw, make, ca-certificates?"; then
  run "DEBIAN_FRONTEND=noninteractive apt install -y git curl ufw make ca-certificates gnupg lsb-release"
fi

# ---- Firewall ----
if confirm "Configure firewall (SSH, 80, 443)?"; then
  run "ufw default deny incoming"
  run "ufw default allow outgoing"
  run "ufw allow OpenSSH"
  run "ufw allow 80"
  run "ufw allow 443"
  run "ufw --force enable"
  run "ufw status verbose"
fi

echo ""
echo "✅ VPS base setup completed"
