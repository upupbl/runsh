#!/bin/bash
# runsh.de/wireguard.sh — WireGuard VPN server setup
# Usage: curl -sL runsh.de/wireguard.sh | bash
# Generates server config + first client config

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[wireguard]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

WG_PORT="${WG_PORT:-51820}"
WG_NET="10.8.0"
SERVER_IP="${WG_NET}.1"
CLIENT_IP="${WG_NET}.2"
WG_IF="wg0"
WG_DIR="/etc/wireguard"

# ── Install ────────────────────────────────────────────────
info "Installing WireGuard..."
apt-get update -qq
apt-get install -y -qq wireguard wireguard-tools

# ── Generate keys ──────────────────────────────────────────
info "Generating keys..."
SERVER_PRIV=$(wg genkey)
SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)
CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
PSK=$(wg genpsk)

# ── Detect public IP & interface ──────────────────────────
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org)
NET_IF=$(ip route show default | awk '{print $5}' | head -1)

# ── Server config ──────────────────────────────────────────
info "Writing server config..."
cat > "$WG_DIR/$WG_IF.conf" <<EOF
[Interface]
Address    = ${SERVER_IP}/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}
PostUp     = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${NET_IF} -j MASQUERADE
PostDown   = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${NET_IF} -j MASQUERADE

[Peer]
# client1
PublicKey    = ${CLIENT_PUB}
PresharedKey = ${PSK}
AllowedIPs   = ${CLIENT_IP}/32
EOF
chmod 600 "$WG_DIR/$WG_IF.conf"

# ── Client config ──────────────────────────────────────────
CLIENT_CONF="$WG_DIR/client1.conf"
cat > "$CLIENT_CONF" <<EOF
[Interface]
Address    = ${CLIENT_IP}/24
PrivateKey = ${CLIENT_PRIV}
DNS        = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey    = ${SERVER_PUB}
PresharedKey = ${PSK}
Endpoint     = ${PUBLIC_IP}:${WG_PORT}
AllowedIPs   = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
chmod 600 "$CLIENT_CONF"

# ── Enable IP forwarding ───────────────────────────────────
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf > /dev/null

# ── UFW ────────────────────────────────────────────────────
if command -v ufw &>/dev/null; then
  ufw allow "$WG_PORT"/udp > /dev/null 2>&1 || true
  info "UFW: opened $WG_PORT/udp"
fi

# ── Start WireGuard ────────────────────────────────────────
systemctl enable wg-quick@$WG_IF --now

echo ""
success "WireGuard server is running!"
echo ""
echo "  Server: ${PUBLIC_IP}:${WG_PORT}"
echo "  Client config: ${CLIENT_CONF}"
echo ""
echo "  ── Client config (copy to your device) ──"
cat "$CLIENT_CONF"
echo "  ─────────────────────────────────────────"
echo ""
echo "  Add more clients:"
echo "    wg genkey | tee priv.key | wg pubkey > pub.key"
echo "    # add [Peer] block to $WG_DIR/$WG_IF.conf"
echo "    wg addconf $WG_IF <(wg-quick strip $WG_IF)"
