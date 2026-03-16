#!/bin/bash
# runsh.de/frp.sh — Install frp (fast reverse proxy)
# Usage:
#   Server: FRP_MODE=server curl -sL runsh.de/frp.sh | bash
#   Client: FRP_MODE=client FRP_SERVER=1.2.3.4 FRP_TOKEN=secret curl -sL runsh.de/frp.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[frp]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

FRP_VERSION="${FRP_VERSION:-0.61.1}"
FRP_MODE="${FRP_MODE:-server}"
ARCH=$(dpkg --print-architecture)
[ "$ARCH" = "amd64" ] && ARCH_NAME="amd64" || ARCH_NAME="arm64"

# ── Download ───────────────────────────────────────────────
TARBALL="frp_${FRP_VERSION}_linux_${ARCH_NAME}.tar.gz"
URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${TARBALL}"

info "Downloading frp v${FRP_VERSION}..."
curl -fsSL "$URL" -o /tmp/frp.tar.gz
tar -xzf /tmp/frp.tar.gz -C /tmp
FRP_DIR="/tmp/frp_${FRP_VERSION}_linux_${ARCH_NAME}"

install -m 755 "$FRP_DIR/frps" /usr/local/bin/frps 2>/dev/null || true
install -m 755 "$FRP_DIR/frpc" /usr/local/bin/frpc 2>/dev/null || true
rm -rf /tmp/frp.tar.gz "$FRP_DIR"

mkdir -p /etc/frp

if [ "$FRP_MODE" = "server" ]; then
  # ── Server (frps) ──────────────────────────────────────
  FRP_TOKEN="${FRP_TOKEN:-$(openssl rand -hex 16)}"

  cat > /etc/frp/frps.toml <<EOF
bindPort = 7000
auth.token = "${FRP_TOKEN}"
webServer.addr = "0.0.0.0"
webServer.port = 7500
EOF

  cat > /etc/systemd/system/frps.service <<EOF
[Unit]
Description=frp server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.toml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable frps --now

  if command -v ufw &>/dev/null; then
    ufw allow 7000/tcp > /dev/null 2>&1 || true
    ufw allow 7500/tcp > /dev/null 2>&1 || true
  fi

  PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

  echo ""
  success "frps (server) is running!"
  echo ""
  echo "  ┌──────────────────────────────────────┐"
  printf "  │  Server IP:  %-23s│\n" "$PUBLIC_IP"
  printf "  │  Bind port:  %-23s│\n" "7000"
  printf "  │  Token:      %-23s│\n" "$FRP_TOKEN"
  echo "  │  Dashboard:  :7500                  │"
  echo "  └──────────────────────────────────────┘"
  echo ""
  echo "  Client install:"
  echo "    FRP_MODE=client FRP_SERVER=${PUBLIC_IP} FRP_TOKEN=${FRP_TOKEN} \\"
  echo "    curl -sL runsh.de/frp.sh | bash"

else
  # ── Client (frpc) ──────────────────────────────────────
  [ -z "$FRP_SERVER" ] && error "FRP_SERVER is required for client mode"
  [ -z "$FRP_TOKEN" ]  && error "FRP_TOKEN is required for client mode"

  LOCAL_PORT="${LOCAL_PORT:-22}"
  REMOTE_PORT="${REMOTE_PORT:-6022}"

  cat > /etc/frp/frpc.toml <<EOF
serverAddr = "${FRP_SERVER}"
serverPort = 7000
auth.token = "${FRP_TOKEN}"

[[proxies]]
name       = "ssh"
type       = "tcp"
localIP    = "127.0.0.1"
localPort  = ${LOCAL_PORT}
remotePort = ${REMOTE_PORT}
EOF

  cat > /etc/systemd/system/frpc.service <<EOF
[Unit]
Description=frp client
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.toml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable frpc --now

  echo ""
  success "frpc (client) is running!"
  echo "  SSH tunnel: ssh -p ${REMOTE_PORT} user@${FRP_SERVER}"
  echo "  Edit /etc/frp/frpc.toml to add more proxies"
fi
