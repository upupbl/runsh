#!/bin/bash
# runsh.de/mongodb.sh — Install MongoDB
# Usage: curl -sL runsh.de/mongodb.sh | bash
#        MONGO_VERSION=8.0 curl -sL runsh.de/mongodb.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[mongodb]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"
[ -f /etc/os-release ] && . /etc/os-release || error "Cannot detect OS"

MONGO_VERSION="${MONGO_VERSION:-8.0}"
MONGO_USER="${MONGO_USER:-dbuser}"
MONGO_PASS="${MONGO_PASS:-$(openssl rand -base64 16 | tr -d '=+/')}"
MONGO_DB="${MONGO_DB:-mydb}"

# ── Add MongoDB repo ───────────────────────────────────────
info "Adding MongoDB $MONGO_VERSION repository..."
apt-get install -y -qq gnupg curl

curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc" \
  | gpg --dearmor -o /usr/share/keyrings/mongodb-server.gpg --batch --yes

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server.gpg ] \
https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME:-jammy}/mongodb-org/${MONGO_VERSION} multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list

# ── Install ────────────────────────────────────────────────
info "Installing MongoDB..."
apt-get update -qq
apt-get install -y -qq mongodb-org

systemctl enable mongod --now
sleep 2
success "MongoDB started"

# ── Create user ────────────────────────────────────────────
info "Creating user '$MONGO_USER'..."
mongosh --quiet --eval "
use ${MONGO_DB}
db.createUser({
  user: '${MONGO_USER}',
  pwd: '${MONGO_PASS}',
  roles: [{ role: 'readWrite', db: '${MONGO_DB}' }]
})
" 2>/dev/null || warn "User may already exist"

echo ""
success "MongoDB is ready!"
echo ""
echo "  ┌──────────────────────────────────────────┐"
printf "  │  Host:     %-30s│\n" "localhost:27017"
printf "  │  Database: %-30s│\n" "$MONGO_DB"
printf "  │  User:     %-30s│\n" "$MONGO_USER"
printf "  │  Password: %-30s│\n" "$MONGO_PASS"
echo "  └──────────────────────────────────────────┘"
echo ""
echo "  Connect: mongosh mongodb://${MONGO_USER}:${MONGO_PASS}@localhost/${MONGO_DB}"
