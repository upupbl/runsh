#!/bin/bash
# runsh.de/python.sh — Install Python via pyenv
# Usage: curl -sL runsh.de/python.sh | bash
#        PYTHON_VERSION=3.12 curl -sL runsh.de/python.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[python]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
PYTHON_VERSION="${PYTHON_VERSION:-3.13}"
PYENV_DIR="$TARGET_HOME/.pyenv"

# ── Dependencies ───────────────────────────────────────────
info "Installing build dependencies..."
apt-get update -qq
apt-get install -y -qq \
  build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget curl llvm \
  libncurses5-dev libncursesw5-dev xz-utils tk-dev \
  libffi-dev liblzma-dev git

# ── Install pyenv ──────────────────────────────────────────
if [ -d "$PYENV_DIR" ]; then
  info "pyenv already installed, updating..."
  su - "$TARGET_USER" -c "cd ~/.pyenv && git pull --quiet"
else
  info "Installing pyenv..."
  su - "$TARGET_USER" -c \
    'curl -fsSL https://pyenv.run | bash'
fi

success "pyenv installed"

# ── Shell config ───────────────────────────────────────────
for RCFILE in "$TARGET_HOME/.bashrc" "$TARGET_HOME/.zshrc"; do
  if [ -f "$RCFILE" ] && ! grep -q "pyenv" "$RCFILE"; then
    cat >> "$RCFILE" <<'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
    info "Added pyenv to $RCFILE"
  fi
done

# ── Install Python ─────────────────────────────────────────
info "Installing Python $PYTHON_VERSION (this may take a few minutes)..."
su - "$TARGET_USER" -c "
  export PYENV_ROOT=\"\$HOME/.pyenv\"
  export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
  eval \"\$(pyenv init -)\"
  pyenv install -s $PYTHON_VERSION
  pyenv global $PYTHON_VERSION
  python --version
  pip install --upgrade pip -q
  echo 'pip: '$(pip --version)
"

echo ""
success "Python $PYTHON_VERSION installed via pyenv!"
echo ""
echo "  Reload shell: source ~/.bashrc  (or ~/.zshrc)"
echo ""
echo "  Common commands:"
echo "    pyenv versions           # list installed"
echo "    pyenv install 3.11       # install another version"
echo "    pyenv local 3.11         # set version for current dir"
echo "    python -m venv .venv     # create virtualenv"
