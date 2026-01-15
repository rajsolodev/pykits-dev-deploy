import os
import subprocess
from pathlib import Path

def run(cmd, sudo=False):
    if sudo:
        cmd = f'sudo bash -c "{cmd}"'
    print(f"\n▶ {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def prompt(msg):
    print(msg, end="", flush=True)
    with open("/dev/tty") as tty:
        return tty.readline().strip()

def confirm(msg):
    ans = prompt(f"\n{msg} (y/n): ").lower()
    return ans == "y"

print("""
========================================
 USER VPS SETUP + PROJECT CLONE
 (Run as sudo user, NOT root)
========================================
""")

if os.geteuid() == 0:
    print(" Do NOT run as root. Run as new user with sudo access.")
    exit(1)

# -------------------------
# Project Info
# -------------------------
project = prompt("Project name (e.g. digistore): ")
github_user = prompt("GitHub username/org: ")
repo_name = prompt("Repo name: ")

home = Path.home()
target_path = home / project

ssh_dir = home / ".ssh"
key_name = f"{project}_ed25519"
key_path = ssh_dir / key_name
config_path = ssh_dir / "config"
host_alias = f"github-{project}"

# -------------------------
# System Update
# -------------------------
if confirm("Run system update & upgrade?"):
    run(
        "DEBIAN_FRONTEND=noninteractive "
        "apt update && "
        "apt upgrade -y "
        "-o Dpkg::Options::=--force-confdef "
        "-o Dpkg::Options::=--force-confold",
        sudo=True
    )

# -------------------------
# Basic Tools
# -------------------------
if confirm("Install git, curl, ufw, ca-certificates?"):
    run(
        "DEBIAN_FRONTEND=noninteractive "
        "apt install -y ca-certificates curl gnupg lsb-release ufw git",
        sudo=True
    )

# -------------------------
# Firewall
# -------------------------
if confirm("Configure firewall (SSH, 80, 443)?"):
    run("ufw default deny incoming", sudo=True)
    run("ufw default allow outgoing", sudo=True)
    run("ufw allow OpenSSH", sudo=True)
    run("ufw allow 80", sudo=True)
    run("ufw allow 443", sudo=True)
    run("ufw --force enable", sudo=True)
    run("ufw status verbose", sudo=True)

# -------------------------
# Docker Official Install
# -------------------------
if confirm("Install Docker (official repo)?"):
  print("\n Installing Docker (official repository)")

  run("install -m 0755 -d /etc/apt/keyrings", sudo=True)
  run("curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc", sudo=True)
  run("chmod a+r /etc/apt/keyrings/docker.asc", sudo=True)

  run(
        'echo "Types: deb\n'
        'URIs: https://download.docker.com/linux/ubuntu\n'
        'Suites: jammy\n'
        'Components: stable\n'
        'Signed-By: /etc/apt/keyrings/docker.asc" '
        '| sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null'
    )

  run("apt update", sudo=True)
  run(
        "DEBIAN_FRONTEND=noninteractive "
        "apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
        sudo=True
    )
  run("systemctl enable docker", sudo=True)
  run("systemctl start docker", sudo=True)

  run("usermod -aG docker $USER", sudo=True)
  print("\n Logout & login again for docker group to take effect (recommended).")

# -------------------------
# SSH Key Setup
# -------------------------
print("\nSetting up GitHub SSH key")

ssh_dir.mkdir(mode=0o700, exist_ok=True)

if not key_path.exists():
    if confirm(f"Generate SSH key {key_name}?"):
        run(f'ssh-keygen -t ed25519 -f "{key_path}" -C "{project}" -N ""')
else:
    print("SSH key already exists")

# -------------------------
# SSH Config
# -------------------------
config_entry = f"""
Host {host_alias}
    HostName github.com
    User git
    IdentityFile {key_path}
    IdentitiesOnly yes
"""

existing = config_path.read_text() if config_path.exists() else ""

if host_alias not in existing:
    if confirm("Add SSH config host entry?"):
        with open(config_path, "a") as f:
            f.write(config_entry)
        os.chmod(config_path, 0o600)

# -------------------------
# Known Hosts
# -------------------------
run("ssh-keyscan github.com >> ~/.ssh/known_hosts")

# -------------------------
# Show Public Key
# -------------------------
print("\n==============================")
print(" ADD THIS KEY TO GITHUB DEPLOY KEYS")
print("==============================\n")
run(f'cat "{key_path}.pub"')

input("\n Add key in GitHub repo → Deploy Keys, then press ENTER...")

# -------------------------
# Clone Repo
# -------------------------
repo_url = f"git@{host_alias}:{github_user}/{repo_name}.git"

if target_path.exists():
    print(f"\n Folder already exists: {target_path}")
else:
    if confirm(f"Clone repo into {target_path}?"):
        run(f"git clone {repo_url} {target_path}")

print("""
========================================
 VPS SETUP COMPLETED
========================================

Next Steps:
1. (If Docker group added) logout & login again:
   exit
   ssh <user>@<VPS_IP>

2. Go to project:
   cd ~/{project}

3. Setup .env file

4. Run first time deploy:
   python3 first_time_deploy.py

After this your site will be LIVE with HTTPS

""")
