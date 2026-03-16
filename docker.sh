#!/bin/bash
# runsh.de/docker.sh — Install Docker + Docker Compose
# Usage: curl -sL runsh.de/docker.sh | bash
# Supports: Ubuntu, Debian

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[docker]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

# ── Root check ─────────────────────────────────────────────
[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Detect OS ──────────────────────────────────────────────
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  error "Cannot detect OS"
fi

case "$ID" in
  ubuntu|debian) ;;
  *) warn "Untested OS: $ID, proceeding anyway..." ;;
esac

info "Detected: $PRETTY_NAME"

# ── Remove old versions ────────────────────────────────────
info "Removing old Docker versions if any..."
apt-get remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true

# ── Install dependencies ───────────────────────────────────
info "Installing dependencies..."
apt-get update -qq
apt-get install -y -qq \
  ca-certificates curl gnupg lsb-release

# ── Add Docker GPG key & repo ──────────────────────────────
info "Adding Docker repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --batch --yes
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$ID $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

# ── Install Docker ─────────────────────────────────────────
info "Installing Docker Engine..."
apt-get update -qq
apt-get install -y -qq \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# ── Start & enable ─────────────────────────────────────────
systemctl enable docker --now
success "Docker service started"

# ── Add current user to docker group ──────────────────────
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
  success "Added $SUDO_USER to docker group"
elif [ -n "$USER" ] && [ "$USER" != "root" ]; then
  usermod -aG docker "$USER"
  success "Added $USER to docker group"
fi

# ── Verify ─────────────────────────────────────────────────
DOCKER_VERSION=$(docker --version)
COMPOSE_VERSION=$(docker compose version)

echo ""
echo -e "${GREEN}✓ Docker installed successfully!${NC}"
echo "  $DOCKER_VERSION"
echo "  $COMPOSE_VERSION"
echo ""
echo "  Usage:"
echo "    docker run hello-world"
echo "    docker compose up -d"
echo ""
warn "Log out and back in for docker group to take effect (if non-root)"
