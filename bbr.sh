#!/bin/bash
# runsh.de/bbr.sh — Enable BBR TCP congestion control
# Usage: curl -sL runsh.de/bbr.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[bbr]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Check kernel version ───────────────────────────────────
KERNEL=$(uname -r)
KERNEL_MAJOR=$(echo "$KERNEL" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL" | cut -d. -f2)

info "Kernel: $KERNEL"

if [ "$KERNEL_MAJOR" -lt 4 ] || { [ "$KERNEL_MAJOR" -eq 4 ] && [ "$KERNEL_MINOR" -lt 9 ]; }; then
  error "BBR requires kernel >= 4.9, current: $KERNEL"
fi

# ── Check if already enabled ───────────────────────────────
CURRENT=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
if [ "$CURRENT" = "bbr" ]; then
  success "BBR is already enabled"
  exit 0
fi

# ── Enable BBR ─────────────────────────────────────────────
info "Enabling BBR..."

modprobe tcp_bbr 2>/dev/null || true

if ! grep -q "tcp_bbr" /etc/modules-load.d/*.conf 2>/dev/null; then
  echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
fi

cat >> /etc/sysctl.conf <<'EOF'

# BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl -p > /dev/null

# ── Verify ─────────────────────────────────────────────────
RESULT=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
if [ "$RESULT" = "bbr" ]; then
  success "BBR enabled successfully"
else
  error "Failed to enable BBR, current: $RESULT"
fi

echo ""
echo -e "${GREEN}✓ BBR is active!${NC}"
echo "  $(sysctl net.ipv4.tcp_congestion_control)"
echo "  $(sysctl net.core.default_qdisc)"
