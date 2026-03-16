#!/bin/bash
# runsh.de/nextcloud.sh — Self-hosted cloud storage
# Usage: curl -sL runsh.de/nextcloud.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[nextcloud]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

PORT="${PORT:-8888}"
DATA_DIR="${DATA_DIR:-/opt/nextcloud}"
NC_ADMIN="${NC_ADMIN:-admin}"
NC_PASS="${NC_PASS:-$(openssl rand -base64 12 | tr -d '=+/')}"
DB_PASS=$(openssl rand -base64 16 | tr -d '=+/')

mkdir -p "$DATA_DIR"

info "Starting Nextcloud on port $PORT..."

cat > "$DATA_DIR/docker-compose.yml" <<EOF
version: '3'

services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASS}root
      MYSQL_PASSWORD: ${DB_PASS}
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud

  app:
    image: nextcloud:latest
    restart: unless-stopped
    ports:
      - "${PORT}:80"
    volumes:
      - nextcloud:/var/www/html
      - ./data:/var/www/html/data
    environment:
      MYSQL_PASSWORD: ${DB_PASS}
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_HOST: db
      NEXTCLOUD_ADMIN_USER: ${NC_ADMIN}
      NEXTCLOUD_ADMIN_PASSWORD: ${NC_PASS}
    depends_on:
      - db

volumes:
  db:
  nextcloud:
EOF

cd "$DATA_DIR"
docker compose up -d

if command -v ufw &>/dev/null; then
  ufw allow "$PORT"/tcp > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "Nextcloud is starting (may take 1-2 min for first boot)..."
echo ""
echo "  ┌─────────────────────────────────────────┐"
printf "  │  URL:      http://%-22s│\n" "${PUBLIC_IP}:${PORT}"
printf "  │  Username: %-29s│\n" "$NC_ADMIN"
printf "  │  Password: %-29s│\n" "$NC_PASS"
echo "  └─────────────────────────────────────────┘"
echo ""
echo "  Credentials saved to: $DATA_DIR/.credentials"
printf "URL=http://%s:%s\nUSER=%s\nPASS=%s\n" "$PUBLIC_IP" "$PORT" "$NC_ADMIN" "$NC_PASS" \
  > "$DATA_DIR/.credentials"
chmod 600 "$DATA_DIR/.credentials"
echo ""
echo "  Recommended: put behind HTTPS with cert.sh + nginx.sh"
