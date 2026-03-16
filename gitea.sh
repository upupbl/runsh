#!/bin/bash
# runsh.de/gitea.sh — Install Gitea (self-hosted Git service)
# Usage: curl -sL runsh.de/gitea.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[gitea]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

GITEA_PORT="${GITEA_PORT:-3000}"
SSH_PORT="${GITEA_SSH_PORT:-2222}"
DATA_DIR="${DATA_DIR:-/opt/gitea}"

mkdir -p "$DATA_DIR"

info "Starting Gitea on port $GITEA_PORT (SSH: $SSH_PORT)..."

cat > "$DATA_DIR/docker-compose.yml" <<EOF
version: '3'
services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    restart: unless-stopped
    environment:
      - USER_UID=1000
      - USER_GID=1000
    ports:
      - "${GITEA_PORT}:3000"
      - "${SSH_PORT}:22"
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
EOF

cd "$DATA_DIR"
docker compose up -d

if command -v ufw &>/dev/null; then
  ufw allow "$GITEA_PORT"/tcp > /dev/null 2>&1 || true
  ufw allow "$SSH_PORT"/tcp  > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "Gitea is running!"
echo "  Web UI:    http://${PUBLIC_IP}:${GITEA_PORT}"
echo "  SSH clone: git clone ssh://git@${PUBLIC_IP}:${SSH_PORT}/user/repo.git"
echo ""
echo "  First visit: complete installation wizard"
echo "  Data dir: $DATA_DIR/data"
