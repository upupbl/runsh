#!/bin/bash
# runsh.de/update.sh — System update & cleanup
# Usage: curl -sL runsh.de/update.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
info()    { echo -e "${CYAN}[update]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }

[ "$EUID" -ne 0 ] && exec sudo bash "$0" "$@"

info "Updating package list..."
apt-get update -qq

info "Upgrading packages..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"

info "Removing unused packages..."
apt-get autoremove -y -qq
apt-get autoclean -qq

info "Cleaning journal logs older than 7 days..."
journalctl --vacuum-time=7d 2>/dev/null || true

info "Cleaning apt cache..."
apt-get clean

# Summary
DISK_FREE=$(df -h / | awk 'NR==2{print $4}')

echo ""
success "System updated & cleaned!"
echo "  Disk free: $DISK_FREE"
echo ""

# Check reboot required
if [ -f /var/run/reboot-required ]; then
  echo -e "\033[1;33m  ⚠ Reboot required\033[0m"
  cat /var/run/reboot-required.pkgs 2>/dev/null | sed 's/^/    /'
  echo ""
fi
