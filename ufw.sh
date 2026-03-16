#!/bin/bash
# runsh.de/ufw.sh — Configure UFW firewall with common rules
# Usage: curl -sL runsh.de/ufw.sh | bash
#        SSH_PORT=22222 curl -sL runsh.de/ufw.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[ufw]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

SSH_PORT="${SSH_PORT:-22}"

# ── Install UFW ────────────────────────────────────────────
apt-get install -y -qq ufw

# ── Reset & set defaults ───────────────────────────────────
info "Configuring UFW..."
ufw --force reset > /dev/null
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null

# ── Allow essential ports ──────────────────────────────────
ufw allow "$SSH_PORT"/tcp  > /dev/null && info "Allowed SSH ($SSH_PORT)"
ufw allow 80/tcp           > /dev/null && info "Allowed HTTP (80)"
ufw allow 443/tcp          > /dev/null && info "Allowed HTTPS (443)"

# ── Enable ─────────────────────────────────────────────────
ufw --force enable > /dev/null
success "UFW enabled"

echo ""
ufw status numbered
echo ""
echo "  Tip: ufw allow 8080      # open custom port"
echo "       ufw deny 8080       # block port"
echo "       ufw delete allow 80 # remove rule"
