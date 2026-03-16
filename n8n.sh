#!/bin/bash
# runsh.de/n8n.sh — Self-hosted workflow automation
# Usage: curl -sL runsh.de/n8n.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[n8n]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

PORT="${PORT:-5678}"
DATA_DIR="${DATA_DIR:-/opt/n8n}"
N8N_USER="${N8N_USER:-admin}"
N8N_PASS="${N8N_PASS:-$(openssl rand -base64 12 | tr -d '=+/')}"
ENCRYPTION_KEY=$(openssl rand -hex 32)

mkdir -p "$DATA_DIR/data"

info "Starting n8n on port $PORT..."

docker rm -f n8n 2>/dev/null || true

docker run -d \
  --name n8n \
  --restart unless-stopped \
  -p "${PORT}:5678" \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER="$N8N_USER" \
  -e N8N_BASIC_AUTH_PASSWORD="$N8N_PASS" \
  -e N8N_ENCRYPTION_KEY="$ENCRYPTION_KEY" \
  -e GENERIC_TIMEZONE="Asia/Shanghai" \
  -e TZ="Asia/Shanghai" \
  -v "$DATA_DIR/data:/home/node/.n8n" \
  n8nio/n8n:latest

if command -v ufw &>/dev/null; then
  ufw allow "$PORT"/tcp > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "n8n is running!"
echo ""
echo "  ┌─────────────────────────────────────────┐"
printf "  │  URL:      http://%-22s│\n" "${PUBLIC_IP}:${PORT}"
printf "  │  Username: %-29s│\n" "$N8N_USER"
printf "  │  Password: %-29s│\n" "$N8N_PASS"
echo "  └─────────────────────────────────────────┘"
echo ""
printf "URL=http://%s:%s\nUSER=%s\nPASS=%s\n" "$PUBLIC_IP" "$PORT" "$N8N_USER" "$N8N_PASS" \
  > "$DATA_DIR/.credentials"
chmod 600 "$DATA_DIR/.credentials"
echo "  Credentials saved to: $DATA_DIR/.credentials"
