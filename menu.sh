#!/bin/bash
# runsh.de/menu.sh — Interactive terminal menu
# Usage: bash <(curl -sL runsh.de/menu.sh)

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

clear
echo -e "${BOLD}"
echo "  ██████╗ ██╗   ██╗███╗   ██╗███████╗██╗  ██╗"
echo "  ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║"
echo "  ██████╔╝██║   ██║██╔██╗ ██║███████╗███████║"
echo "  ██╔══██╗██║   ██║██║╚██╗██║╚════██║██╔══██║"
echo "  ██║  ██║╚██████╔╝██║ ╚████║███████║██║  ██║"
echo "  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝"
echo -e "${NC}${DIM}  runsh.de · Shell scripts, ready to run${NC}"
echo ""

declare -A SCRIPTS
declare -a KEYS

add() { SCRIPTS["$1"]="$2"; KEYS+=("$1"); }

echo -e "${CYAN}  // basics${NC}"
add "1"  "init          New server bootstrap"
add "2"  "update        Update & clean system"
add "3"  "swap          Create swap file (2G)"
add "4"  "bbr           Enable BBR TCP"
add "5"  "info          System overview"
add "6"  "bench         Performance benchmark"
add "7"  "cleanup       Deep disk cleanup"

echo -e "${CYAN}  // security${NC}"
add "8"  "ssh-harden    Harden SSH config"
add "9"  "ufw           Configure firewall"
add "10" "fail2ban      Block brute-force"

echo -e "${CYAN}  // network${NC}"
add "11" "wireguard     WireGuard VPN server"
add "12" "caddy         Caddy web server"
add "13" "frp           Fast reverse proxy"
add "14" "tailscale     Mesh VPN (easy)"

echo -e "${CYAN}  // runtime${NC}"
add "15" "docker        Docker + Compose"
add "16" "node          Node.js via nvm"
add "17" "python        Python via pyenv"
add "18" "go            Go language"
add "19" "rust          Rust via rustup"
add "20" "java          OpenJDK"
add "21" "php           PHP + FPM + Composer"
add "22" "zsh           Zsh + oh-my-zsh"
add "23" "nginx         Nginx web server"
add "24" "cert          SSL via Let's Encrypt"

echo -e "${CYAN}  // databases${NC}"
add "25" "postgres      PostgreSQL"
add "26" "mysql         MySQL / MariaDB"
add "27" "redis         Redis cache"
add "28" "mongodb       MongoDB"

echo -e "${CYAN}  // monitoring${NC}"
add "29" "netdata       Netdata dashboard"
add "30" "nezha         哪吒监控"
add "31" "uptime-kuma   Uptime monitor"

echo -e "${CYAN}  // self-hosted${NC}"
add "32" "vaultwarden   Password manager"
add "33" "nextcloud     Self-hosted cloud"
add "34" "n8n           Workflow automation"
add "35" "minio         S3-compatible storage"
add "36" "gitea         Self-hosted Git"

echo -e "${CYAN}  // apps${NC}"
add "37" "portainer     Docker GUI"

echo -e "${CYAN}  // utils${NC}"
add "38" "user          Create sudo user"
add "39" "cron-backup   Scheduled DB backup"

for key in "${KEYS[@]}"; do
  printf "  ${DIM}%3s${NC}  %s\n" "[$key]" "${SCRIPTS[$key]}"
done

echo ""
echo -e "${DIM}  ──────────────────────────────────────────────${NC}"
echo -n -e "  ${BOLD}Select a number (or q to quit):${NC} "
read -r choice

[ "$choice" = "q" ] && exit 0

# Map number to script name
NAMES=(
  "" init update swap bbr info bench cleanup
  ssh-harden ufw fail2ban
  wireguard caddy frp tailscale
  docker node python go rust java php zsh nginx cert
  postgres mysql redis mongodb
  netdata nezha uptime-kuma
  vaultwarden nextcloud n8n minio gitea
  portainer
  user cron-backup
)

SCRIPT="${NAMES[$choice]}"

if [ -z "$SCRIPT" ]; then
  echo -e "  ${YELLOW}Invalid choice.${NC}"
  exit 1
fi

echo ""
echo -e "  Running: ${GREEN}curl -sL runsh.de/${SCRIPT}.sh | bash${NC}"
echo -e "  ${DIM}Press Ctrl+C to cancel...${NC}"
sleep 2

curl -fsSL "https://runsh.de/${SCRIPT}.sh" | bash
