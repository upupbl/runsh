#!/bin/bash
# runsh.de/vaultwarden.sh — Self-hosted password manager (Bitwarden compatible)
# Usage: curl -sL runsh.de/vaultwarden.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[vaultwarden]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

PORT="${PORT:-8080}"
DATA_DIR="${DATA_DIR:-/opt/vaultwarden}"

mkdir -p "$DATA_DIR/data"

ADMIN_TOKEN=$(openssl rand -base64 48 | tr -d '=+/')

info "Starting Vaultwarden on port $PORT..."

docker rm -f vaultwarden 2>/dev/null || true

docker run -d \
  --name vaultwarden \
  --restart unless-stopped \
  -p "${PORT}:80" \
  -e ADMIN_TOKEN="$ADMIN_TOKEN" \
  -e SIGNUPS_ALLOWED=true \
  -e WEBSOCKET_ENABLED=true \
  -v "$DATA_DIR/data:/data" \
  vaultwarden/server:latest

if command -v ufw &>/dev/null; then
  ufw allow "$PORT"/tcp > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "Vaultwarden is running!"
echo ""
echo "  ┌─────────────────────────────────────────────┐"
printf "  │  Web UI:     http://%-24s│\n" "${PUBLIC_IP}:${PORT}"
printf "  │  Admin:      http://%-24s│\n" "${PUBLIC_IP}:${PORT}/admin"
printf "  │  Admin token: %-26s│\n" "${ADMIN_TOKEN:0:20}..."
echo "  └─────────────────────────────────────────────┘"
echo ""
echo "  Admin token saved to: $DATA_DIR/admin_token.txt"
echo "$ADMIN_TOKEN" > "$DATA_DIR/admin_token.txt"
chmod 600 "$DATA_DIR/admin_token.txt"
echo ""
echo "  Client apps: bitwarden.com/download (use custom server URL)"
echo "  Recommended: put behind HTTPS with cert.sh + nginx.sh"
