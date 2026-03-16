#!/bin/bash
# runsh.de/portainer.sh — Install Portainer (Docker GUI)
# Usage: curl -sL runsh.de/portainer.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[portainer]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

PORT="${PORT:-9000}"

info "Deploying Portainer CE on port $PORT..."

docker rm -f portainer 2>/dev/null || true
docker volume create portainer_data > /dev/null

docker run -d \
  --name portainer \
  --restart unless-stopped \
  -p "${PORT}:9000" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

if command -v ufw &>/dev/null; then
  ufw allow "$PORT"/tcp > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "Portainer is running!"
echo "  URL: http://${PUBLIC_IP}:${PORT}"
echo ""
echo "  First visit: create admin account (expires in 5min)"
echo "  custom port: PORT=9001 bash <(curl -sL runsh.de/portainer.sh)"
