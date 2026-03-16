#!/bin/bash
# runsh.de/postgres.sh — Install PostgreSQL
# Usage: curl -sL runsh.de/postgres.sh | bash
#        PG_VERSION=16 curl -sL runsh.de/postgres.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[postgres]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"
[ -f /etc/os-release ] && . /etc/os-release || error "Cannot detect OS"

PG_VERSION="${PG_VERSION:-17}"

# ── Add official PostgreSQL repo ───────────────────────────
info "Adding PostgreSQL $PG_VERSION repository..."
apt-get install -y -qq curl ca-certificates
install -d /usr/share/postgresql-common/pgdg
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

# ── Install ────────────────────────────────────────────────
info "Installing PostgreSQL $PG_VERSION..."
apt-get update -qq
apt-get install -y -qq postgresql-$PG_VERSION

systemctl enable postgresql --now
success "PostgreSQL $PG_VERSION installed and running"

# ── Create default user & db ───────────────────────────────
PG_USER="${PG_USER:-dbuser}"
PG_PASS="${PG_PASS:-$(openssl rand -base64 16 | tr -d '=+/')}"
PG_DB="${PG_DB:-mydb}"

info "Creating user '$PG_USER' and database '$PG_DB'..."
su - postgres -c "psql -c \"CREATE USER $PG_USER WITH PASSWORD '$PG_PASS';\"" 2>/dev/null || true
su - postgres -c "psql -c \"CREATE DATABASE $PG_DB OWNER $PG_USER;\"" 2>/dev/null || true
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_USER;\"" 2>/dev/null || true

# ── UFW ────────────────────────────────────────────────────
if command -v ufw &>/dev/null; then
  ufw allow 5432/tcp > /dev/null 2>&1 || true
fi

echo ""
success "PostgreSQL is ready!"
echo ""
echo "  ┌─────────────────────────────────────┐"
echo "  │  Host:     localhost                 │"
echo "  │  Port:     5432                      │"
printf "  │  User:     %-25s│\n" "$PG_USER"
printf "  │  Password: %-25s│\n" "$PG_PASS"
printf "  │  Database: %-25s│\n" "$PG_DB"
echo "  └─────────────────────────────────────┘"
echo ""
echo "  Connect: psql -U $PG_USER -d $PG_DB -h localhost"
echo "  Admin:   sudo -u postgres psql"
echo ""
echo -e "\033[1;33m  Save your password — it won't be shown again!\033[0m"
