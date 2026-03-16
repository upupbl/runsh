#!/bin/bash
# runsh.de/caddy.sh — Install Caddy web server
# Usage: curl -sL runsh.de/caddy.sh | bash
# Auto HTTPS, simpler config than Nginx

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[caddy]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Install ────────────────────────────────────────────────
info "Adding Caddy repository..."
apt-get install -y -qq debian-keyring debian-archive-keyring apt-transport-https curl
curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
  | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --batch --yes
echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] \
https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" \
  > /etc/apt/sources.list.d/caddy-stable.list

apt-get update -qq
apt-get install -y -qq caddy
success "Caddy installed: $(caddy version)"

# ── Default Caddyfile ──────────────────────────────────────
PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

cat > /etc/caddy/Caddyfile <<EOF
# Caddy configuration
# Docs: https://caddyserver.com/docs

:80 {
    root * /var/www/html
    file_server
    encode gzip
}

# To enable HTTPS for a domain, replace :80 with your domain:
# example.com {
#     root * /var/www/html
#     file_server
#     encode gzip
# }
EOF

mkdir -p /var/www/html
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Caddy</title>
<style>body{font-family:monospace;background:#0d0d0d;color:#e0e0e0;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.box{text-align:center}.ok{color:#00e676;font-size:2rem}</style></head>
<body><div class="box"><div class="ok">✓</div><p>Caddy is running</p>
<small style="color:#555">$(hostname) · $(date '+%Y-%m-%d')</small></div></body></html>
EOF

if command -v ufw &>/dev/null; then
  ufw allow 80/tcp > /dev/null 2>&1 || true
  ufw allow 443/tcp > /dev/null 2>&1 || true
fi

systemctl enable caddy --now
systemctl reload caddy

echo ""
success "Caddy is running!"
echo "  Visit: http://${PUBLIC_IP}"
echo "  Config: /etc/caddy/Caddyfile"
echo "  Web root: /var/www/html"
echo ""
echo "  Auto HTTPS example:"
echo "    echo 'example.com { root * /var/www/html; file_server }' > /etc/caddy/Caddyfile"
echo "    systemctl reload caddy"
