#!/bin/bash
set -e

echo "========================================"
echo " DOCKER INSTALLER (Official Repo)"
echo "========================================"

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do NOT run as root. Use sudo user."
  exit 1
fi

. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
  echo "❌ Only Ubuntu is supported."
  exit 1
fi

CODENAME=$VERSION_CODENAME

if [[ "$CODENAME" != "jammy" && "$CODENAME" != "noble" ]]; then
  echo "⚠ Ubuntu $CODENAME not officially supported by Docker."
  echo "➡ Falling back to jammy repo."
  CODENAME="jammy"
fi

run () {
  echo -e "\n▶ $1"
  sudo bash -c "$1"
}

echo "Installing Docker..."

run "install -m 0755 -d /etc/apt/keyrings"
run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
run "chmod a+r /etc/apt/keyrings/docker.asc"

run "cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF"

run "apt update"

run "DEBIAN_FRONTEND=noninteractive apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

run "systemctl enable docker"
run "systemctl start docker"

run "usermod -aG docker $USER"

echo ""
echo "✅ Docker installed successfully"
echo "⚠ Logout & login again to use docker without sudo"
