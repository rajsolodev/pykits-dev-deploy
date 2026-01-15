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
- Setup firewall (UFW) and Allow Ports 80, 443
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

## 🧱 Architecture

You will use **two repositories**:

### 🔵 Public Repo (this one)

**pykits-dev-deploy**

Contains only infrastructure scripts:

    pykits-dev-deploy/
    ├── create_sudo_user.py
    ├── vps_setup.py

Safe to keep public.
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
  - `first_time_deploy.py`
  - `setup_db_backup_schedule.py`

---

## 🔥 FULL VPS SETUP PIPELINEE (STEP-BY-STEP)

This is the **exact flow on a fresh VPS**.

---

### STEP 1 --- Login to VPS as root

```bash
ssh root@YOUR_VPS_IP
```

---

### STEP 2 --- Install minimal tools + clone deploy repo

```bash
apt update
apt install -y git python3

git clone https://github.com/rajsolodev/pykits-dev-deploy.git
cd pykits-dev-deploy
```

---

### STEP 3 --- Create secure sudo deploy user

```bash
python3 create_sudo_user.py
```

You will be asked to:

- enter username (e.g. john)
- set password (e.g. john123)

After success:

```bash
exit
ssh username@YOUR_VPS_IP
```

---

### STEP 4 --- Setup VPS + Clone PRIVATE project repo

Login as new user, then:

```bash
cd pykits-dev-deploy
python3 vps_setup.py
```

This script will:

- Update system
- Setup firewall (UFW)
- Install Docker (official)
- Setup GitHub SSH deploy key
- Ask for your private repo URL
- Clone project into: `home/username/PROJECT_NAME`

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
- Database backups can be automated to cloud storage

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
