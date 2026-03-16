#!/bin/bash
# runsh.de/redis.sh — Install Redis
# Usage: curl -sL runsh.de/redis.sh | bash
#        REDIS_PASSWORD=yourpass curl -sL runsh.de/redis.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[redis]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Install ────────────────────────────────────────────────
info "Installing Redis..."
apt-get update -qq
apt-get install -y -qq redis-server

# ── Configure ──────────────────────────────────────────────
CONF="/etc/redis/redis.conf"
cp "$CONF" "${CONF}.bak"

# Bind to localhost only (secure default)
sed -i 's/^bind .*/bind 127.0.0.1/' "$CONF"

# Set supervised
sed -i 's/^supervised no/supervised systemd/' "$CONF"

# Max memory policy
if ! grep -q "maxmemory-policy" "$CONF"; then
  echo "maxmemory-policy allkeys-lru" >> "$CONF"
fi

# Password
REDIS_PASSWORD="${REDIS_PASSWORD:-}"
if [ -n "$REDIS_PASSWORD" ]; then
  sed -i "s/^# requirepass.*/requirepass $REDIS_PASSWORD/" "$CONF"
  sed -i "s/^requirepass.*/requirepass $REDIS_PASSWORD/" "$CONF"
  info "Password authentication enabled"
else
  info "No password set (localhost-only, acceptable for local use)"
fi

# ── Enable & start ─────────────────────────────────────────
systemctl enable redis-server --now
sleep 1

# ── Verify ─────────────────────────────────────────────────
if [ -n "$REDIS_PASSWORD" ]; then
  PONG=$(redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null)
else
  PONG=$(redis-cli ping 2>/dev/null)
fi

[ "$PONG" = "PONG" ] && success "Redis is responding" || error "Redis not responding"

echo ""
success "Redis installed!"
redis-server --version
echo ""
echo "  ┌─────────────────────────────────────┐"
echo "  │  Host:   127.0.0.1                  │"
echo "  │  Port:   6379                        │"
if [ -n "$REDIS_PASSWORD" ]; then
printf "  │  Auth:   %-27s│\n" "$REDIS_PASSWORD"
fi
echo "  └─────────────────────────────────────┘"
echo ""
echo "  Connect: redis-cli"
echo "  Monitor: redis-cli monitor"
