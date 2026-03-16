#!/bin/bash
# runsh.de/rust.sh — Install Rust via rustup
# Usage: curl -sL runsh.de/rust.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
info()    { echo -e "${CYAN}[rust]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

# ── Dependencies ───────────────────────────────────────────
apt-get install -y -qq curl build-essential gcc

# ── Install rustup ─────────────────────────────────────────
info "Installing Rust via rustup..."

if [ -d "$TARGET_HOME/.cargo" ]; then
  info "Rust already installed, updating..."
  su - "$TARGET_USER" -c '$HOME/.cargo/bin/rustup update'
else
  su - "$TARGET_USER" -c \
    'curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path'
fi

# ── Shell config ───────────────────────────────────────────
for RCFILE in "$TARGET_HOME/.bashrc" "$TARGET_HOME/.zshrc"; do
  [ -f "$RCFILE" ] || continue
  grep -q "cargo/bin" "$RCFILE" && continue
  echo 'source "$HOME/.cargo/env"' >> "$RCFILE"
  info "Added cargo to $RCFILE"
done

echo ""
RUST_VER=$(su - "$TARGET_USER" -c '$HOME/.cargo/bin/rustc --version 2>/dev/null || echo "installed"')
success "$RUST_VER"
echo ""
echo "  Reload shell: source ~/.bashrc"
echo ""
echo "  Quick start:"
echo "    cargo new hello && cd hello && cargo run"
echo "    cargo install ripgrep    # install CLI tools"
