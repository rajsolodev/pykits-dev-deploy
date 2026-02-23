# 🟢 FastAPI Production Deployment Guide

This guide explains how to deploy FastAPI projects after VPS setup is complete.

Prerequisite:
You must have already completed VPS setup using the public installers:

```bash
create-sudo-user.sh
vps-base-setup.sh
install-docker.sh
project-setup.sh
setup-http-nginx.sh
```

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

### Step 3 —  Deploy Project

```bash
cd project_folder
make deploy
```

This will:

- Git Pull
- Start full Docker stack
- Run database migrations
- Collect static files on Cloud

*Your Site must be running on HTTP Now check your site url (http://example.com) on any browser, make sure there is no https (https://example.com).*

### Step 4 — Management Commands

Use the `manage` script (via `make` or `uv`) for administrative tasks:

- `make manage c="makeroles"`: Seed default roles.
- `make manage c="makepermissions"`: Discover and seed perms from routers.
- `make manage c="makerolepermissions"`: Map permissions to roles automatically.
- `make manage c="createsuperadmin"`: Initialize a super user.

### Step 5 — Enable HTTPS (Recommended)

After your site is reachable on HTTP and domain is pointing to VPS IP:

```bash
tmp=$(mktemp) && \
curl -fsSL https://raw.githubusercontent.com/rajsolodev/pykits-dev-deploy/main/install-ssl.sh -o "$tmp" && \
trap 'rm -f "$tmp"' EXIT && \
bash "$tmp"
```

This will:

- Issue Let's Encrypt certificate
- Switch Nginx to HTTPS
- Enable HTTP → HTTPS redirect
- Verify auto-renew with dry-run

---

### Step 6 - Change CSRF_TRUSTED_ORIGINS (Only If HTTPS Enabled)

- Edit .env

  ```bash
  cd project_folder_name
  nano .env
  ```

  Change http to https in domain as below
  `CSRF_TRUSTED_ORIGINS=https://example.com,https://www.example.com`
- re-deploy new changes

  ```bash
    make deploy
  ```

---

### Step 7 — Database & Redis Access (Production)

For direct access to your database or cache in production:

- `make db-cli`: Open PostgreSQL CLI (asks for username).
- `make redis-cli`: Open Redis CLI (asks for username/password).

---

## 🔁 FUTURE DEPLOYMENTS

For future updates, If Later, you make any code change and push it to github just run:

```bash
make deploy
make nginx-reload OR make nginx-restart
```

This will safely:

- Pull latest code
- Rebuild containers
- Apply migrations
- Collect static files
- Restart or Reload Nginx

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

- Create FastAPI superuser `make manage c="createsuperadmin"`
- Verify SSL auto-renewal
- Verify database backups in cloud storage
- Test restore process once on staging

---

## 🆘 Troubleshooting

#### Containers not starting / Site Not Loading

* Check Container Online: `make ps-all`
* Check FastAPI logs: `make fastapi-logs`
* Check Celery logs: `make celery-logs`
* Check Celery beat logs: `make celery-beat-logs`
* Check Nginx Logs: `make nginx-logs`

  Domain not working on HTTPS:
  Verify:

  - DNS A-record points to VPS IP
  - Port 80 and 443 open: `sudo ufw status`
