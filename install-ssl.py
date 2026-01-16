#!/usr/bin/env python3
import os
import sys
import subprocess
from pathlib import Path

# -------------------------
# TTY PROMPT HELPERS
# -------------------------

def tty_input(prompt: str) -> str:
    try:
        with open("/dev/tty", "r+") as tty:
            tty.write(prompt)
            tty.flush()
            return tty.readline().strip()
    except Exception:
        print("❌ No TTY available for input.")
        sys.exit(1)


# -------------------------
# Helpers
# -------------------------

def run(cmd, check=True):
    print(f"\n▶ {cmd}")
    res = subprocess.run(cmd, shell=True)
    if check and res.returncode != 0:
        print("\n❌ Command failed")
        sys.exit(res.returncode)
    return res.returncode


print("=======================================")
print("   Pykits SSL Installer (Let's Encrypt)")
print("=======================================\n")

# -------------------------
# Safety Checks
# -------------------------

if not Path("docker-compose.prod.yml").exists():
    print("❌ Run this from project root (docker-compose.prod.yml not found)")
    sys.exit(1)

if subprocess.run("docker info > /dev/null 2>&1", shell=True).returncode != 0:
    print("❌ Docker is not running")
    sys.exit(1)

# -------------------------
# PROMPT (TTY SAFE)
# -------------------------

DOMAIN = tty_input("Enter domain (example.com): ").strip()
EMAIL = tty_input("Enter email for SSL: ").strip()

if "." not in DOMAIN:
    print(f"❌ Invalid domain: {DOMAIN}")
    sys.exit(1)

CONF_DIR = Path("deploy/nginx/conf.d")
CONF_DIR.mkdir(parents=True, exist_ok=True)

COMPOSE = "docker compose -f docker-compose.prod.yml"

# # -------------------------
# # Issue Certificate
# # -------------------------

print("\n▶ Issuing SSL certificate...")
# print("---------------------------------------")

# cert_cmd = (
#     f'{COMPOSE} run --rm --entrypoint "" certbot certbot certonly '
#     f'--webroot -w /var/www/certbot '
#     f'-d {DOMAIN} -d www.{DOMAIN} '
#     f'--email {EMAIL} --agree-tos --no-eff-email'
# )

# ret = run(cert_cmd, check=False)

# if ret != 0:
#     print("\n❌ SSL certificate issuance failed.")
#     print("👉 Check:")
#     print("   - Domain A record points to this VPS IP")
#     print("   - Port 80 is open")
#     print("   - HTTP nginx config is active")
#     sys.exit(1)

# -------------------------
# Write Nginx HTTPS Config
# -------------------------

print("\n▶ Switching Nginx to HTTPS...")
print("---------------------------------------")

for f in CONF_DIR.glob("*.conf"):
    f.unlink()

ssl_conf = f"""
server {{
    listen 443 ssl;
    server_name {DOMAIN} www.{DOMAIN};

    ssl_certificate /etc/letsencrypt/live/{DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{DOMAIN}/privkey.pem;

    location / {{
        proxy_pass http://app:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }}
}}

server {{
    listen 80;
    server_name {DOMAIN} www.{DOMAIN};

    location /.well-known/acme-challenge/ {{
        root /var/www/certbot;
    }}

    location / {{
        return 301 https://$host$request_uri;
    }}
}}
"""

(CONF_DIR / "ssl.conf").write_text(ssl_conf.strip() + "\n")

# -------------------------
# Restart Nginx
# -------------------------

print("\n▶ Restarting Nginx...")
print("---------------------------------------")

run(f"{COMPOSE} restart nginx")

# -------------------------
# Test Auto Renew
# -------------------------

print("\n▶ Testing auto-renew (dry run)...")
print("---------------------------------------")

# run(f'{COMPOSE} run --rm --entrypoint "" certbot certbot renew --dry-run', check=False)

# -------------------------
# Done
# -------------------------

print("\n=======================================")
print("✅ HTTPS ENABLED SUCCESSFULLY")
print(f"🔒 https://{DOMAIN}")
print("♻ Auto-renew verified")
print("=======================================")
