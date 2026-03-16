#!/bin/bash
# runsh.de/swap.sh — Create swap file
# Usage: curl -sL runsh.de/swap.sh | bash
#        SWAP_SIZE=4G curl -sL runsh.de/swap.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[swap]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

SWAP_FILE="/swapfile"
SWAP_SIZE="${SWAP_SIZE:-2G}"

# ── Check existing swap ────────────────────────────────────
if swapon --show | grep -q "$SWAP_FILE"; then
  warn "Swap already exists at $SWAP_FILE"
  swapon --show
  exit 0
fi

info "Creating ${SWAP_SIZE} swap file at ${SWAP_FILE}..."
fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count="${SWAP_SIZE//[^0-9]/}000" status=progress
chmod 600 "$SWAP_FILE"
mkswap "$SWAP_FILE"
swapon "$SWAP_FILE"
success "Swap activated"

# ── Persist across reboots ─────────────────────────────────
if ! grep -q "$SWAP_FILE" /etc/fstab; then
  echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  success "Added to /etc/fstab"
fi

# ── Tune swappiness ────────────────────────────────────────
sysctl vm.swappiness=10 > /dev/null
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
  echo "vm.swappiness=10" >> /etc/sysctl.conf
fi

echo ""
echo -e "${GREEN}✓ Swap created!${NC}"
free -h | grep -E "Mem|Swap"
