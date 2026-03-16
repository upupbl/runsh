#!/bin/bash
# runsh.de/nginx.sh — Install Nginx with sensible defaults
# Usage: curl -sL runsh.de/nginx.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[nginx]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Install ────────────────────────────────────────────────
info "Installing Nginx..."
apt-get update -qq
apt-get install -y -qq nginx

systemctl enable nginx --now
success "Nginx installed: $(nginx -v 2>&1)"

# ── Tune nginx.conf ────────────────────────────────────────
info "Applying performance tweaks..."

WORKERS=$(nproc)
sed -i "s/worker_processes.*/worker_processes $WORKERS;/" /etc/nginx/nginx.conf
sed -i "s/# server_tokens off/server_tokens off/" /etc/nginx/nginx.conf

# Enable gzip if not already
if ! grep -q "gzip on" /etc/nginx/nginx.conf; then
  sed -i '/##\s*Gzip/a\\tgzip on;\n\tgzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;\n\tgzip_min_length 1024;' /etc/nginx/nginx.conf
fi

# ── UFW allow HTTP/HTTPS ───────────────────────────────────
if command -v ufw &>/dev/null; then
  ufw allow 'Nginx Full' > /dev/null 2>&1 || true
  info "UFW: allowed HTTP & HTTPS"
fi

nginx -t && systemctl reload nginx
success "Nginx configured and running"

# ── Create simple default page ─────────────────────────────
PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Nginx</title>
<style>body{font-family:monospace;background:#0d0d0d;color:#e0e0e0;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.box{text-align:center}.ok{color:#00e676;font-size:2rem}</style></head>
<body><div class="box"><div class="ok">✓</div><p>Nginx is running</p><small style="color:#555">$(hostname) · $(date '+%Y-%m-%d')</small></div></body></html>
EOF

echo ""
success "Done!"
echo "  Visit: http://${PUBLIC_IP}"
echo ""
echo "  Config dir: /etc/nginx/sites-available/"
echo "  Web root:   /var/www/html/"
echo "  Logs:       /var/log/nginx/"
