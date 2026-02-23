# 🟣 Next.js Production Deployment Guide

This guide explains how to deploy Next.js projects after VPS setup is complete.

Prerequisite:
You must have already completed VPS setup using the public installers:

```bash
create-sudo-user.sh
vps-base-setup.sh
install-docker.sh
project-setup.sh
setup-http-nginx.sh
```

And your project must be cloned into: `/home/USER/PROJECT_NAME`

---

### Step 1 — Go to Project Directory

```bash
cd ~/PROJECT_NAME
```

### Step 2 — Setup Environment Variables

Create your `.env` file: `cp .env.example .env`
Open and configure all required values: `nano .env`

Make sure these are correctly set (if applicable):

- MAKEFILE_ENV=prod
- NEXT_PUBLIC_API_URL
- NEXT_PUBLIC_DOMAIN
- Any third-party API keys
  ⚠ Do not skip any required env values — production containers may fail silently.

### Step 3 — Deploy Project

```bash
cd project_folder
make deploy
```

This will:

- Git Pull
- Start full Docker stack
- Rebuild Next.js app

*Your Site must be running on HTTP Now check your site url (http://example.com) on any browser, make sure there is no https (https://example.com).*

### Step 4 — Enable HTTPS (Recommended)

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

## 🔁 FUTURE DEPLOYMENTS

For future updates, If Later, you make any code change and push it to github just run:

```bash
make deploy
```

This will safely:

- Pull latest code
- Rebuild containers
- Update the live site

Zero infra work needed.

---

## ⚠️ Important Production Notes

- ❌ Never run `docker compose down -v` on production
- ❌ Never delete Docker volumes on production
- ✅ Always keep off-server database backups (if using a local DB)
- ✅ Monitor disk space regularly
- ✅ Keep OS security updates enabled

---

## 🎯 Recommended Next Steps

After first deploy:

- Verify SSL auto-renewal
- Check logs for any client-side or server-side errors
- Verify environment variables are correctly loaded

---

## 🆘 Troubleshooting

  Containers not starting / Site Not Loading
    - Check Container Online: `make ps-all`
    - Check Next.js logs: `make logs` (or specific container logs)

  Domain not working on HTTPS:
  Verify:
    - DNS A-record points to VPS IP
    - Port 80 and 443 open: `sudo ufw status`
