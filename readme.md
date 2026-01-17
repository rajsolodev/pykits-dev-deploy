# Pykits Dev --- VPS Deployment Helper

This repository contains **public deployment helper scripts** to prepare
a fresh VPS for running Docker-based production applications.

It helps you go from:

👉 **Fresh VPS → Secure server → Docker-ready → Project cloned**

Actual application deployment depends on your project framework
(Django, FastAPI, Node, etc.) and is handled inside the project repository.

---

## ✅ What This Repo Does (Generic Infra Only)

This repo helps you to:

- Create a secure sudo user
- Setup firewall (UFW) and allow ports 22, 80, 443
- Install basic system tools (git, curl, make, etc.)
- Install Docker (official repository)
- Setup SSH deploy key for private GitHub repo
- Clone your actual project into home directory

❗ **This repo does NOT run app-specific deploy steps like:**

- database migrations
- collectstatic
- alembic migrations
- npm run

Those steps are handled by **project-level scripts**.

---

## ✅ Supported Systems

This bootstrap pipeline supports:

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

Providers tested:

- DigitalOcean VPS
- AWS EC2 (Ubuntu AMI)
- Hostinger VPS
- Vultr / Hetzner

> ⚠ Only Ubuntu is supported. Other distros are intentionally not supported.

---

## 🧱 Architecture

You will use **two repositories**:

### 🔵 Public Repo (this one)

**pykits-dev-deploy**

Contains only infrastructure scripts:

    pykits-dev-deploy/
    ├── create-user.sh
    ├── vps-base-setup.sh
    ├── install-docker.sh
    ├── project-setup.sh
    └── ssl.sh

No secrets. No project code.

---

### 🔵 Private Repo (your actual product)

Example: `digistore`

Contains:

- Dockerfile
- docker-compose.prod files
- Makefile
- Django/FastAPI/Node code
- Framework-specific deployment scripts like (if needed):
  - `setup_db_backup_schedule.py`

---

## 🔥 FULL VPS SETUP PIPELINEE (STEP-BY-STEP)

This is the **exact flow on a fresh VPS**.

---

### STEP 1 --- Login to VPS as root

```bash
ssh root@YOUR_VPS_IP
```

then run `apt update & apt upgrade -y`

---

### STEP 2 --- Create secure sudo user

```bash
tmp=$(mktemp) && \
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/create-sudo-user.sh -o "$tmp" && \
trap 'rm -f "$tmp"' EXIT && \
bash "$tmp"
```

You will be asked to:

- enter username (e.g. john)
- set password (e.g. john123)

After success:

```bash
exit
ssh new_user@YOUR_VPS_IP
```

---

### STEP 3 --- Base VPS Setup (Firewall + Tools)

Login as new user, then:

```bash
tmp=$(mktemp) && \
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/vps-base-setup.sh -o "$tmp" && \
trap 'rm -f "$tmp"' EXIT && \
bash "$tmp"

```

This script will:

- Run system update (optional)
- Install basic tools (git, python3, make etc)
- Configure UFW firewall
- Allow ports 22, 80, 443

---

### STEP 4 — Install Docker (If Not Already Installed)

```bash
tmp=$(mktemp) && \
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/install-docker.sh -o "$tmp" && \
trap 'rm -f "$tmp"' EXIT && \
bash "$tmp"
```

After this:

👉 Logout & login again so docker group applies.

```bash
exit
ssh newuser@VPS_IP
```

---

### STEP 5 — Setup Project & Clone Repo

```bash
tmp=$(mktemp) && \
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/project-setup.sh -o "$tmp" && \
trap 'rm -f "$tmp"' EXIT && \
bash "$tmp"
```

This will:

- Generate SSH deploy key
- Ask you to add it to GitHub Deploy Keys
- Test SSH connection
- Clone your private repo into: /home/USER/PROJECT_NAME

---

### STEP 6 — Setup HTTP Nginx

Change Directory to Project Folder

```bash
cd project_folder_name
```

then run below in terminal:

```bash
tmp=$(mktemp) && \
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/setup-http-nginx.sh -o "$tmp" && \
trap 'rm -f "$tmp"' EXIT && \
bash "$tmp"
```

This will:

- Ask for your domain name (e.g. example.com)
- Create an HTTP Nginx config (default.conf) for your site
- Route traffic from port 80 → your app container
- Enable access to /.well-known/acme-challenge/ for SSL verification

---

## 🚀 APPLICATION DEPLOY (PROJECT-SPECIFIC)

After VPS setup, deployment depends on your project framework.

Follow the appropriate guide:

- 🟢 Django Projects → [docs/django-deploy.md](https://github.com/rajsolodev/pykits-dev-deploy/blob/main/docs/django.md)
- 🔵 FastAPI Projects → Coming soon
- 🟣 Node.js Projects → coming soon

Each guide explains:

- first-time deploy
- migrations
- SSL setup (if applicable)
- future deployments

---

## 🔐 Why This Setup Is Secure

- No deployment using root user
- Docker runs under deploy user
- Firewall blocks all unused ports
- SSH deploy keys are project-specific
- No secrets stored in public repo

---

## ⚠️ Important Notes

- Never run `docker compose down -v` on production
- Never delete Docker volumes on production
- Always keep off-server DB backups

---

## ❤️ Built for Pykits Products/Apps

This deployment flow is designed to support:

- SaaS products
- Digital product platforms
- FastAPI / Django microservices
- Docker-based production stacks

Feel free to adapt this for your own projects.

## 🆘 Troubleshooting

  Containers not starting
    - Check logs: `make logs`
    - Check Container Online: `make ps-all`

  Domain not working on HTTPS:
  Verify:
    - DNS A-record points to VPS IP
    - Port 80 and 443 open: `sudo ufw status`
