#!/usr/bin/env bash
# network_audit.sh - Automated Local Network Security Audit & Vulnerability Scanner
#
# Author: ShadowHarvy
# Version: 1.0.0
#
# DESCRIPTION:
#   Automatically detects your local network subnet range, discovers all connected
#   devices via ICMP ping & ARP sweep, identifies device OS & hardware vendors,
#   performs service vulnerability assessments, and generates a comprehensive
#   markdown audit summary report.
#
# USAGE:
#   sudo ./network_audit.sh [OPTIONS]
#
# OPTIONS:
#   -r, --range CIDR       Specify target network range (default: auto-detected LAN, e.g. 192.168.1.0/24)
#   -i, --interface IFACE  Specify network interface (default: auto-detected default route interface)
#   -o, --output FILE      Custom path for the Markdown audit report (default: ./reports/network_audit_<date>.md)
#   -q, --quick            Quick audit (fast discovery + top 100 ports + basic OS detection)
#   -f, --full             Full audit (all ports + thorough vulnerability script scanning)
#   --skip-vuln            Host discovery and OS identification only (skip vulnerability scripts)
#   -h, --help             Show this help message

set -uo pipefail

# --- ANSI Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Global Variables ---
TARGET_RANGE=""
TARGET_IFACE=""
OUTPUT_FILE=""
SCAN_MODE="standard" # quick, standard, full
SKIP_VULN=0
TEMP_DIR=""
START_TIME=0
REPORT_DIR="$(pwd)/reports"

# --- Title Banner ---
show_banner() {
  clear 2>/dev/null || true
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║                                                                       ║"
  echo -e "║  ${BOLD}${MAGENTA}   ███╗   ██╗███████╗████████╗     █████╗ ██╗   ██╗██████╗ ██╗████████╗${CYAN}║"
  echo -e "║  ${BOLD}${MAGENTA}   ████╗  ██║██╔════╝╚══██╔══╝    ██╔══██╗██║   ██║██╔══██╗██║╚══██╔══╝${CYAN}║"
  echo -e "║  ${BOLD}${MAGENTA}   ██╔██╗ ██║█████╗     ██║       ███████║██║   ██║██║  ██║██║   ██║   ${CYAN}║"
  echo -e "║  ${BOLD}${MAGENTA}   ██║╚██╗██║██╔══╝     ██║       ██╔══██║██║   ██║██║  ██║██║   ██║   ${CYAN}║"
  echo -e "║  ${BOLD}${MAGENTA}   ██║ ╚████║███████╗   ██║       ██║  ██║╚██████╔╝██████╔╝██║   ██║   ${CYAN}║"
  echo -e "║  ${BOLD}${MAGENTA}   ╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ${CYAN}║"
  echo "║                                                                       ║"
  echo -e "║              ${YELLOW}${BOLD}Local Network Security Audit & Device Scanner${CYAN}           ║"
  echo "║                                                                       ║"
  echo -e "║              ${GREEN}Auto-Detect Range • Ping Sweep • OS Identification${CYAN}       ║"
  echo -e "║               ${GREEN}Vulnerability Assessment • Markdown Summary Report${CYAN}      ║"
  echo "║                                                                       ║"
  echo -e "║  ${WHITE}Author:${NC} ${BLUE}${BOLD}ShadowHarvy${CYAN}                                                 ║"
  echo -e "║  ${WHITE}Version:${NC} ${GREEN}1.0.0${CYAN}                                                       ║"
  echo "║                                                                       ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo
}

# --- Usage Function ---
usage() {
  echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
  echo
  echo -e "${BOLD}Description:${NC}"
  echo "  Audits your local personal network by auto-detecting the subnet range,"
  echo "  pinging all live devices, identifying operating systems and hardware vendors,"
  echo "  checking for open security risks and vulnerabilities, and generating a detailed report."
  echo
  echo -e "${BOLD}Options:${NC}"
  echo "  -r, --range CIDR       Target network range (default: auto-detected, e.g. 192.168.1.0/24)"
  echo "  -i, --interface IFACE  Network interface to scan through (default: auto-detected)"
  echo "  -o, --output FILE      Custom output path for markdown report"
  echo "  -q, --quick            Quick scan (top 100 ports, fast discovery, skips deep scripts)"
  echo "  -f, --full             Thorough scan (all 65,535 ports + deep CVE vulnerability checks)"
  echo "      --skip-vuln        Device discovery & OS detection only, skip vulnerability scripts"
  echo "  -h, --help             Show this help message"
  echo
  echo -e "${BOLD}Examples:${NC}"
  echo "  sudo $0                     # Auto-detect local range and perform standard audit"
  echo "  sudo $0 -q                  # Quick audit mode"
  echo "  sudo $0 -r 192.168.1.0/24   # Audit specific subnet"
  echo "  sudo $0 -o my_audit.md      # Save markdown report to custom filename"
}

# --- Cleanup Trap ---
cleanup() {
  if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
  tput cnorm 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--range)
      TARGET_RANGE="${2:-}"
      shift 2
      ;;
    -i|--interface)
      TARGET_IFACE="${2:-}"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE="${2:-}"
      shift 2
      ;;
    -q|--quick)
      SCAN_MODE="quick"
      shift
      ;;
    -f|--full)
      SCAN_MODE="full"
      shift
      ;;
    --skip-vuln)
      SKIP_VULN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown argument: $1${NC}" >&2
      usage
      exit 1
      ;;
  esac
done

show_banner

