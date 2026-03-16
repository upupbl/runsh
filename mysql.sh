#!/bin/bash
# runsh.de/mysql.sh — Install MySQL (or MariaDB)
# Usage: curl -sL runsh.de/mysql.sh | bash
#        USE_MARIADB=1 curl -sL runsh.de/mysql.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[mysql]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

DB_USER="${DB_USER:-dbuser}"
DB_PASS="${DB_PASS:-$(openssl rand -base64 16 | tr -d '=+/')}"
DB_NAME="${DB_NAME:-mydb}"
ROOT_PASS="${ROOT_PASS:-$(openssl rand -base64 20 | tr -d '=+/')}"

apt-get update -qq

if [ "${USE_MARIADB:-0}" = "1" ]; then
  info "Installing MariaDB..."
  apt-get install -y -qq mariadb-server
  SERVICE="mariadb"
else
  info "Installing MySQL..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mysql-server
  SERVICE="mysql"
fi

systemctl enable "$SERVICE" --now
success "$SERVICE started"

# ── Secure installation ────────────────────────────────────
info "Securing installation..."
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# ── Create user & database ─────────────────────────────────
info "Creating user '$DB_USER' and database '$DB_NAME'..."
mysql -u root -p"${ROOT_PASS}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo ""
success "MySQL is ready!"
echo ""
echo "  ┌──────────────────────────────────────────┐"
printf "  │  Root password: %-25s│\n" "$ROOT_PASS"
printf "  │  User:          %-25s│\n" "$DB_USER"
printf "  │  Password:      %-25s│\n" "$DB_PASS"
printf "  │  Database:      %-25s│\n" "$DB_NAME"
echo "  └──────────────────────────────────────────┘"
echo ""
echo "  Connect: mysql -u $DB_USER -p $DB_NAME"
echo "  Admin:   mysql -u root -p"
echo ""
warn "Save your passwords — they won't be shown again!"
