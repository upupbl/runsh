#!/bin/bash
# runsh.de/uptime-kuma.sh — Install Uptime Kuma (self-hosted uptime monitor)
# Usage: curl -sL runsh.de/uptime-kuma.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[uptime-kuma]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

PORT="${PORT:-3001}"

info "Starting Uptime Kuma on port $PORT..."

docker rm -f uptime-kuma 2>/dev/null || true

docker run -d \
  --name uptime-kuma \
  --restart unless-stopped \
  -p "${PORT}:3001" \
  -v uptime-kuma-data:/app/data \
  louislam/uptime-kuma:latest

if command -v ufw &>/dev/null; then
  ufw allow "$PORT"/tcp > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "Uptime Kuma is running!"
echo "  URL: http://${PUBLIC_IP}:${PORT}"
echo ""
echo "  First visit: create admin account"
echo "  custom port: PORT=3002 bash <(curl -sL runsh.de/uptime-kuma.sh)"
