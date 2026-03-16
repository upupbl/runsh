#!/bin/bash
# runsh.de/bench.sh — Quick server benchmark
# Usage: curl -sL runsh.de/bench.sh | bash
# Tests: CPU, memory, disk I/O, network speed

CYAN='\033[0;36m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
line() { echo -e "${CYAN}──────────────────────────────────────${NC}"; }

line
echo -e "${BOLD}  Server Benchmark${NC}  $(date '+%Y-%m-%d %H:%M')"
line

# ── System info ────────────────────────────────────────────
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
CORES=$(nproc)
MEM=$(free -h | awk '/^Mem:/{print $2}')
echo -e "  OS:   $OS"
echo -e "  CPU:  $CPU ($CORES cores)"
echo -e "  RAM:  $MEM"
line

# ── CPU benchmark ──────────────────────────────────────────
echo -e "  ${CYAN}CPU${NC} (calculating 1M prime numbers)..."
CPU_START=$(date +%s%N)
python3 -c "
n=0
for i in range(2,1000000):
    for j in range(2,int(i**0.5)+1):
        if i%j==0: break
    else: n+=1
print(n)
" > /dev/null 2>&1 || \
  dd if=/dev/zero bs=1M count=512 | md5sum > /dev/null 2>&1
CPU_END=$(date +%s%N)
CPU_TIME=$(( (CPU_END - CPU_START) / 1000000 ))
echo -e "  ${GREEN}CPU time: ${CPU_TIME}ms${NC}"

line

# ── Disk I/O benchmark ─────────────────────────────────────
echo -e "  ${CYAN}Disk I/O${NC}..."
TMPFILE=$(mktemp)

# Write
WRITE=$(dd if=/dev/zero of="$TMPFILE" bs=1M count=512 conv=fdatasync 2>&1 | grep -oP '[\d.]+ [MG]B/s')
echo -e "  Write: ${GREEN}${WRITE:-N/A}${NC}"

# Read
READ=$(dd if="$TMPFILE" of=/dev/null bs=1M 2>&1 | grep -oP '[\d.]+ [MG]B/s')
echo -e "  Read:  ${GREEN}${READ:-N/A}${NC}"

rm -f "$TMPFILE"
line

# ── Network speed ──────────────────────────────────────────
echo -e "  ${CYAN}Network${NC} (download test)..."

# Try multiple test files from different regions
declare -A NODES=(
  ["Tokyo"]="http://speed.cloudflare.com/__down?bytes=104857600"
  ["LA"]="http://lg.la.leaseweb.net/100MB.test"
)

for NODE in "${!NODES[@]}"; do
  URL="${NODES[$NODE]}"
  SPEED=$(curl -o /dev/null -s --max-time 10 -w "%{speed_download}" "$URL" 2>/dev/null || echo "0")
  if [ "$SPEED" != "0" ] && [ -n "$SPEED" ]; then
    MBPS=$(echo "$SPEED" | awk '{printf "%.1f MB/s", $1/1048576}')
    echo -e "  ${NODE}: ${GREEN}${MBPS}${NC}"
  else
    echo -e "  ${NODE}: timeout"
  fi
done

line
echo ""
