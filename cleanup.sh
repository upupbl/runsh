#!/bin/bash
# runsh.de/cleanup.sh — Deep system cleanup
# Usage: curl -sL runsh.de/cleanup.sh | bash

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${CYAN}[cleanup]${NC} $1"; }
success() { echo -e "${GREEN}[ok]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $1"; }

[ "$EUID" -ne 0 ] && exec sudo bash "$0" "$@"

BEFORE=$(df / | awk 'NR==2{print $3}')

# ── APT ────────────────────────────────────────────────────
info "Cleaning APT cache..."
apt-get autoremove -y -qq
apt-get autoclean -qq
apt-get clean -qq
success "APT cleaned"

# ── Logs ───────────────────────────────────────────────────
info "Vacuuming journal logs (keep 7 days)..."
journalctl --vacuum-time=7d 2>/dev/null || true

info "Cleaning old log files (>30 days)..."
find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true
find /var/log -type f -name "*.1" -mtime +7 -delete 2>/dev/null || true

success "Logs cleaned"

# ── Temp files ─────────────────────────────────────────────
info "Cleaning /tmp (files >3 days)..."
find /tmp -type f -atime +3 -delete 2>/dev/null || true
success "Temp files cleaned"

# ── Docker ─────────────────────────────────────────────────
if command -v docker &>/dev/null; then
  info "Pruning Docker (stopped containers, dangling images, unused networks)..."
  docker system prune -f > /dev/null
  DOCKER_RECLAIMED=$(docker system df 2>/dev/null | grep "RECLAIMABLE" | head -1 || true)
  success "Docker pruned"
fi

# ── Thumbnail / cache ──────────────────────────────────────
find /root /home -type d -name ".cache" 2>/dev/null | while read dir; do
  SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
  warn "Found cache dir: $dir ($SIZE) — skipping (manual review recommended)"
done

# ── Large files report ─────────────────────────────────────
echo ""
echo -e "${CYAN}  Top 10 largest files in /var and /tmp:${NC}"
find /var /tmp -type f -size +50M 2>/dev/null \
  | xargs du -sh 2>/dev/null \
  | sort -rh \
  | head -10 \
  | sed 's/^/    /' || true

# ── Summary ────────────────────────────────────────────────
AFTER=$(df / | awk 'NR==2{print $3}')
FREED=$(( (BEFORE - AFTER) / 1024 ))

echo ""
success "Cleanup complete! Freed ~${FREED}MB"
df -h / | awk 'NR==2{printf "  Disk: %s used / %s total (%s free)\n", $3, $2, $4}'
