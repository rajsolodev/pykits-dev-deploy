#!/bin/bash
set -e

echo "========================================"
echo " USER VPS SETUP + PROJECT CLONE"
echo " (Run as sudo user, NOT root)"
echo "========================================"
echo ""

# ---- Root Check ----
if [ "$EUID" -eq 0 ]; then
  echo "❌ Do NOT run as root. Run as sudo user."
  exit 1
fi

# ---- Helpers ----
confirm () {
  read -p "$1 (y/n): " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

run () {
  echo -e "\n▶ $1"
  sudo bash -c "$1"
}

# ---- Project Info ----
read -p "Project name (e.g. digistore): " PROJECT
read -p "GitHub username/org: " GITHUB_USER
read -p "Repo name: " REPO_NAME

HOME_DIR="$HOME"
TARGET_PATH="$HOME_DIR/$PROJECT"

SSH_DIR="$HOME_DIR/.ssh"
KEY_NAME="${PROJECT}_ed25519"
KEY_PATH="$SSH_DIR/$KEY_NAME"
CONFIG_PATH="$SSH_DIR/config"
HOST_ALIAS="github-$PROJECT"

# ---- Fix Broken Docker Repo ----
fix_broken_docker_repo () {
  echo -e "\n🧹 Checking for broken Docker repo..."
  sudo rm -f /etc/apt/sources.list.d/docker.sources
}

# -------------------------
# System Update
# -------------------------
if confirm "Run system update & upgrade?"; then
  fix_broken_docker_repo
  run "DEBIAN_FRONTEND=noninteractive apt update && apt upgrade -y \
      -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold"
fi

# -------------------------
# Basic Tools
# -------------------------
if confirm "Install git, curl, ufw, ca-certificates, make?"; then
  run "DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates curl gnupg lsb-release ufw git make"
fi

# -------------------------
# Firewall
# -------------------------
if confirm "Configure firewall (SSH, 80, 443)?"; then
  run "ufw default deny incoming"
  run "ufw default allow outgoing"
  run "ufw allow OpenSSH"
  run "ufw allow 80"
  run "ufw allow 443"
  run "ufw --force enable"
  run "ufw status verbose"
fi

# -------------------------
# Docker Official Install
# -------------------------
if confirm "Install Docker (official repo)?"; then
  echo -e "\n▶ Installing Docker (official repository)"

  run "install -m 0755 -d /etc/apt/keyrings"
  run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
  run "chmod a+r /etc/apt/keyrings/docker.asc"

  UBUNTU_CODENAME=$(lsb_release -cs)

  run "cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $UBUNTU_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF"

  run "apt update"
  run "DEBIAN_FRONTEND=noninteractive apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  run "systemctl enable docker"
  run "systemctl start docker"

  run "usermod -aG docker $USER"

  echo ""
  echo "⚠ Logout & login again for docker group to take effect (recommended)"
fi

# -------------------------
# SSH Key Setup
# -------------------------
echo -e "\n🔐 Setting up GitHub SSH key"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$KEY_PATH" ]; then
  if confirm "Generate SSH key $KEY_NAME ?"; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$PROJECT" -N ""
  fi
else
  echo "SSH key already exists"
fi

# -------------------------
# SSH Config
# -------------------------
CONFIG_ENTRY="
Host $HOST_ALIAS
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
"

if ! grep -q "$HOST_ALIAS" "$CONFIG_PATH" 2>/dev/null; then
  if confirm "Add SSH config host entry?"; then
    echo "$CONFIG_ENTRY" >> "$CONFIG_PATH"
    chmod 600 "$CONFIG_PATH"
  fi
fi

# -------------------------
# Known Hosts
# -------------------------
ssh-keyscan github.com >> "$SSH_DIR/known_hosts"

# -------------------------
# Show Public Key
# -------------------------
echo ""
echo "=============================="
echo " ADD THIS KEY TO GITHUB DEPLOY KEYS"
echo "=============================="
echo ""
cat "$KEY_PATH.pub"

echo ""
echo "👉 STEP REQUIRED:"
echo "1. Open your GitHub repo"
echo "2. Go to: Settings → Deploy Keys"
echo "3. Click: Add deploy key"
echo "4. Paste the above public key"
echo "5. Enable: Allow write access (if needed)"
echo ""

while true; do
  read -p "Type CLONE after adding the key: " CONFIRM_WORD
  if [ "$CONFIRM_WORD" == "CLONE" ]; then
    break
  fi
  echo "Please type CLONE only after adding the deploy key."
done

# -------------------------
# Test SSH
# -------------------------
echo -e "\n▶ Testing SSH connection to GitHub..."
set +e
ssh -T "$HOST_ALIAS"
SSH_STATUS=$?
set -e

if [ "$SSH_STATUS" -ne 1 ]; then
  echo "❌ SSH authentication failed. Check deploy key setup."
  exit 1
fi

echo "✅ SSH authentication successful."

# -------------------------
# Clone Repo
# -------------------------
REPO_URL="git@$HOST_ALIAS:$GITHUB_USER/$REPO_NAME.git"

if [ -d "$TARGET_PATH" ]; then
  echo "⚠ Folder already exists: $TARGET_PATH"
else
  if confirm "Clone repo into $TARGET_PATH ?"; then
    git clone "$REPO_URL" "$TARGET_PATH"
  fi
fi

# -------------------------
# Done
# -------------------------
echo ""
echo "========================================"
echo " VPS SETUP COMPLETED"
echo "========================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. (If Docker group added) logout & login again:"
echo "   exit"
echo "   ssh <user>@<VPS_IP>"
echo ""
echo "2. Go to project:"
echo "   cd ~/$PROJECT"
echo ""
echo "3. Setup .env file"
echo ""
echo "4. Run first time deploy:"
echo "   bash first_time_deploy.sh  (or your installer)"
echo ""
echo "After this your site will be LIVE with HTTPS 🚀"
echo ""
