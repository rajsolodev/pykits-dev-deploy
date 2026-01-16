# 🟢 Django Production Deployment Guide

This guide explains how to deploy Django projects after VPS setup is complete.

Prerequisite:
You must have already completed VPS setup using the public installers:

From root:

- `create-user.sh`

From deploy user:

- `vps-base-setup.sh`
- `install-docker.sh` (if Docker was not already installed)
- `project-setup.sh`

And your project must be cloned into:: `/home/USER/PROJECT_NAME`

---

### Step 1 — Go to Project Directory

```bash
cd ~/PROJECT_NAME
```

### Step 2 — Setup Environment Variables

Create your `.env` file: `cp .env.example .env`
Open and configure all required values: `nano .env`

Make sure these are correctly set:
- MAKEFILE_ENV=prod
- SECRET_KEY
- Database credentials
- Redis credentials
- Domain name
- Any third-party API keys
  ⚠ Do not skip any required env values — production containers may fail silently.

### Step 3 — First Time Deploy

```bash
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/first-time-django-deploy.sh | bash
```

This will:

- Start full Docker stack (make up)
- Run database migrations
- Run database migrations
- Collect static files on Cloud
- Optionally setup automatic DB backup schedule (Celery Beat)
  🔐 HTTPS is enabled separately using the SSL installer script.

### Step 4 — Enable HTTPS (Recommended)
After your site is reachable on HTTP and domain is pointing to VPS IP:

```bash
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/install-ssl.sh | bash
```

This will:
- Issue Let's Encrypt certificate
- Switch Nginx to HTTPS
- Enable HTTP → HTTPS redirect
- Verify auto-renew with dry-run

---

## 🔁 FUTURE DEPLOYMENTS

For future updates, just run:

```bash
make deploy
```

This will safely:

- Pull latest code
- Rebuild containers
- Apply migrations
- Collect static files

Zero infra work needed.

---

## ⚠️ Important Production Notes

- ❌ Never run docker compose down -v on production
- ❌ Never delete Docker volumes on production
- ✅ Always keep off-server database backups
- ✅ Monitor disk space regularly
- ✅ Keep OS security updates enabled

---

## 🎯 Recommended Next Steps

After first deploy:

- Create Django superuser `make superuser`
- Verify SSL auto-renewal
- Verify database backups in cloud storage
- Test restore process once on staging

---

## 🆘 Troubleshooting
  Containers not starting / Site Not Loading
    - Check Container Online: `make ps-all`
    - Check Django logs: `make django-logs`
    - Check Celery logs: `make celery-logs`
    - Check Celery beat logs: `make celery-beat-logs`

  Domain not working on HTTPS:
  Verify:
    - DNS A-record points to VPS IP
    - Port 80 and 443 open: `sudo ufw status`