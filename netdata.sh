#!/bin/bash
# runsh.de/netdata.sh — Install Netdata real-time monitoring
# Usage: curl -sL runsh.de/netdata.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[netdata]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

info "Installing Netdata via official kickstart..."
curl -fsSL https://get.netdata.cloud/kickstart.sh | bash -s -- --non-interactive --no-updates

systemctl enable netdata --now 2>/dev/null || true

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

if command -v ufw &>/dev/null; then
  ufw allow 19999/tcp > /dev/null 2>&1 || true
  info "UFW: opened port 19999"
fi

echo ""
success "Netdata installed!"
echo "  Dashboard: http://${PUBLIC_IP}:19999"
echo ""
echo "  To restrict access (recommended):"
echo "    ufw deny 19999"
echo "    # then use SSH tunnel: ssh -L 19999:localhost:19999 user@server"
