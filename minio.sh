#!/bin/bash
# runsh.de/minio.sh — Self-hosted S3-compatible object storage
# Usage: curl -sL runsh.de/minio.sh | bash
# Requires: Docker

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[minio]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

command -v docker &>/dev/null || error "Docker not found. Run: curl -sL runsh.de/docker.sh | bash"

API_PORT="${API_PORT:-9000}"
CONSOLE_PORT="${CONSOLE_PORT:-9001}"
DATA_DIR="${DATA_DIR:-/opt/minio/data}"
MINIO_USER="${MINIO_USER:-minioadmin}"
MINIO_PASS="${MINIO_PASS:-$(openssl rand -base64 16 | tr -d '=+/')}"

mkdir -p "$DATA_DIR"

info "Starting MinIO on API :$API_PORT, Console :$CONSOLE_PORT..."

docker rm -f minio 2>/dev/null || true

docker run -d \
  --name minio \
  --restart unless-stopped \
  -p "${API_PORT}:9000" \
  -p "${CONSOLE_PORT}:9001" \
  -e MINIO_ROOT_USER="$MINIO_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_PASS" \
  -v "$DATA_DIR:/data" \
  minio/minio server /data --console-address ":9001"

if command -v ufw &>/dev/null; then
  ufw allow "$API_PORT"/tcp > /dev/null 2>&1 || true
  ufw allow "$CONSOLE_PORT"/tcp > /dev/null 2>&1 || true
fi

PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
success "MinIO is running!"
echo ""
echo "  ┌─────────────────────────────────────────────┐"
printf "  │  Console:  http://%-26s│\n" "${PUBLIC_IP}:${CONSOLE_PORT}"
printf "  │  API:      http://%-26s│\n" "${PUBLIC_IP}:${API_PORT}"
printf "  │  User:     %-33s│\n" "$MINIO_USER"
printf "  │  Password: %-33s│\n" "$MINIO_PASS"
echo "  └─────────────────────────────────────────────┘"
echo ""
printf "API=http://%s:%s\nUSER=%s\nPASS=%s\n" "$PUBLIC_IP" "$API_PORT" "$MINIO_USER" "$MINIO_PASS" \
  > /opt/minio/.credentials
chmod 600 /opt/minio/.credentials
echo "  Credentials saved to: /opt/minio/.credentials"
echo ""
echo "  S3-compatible: use endpoint http://${PUBLIC_IP}:${API_PORT}"
echo "  CLI: pip install awscli && aws --endpoint-url http://localhost:${API_PORT} s3 ls"
