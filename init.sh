#!/bin/bash
# runsh.de/init.sh — New server bootstrap
# Usage: curl -sL runsh.de/init.sh | bash

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[init]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }

# ── Detect OS ──────────────────────────────────────────────
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  warn "Cannot detect OS, assuming debian-based"
  OS="debian"
fi

info "Detected OS: $OS"

# ── Update & install common tools ─────────────────────────
info "Updating package list..."
apt-get update -qq

info "Installing common tools..."
apt-get install -y -qq \
  curl wget git vim htop \
  unzip zip \
  net-tools dnsutils \
  fail2ban ufw \
  ca-certificates gnupg

success "Common tools installed"

# ── Timezone ───────────────────────────────────────────────
info "Setting timezone to Asia/Shanghai..."
timedatectl set-timezone Asia/Shanghai 2>/dev/null || ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
success "Timezone set"

# ── Basic UFW rules ────────────────────────────────────────
info "Configuring firewall (UFW)..."
ufw --force reset > /dev/null
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null
ufw allow ssh > /dev/null
ufw --force enable > /dev/null
success "Firewall configured (SSH allowed)"

# ── Done ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✓ Bootstrap complete!${NC}"
echo ""
echo "  Next steps:"
echo "    Docker  →  curl -sL runsh.de/docker.sh | bash"
echo "    Zsh     →  curl -sL runsh.de/zsh.sh | bash"
echo "    Harden  →  curl -sL runsh.de/ssh-harden.sh | bash"
echo ""
