#!/bin/bash
set -e

echo "======================================="
echo "   Generic SSL Installer (Certbot + Nginx)"
echo "======================================="

TTY=/dev/tty

# ---- Safety Checks ----
FILE_COMPOSE="docker-compose.prod.yml"
if [ ! -f "$FILE_COMPOSE" ]; then
    read -p "Enter docker-compose file name (default: docker-compose.prod.yml): " INPUT_COMPOSE < $TTY
    FILE_COMPOSE=${INPUT_COMPOSE:-$FILE_COMPOSE}
fi

if [ ! -f "$FILE_COMPOSE" ]; then
  echo "❌ $FILE_COMPOSE not found"
  exit 1
fi

# ---- User Input ----
read -p "Enter target domain (e.g., javasikho.com): " DOMAIN < $TTY
read -p "Enter email for SSL: " EMAIL < $TTY
read -p "Enter internal service name (e.g., api or nextjs): " SERVICE < $TTY
read -p "Enter internal port (e.g., 8000 or 3000): " PORT < $TTY

# Clean inputs
DOMAIN=$(echo "$DOMAIN" | xargs)
SERVICE=$(echo "$SERVICE" | xargs)
PORT=$(echo "$PORT" | xargs)
CONFIG_FILENAME="$DOMAIN.conf"

CONF_DIR="deploy/nginx/conf.d"
COMPOSE="docker compose -f $FILE_COMPOSE"

# ---- Issue Certificate ----
echo "▶ Issuing certificate for $DOMAIN and www.$DOMAIN..."
$COMPOSE run --rm --entrypoint "" certbot certbot certonly \
  --webroot -w /var/www/certbot \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --email "$EMAIL" --agree-tos --no-eff-email

# ---- Generate Nginx Config ----
echo "▶ Generating config: $CONF_DIR/$CONFIG_FILENAME..."
cat > "$CONF_DIR/$CONFIG_FILENAME" <<EOF
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

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    client_max_body_size 100M;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://$SERVICE:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Proto https;

        proxy_redirect http:// https://;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# ---- Reload Nginx ----
echo "▶ Reloading Nginx..."
$COMPOSE exec nginx nginx -s reload

echo "✅ SUCCESS: HTTPS enabled for $DOMAIN"
echo "📂 Config saved to: $CONF_DIR/$CONFIG_FILENAME"
