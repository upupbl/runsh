#!/bin/bash
# runsh.de/ssh-harden.sh — SSH hardening
# Usage: curl -sL runsh.de/ssh-harden.sh | bash
# What it does:
#   - Disables root login
#   - Disables password authentication (key-only)
#   - Changes default SSH port to 22222
# WARNING: Make sure you have SSH key auth working BEFORE running this!

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[ssh]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

SSHD_CONFIG="/etc/ssh/sshd_config"
NEW_PORT=22222

# ── Check SSH key exists ───────────────────────────────────
AUTHORIZED_KEYS_COUNT=$(find /home /root -name "authorized_keys" 2>/dev/null | xargs cat 2>/dev/null | grep -c "ssh-" || true)
if [ "$AUTHORIZED_KEYS_COUNT" -eq 0 ]; then
  error "No SSH authorized_keys found! Add your public key first, then re-run."
fi
success "Found $AUTHORIZED_KEYS_COUNT SSH key(s)"

# ── Backup original config ─────────────────────────────────
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
success "Backed up sshd_config"

# ── Apply settings ─────────────────────────────────────────
info "Applying SSH hardening..."

set_config() {
  local key="$1" val="$2"
  if grep -qE "^#?${key}" "$SSHD_CONFIG"; then
    sed -i "s|^#\?${key}.*|${key} ${val}|" "$SSHD_CONFIG"
  else
    echo "${key} ${val}" >> "$SSHD_CONFIG"
  fi
}

set_config "Port"                    "$NEW_PORT"
set_config "PermitRootLogin"         "no"
set_config "PasswordAuthentication"  "no"
set_config "PubkeyAuthentication"    "yes"
set_config "X11Forwarding"           "no"
set_config "MaxAuthTries"            "3"
set_config "ClientAliveInterval"     "300"
set_config "ClientAliveCountMax"     "2"

# ── Update UFW if present ──────────────────────────────────
if command -v ufw &>/dev/null; then
  ufw allow "$NEW_PORT"/tcp > /dev/null
  ufw delete allow ssh > /dev/null 2>&1 || true
  info "UFW updated: opened port $NEW_PORT"
fi

# ── Restart sshd ──────────────────────────────────────────
sshd -t && systemctl restart sshd
success "sshd restarted"

echo ""
echo -e "${GREEN}✓ SSH hardened!${NC}"
echo ""
echo -e "  ${RED}IMPORTANT: New SSH port is ${NEW_PORT}${NC}"
echo "  Next login: ssh -p $NEW_PORT user@your-server"
echo ""
warn "Keep this session open and test in a NEW terminal before closing!"
