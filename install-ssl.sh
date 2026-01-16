#!/bin/bash
set -e

echo "======================================="
echo "   Pykits SSL Installer (Let's Encrypt)"
echo "======================================="

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

read -p "Enter domain (example.com): " DOMAIN
read -p "Enter email for SSL: " EMAIL

DOMAIN=$(echo "$DOMAIN" | xargs)
EMAIL=$(echo "$EMAIL" | xargs)

if [[ ! "$DOMAIN" =~ \. ]]; then
  echo "❌ Invalid domain: $DOMAIN"
  exit 1
fi

CONF_DIR="deploy/nginx/conf.d"
COMPOSE="docker compose -f docker-compose.prod.yml"

# ---- Issue Certificate (HTTP config must exist) ----

echo ""
echo "▶ Issuing SSL certificate..."
echo "---------------------------------------"

$COMPOSE run --rm --entrypoint "" certbot certbot certonly \
  --webroot -w /var/www/certbot \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --email "$EMAIL" --agree-tos --no-eff-email

# ---- Switch Nginx to HTTPS ----

echo ""
echo "▶ Switching Nginx to HTTPS..."
echo "---------------------------------------"

rm -f "$CONF_DIR"/*.conf

cat > "$CONF_DIR/ssl.conf" <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://app:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

# ---- Restart Nginx ----

echo ""
echo "▶ Restarting Nginx..."
echo "---------------------------------------"

$COMPOSE restart nginx

# ---- Test Auto Renew ----

echo ""
echo "▶ Testing auto-renew (dry run)..."
echo "---------------------------------------"

$COMPOSE run --rm --entrypoint "" certbot certbot renew --dry-run

# ---- Done ----

echo ""
echo "======================================="
echo "✅ HTTPS ENABLED SUCCESSFULLY"
echo "🔒 https://$DOMAIN"
echo "♻ Auto-renew verified"
echo "======================================="
