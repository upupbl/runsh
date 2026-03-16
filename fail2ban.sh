#!/bin/bash
# runsh.de/fail2ban.sh — Install & configure fail2ban
# Usage: curl -sL runsh.de/fail2ban.sh | bash
# What it does:
#   - Installs fail2ban
#   - Protects SSH (bans after 5 failed attempts, 1h ban)
#   - Protects Nginx (if installed)

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[fail2ban]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Install ────────────────────────────────────────────────
info "Installing fail2ban..."
apt-get update -qq
apt-get install -y -qq fail2ban

# ── Detect SSH port ────────────────────────────────────────
SSH_PORT=$(ss -tlnp | grep sshd | awk '{print $4}' | grep -oP ':\K\d+' | head -1)
SSH_PORT="${SSH_PORT:-22}"
info "Detected SSH port: $SSH_PORT"

# ── Write jail config ──────────────────────────────────────
info "Writing /etc/fail2ban/jail.local..."
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = $SSH_PORT
logpath  = %(sshd_log)s
maxretry = 3

EOF

# Nginx protection if installed
if command -v nginx &>/dev/null; then
cat >> /etc/fail2ban/jail.local <<'EOF'
[nginx-http-auth]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log

[nginx-limit-req]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
EOF
info "Nginx jails added"
fi

# ── Enable & start ─────────────────────────────────────────
systemctl enable fail2ban --now
sleep 2

echo ""
success "fail2ban is active!"
fail2ban-client status 2>/dev/null || true
echo ""
echo "  Useful commands:"
echo "    fail2ban-client status sshd       # view SSH bans"
echo "    fail2ban-client unban <IP>        # unban an IP"
echo "    fail2ban-client banned            # list all bans"
