#!/bin/bash
# runsh.de/php.sh — Install PHP + common extensions
# Usage: curl -sL runsh.de/php.sh | bash
#        PHP_VERSION=8.3 curl -sL runsh.de/php.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[php]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

PHP_VERSION="${PHP_VERSION:-8.3}"

# ── Add ondrej/php PPA (latest versions) ──────────────────
info "Adding PHP repository (ondrej/php)..."
apt-get install -y -qq software-properties-common
add-apt-repository -y ppa:ondrej/php 2>/dev/null || true
apt-get update -qq

# ── Install PHP + extensions ───────────────────────────────
info "Installing PHP $PHP_VERSION..."
apt-get install -y -qq \
  "php${PHP_VERSION}" \
  "php${PHP_VERSION}-cli" \
  "php${PHP_VERSION}-fpm" \
  "php${PHP_VERSION}-common" \
  "php${PHP_VERSION}-curl" \
  "php${PHP_VERSION}-mbstring" \
  "php${PHP_VERSION}-xml" \
  "php${PHP_VERSION}-zip" \
  "php${PHP_VERSION}-bcmath" \
  "php${PHP_VERSION}-gd" \
  "php${PHP_VERSION}-intl" \
  "php${PHP_VERSION}-mysql" \
  "php${PHP_VERSION}-pgsql" \
  "php${PHP_VERSION}-redis" \
  "php${PHP_VERSION}-opcache"

# ── Install Composer ───────────────────────────────────────
info "Installing Composer..."
curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --quiet
success "Composer installed: $(composer --version 2>/dev/null | head -1)"

# ── Enable PHP-FPM ─────────────────────────────────────────
systemctl enable "php${PHP_VERSION}-fpm" --now
success "PHP-FPM started"

# ── Nginx integration hint ─────────────────────────────────
if command -v nginx &>/dev/null; then
  info "Nginx detected. PHP-FPM socket: /run/php/php${PHP_VERSION}-fpm.sock"
fi

echo ""
success "PHP ${PHP_VERSION} installed!"
php -v | head -1
echo ""
echo "  Extensions: curl mbstring xml zip bcmath gd intl mysql pgsql redis opcache"
echo "  FPM socket: /run/php/php${PHP_VERSION}-fpm.sock"
echo "  CLI:        php script.php"
echo "  Composer:   composer install"