# --- Check Privileges ---
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${YELLOW}[!] Notice: Running without root/sudo.${NC}"
  echo -e "${YELLOW}    OS fingerprinting (-O) and raw SYN packets require root privileges.${NC}"
  echo -e "${YELLOW}    For optimal accuracy, consider running: ${BOLD}sudo $0${NC}"
  echo
fi

# --- Check & Suggest Dependencies ---
check_dependencies() {
  local missing=()
  for cmd in ip ping awk python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}[error] Missing required system tools: ${missing[*]}${NC}" >&2
    exit 1
  fi

  if ! command -v nmap >/dev/null 2>&1; then
    echo -e "${YELLOW}[!] 'nmap' is not currently installed.${NC}"
    echo -e "    ${WHITE}nmap is required for deep OS fingerprinting and CVE vulnerability script checks.${NC}"
    
    if [ -t 0 ] && command -v pacman >/dev/null 2>&1; then
      read -t 5 -r -p "$(echo -e "${CYAN}Would you like to install nmap now via pacman? [Y/n]: ${NC}")" DO_INSTALL || DO_INSTALL="n"
      DO_INSTALL="${DO_INSTALL:-y}"
      if [[ "$DO_INSTALL" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing nmap...${NC}"
        sudo pacman -S --needed --noconfirm nmap || true
      fi
    elif [ -t 0 ] && command -v apt >/dev/null 2>&1; then
      read -t 5 -r -p "$(echo -e "${CYAN}Would you like to install nmap now via apt? [Y/n]: ${NC}")" DO_INSTALL || DO_INSTALL="n"
      DO_INSTALL="${DO_INSTALL:-y}"
      if [[ "$DO_INSTALL" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing nmap...${NC}"
        sudo apt update && sudo apt install -y nmap || true
      fi
    fi
  fi
}

check_dependencies

TEMP_DIR=$(mktemp -d /tmp/net_audit_XXXXXX)
START_TIME=$(date +%s)
SCAN_DATE=$(date "+%Y-%m-%d %H:%M:%S")

# -------------------------------------------------------------
# STEP 1: Auto-Detect Network Range & Interface
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 1: Network Environment Auto-Detection${NC}"

# Auto-detect default route interface and gateway if not specified
if [[ -z "$TARGET_IFACE" ]]; then
  DEFAULT_ROUTE=$(ip -o -4 route show to default 2>/dev/null | head -n1 || echo "")
  if [[ -n "$DEFAULT_ROUTE" ]]; then
    TARGET_IFACE=$(echo "$DEFAULT_ROUTE" | awk '{
      for (i=1; i<=NF; i++) {
        if ($i == "dev") { print $(i+1); exit }
      }
    }')
    GATEWAY_IP=$(echo "$DEFAULT_ROUTE" | awk '{
      for (i=1; i<=NF; i++) {
        if ($i == "via") { print $(i+1); exit }
      }
    }')
  fi
fi

# Fallback interface detection
if [[ -z "$TARGET_IFACE" ]]; then
  TARGET_IFACE=$(ip -o -4 addr show | grep -v ' lo ' | awk '{print $2}' | head -n1 || echo "")
fi

if [[ -z "$TARGET_IFACE" ]]; then
  echo -e "${RED}[error] Unable to detect an active network interface. Please specify one with -i <iface>.${NC}" >&2
  exit 1
fi

# Resolve Local IP and CIDR
LOCAL_IP_CIDR=$(ip -o -4 addr show dev "$TARGET_IFACE" 2>/dev/null | awk '{print $4}' | head -n1 || echo "")
if [[ -z "$LOCAL_IP_CIDR" ]]; then
  echo -e "${RED}[error] Interface $TARGET_IFACE has no active IPv4 address.${NC}" >&2
  exit 1
fi

LOCAL_IP="${LOCAL_IP_CIDR%/*}"
PREFIX_LEN="${LOCAL_IP_CIDR#*/}"
GATEWAY_IP="${GATEWAY_IP:-$(ip route show dev "$TARGET_IFACE" 2>/dev/null | grep default | awk '{print $3}' || echo "Unknown")}"

# Calculate Network Range in CIDR notation
if [[ -z "$TARGET_RANGE" ]]; then
  TARGET_RANGE=$(python3 -c "
import ipaddress
try:
    net = ipaddress.IPv4Network('$LOCAL_IP_CIDR', strict=False)
    print(str(net))
except Exception:
    print('$LOCAL_IP_CIDR')
" 2>/dev/null || echo "$LOCAL_IP_CIDR")
fi

echo -e "  ${GREEN}✓${NC} Interface        : ${BOLD}$TARGET_IFACE${NC}"
echo -e "  ${GREEN}✓${NC} Local Host IP    : ${BOLD}$LOCAL_IP${NC} (Prefix /$PREFIX_LEN)"
echo -e "  ${GREEN}✓${NC} Default Gateway  : ${BOLD}$GATEWAY_IP${NC}"
echo -e "  ${GREEN}✓${NC} Detected Subnet  : ${BOLD}${CYAN}$TARGET_RANGE${NC}"
echo -e "  ${GREEN}✓${NC} Audit Scan Mode  : ${BOLD}${MAGENTA}${SCAN_MODE^^}${NC}"
echo

# -------------------------------------------------------------
# STEP 2: Ping & Host Discovery Sweep
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 2: Host Discovery (Ping & ARP Sweep)${NC}"
echo -e "${WHITE}Scanning subnet ${CYAN}$TARGET_RANGE${WHITE} for responsive devices...${NC}"

DISCOVERED_HOSTS_FILE="$TEMP_DIR/discovered_hosts.txt"
touch "$DISCOVERED_HOSTS_FILE"

HAS_NMAP=0
if command -v nmap >/dev/null 2>&1; then
  HAS_NMAP=1
fi

if [[ $HAS_NMAP -eq 1 ]]; then
  # Fast Nmap Ping Sweep (ICMP echo, timestamp, ARP on local LAN, common TCP SYN probes)
  echo -e "  ${BLUE}•${NC} Running nmap host discovery..."
  nmap -sn -T4 --min-parallelism 64 "$TARGET_RANGE" -oG "$TEMP_DIR/nmap_hosts.gnmap" >/dev/null 2>&1 || true
  
  grep "Status: Up" "$TEMP_DIR/nmap_hosts.gnmap" 2>/dev/null | awk '{print $2}' | sort -V -u > "$DISCOVERED_HOSTS_FILE"
else
  # Native Python & Ping Sweep Fallback
  echo -e "  ${BLUE}•${NC} Performing multithreaded ping sweep..."
  python3 -c "
import ipaddress, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

network = ipaddress.IPv4Network('$TARGET_RANGE', strict=False)
live_hosts = []

def ping_host(ip_str):
    res = subprocess.run(['ping', '-c', '1', '-W', '1', ip_str], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if res.returncode == 0:
        return ip_str
    return None

hosts = [str(ip) for ip in network.hosts()]
with ThreadPoolExecutor(max_workers=50) as executor:
    results = executor.map(ping_host, hosts)
    for r in results:
        if r:
            live_hosts.append(r)

for h in sorted(live_hosts, key=lambda x: [int(p) for p in x.split('.')]):
    print(h)
" > "$DISCOVERED_HOSTS_FILE" 2>/dev/null || true
fi

# Ensure local host and gateway are included if ARP populated
if [[ -n "$LOCAL_IP" ]] && ! grep -q "^$LOCAL_IP$" "$DISCOVERED_HOSTS_FILE"; then
  echo "$LOCAL_IP" >> "$DISCOVERED_HOSTS_FILE"
fi

# Also check ARP table / ip neigh for hosts that might suppress ICMP echo
while read -r neigh_ip; do
  if [[ -n "$neigh_ip" ]] && ! grep -q "^$neigh_ip$" "$DISCOVERED_HOSTS_FILE"; then
    echo "$neigh_ip" >> "$DISCOVERED_HOSTS_FILE"
  fi
done < <(ip -4 neigh show dev "$TARGET_IFACE" 2>/dev/null | grep -E 'REACHABLE|STALE|DELAY' | awk '{print $1}')

# Filter discovered hosts to strictly match TARGET_RANGE
python3 -c "
import ipaddress, sys
try:
    net = ipaddress.IPv4Network('$TARGET_RANGE', strict=False)
except Exception:
    net = None

with open('$DISCOVERED_HOSTS_FILE', 'r') as f:
    hosts = [line.strip() for line in f if line.strip()]

valid = []
for h in hosts:
    try:
        ip = ipaddress.IPv4Address(h)
        if net is None or ip in net:
            valid.append(h)
    except Exception:
        pass

for v in sorted(valid, key=lambda x: [int(p) for p in x.split('.')]):
    print(v)
" > "$TEMP_DIR/filtered_hosts.txt" 2>/dev/null && mv "$TEMP_DIR/filtered_hosts.txt" "$DISCOVERED_HOSTS_FILE"

sort -V -u "$DISCOVERED_HOSTS_FILE" -o "$DISCOVERED_HOSTS_FILE"
TOTAL_HOSTS=$(wc -l < "$DISCOVERED_HOSTS_FILE")

if [[ $TOTAL_HOSTS -eq 0 ]]; then
  echo -e "${RED}[!] No responsive devices detected on $TARGET_RANGE.${NC}"
  echo -e "    Check your network connection and verify firewall settings."
  exit 0
fi

echo -e "  ${GREEN}✓${NC} Discovered ${BOLD}${GREEN}$TOTAL_HOSTS live device(s)${NC} on the network."
echo

# --- MAC Vendor / Manufacturer Lookup Function ---
lookup_mac_vendor() {
  local mac="$1"
  local ip="${2:-}"
  
  if [[ -z "$mac" || "$mac" == "-" ]]; then
    echo "Unknown Manufacturer"
    return
  fi

  # Local host special check via DMI
  if [[ -n "$LOCAL_IP" && "$ip" == "$LOCAL_IP" ]]; then
    local dmi_vendor
    dmi_vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | tr -d '\r\n' || true)
    if [[ -n "$dmi_vendor" && "$dmi_vendor" != "System manufacturer" && "$dmi_vendor" != "To be filled by O.E.M." ]]; then
      echo "$dmi_vendor"
      return
    fi
  fi

  # Clean MAC to 6 uppercase hex characters
  local clean_mac
  clean_mac=$(echo "$mac" | tr -d ':-' | tr '[:lower:]' '[:upper:]' | cut -c1-6)

  # 1. Check IEEE OUI Database (/usr/share/hwdata/oui.txt)
  if [[ -f "/usr/share/hwdata/oui.txt" ]]; then
    local v
    v=$(grep -m1 "^$clean_mac" /usr/share/hwdata/oui.txt 2>/dev/null | awk -F'\t+' '{print $NF}' | sed 's/^[ \t]*//;s/[ \t]*$//' || true)
    if [[ -n "$v" ]]; then
      echo "$v"
      return
    fi
  fi

  # 2. Check Nmap MAC Prefixes
  if [[ -f "/usr/share/nmap/nmap-mac-prefixes" ]]; then
    local v
    v=$(grep -i -m1 "^$clean_mac" /usr/share/nmap/nmap-mac-prefixes 2>/dev/null | cut -d' ' -f2- | sed 's/^[ \t]*//;s/[ \t]*$//' || true)
    if [[ -n "$v" ]]; then
      echo "$v"
      return
    fi
  fi

  # 3. Check if Locally Administered / Private MAC (2nd bit of 1st byte is 1)
  local first_byte
  first_byte=$(echo "$clean_mac" | cut -c1-2)
  if [[ "$first_byte" =~ ^[0-9A-F][26AEae]$ ]]; then
    echo "Private / Randomized MAC"
    return
  fi

  echo "Unknown Manufacturer"
}

# --- Device Name Resolution Function ---
resolve_device_name() {
  local ip="$1"
  local dev_name=""

  # Local host special check
  if [[ -n "$LOCAL_IP" && "$ip" == "$LOCAL_IP" ]]; then
    local local_h
    local_h=$(hostname 2>/dev/null || uname -n 2>/dev/null || true)
    if [[ -n "$local_h" ]]; then
      echo "$local_h"
      return
    fi
  fi

  # Tier 1: mDNS / Avahi (Apple devices, smart TVs, IoT, Linux, Google Cast)
  if command -v avahi-resolve >/dev/null 2>&1; then
    dev_name=$(timeout 0.5 avahi-resolve -a "$ip" 2>/dev/null | awk '{print $2}' | sed 's/\.local$//' | tr -d '\r\n' || true)
    if [[ -n "$dev_name" && "$dev_name" != *"Failed"* ]]; then
      echo "$dev_name"
      return
    fi
  fi

  # Tier 2: NetBIOS (Windows computers, Samba NAS, Windows domain members)
  if command -v nmblookup >/dev/null 2>&1; then
    local nb_name
    nb_name=$(timeout 0.5 nmblookup -A "$ip" 2>/dev/null | grep '<00>' | grep -v '<GROUP>' | head -n1 | awk '{print $1}' | tr -d '\r\n' || true)
    if [[ -n "$nb_name" && "$nb_name" != *"Looking"* && "$nb_name" != *"unknown"* ]]; then
      echo "$nb_name"
      return
    fi
  fi

  # Tier 3: Standard DNS PTR resolution via getent or host
  local dns_name
  dns_name=$(timeout 0.4 getent hosts "$ip" 2>/dev/null | awk '{print $2}' | tr -d '\r\n' || true)
  if [[ -z "$dns_name" && -x "$(command -v host)" ]]; then
    dns_name=$(timeout 0.4 host "$ip" 2>/dev/null | awk '{print $NF}' | sed 's/\.$//' | tr -d '\r\n' || true)
  fi
  if [[ -n "$dns_name" && "$dns_name" != *"not found"* && "$dns_name" != *"3(NXDOMAIN)"* ]]; then
    echo "$dns_name"
    return
  fi

  # Tier 4: HTTP title banner for web-enabled devices (routers, printers, smart switches)
  if command -v curl >/dev/null 2>&1; then
    local web_title
    web_title=$(timeout 0.6 curl -s -m 0.5 -k "http://$ip/" 2>/dev/null | grep -o -i '<title>[^<]*</title>' | head -n1 | sed -e 's/<[^>]*>//g' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r\n' || true)
    if [[ -n "$web_title" && ${#web_title} -lt 35 && "$web_title" != *"404"* && "$web_title" != *"302"* && "$web_title" != *"Index of"* ]]; then
      echo "$web_title"
      return
    fi
  fi

  echo "-"
}

# -------------------------------------------------------------
# STEP 3: OS Detection & Port Scanning
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 3: Operating System & Service Detection${NC}"
echo -e "${WHITE}Inspecting device signatures, service banners, and operating systems...${NC}"
echo

# Temporary structured results storage
HOSTS_DATA_FILE="$TEMP_DIR/hosts_inventory.tsv"
echo -e "IP\tDEVICE_NAME\tMANUFACTURER\tMAC\tOS\tPORTS\tRISKS" > "$HOSTS_DATA_FILE"

current_idx=0
while read -r host_ip; do
  ((current_idx++))

  # 1. Resolve MAC Address
  mac="-"
  neigh_entry=$(ip -4 neigh show "$host_ip" dev "$TARGET_IFACE" 2>/dev/null || true)
  found_mac=$(echo "$neigh_entry" | awk '{for(i=1;i<=NF;i++) if($i ~ /^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$/) {print $i; exit}}' || true)
  if [[ -z "$found_mac" && -f "/proc/net/arp" ]]; then
    found_mac=$(awk -v ip="$host_ip" '$1 == ip {print $4}' /proc/net/arp 2>/dev/null | grep -E '^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$' || true)
  fi
  if [[ -n "$found_mac" && "$found_mac" != "00:00:00:00:00:00" ]]; then
    mac="$found_mac"
  elif [[ "$host_ip" == "$LOCAL_IP" ]]; then
    mac=$(cat "/sys/class/net/$TARGET_IFACE/address" 2>/dev/null || echo "Local Device")
  fi

  # 2. Resolve Manufacturer Name (IEEE OUI database + local DMI)
  vendor=$(lookup_mac_vendor "$mac" "$host_ip")

  # 3. Resolve Device Friendly Name (mDNS / NetBIOS / DNS / Web Title)
  device_name=$(resolve_device_name "$host_ip")
  if [[ "$device_name" == "-" || "$device_name" == "Unknown Device" ]]; then
    if [[ "$vendor" != "Unknown Manufacturer" && "$vendor" != "Private / Randomized MAC" ]]; then
      device_name="$vendor Device"
    else
      device_name="Device-$host_ip"
    fi
  fi

  # Shorten preview name if needed
  preview_name="$device_name"
  if [[ ${#preview_name} -gt 18 ]]; then preview_name="${preview_name:0:16}.."; fi
  preview_vendor="$vendor"
  if [[ ${#preview_vendor} -gt 18 ]]; then preview_vendor="${preview_vendor:0:16}.."; fi

  printf "  [%d/%d] Scanning %-15s (%s | %s) ... " "$current_idx" "$TOTAL_HOSTS" "$host_ip" "$preview_name" "$preview_vendor"

  detected_os="Unknown"
  open_ports_str="None"
  host_risks=()

  if [[ $HAS_NMAP -eq 1 ]]; then
    # Port scan & OS detection flags based on mode
    scan_args=("-sV" "--version-light")
    
    if [[ "$EUID" -eq 0 ]]; then
      scan_args+=("-O" "--osscan-guess" "--max-os-tries" "2")
    fi

    if [[ "$SCAN_MODE" == "quick" ]]; then
      scan_args+=("-F" "-T4" "--max-retries" "1" "--host-timeout" "4s") # Top 100 ports
    elif [[ "$SCAN_MODE" == "full" ]]; then
      scan_args+=("-p-" "-T4" "--host-timeout" "60s") # All 65535 ports
    else
      # Standard common 1000 ports or standard audit list
      scan_args+=("-p" "21,22,23,25,53,80,110,135,139,143,443,445,554,993,995,1433,1723,1883,3306,3389,5000,5353,5357,5432,5900,6379,8000,8080,8443,8888,9000" "-T4" "--max-retries" "1" "--host-timeout" "8s")
    fi

    host_nmap_out="$TEMP_DIR/nmap_${host_ip}.txt"
    host_nmap_xml="$TEMP_DIR/nmap_${host_ip}.xml"
    
    nmap "${scan_args[@]}" "$host_ip" -oN "$host_nmap_out" -oX "$host_nmap_xml" >/dev/null 2>&1 || true

    # Extract MAC and vendor if nmap found it and local was unknown
    nmap_mac=$(grep -m1 "MAC Address:" "$host_nmap_out" 2>/dev/null | awk '{print $3}' || true)
    nmap_vendor=$(grep -m1 "MAC Address:" "$host_nmap_out" 2>/dev/null | sed 's/.*(\(.*\))/\1/' || true)
    if [[ -n "$nmap_mac" && "$mac" == "-" ]]; then mac="$nmap_mac"; fi
    if [[ -n "$nmap_vendor" && "$nmap_vendor" != "$nmap_mac" && ("$vendor" == "Unknown Manufacturer" || "$vendor" == "-") ]]; then
      vendor="$nmap_vendor"
    fi

    # Check Nmap script outputs for device name (NetBIOS / http-title)
    nmap_nb_name=$(grep -m1 "NetBIOS computer name:" "$host_nmap_out" 2>/dev/null | awk '{print $NF}' || true)
    if [[ -n "$nmap_nb_name" && "$device_name" == *"Device"* ]]; then
      device_name="$nmap_nb_name"
    fi

    # Extract OS
    nmap_os=$(grep -m1 "OS details:" "$host_nmap_out" 2>/dev/null | cut -d: -f2- | sed 's/^[ \t]*//' || true)
    if [[ -z "$nmap_os" ]]; then
      nmap_os=$(grep -m1 "Running:" "$host_nmap_out" 2>/dev/null | cut -d: -f2- | sed 's/^[ \t]*//' || true)
    fi
    if [[ -z "$nmap_os" ]]; then
      nmap_os=$(grep -m1 "Aggressive OS guesses:" "$host_nmap_out" 2>/dev/null | cut -d: -f2- | cut -d, -f1 | sed 's/^[ \t]*//' || true)
    fi
    if [[ -n "$nmap_os" ]]; then
      detected_os="$nmap_os"
    fi

    # Extract Open Ports
    open_ports_list=$(grep -E '^[0-9]+/(tcp|udp)[ \t]+open' "$host_nmap_out" 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || true)
    if [[ -n "$open_ports_list" ]]; then
      open_ports_str="$open_ports_list"
    fi

  else
    # Fallback OS Heuristics: ICMP TTL & TCP banner check
    ttl=$(ping -c 1 -W 1 "$host_ip" 2>/dev/null | grep -o 'ttl=[0-9]*' | cut -d= -f2 || true)
    if [[ -n "$ttl" ]]; then
      if [[ "$ttl" -le 64 ]]; then
        detected_os="Linux / Unix / Android / macOS (TTL ~$ttl)"
      elif [[ "$ttl" -le 128 ]]; then
        detected_os="Microsoft Windows (TTL ~$ttl)"
      else
        detected_os="Network Device / Cisco (TTL ~$ttl)"
      fi
    fi

    # Quick probe for common ports using python
    open_ports_str=$(python3 -c "
import socket
target = '$host_ip'
ports = [21, 22, 23, 80, 139, 443, 445, 3389, 5357, 8080]
open_p = []
for p in ports:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.3)
    if s.connect_ex((target, p)) == 0:
        open_p.append(f'{p}/tcp')
    s.close()
print(','.join(open_p) if open_p else 'None')
" 2>/dev/null || echo "None")

  fi

  # Multi-tier OS heuristic fallback if Nmap did not identify specific OS
  if [[ "$detected_os" == "Unknown" || -z "$detected_os" ]]; then
    # Tier 1: Local Auditor Machine
    if [[ -n "$LOCAL_IP" && "$host_ip" == "$LOCAL_IP" ]]; then
      local_os_name=$(grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || uname -sr 2>/dev/null || true)
      if [[ -n "$local_os_name" ]]; then
        detected_os="$local_os_name"
      fi
    fi

    # Tier 2: Signature identification from Device Name and Vendor
    if [[ "$detected_os" == "Unknown" || -z "$detected_os" ]]; then
      if [[ "$device_name" =~ (eero|Eero) || "$vendor" =~ (eero|Eero) ]]; then
        detected_os="eeroOS (Embedded Linux)"
      elif [[ "$device_name" =~ (homeassistant|HomeAssistant) ]]; then
        detected_os="Home Assistant OS (Linux)"
      elif [[ "$device_name" =~ [Aa]ndroid || "$device_name" =~ [Gg]oogle || "$vendor" =~ Google ]]; then
        detected_os="Android (Linux)"
      elif [[ "$device_name" =~ (Tasmota|tasmota|plug|switch|bulb|light) || "$vendor" =~ (Espressif|Tuya) ]]; then
        detected_os="Embedded RTOS / ESP32"
      elif [[ "$device_name" =~ (dietprinter|DietPi) || "$vendor" =~ Raspberry ]]; then
        detected_os="Debian / Raspberry Pi OS"
      elif [[ "$vendor" =~ (Philips Lighting|Signify) ]]; then
        detected_os="Philips Hue OS (Embedded Linux)"
      elif [[ "$vendor" =~ Apple ]]; then
        detected_os="Apple iOS / iPadOS / macOS"
      elif [[ "$vendor" =~ Microsoft ]]; then
        detected_os="Microsoft Windows"
      fi
    fi

    # Tier 3: ICMP TTL Heuristics fallback
    if [[ "$detected_os" == "Unknown" || -z "$detected_os" ]]; then
      ttl=$(ping -c 1 -W 1 "$host_ip" 2>/dev/null | grep -o 'ttl=[0-9]*' | cut -d= -f2 || true)
      if [[ -n "$ttl" ]]; then
        if [[ "$ttl" -le 64 ]]; then
          detected_os="Linux / Apple / Android (TTL ~$ttl)"
        elif [[ "$ttl" -le 128 ]]; then
          detected_os="Microsoft Windows (TTL ~$ttl)"
        else
          detected_os="Network Appliance (TTL ~$ttl)"
        fi
      fi
    fi
  fi

  # -------------------------------------------------------------
  # Security Risk Evaluation for Open Services
  # -------------------------------------------------------------
  if [[ "$open_ports_str" != "None" ]]; then
    # Insecure Plaintext Protocols
    if [[ "$open_ports_str" =~ 23/(tcp|udp) ]]; then
      host_risks+=("CRITICAL: Telnet (port 23) in use - unencrypted plaintext protocol!")
    fi
    if [[ "$open_ports_str" =~ 21/(tcp|udp) ]]; then
      host_risks+=("MEDIUM: FTP service (port 21) detected - cleartext credentials risk")
    fi
    if [[ "$open_ports_str" =~ 80/(tcp|udp) ]] && [[ ! "$open_ports_str" =~ 443/(tcp|udp) ]]; then
      host_risks+=("LOW: Unencrypted HTTP management (port 80) without HTTPS (443)")
    fi

    # Exposed Remote Desktop & Sharing
    if [[ "$open_ports_str" =~ 445/(tcp|udp) ]]; then
      host_risks+=("MEDIUM: SMB File Sharing (port 445) exposed on LAN")
    fi
    if [[ "$open_ports_str" =~ 3389/(tcp|udp) ]]; then
      host_risks+=("MEDIUM: RDP Remote Desktop (port 3389) accessible on LAN")
    fi
    if [[ "$open_ports_str" =~ 5900/(tcp|udp) ]]; then
      host_risks+=("MEDIUM: VNC Remote Desktop (port 5900) exposed")
    fi

    # Exposed Databases
    if [[ "$open_ports_str" =~ 3306/(tcp|udp) ]]; then
      host_risks+=("HIGH: MySQL Database (port 3306) exposed to local subnet")
    fi
    if [[ "$open_ports_str" =~ 5432/(tcp|udp) ]]; then
      host_risks+=("HIGH: PostgreSQL Database (port 5432) exposed to local subnet")
    fi
    if [[ "$open_ports_str" =~ 6379/(tcp|udp) ]]; then
      host_risks+=("HIGH: Redis Server (port 6379) exposed (frequently unauthenticated!)")
    fi
    if [[ "$open_ports_str" =~ 27017/(tcp|udp) ]]; then
      host_risks+=("HIGH: MongoDB (port 27017) exposed on LAN")
    fi
  fi

  # Format Risks String
  risks_str="None"
  if [[ ${#host_risks[@]} -gt 0 ]]; then
    risks_str=$(IFS='; '; echo "${host_risks[*]}")
  fi

  # Print status
  if [[ "$risks_str" != "None" ]]; then
    echo -e "${YELLOW}Done! (Risks identified)${NC}"
  else
    echo -e "${GREEN}Done!${NC}"
  fi

  # Store row
  echo -e "${host_ip}\t${device_name}\t${vendor}\t${mac}\t${detected_os}\t${open_ports_str}\t${risks_str}" >> "$HOSTS_DATA_FILE"
done < "$DISCOVERED_HOSTS_FILE"

echo

# -------------------------------------------------------------
# STEP 4: Vulnerability Script Assessment (Nmap NSE)
# -------------------------------------------------------------
VULN_RESULTS_DIR="$TEMP_DIR/vuln_scans"
mkdir -p "$VULN_RESULTS_DIR"

if [[ $HAS_NMAP -eq 1 && $SKIP_VULN -eq 0 ]]; then
  echo -e "${CYAN}${BOLD}▶ Phase 4: CVE & Vulnerability Script Assessment${NC}"
  echo -e "${WHITE}Executing vulnerability checks against open network services...${NC}"
  echo

  # Find hosts with open ports
  while IFS=$'\t' read -r r_ip r_dev_name r_vendor r_mac r_os r_ports r_risks; do
    [[ "$r_ip" == "IP" ]] && continue
    [[ "$r_ports" == "None" ]] && continue

    echo -e "  ${BLUE}•${NC} Auditing vulnerabilities on ${BOLD}$r_ip${NC} ($r_dev_name | ports: $r_ports)..."
    vuln_out="$VULN_RESULTS_DIR/${r_ip}_vuln.txt"
    
    # Run NSE vulnerability and security audit scripts
    nmap -sV --version-light --script "vuln and not (dos or brute)" --script-timeout 30s -p "$r_ports" "$r_ip" -oN "$vuln_out" >/dev/null 2>&1 || true

    # Extract detected CVEs or vulnerabilities
    cve_found=$(grep -E 'VULNERABLE|CVE-[0-9]{4}-[0-9]+' "$vuln_out" 2>/dev/null | head -n5 || true)
    if [[ -n "$cve_found" ]]; then
      echo -e "    ${RED}⚠ Found potential vulnerability on $r_ip ($r_dev_name)!${NC}"
      echo "$cve_found" | sed 's/^/      /'
    else
      echo -e "    ${GREEN}✓ No high-profile CVEs flagged by automated scripts.${NC}"
    fi
  done < "$HOSTS_DATA_FILE"
  echo
fi

# -------------------------------------------------------------
# STEP 5: Terminal Output & Report Generation
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 5: Audit Summary & Report Generation${NC}"
echo

# Summary Metrics
TOTAL_DEVICES=$(tail -n +2 "$HOSTS_DATA_FILE" | wc -l)
DEVICES_WITH_RISKS=0
while IFS=$'\t' read -r r_ip r_dev_name r_vendor r_mac r_os r_ports r_risks; do
  [[ "$r_ip" == "IP" ]] && continue
  if [[ "$r_risks" != "None" ]]; then
    ((DEVICES_WITH_RISKS++))
  fi
done < "$HOSTS_DATA_FILE"

# Print Terminal Table
echo -e "${WHITE}${BOLD}=== Local Device Inventory & Audit Table ===${NC}"
printf "${BLUE}%-15s %-20s %-24s %-22s %-15s %b${NC}\n" "IP ADDRESS" "DEVICE NAME" "MANUFACTURER" "DETECTED OS" "OPEN PORTS" "RISK LEVEL"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"

while IFS=$'\t' read -r r_ip r_dev_name r_vendor r_mac r_os r_ports r_risks; do
  [[ "$r_ip" == "IP" ]] && continue

  # Shorten strings for clean column alignment
  short_dev="$r_dev_name"
  if [[ ${#short_dev} -gt 19 ]]; then short_dev="${short_dev:0:17}.."; fi

  short_vendor="$r_vendor"
  if [[ ${#short_vendor} -gt 23 ]]; then short_vendor="${short_vendor:0:21}.."; fi

  short_os="$r_os"
  if [[ ${#short_os} -gt 21 ]]; then short_os="${short_os:0:19}.."; fi

  short_ports="$r_ports"
  if [[ ${#short_ports} -gt 14 ]]; then short_ports="${short_ports:0:12}.."; fi

  # Risk Color
  risk_badge="${GREEN}CLEAN${NC}"
  if [[ "$r_risks" == *"CRITICAL"* || "$r_risks" == *"HIGH"* ]]; then
    risk_badge="${RED}${BOLD}HIGH RISK${NC}"
  elif [[ "$r_risks" == *"MEDIUM"* ]]; then
    risk_badge="${YELLOW}MEDIUM${NC}"
  elif [[ "$r_risks" == *"LOW"* ]]; then
    risk_badge="${CYAN}LOW/INFO${NC}"
  fi

  printf "%-15s %-20s %-24s %-22s %-15s %b\n" "$r_ip" "$short_dev" "$short_vendor" "$short_os" "$short_ports" "$risk_badge"
done < "$HOSTS_DATA_FILE"

echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo

# -------------------------------------------------------------
# Generate Markdown Audit Report
# -------------------------------------------------------------
mkdir -p "$REPORT_DIR"
if [[ -z "$OUTPUT_FILE" ]]; then
  OUTPUT_FILE="$REPORT_DIR/network_audit_$(date +%Y%m%d_%H%M%S).md"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

{
  echo "# Network Security Audit Report"
  echo
  echo "**Audit Date:** $SCAN_DATE  "
  echo "**Target Subnet:** \`$TARGET_RANGE\`  "
  echo "**Interface:** \`$TARGET_IFACE\` | **Gateway:** \`$GATEWAY_IP\` | **Auditor Host:** \`$LOCAL_IP\`  "
  echo "**Scan Duration:** ${DURATION} seconds  "
  echo
  echo "---"
  echo
  echo "## 📊 Executive Summary"
  echo
  echo "| Metric | Value |"
  echo "| :--- | :--- |"
  echo "| **Total Devices Detected** | **$TOTAL_DEVICES** |"
  echo "| **Devices With Open Ports / Risks** | **$DEVICES_WITH_RISKS** |"
  echo "| **Clean / No Exposed Risks** | **$((TOTAL_DEVICES - DEVICES_WITH_RISKS))** |"
  echo "| **Audit Mode** | \`${SCAN_MODE^^}\` |"
  echo
  echo "---"
  echo
  echo "## 🖥️ Device Inventory"
  echo
  echo "| IP Address | Device Name | Manufacturer | MAC Address | Detected OS | Open Ports | Status |"
  echo "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"

  while IFS=$'\t' read -r r_ip r_dev_name r_vendor r_mac r_os r_ports r_risks; do
    [[ "$r_ip" == "IP" ]] && continue
    status="🟢 Clean"
    if [[ "$r_risks" == *"CRITICAL"* || "$r_risks" == *"HIGH"* ]]; then
      status="🔴 High Risk"
    elif [[ "$r_risks" == *"MEDIUM"* ]]; then
      status="🟡 Warning"
    elif [[ "$r_risks" == *"LOW"* ]]; then
      status="🔵 Info"
    fi
    echo "| \`$r_ip\` | **$r_dev_name** | $r_vendor | \`$r_mac\` | $r_os | \`$r_ports\` | $status |"
  done < "$HOSTS_DATA_FILE"

  echo
  echo "---"
  echo
  echo "## ⚠️ Security Risks & Vulnerability Findings"
  echo

  has_findings=0
  while IFS=$'\t' read -r r_ip r_dev_name r_vendor r_mac r_os r_ports r_risks; do
    [[ "$r_ip" == "IP" ]] && continue
    
    vuln_log="$VULN_RESULTS_DIR/${r_ip}_vuln.txt"
    has_nmap_vuln=0
    if [[ -f "$vuln_log" ]] && grep -qE 'VULNERABLE|CVE-[0-9]{4}-[0-9]+' "$vuln_log"; then
      has_nmap_vuln=1
    fi

    if [[ "$r_risks" != "None" || $has_nmap_vuln -eq 1 ]]; then
      has_findings=1
      echo "### Device: \`$r_ip\` ($r_dev_name)"
      echo "- **Device Name:** **$r_dev_name**"
      echo "- **Manufacturer / Vendor:** $r_vendor"
      echo "- **MAC Address:** \`$r_mac\`"
      echo "- **Detected Operating System:** $r_os"
      echo "- **Open Ports:** \`$r_ports\`"
      echo
      echo "**Identified Risks:**"
      IFS=';' read -ra ADDR <<< "$r_risks"
      for i in "${ADDR[@]}"; do
        trimmed=$(echo "$i" | sed 's/^[ \t]*//')
        if [[ -n "$trimmed" && "$trimmed" != "None" ]]; then
          echo "- ⚠️ $trimmed"
        fi
      done

      if [[ $has_nmap_vuln -eq 1 ]]; then
        echo
        echo "**NSE Vulnerability Scanner Output:**"
        echo '```text'
        grep -B1 -A3 -E 'VULNERABLE|CVE-[0-9]{4}-[0-9]+' "$vuln_log" | head -n 25
        echo '```'
      fi
      echo
    fi
  done < "$HOSTS_DATA_FILE"

  if [[ $has_findings -eq 0 ]]; then
    echo "🎉 **No critical vulnerabilities or exposed risky management services were discovered.**"
    echo
  fi

  echo "---"
  echo
  echo "## 🛡️ Defensive Hardening & Remediation Recommendations"
  echo
  echo "1. **Isolate IoT Devices on a Guest/IoT VLAN:**"
  echo "   - Smart TVs, smart plugs, and IoT peripherals should not share the same network subnet as personal workstations or storage servers."
  echo
  echo "2. **Disable Unencrypted Management Protocols:**"
  echo "   - Replace any remaining Telnet (23) or plain HTTP web management consoles with SSH and HTTPS."
  echo
  echo "3. **Restrict File Sharing & Database Exposure:**"
  echo "   - Ensure SMB (445), MySQL (3306), and Redis (6379) are bound only to \`127.0.0.1\` or properly authenticated with strong passwords and firewall rules."
  echo
  echo "4. **Keep Firmware and Operating Systems Updated:**"
  echo "   - Check your router's administration portal for latest vendor security patches."
  echo "   - Disable UPnP (Universal Plug and Play) and WPS on your primary gateway router."
  echo
  echo "---"
  echo "*Generated automatically by ShadowHarvy Network Audit Tool on $SCAN_DATE*"
} > "$OUTPUT_FILE"

echo -e "${GREEN}${BOLD}✔ Network audit complete!${NC}"
echo -e "  Markdown report saved to: ${BLUE}${BOLD}$OUTPUT_FILE${NC}"
echo
