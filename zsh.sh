#!/bin/bash
# runsh.de/zsh.sh — Install zsh + oh-my-zsh
# Usage: curl -sL runsh.de/zsh.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[zsh]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

# ── Determine target user ──────────────────────────────────
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
[ -z "$TARGET_USER" ] && error "Cannot determine target user"

info "Installing for user: $TARGET_USER"

# ── Install zsh ────────────────────────────────────────────
info "Installing zsh..."
apt-get update -qq
apt-get install -y -qq zsh curl git
success "zsh installed: $(zsh --version)"

# ── Install oh-my-zsh ──────────────────────────────────────
if [ -d "$TARGET_HOME/.oh-my-zsh" ]; then
  warn "oh-my-zsh already installed, skipping"
else
  info "Installing oh-my-zsh..."
  su - "$TARGET_USER" -c \
    'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  success "oh-my-zsh installed"
fi

# ── Install plugins ────────────────────────────────────────
ZSH_CUSTOM="$TARGET_HOME/.oh-my-zsh/custom"

info "Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  su - "$TARGET_USER" -c \
    "git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

info "Installing zsh-syntax-highlighting..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  su - "$TARGET_USER" -c \
    "git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ── Update .zshrc plugins ──────────────────────────────────
ZSHRC="$TARGET_HOME/.zshrc"
if grep -q "^plugins=" "$ZSHRC"; then
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
  success "Plugins configured"
fi

# ── Set zsh as default shell ───────────────────────────────
ZSH_PATH=$(which zsh)
if ! grep -q "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" >> /etc/shells
fi
chsh -s "$ZSH_PATH" "$TARGET_USER"
success "Default shell set to zsh"

echo ""
echo -e "${GREEN}✓ zsh + oh-my-zsh installed!${NC}"
echo ""
echo "  Plugins enabled:"
echo "    - git"
echo "    - zsh-autosuggestions"
echo "    - zsh-syntax-highlighting"
echo ""
echo "  Re-login or run: exec zsh"
