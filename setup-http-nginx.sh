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

read -p "Enter internal service name (e.g., api or nextjs): " SERVICE < $TTY
SERVICE=$(echo "$SERVICE" | xargs)

read -p "Enter internal port (e.g., 8000 or 3000): " PORT < $TTY
PORT=$(echo "$PORT" | xargs)

CONF_DIR="deploy/nginx/conf.d"
COMPOSE="docker compose -f docker-compose.prod.yml"

mkdir -p "$CONF_DIR"

# ---- Create HTTP Config ----

echo ""
echo "▶ Creating HTTP Nginx config for $DOMAIN ($SERVICE:$PORT)..."
echo "---------------------------------------"

cat > "$CONF_DIR/$DOMAIN.conf" <<EOF
server {
    listen 80;
    server_name www.$DOMAIN;
    return 301 \$scheme://$DOMAIN\$request_uri;
}

server {
    listen 80;
    server_name $DOMAIN;
    
    client_max_body_size 100M;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://$SERVICE:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "✅ $DOMAIN.conf created at $CONF_DIR/$DOMAIN.conf"

echo ""
echo "======================================="
echo "✅ HTTP Nginx config ready"
echo "➡ Now run: make deploy"
echo "➡ Then test: http://$DOMAIN"
echo "➡ After that: run install-ssl.sh for HTTPS"
echo "======================================="
