#!/bin/bash
# runsh.de/go.sh — Install Go
# Usage: curl -sL runsh.de/go.sh | bash
#        GO_VERSION=1.23 curl -sL runsh.de/go.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[go]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

# ── Get latest version if not specified ───────────────────
if [ -z "$GO_VERSION" ]; then
  info "Fetching latest Go version..."
  GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -1 | sed 's/go//')
fi

info "Installing Go $GO_VERSION..."

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
[ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] && ARCH="amd64" || ARCH="arm64"

TARBALL="go${GO_VERSION}.linux-${ARCH}.tar.gz"
URL="https://go.dev/dl/${TARBALL}"

# ── Download & install ─────────────────────────────────────
curl -fsSL "$URL" -o /tmp/go.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
success "Go extracted to /usr/local/go"

# ── Shell config ───────────────────────────────────────────
for RCFILE in "$TARGET_HOME/.bashrc" "$TARGET_HOME/.zshrc" "/root/.bashrc"; do
  [ -f "$RCFILE" ] || continue
  grep -q "/usr/local/go/bin" "$RCFILE" && continue
  cat >> "$RCFILE" <<'EOF'

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
  info "Added Go to $RCFILE"
done

export PATH=$PATH:/usr/local/go/bin

echo ""
success "Go $(go version) installed!"
echo ""
echo "  Reload shell: source ~/.bashrc"
echo ""
echo "  Quick start:"
echo "    mkdir hello && cd hello"
echo "    go mod init hello"
echo "    # write main.go, then: go run ."
