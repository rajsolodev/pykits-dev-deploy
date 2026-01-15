# 🟢 Django Production Deployment Guide

This guide explains how to deploy Django projects after VPS setup is complete.

Prerequisite:
You must have already run:

- create_sudo_user.py
- vps_setup.py

And your project must be cloned in: `/home/USER/PROJECT_NAME`

---

### ✅ Step 1 — Go to Project Directory

```bash
cd ~/PROJECT_NAME
```

### ✅ Step 2 — Setup Environment Variables

Create `.env` file and configure Or copy `.env.example` file to create own `cp .env.example .env`

Open .env file and make sure you write or change Value of All required field:

* Required Makefile env `MAKEFILE_ENV=prod`
* Django secret key
* Database credentials
* Redis
* Domain name

### ✅ Step 3 — First Time Deploy

```bash
python3 first_time_deploy.py
```

This will:

- Start full Docker stack
- Setup HTTPS via Certbot
- Restart services with SSL
- Run database migrations
- Collect static files
- Optionally setup DB backup schedule

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

* Never delete docker volumes
* Always keep database backups
* Monitor SSL renewal logs

---

## 🎯 Recommended Next Steps

After first deploy:

- Create Django superuser `make superuser`
- Verify SSL auto-renewal
- Verify database backups in cloud storage
- Test restore process once on staging
