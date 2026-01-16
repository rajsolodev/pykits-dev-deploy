#!/bin/bash
set -e

echo "========================================"
echo "  Pykits — FIRST TIME DEPLOY SCRIPT"
echo "========================================"
echo ""
echo "Make sure:"
echo "✔ Domain is pointing to VPS IP"
echo "✔ .env is configured"
echo "✔ MAKEFILE_ENV=prod"
echo "✔ AWS S3/DO setup for static and media files
echo ""
echo "This script will:"
echo "1. Start full docker stack (make up)"
echo "2. Run DB migrations"
echo "3. Collect static files"
echo "4. Optional: setup automatic DB backup schedule"
echo ""

confirm () {
  read -p "$1 (y/n): " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

if ! confirm "Continue with first-time production deploy?"; then
  echo "❌ Cancelled"
  exit 0
fi

read -p "Enter your primary domain (e.g. javasikho.com): " DOMAIN
DOMAIN=$(echo "$DOMAIN" | xargs)

# -------------------------
# Step 1 — make up
# -------------------------
echo ""
echo "▶ STEP 1: Starting containers (make up)"
echo "----------------------------------------"
make up

# -------------------------
# Step 2 — Migrations
# -------------------------
echo ""
echo "▶ STEP 2: Running database migrations"
echo "----------------------------------------"
make migrate

# -------------------------
# Step 3 — Collect Static
# -------------------------
echo ""
echo "▶ STEP 3: Collecting static files"
echo "----------------------------------------"
make collectstatic

# -------------------------
# Step 4 — DB Backup Schedule
# -------------------------
echo ""
echo "▶ STEP 4: Automatic Database Backup Setup (Recommended)"
echo ""
echo "This will schedule daily DB backup using Celery Beat."
echo "You can later modify or disable it from Django Admin."
echo ""

if confirm "Do you want to enable automatic daily DB backup now?"; then
  echo ""
  echo "🟢 Setting up DB backup schedule..."
  docker compose -f docker-compose.prod.yml exec app python setup_db_backup_schedule.py
else
  echo ""
  echo "⚠ IMPORTANT: DB BACKUP NOT ENABLED"
  echo ""
  echo "You should setup DB backup manually from Admin:"
  echo ""
  echo "1. Login to Admin:"
  echo "   https://$DOMAIN/admin/"
  echo ""
  echo "2. Go to:"
  echo "   Periodic Tasks → Add Periodic Task"
  echo ""
  echo "3. Task path:"
  echo "   core.tasks.run_db_backup   (or your actual task path)"
  echo ""
  echo "Without this step, NO automatic DB backup will run."
fi

# -------------------------
# DONE
# -------------------------
echo ""
echo "========================================"
echo " ✅ FIRST TIME DEPLOY COMPLETED"
echo "========================================"
echo ""
echo "Your site should now be live on:"
echo ""
echo "👉 https://$DOMAIN"
echo "👉 https://www.$DOMAIN"
echo ""
echo "Next deployments:"
echo "✔ Just run: make deploy"
echo ""
echo "Recommended next steps:"
echo "✔ Create superuser: make superuser"
echo "✔ Verify backup files in cloud storage"
echo ""
echo "Happy shipping 🚀🔥"
echo ""
