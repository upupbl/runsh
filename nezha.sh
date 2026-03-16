#!/bin/bash
# runsh.de/nezha.sh — Install 哪吒监控 agent
# Usage: NZ_SERVER=your.server:5555 NZ_KEY=yourkey curl -sL runsh.de/nezha.sh | bash
# Docs: https://nezha.wiki

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[nezha]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Dashboard install (no args) or Agent install ───────────
if [ -z "$NZ_SERVER" ]; then
  info "No NZ_SERVER set — installing 哪吒 Dashboard..."
  warn "Make sure Docker is installed first: curl -sL runsh.de/docker.sh | bash"

  mkdir -p /opt/nezha/dashboard
  cat > /opt/nezha/dashboard/docker-compose.yml <<'EOF'
version: '3'
services:
  dashboard:
    image: ghcr.io/nezhahq/nezha
    restart: always
    ports:
      - "8008:8008"
      - "5555:5555"
    volumes:
      - ./data:/dashboard/data
EOF

  cd /opt/nezha/dashboard
  docker compose up -d

  PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

  if command -v ufw &>/dev/null; then
    ufw allow 8008/tcp > /dev/null 2>&1 || true
    ufw allow 5555/tcp > /dev/null 2>&1 || true
  fi

  echo ""
  success "哪吒 Dashboard started!"
  echo "  Web UI: http://${PUBLIC_IP}:8008"
  echo "  Agent port: 5555"
  echo ""
  echo "  Default login: admin / admin  (change immediately!)"

else
  # Agent mode
  info "Installing 哪吒 agent → $NZ_SERVER"
  [ -z "$NZ_KEY" ] && error "NZ_KEY is required"

  curl -L https://raw.githubusercontent.com/nezhahq/scripts/main/agent/install.sh -o /tmp/nezha-agent-install.sh
  bash /tmp/nezha-agent-install.sh install "$NZ_SERVER" "$NZ_KEY"

  echo ""
  success "哪吒 agent installed and connected to $NZ_SERVER"
fi
