#!/bin/bash
# runsh.de/tailscale.sh — Install Tailscale mesh VPN
# Usage: curl -sL runsh.de/tailscale.sh | bash
# Simpler than WireGuard — no server needed, just install on each device

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[tailscale]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Install ────────────────────────────────────────────────
info "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# ── Enable IP forwarding (for subnet routing / exit node) ──
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf > /dev/null

success "Tailscale installed: $(tailscale version 2>/dev/null | head -1)"

echo ""
echo "  ── Authenticate ──────────────────────────────"
echo ""

# Connect - offer options
if [ -n "$TS_AUTHKEY" ]; then
  info "Authenticating with auth key..."
  tailscale up --authkey="$TS_AUTHKEY" ${TS_ARGS:-}
  success "Connected to Tailscale network!"
  tailscale ip -4
else
  echo "  Run one of the following to connect:"
  echo ""
  echo -e "  ${CYAN}# Interactive (opens browser)${NC}"
  echo "    tailscale up"
  echo ""
  echo -e "  ${CYAN}# With auth key (for automation)${NC}"
  echo "    tailscale up --authkey=tskey-auth-xxxxx"
  echo ""
  echo -e "  ${CYAN}# As exit node (route all traffic through this server)${NC}"
  echo "    tailscale up --advertise-exit-node"
  echo ""
  echo -e "  ${CYAN}# Expose subnet (e.g. 192.168.1.0/24)${NC}"
  echo "    tailscale up --advertise-routes=192.168.1.0/24"
  echo ""
  echo "  Get auth keys at: https://login.tailscale.com/admin/settings/keys"
fi
