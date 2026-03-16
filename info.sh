#!/bin/bash
# runsh.de/info.sh — System info overview
# Usage: curl -sL runsh.de/info.sh | bash

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

line() { echo -e "${CYAN}──────────────────────────────────────${NC}"; }

line
echo -e "${BOLD}  System Info${NC}"
line

# OS
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
ARCH=$(uname -m)
HOSTNAME=$(hostname)
UPTIME=$(uptime -p 2>/dev/null || uptime)

echo -e "  ${CYAN}Hostname${NC}   $HOSTNAME"
echo -e "  ${CYAN}OS${NC}         $OS"
echo -e "  ${CYAN}Kernel${NC}     $KERNEL ($ARCH)"
echo -e "  ${CYAN}Uptime${NC}     $UPTIME"

line

# CPU
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(nproc)
CPU_LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')

echo -e "  ${CYAN}CPU${NC}        $CPU_MODEL"
echo -e "  ${CYAN}Cores${NC}      $CPU_CORES"
echo -e "  ${CYAN}Load avg${NC}   $CPU_LOAD"

line

# Memory
MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
MEM_USED=$(free -h  | awk '/^Mem:/{print $3}')
MEM_FREE=$(free -h  | awk '/^Mem:/{print $4}')
SWAP_TOTAL=$(free -h | awk '/^Swap:/{print $2}')
SWAP_USED=$(free -h  | awk '/^Swap:/{print $3}')

echo -e "  ${CYAN}Memory${NC}     ${MEM_USED} used / ${MEM_TOTAL} total (${MEM_FREE} free)"
echo -e "  ${CYAN}Swap${NC}       ${SWAP_USED} used / ${SWAP_TOTAL} total"

line

# Disk
echo -e "  ${CYAN}Disk${NC}"
df -h | awk 'NR>1 && /^\// {printf "    %-20s %s used / %s total (%s)\n", $6, $3, $2, $5}'

line

# Network
echo -e "  ${CYAN}Network${NC}"
ip -4 addr show scope global 2>/dev/null | awk '/inet/{print "    " $NF ": " $2}'

# Public IP
PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "unavailable")
echo -e "  ${CYAN}Public IP${NC}  $PUBLIC_IP"

line

# Docker
if command -v docker &>/dev/null; then
  DOCKER_VER=$(docker --version | awk '{print $3}' | tr -d ',')
  CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
  echo -e "  ${CYAN}Docker${NC}     v${DOCKER_VER} (${CONTAINERS} running)"
  line
fi

# BBR
BBR=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
echo -e "  ${CYAN}TCP CC${NC}     $BBR"
line
echo ""
