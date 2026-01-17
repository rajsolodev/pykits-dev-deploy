#!/bin/bash
set -e

echo "======================================="
echo "   Pykits HTTP Nginx Setup (NOT SSL/HTTPS)"
echo "======================================="

TTY=/dev/tty

# ---- Safety Checks ----

if [ ! -f docker-compose.prod.yml ]; then
  echo "❌ Run this from project root (docker-compose.prod.yml not found)"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running"
  exit 1
fi

# ---- User Input ----

read -p "Enter domain (example.com): " DOMAIN < $TTY
DOMAIN=$(echo "$DOMAIN" | xargs)

if [[ ! "$DOMAIN" =~ \. ]]; then
  echo "❌ Invalid domain: $DOMAIN"
  exit 1
fi

CONF_DIR="deploy/nginx/conf.d"
COMPOSE="docker compose -f docker-compose.prod.yml"

mkdir -p "$CONF_DIR"

# ---- Create HTTP Config ----

echo ""
echo "▶ Creating HTTP Nginx config..."
echo "---------------------------------------"

rm -f "$CONF_DIR"/*.conf

cat > "$CONF_DIR/default.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://app:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "✅ default.conf created at $CONF_DIR/default.conf"

echo ""
echo "======================================="
echo "✅ HTTP Nginx config ready"
echo "➡ Now run: make deploy   (or docker compose up -d)"
echo "➡ Then test: http://$DOMAIN"
echo "➡ After that: run install-ssl.sh for HTTPS"
echo "======================================="
