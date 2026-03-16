#!/bin/bash
# runsh.de/java.sh — Install OpenJDK
# Usage: curl -sL runsh.de/java.sh | bash
#        JAVA_VERSION=21 curl -sL runsh.de/java.sh | bash

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[java]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && error "Please run as root"

JAVA_VERSION="${JAVA_VERSION:-21}"

info "Installing OpenJDK $JAVA_VERSION..."
apt-get update -qq
apt-get install -y -qq "openjdk-${JAVA_VERSION}-jdk"

# ── Set JAVA_HOME ──────────────────────────────────────────
JAVA_HOME_PATH=$(update-java-alternatives -l 2>/dev/null | grep "$JAVA_VERSION" | awk '{print $3}' | head -1)
[ -z "$JAVA_HOME_PATH" ] && JAVA_HOME_PATH="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"

for RCFILE in /root/.bashrc /root/.zshrc /etc/environment; do
  [ -f "$RCFILE" ] || continue
  grep -q "JAVA_HOME" "$RCFILE" && continue
  echo "export JAVA_HOME=${JAVA_HOME_PATH}" >> "$RCFILE"
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >> "$RCFILE"
done

export JAVA_HOME="$JAVA_HOME_PATH"

echo ""
success "Java installed!"
java -version 2>&1 | head -1
echo "  JAVA_HOME: $JAVA_HOME_PATH"
echo ""
echo "  Reload shell: source ~/.bashrc"
echo ""
echo "  Switch version:"
echo "    update-alternatives --config java"
