#!/bin/bash
# runsh.de/user.sh — Create a sudo user with SSH key
# Usage: USERNAME=deploy SSH_KEY="ssh-ed25519 AAAA..." curl -sL runsh.de/user.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[user]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

# ── Get username ───────────────────────────────────────────
if [ -z "$USERNAME" ]; then
  echo -n -e "  ${CYAN}Enter username:${NC} "
  read -r USERNAME
fi
[ -z "$USERNAME" ] && error "Username cannot be empty"

# Validate
echo "$USERNAME" | grep -qE '^[a-z][a-z0-9_-]{0,31}$' || \
  error "Invalid username (lowercase, alphanumeric, 1-32 chars)"

# ── Create user ────────────────────────────────────────────
if id "$USERNAME" &>/dev/null; then
  warn "User '$USERNAME' already exists"
else
  info "Creating user '$USERNAME'..."
  useradd -m -s /bin/bash "$USERNAME"
  success "User created"
fi

# ── Add to sudo ────────────────────────────────────────────
usermod -aG sudo "$USERNAME"
success "Added to sudo group"

# ── Set password ───────────────────────────────────────────
if [ -n "$USER_PASS" ]; then
  echo "${USERNAME}:${USER_PASS}" | chpasswd
  success "Password set"
else
  PASS=$(openssl rand -base64 16 | tr -d '=+/')
  echo "${USERNAME}:${PASS}" | chpasswd
  warn "Generated password: ${PASS}  (save this!)"
fi

# ── SSH key ────────────────────────────────────────────────
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ -n "$SSH_KEY" ]; then
  echo "$SSH_KEY" >> "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"
  chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
  success "SSH key added"
elif [ -f /root/.ssh/authorized_keys ]; then
  cp /root/.ssh/authorized_keys "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"
  chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
  info "Copied root's SSH keys to $USERNAME"
else
  warn "No SSH key set. Add manually: echo 'ssh-...' >> $SSH_DIR/authorized_keys"
fi

# ── Sudoers (no password for convenience, optional) ────────
if [ "${NOPASSWD:-0}" = "1" ]; then
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
  chmod 440 "/etc/sudoers.d/$USERNAME"
  info "Passwordless sudo enabled"
fi

echo ""
success "User '$USERNAME' ready!"
echo "  Login: ssh ${USERNAME}@$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
