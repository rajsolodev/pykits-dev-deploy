#!/bin/bash
set -e

echo "========================================"
echo " PROJECT SETUP + GITHUB CLONE"
echo "========================================"

TTY=/dev/tty

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do NOT run as root."
  exit 1
fi

confirm () {
  read -p "$1 (y/n): " ans < $TTY
  [[ "$ans" =~ ^[Yy]$ ]]
}

# ---- User Input (TTY SAFE) ----
read -p "Project name (folder): " PROJECT < $TTY
read -p "GitHub username/org: " GITHUB_USER < $TTY
read -p "Repo name: " REPO_NAME < $TTY

PROJECT=$(echo "$PROJECT" | xargs)
GITHUB_USER=$(echo "$GITHUB_USER" | xargs)
REPO_NAME=$(echo "$REPO_NAME" | xargs)

if [ -z "$PROJECT" ] || [ -z "$GITHUB_USER" ] || [ -z "$REPO_NAME" ]; then
  echo "❌ All fields are required"
  exit 1
fi

TARGET="$HOME/$PROJECT"

SSH_DIR="$HOME/.ssh"
KEY_NAME="${PROJECT}_ed25519"
KEY_PATH="$SSH_DIR/$KEY_NAME"
CONFIG="$SSH_DIR/config"
HOST_ALIAS="github-$PROJECT"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ---- SSH Key ----
if [ ! -f "$KEY_PATH" ]; then
  if confirm "Generate SSH deploy key?"; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$PROJECT" -N ""
  else
    echo "❌ SSH key required to clone via SSH"
    exit 1
  fi
fi

# ---- SSH Config ----
if ! grep -q "$HOST_ALIAS" "$CONFIG" 2>/dev/null; then
  if confirm "Add SSH config entry?"; then
    cat >> "$CONFIG" <<EOF

Host $HOST_ALIAS
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF
    chmod 600 "$CONFIG"
  else
    echo "❌ SSH config entry required"
    exit 1
  fi
fi

ssh-keyscan github.com >> "$SSH_DIR/known_hosts" 2>/dev/null

echo ""
echo "=============================="
echo " ADD THIS KEY TO GITHUB DEPLOY KEYS"
echo "=============================="
cat "$KEY_PATH.pub"
echo "=============================="

echo ""
echo "Repo → Settings → Deploy Keys → Add key → Allow write (if needed)"
echo ""

# ---- Wait for user confirmation (TTY SAFE) ----
while true; do
  read -p "Type CLONE after adding key: " X < $TTY
  [ "$X" = "CLONE" ] && break
done

echo "Testing SSH..."
set +e
ssh -T "$HOST_ALIAS"
RES=$?
set -e

if [ "$RES" -ne 1 ]; then
  echo "❌ SSH failed"
  exit 1
fi

REPO_URL="git@$HOST_ALIAS:$GITHUB_USER/$REPO_NAME.git"

if [ -d "$TARGET" ]; then
  echo "Folder already exists: $TARGET"
else
  git clone "$REPO_URL" "$TARGET"
fi

echo ""
echo "✅ Project cloned to $TARGET"
