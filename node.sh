#!/bin/bash
# runsh.de/node.sh — Install Node.js via nvm
# Usage: curl -sL runsh.de/node.sh | bash
#        NODE_VERSION=20 curl -sL runsh.de/node.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[node]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
NODE_VERSION="${NODE_VERSION:-22}"

# ── Install nvm ────────────────────────────────────────────
NVM_DIR="$TARGET_HOME/.nvm"

if [ -d "$NVM_DIR" ]; then
  info "nvm already installed, updating..."
else
  info "Installing nvm..."
fi

su - "$TARGET_USER" -c \
  'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash'

success "nvm installed"

# ── Install Node.js ────────────────────────────────────────
info "Installing Node.js v${NODE_VERSION} LTS..."

su - "$TARGET_USER" -c "
  export NVM_DIR=\"\$HOME/.nvm\"
  [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
  nvm install ${NODE_VERSION}
  nvm use ${NODE_VERSION}
  nvm alias default ${NODE_VERSION}
  echo \"node: \$(node --version)\"
  echo \"npm:  \$(npm --version)\"
"

# ── Shell config reminder ──────────────────────────────────
echo ""
success "Node.js v${NODE_VERSION} installed via nvm!"
echo ""
echo "  Reload shell or run:"
echo "    source ~/.bashrc   # or ~/.zshrc"
echo ""
echo "  Common nvm commands:"
echo "    nvm install 20       # install specific version"
echo "    nvm use 20           # switch version"
echo "    nvm ls               # list installed versions"
