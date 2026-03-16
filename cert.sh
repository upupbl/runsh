#!/bin/bash
# runsh.de/cert.sh — Get SSL certificate via acme.sh (Let's Encrypt)
# Usage: DOMAIN=example.com EMAIL=you@example.com curl -sL runsh.de/cert.sh | bash
# Requires: Nginx or Apache running, port 80 open

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[cert]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Check required vars ────────────────────────────────────
[ -z "$DOMAIN" ] && error "DOMAIN is required. Usage: DOMAIN=example.com EMAIL=you@example.com bash cert.sh"
[ -z "$EMAIL" ]  && error "EMAIL is required."

info "Domain: $DOMAIN"
info "Email:  $EMAIL"

# ── Install acme.sh ────────────────────────────────────────
ACME_HOME="/root/.acme.sh"

if [ ! -f "$ACME_HOME/acme.sh" ]; then
  info "Installing acme.sh..."
  curl -fsSL https://get.acme.sh | sh -s email="$EMAIL"
  success "acme.sh installed"
else
  info "acme.sh already installed"
fi

export PATH="$ACME_HOME:$PATH"

# ── Issue certificate ──────────────────────────────────────
CERT_DIR="/etc/ssl/$DOMAIN"
mkdir -p "$CERT_DIR"

# Detect web server
if systemctl is-active --quiet nginx 2>/dev/null; then
  WEBROOT="/var/www/html"
  WEB_SERVER="nginx"
elif systemctl is-active --quiet apache2 2>/dev/null; then
  WEBROOT="/var/www/html"
  WEB_SERVER="apache2"
else
  warn "No running web server detected, using standalone mode (port 80 must be free)"
  WEB_SERVER="standalone"
fi

info "Issuing certificate for $DOMAIN (mode: $WEB_SERVER)..."

if [ "$WEB_SERVER" = "standalone" ]; then
  acme.sh --issue --standalone -d "$DOMAIN" --accountemail "$EMAIL"
else
  acme.sh --issue -d "$DOMAIN" --webroot "$WEBROOT" --accountemail "$EMAIL"
fi

# ── Install certificate ────────────────────────────────────
info "Installing certificate..."
acme.sh --install-cert -d "$DOMAIN" \
  --cert-file      "$CERT_DIR/cert.pem" \
  --key-file       "$CERT_DIR/key.pem" \
  --fullchain-file "$CERT_DIR/fullchain.pem" \
  --reloadcmd      "systemctl reload $WEB_SERVER 2>/dev/null || true"

# ── Nginx config snippet ───────────────────────────────────
if [ "$WEB_SERVER" = "nginx" ]; then
  CONF="/etc/nginx/sites-available/$DOMAIN"
  if [ ! -f "$CONF" ]; then
    cat > "$CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate     $CERT_DIR/fullchain.pem;
    ssl_certificate_key $CERT_DIR/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    ln -sf "$CONF" /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    info "Nginx config created: $CONF"
  fi
fi

echo ""
success "SSL certificate issued for $DOMAIN!"
echo "  Cert:      $CERT_DIR/fullchain.pem"
echo "  Key:       $CERT_DIR/key.pem"
echo "  Auto-renew: enabled (via cron)"
echo ""
echo "  Visit: https://$DOMAIN"
