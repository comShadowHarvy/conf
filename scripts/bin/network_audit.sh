#!/usr/bin/env bash
# network_audit.sh - Automated Local Network Security Audit & Vulnerability Scanner
#
# Author: ShadowHarvy
# Version: 2.1.0
#
# DESCRIPTION:
#   Automatically detects local network subnets, discovers connected devices via
#   multi-protocol sweeping (ARP, ICMP, SSDP UPnP, mDNS), identifies hardware vendors
#   & operating systems, classifies devices (Routers, PCs, IoT, Mobile, Servers),
#   probes for unauthenticated & dangerous services (Docker API, Redis, Telnet, RTSP),
#   tracks changes/rogue devices across audits, and produces Markdown, JSON, and
#   interactive dark-mode HTML summary reports.
#
#   PROGRESSIVE DISCLOSURE:
#   Lists devices and all known details at each progressive phase, then synthesizes
#   everything together in the final assembly report and dashboard.
#
# USAGE:
#   sudo ./network_audit.sh [OPTIONS]
#
# OPTIONS:
#   -r, --range CIDR       Target network range (default: auto-detected LAN, e.g. 192.168.1.0/24)
#   -i, --interface IFACE  Network interface (default: auto-detected default route interface)
#   -o, --output FILE      Custom path for Markdown report (default: ./reports/network_audit_<date>.md)
#       --html FILE        Custom path for Interactive HTML report (default: ./reports/network_audit_<date>.html)
#       --json FILE        Custom path for structured JSON export (default: ./reports/network_audit_<date>.json)
#   -q, --quick            Quick scan (top 100 ports, fast discovery, skip deep vuln scripts)
#   -f, --full             Full audit (all 65,535 ports + deep CVE vulnerability checks)
#       --skip-vuln        Device discovery & OS detection only (skip vulnerability scripts)
#       --diff             Force display of diff comparison against previous audit
#   -t, --threads N        Parallel threads for discovery and resolution (default: 16)
#       --exclude IPS      Comma-separated IPs to exclude from audit (e.g. 192.168.1.5,192.168.1.10)
#       --force            Allow scanning subnets wider than /24 (e.g. /16 or /8)
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
OUTPUT_MD=""
OUTPUT_HTML=""
OUTPUT_JSON=""
SCAN_MODE="standard" # quick, standard, full
SKIP_VULN=0
SHOW_DIFF=1
THREADS=16
EXCLUDE_IPS=""
FORCE_SCAN=0
TEMP_DIR=""
START_TIME=0
REPORT_DIR="$(pwd)/reports"
LOCAL_IP=""
GATEWAY_IP=""
PREFIX_LEN=""
TOTAL_HOSTS=0

# --- Title Banner ---
show_banner() {
  clear 2>/dev/null || true
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
  echo "║                                                                               ║"
  echo -e "║  ${BOLD}${MAGENTA}   ███╗   ██╗███████╗████████╗     █████╗ ██╗   ██╗██████╗ ██╗████████╗${CYAN}        ║"
  echo -e "║  ${BOLD}${MAGENTA}   ████╗  ██║██╔════╝╚══██╔══╝    ██╔══██╗██║   ██║██╔══██╗██║╚══██╔══╝${CYAN}        ║"
  echo -e "║  ${BOLD}${MAGENTA}   ██╔██╗ ██║█████╗     ██║       ███████║██║   ██║██║  ██║██║   ██║   ${CYAN}        ║"
  echo -e "║  ${BOLD}${MAGENTA}   ██║╚██╗██║██╔══╝     ██║       ██╔══██║██║   ██║██║  ██║██║   ██║   ${CYAN}        ║"
  echo -e "║  ${BOLD}${MAGENTA}   ██║ ╚████║███████╗   ██║       ██║  ██║╚██████╔╝██████╔╝██║   ██║   ${CYAN}        ║"
  echo -e "║  ${BOLD}${MAGENTA}   ╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ${CYAN}        ║"
  echo "║                                                                               ║"
  echo -e "║              ${YELLOW}${BOLD}Automated Local Network Security Audit & Device Scanner${CYAN}          ║"
  echo "║                                                                               ║"
  echo -e "║    ${GREEN}Multi-Protocol Discovery • Progressive Disclosure • Device Classification${CYAN}   ║"
  echo -e "║     ${GREEN}Active Risk Probes • Rogue Device Diffing • Interactive HTML Dashboard${CYAN}    ║"
  echo "║                                                                               ║"
  echo -e "║  ${WHITE}Author:${NC} ${BLUE}${BOLD}ShadowHarvy${CYAN}                                                         ║"
  echo -e "║  ${WHITE}Version:${NC} ${GREEN}2.1.0 (Progressive Disclosure Edition)${CYAN}                               ║"
  echo "║                                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo
}

# --- Usage Function ---
usage() {
  echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
  echo
  echo -e "${BOLD}Description:${NC}"
  echo "  Comprehensive network security auditing tool designed to auto-discover local subnet"
  echo "  devices, identify vendors, OS and device types, probe for unauthenticated and risky"
  echo "  services, track network changes against previous scans, and generate rich reports."
  echo
  echo -e "${BOLD}Options:${NC}"
  echo "  -r, --range CIDR       Target network range (default: auto-detected, e.g. 192.168.1.0/24)"
  echo "  -i, --interface IFACE  Network interface to scan through (default: auto-detected)"
  echo "  -o, --output FILE      Custom path for Markdown report (default: ./reports/network_audit_<date>.md)"
  echo "      --html FILE        Custom path for Interactive HTML report (default: ./reports/network_audit_<date>.html)"
  echo "      --json FILE        Custom path for structured JSON export (default: ./reports/network_audit_<date>.json)"
  echo "  -q, --quick            Quick scan (top 100 ports, fast discovery, skips deep scripts)"
  echo "  -f, --full             Thorough scan (all 65,535 ports + deep CVE vulnerability checks)"
  echo "      --skip-vuln        Device discovery & OS detection only, skip vulnerability scripts"
  echo "      --diff             Compare results against previous audit to detect rogue devices"
  echo "  -t, --threads N        Parallel threads for discovery and resolution (default: 16)"
  echo "      --exclude IPS      Comma-separated IPs to exclude (e.g. 192.168.1.1,192.168.1.5)"
  echo "      --force            Allow scanning subnets wider than /24 (e.g. /16 or /8)"
  echo "  -h, --help             Show this help message"
  echo
  echo -e "${BOLD}Examples:${NC}"
  echo "  sudo $0                      # Auto-detect local range and perform progressive audit"
  echo "  sudo $0 -q                   # Fast scan mode (top 100 ports)"
  echo "  sudo $0 --html my_report.html # Generate standalone interactive dashboard"
  echo "  sudo $0 -r 192.168.1.0/24    # Audit specific subnet"
  echo "  sudo $0 --exclude 192.168.1.1 # Audit subnet excluding router"
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
      OUTPUT_MD="${2:-}"
      shift 2
      ;;
    --html)
      OUTPUT_HTML="${2:-}"
      shift 2
      ;;
    --json)
      OUTPUT_JSON="${2:-}"
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
    --diff)
      SHOW_DIFF=1
      shift
      ;;
    -t|--threads)
      THREADS="${2:-16}"
      shift 2
      ;;
    --exclude)
      EXCLUDE_IPS="${2:-}"
      shift 2
      ;;
    --force)
      FORCE_SCAN=1
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
  echo -e "${YELLOW}[!] Notice: Running without root privileges.${NC}"
  echo -e "${YELLOW}    OS TCP fingerprinting (-O) and raw SYN packets require root privileges.${NC}"
  echo -e "${YELLOW}    For optimal results and full MAC address detection, consider: ${BOLD}sudo $0${NC}"
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
    echo -e "    ${WHITE}nmap is recommended for deep OS fingerprinting and CVE vulnerability checks.${NC}"
    
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
  TARGET_IFACE=$(ip -o -4 addr show scope global 2>/dev/null | grep -v ' lo ' | awk '{print $2}' | head -n1 || echo "")
fi

if [[ -z "$TARGET_IFACE" ]]; then
  echo -e "${RED}[error] Unable to detect an active network interface. Please specify one with -i <iface>.${NC}" >&2
  exit 1
fi

# Resolve Local IP and CIDR
LOCAL_IP_CIDR=$(ip -o -4 addr show dev "$TARGET_IFACE" scope global 2>/dev/null | awk '{print $4}' | head -n1 || echo "")
if [[ -z "$LOCAL_IP_CIDR" ]]; then
  # Fallback to any IPv4 on interface
  LOCAL_IP_CIDR=$(ip -o -4 addr show dev "$TARGET_IFACE" 2>/dev/null | awk '{print $4}' | head -n1 || echo "")
fi

if [[ -z "$LOCAL_IP_CIDR" ]]; then
  echo -e "${RED}[error] Interface $TARGET_IFACE has no active IPv4 address.${NC}" >&2
  exit 1
fi

LOCAL_IP="${LOCAL_IP_CIDR%/*}"
PREFIX_LEN="${LOCAL_IP_CIDR#*/}"
GATEWAY_IP="${GATEWAY_IP:-$(ip -4 route show default dev "$TARGET_IFACE" 2>/dev/null | awk '{print $3}' | head -n1 || echo "Unknown")}"

# Calculate Network Range in CIDR notation
if [[ -z "$TARGET_RANGE" ]]; then
  if [[ "$PREFIX_LEN" -lt 24 && "$FORCE_SCAN" -eq 0 ]]; then
    TARGET_RANGE=$(python3 -c "
import ipaddress
ip = ipaddress.IPv4Interface('$LOCAL_IP_CIDR')
safe_net = ipaddress.IPv4Network(f'{ip.ip}/24', strict=False)
print(str(safe_net))
" 2>/dev/null || echo "$LOCAL_IP_CIDR")
    echo -e "  ${YELLOW}⚠ Wide subnet detected: /$PREFIX_LEN (over 1,000 potential hosts).${NC}"
    echo -e "  ${YELLOW}  Safely defaulting target range to local /24 (${CYAN}${TARGET_RANGE}${YELLOW}).${NC}"
    echo -e "  ${YELLOW}  (Use ${BOLD}--force${YELLOW} or ${BOLD}-r <cidr>${YELLOW} to scan the entire wide range).${NC}"
  else
    TARGET_RANGE=$(python3 -c "
import ipaddress
try:
    net = ipaddress.IPv4Network('$LOCAL_IP_CIDR', strict=False)
    print(str(net))
except Exception:
    print('$LOCAL_IP_CIDR')
" 2>/dev/null || echo "$LOCAL_IP_CIDR")
  fi
fi

echo -e "  ${GREEN}✓${NC} Interface        : ${BOLD}$TARGET_IFACE${NC}"
echo -e "  ${GREEN}✓${NC} Local Host IP    : ${BOLD}$LOCAL_IP${NC} (Prefix /$PREFIX_LEN)"
echo -e "  ${GREEN}✓${NC} Default Gateway  : ${BOLD}$GATEWAY_IP${NC}"
echo -e "  ${GREEN}✓${NC} Detected Subnet  : ${BOLD}${CYAN}$TARGET_RANGE${NC}"
echo -e "  ${GREEN}✓${NC} Audit Scan Mode  : ${BOLD}${MAGENTA}${SCAN_MODE^^}${NC} (${THREADS} threads)"
if [[ -n "$EXCLUDE_IPS" ]]; then
  echo -e "  ${YELLOW}•${NC} Excluded Hosts   : ${BOLD}$EXCLUDE_IPS${NC}"
fi
echo

# -------------------------------------------------------------
# Generate Python Engine in Temp Directory
# -------------------------------------------------------------
cat << 'PY_EOF' > "$TEMP_DIR/audit_engine.py"
import os, sys, json, socket, struct, ipaddress, subprocess, time, re
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed

TOP_VENDORS = {
    "00000C": "Cisco", "000142": "Cisco", "001422": "Dell", "001E4F": "Dell", "0024E8": "Dell", "B8AC6F": "Dell",
    "000C29": "VMware", "005056": "VMware", "080027": "Oracle VirtualBox", "525400": "QEMU / KVM",
    "001A11": "Google", "3C5AB4": "Google", "F4F5DB": "Google", "D83ADD": "Google", "546009": "Google",
    "001788": "Philips Lighting", "ECB5FA": "Philips Lighting", "0017C5": "Philips Lighting",
    "001E8C": "ASUSTeK", "04D9F5": "ASUSTeK", "107B44": "ASUSTeK", "2C4D54": "ASUSTeK", "40167E": "ASUSTeK", "AC9E17": "ASUSTeK",
    "0014D1": "TP-Link", "50C7BF": "TP-Link", "984827": "TP-Link", "B09575": "TP-Link", "C006C3": "TP-Link", "E848B8": "TP-Link",
    "001132": "Synology", "00089B": "QNAP", "245EBE": "Synology",
    "B827EB": "Raspberry Pi", "DCA632": "Raspberry Pi", "E45F01": "Raspberry Pi", "28CDC1": "Raspberry Pi",
    "18FE34": "Espressif", "240AC4": "Espressif", "30AEA4": "Espressif", "84F3EB": "Espressif", "A4CF12": "Espressif", "C44F33": "Espressif", "485519": "Espressif",
    "102C6B": "Tuya Smart", "708976": "Tuya Smart", "D81F12": "Tuya Smart", "68C63A": "Tuya Smart",
    "000420": "Slim Devices", "000E58": "Sonos", "48A6B8": "Sonos", "5C8959": "Sonos", "949F3E": "Sonos",
    "002500": "Apple", "003EE1": "Apple", "00F4B9": "Apple", "34363B": "Apple", "38F9D3": "Apple", "705681": "Apple", "A483E7": "Apple", "F01898": "Apple", "BC926B": "Apple", "F437B7": "Apple",
    "0012FB": "Samsung", "002637": "Samsung", "508569": "Samsung", "842519": "Samsung", "A87C01": "Samsung", "BC4486": "Samsung",
    "00155D": "Microsoft", "70F35A": "Microsoft", "985FD3": "Microsoft", "DC5360": "Microsoft",
    "00215A": "HP", "3C4A92": "HP", "A0D3C1": "HP", "C8D3FF": "HP",
    "000E08": "Ubiquiti", "0418D6": "Ubiquiti", "24A43C": "Ubiquiti", "68D79A": "Ubiquiti", "7483C2": "Ubiquiti", "B4FBE4": "Ubiquiti", "F09FC2": "Ubiquiti",
    "000FB5": "Netgear", "20E52A": "Netgear", "288088": "Netgear", "841B5E": "Netgear", "A00460": "Netgear",
    "00234D": "Amazon", "34D270": "Amazon", "40B4CD": "Amazon", "6854FD": "Amazon", "747548": "Amazon", "AC63BE": "Amazon", "FC65DE": "Amazon",
    "00180A": "Sony", "001A80": "Sony", "709E29": "Sony", "F8461C": "Sony",
    "002261": "Roku", "2082C0": "Roku", "AC3A7A": "Roku", "D83134": "Roku",
    "001788": "Signify / Hue", "0005CD": "Denon", "001B67": "Intel", "0024D7": "Intel", "F8633F": "Intel"
}

def lookup_vendor(mac, ip, local_ip):
    if not mac or mac in ["-", "Unknown", "Local Device"]:
        if ip == local_ip:
            try:
                with open("/sys/class/dmi/id/sys_vendor", "r") as f:
                    v = f.read().strip()
                    if v and v not in ["System manufacturer", "To be filled by O.E.M."]:
                        return v
            except:
                pass
        return "Unknown Manufacturer"

    clean_mac = mac.replace(":", "").replace("-", "").upper()[:6]
    
    if ip == local_ip:
        try:
            with open("/sys/class/dmi/id/sys_vendor", "r") as f:
                v = f.read().strip()
                if v and v not in ["System manufacturer", "To be filled by O.E.M."]:
                    return v
        except:
            pass

    if clean_mac in TOP_VENDORS:
        return TOP_VENDORS[clean_mac]

    for oui_path in ["/usr/share/hwdata/oui.txt", "/var/lib/ieee-data/oui.txt"]:
        if os.path.isfile(oui_path):
            try:
                with open(oui_path, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        if line.startswith(clean_mac):
                            parts = line.strip().split("\t")
                            return parts[-1].strip()
            except:
                pass

    nmap_mac_file = "/usr/share/nmap/nmap-mac-prefixes"
    if os.path.isfile(nmap_mac_file):
        try:
            with open(nmap_mac_file, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith(clean_mac):
                        return line.strip()[7:].strip()
        except:
            pass

    try:
        first_byte = int(clean_mac[:2], 16)
        if (first_byte & 0x02) != 0:
            return "Private / Randomized MAC"
    except:
        pass

    return "Unknown Manufacturer"

def probe_ssdp():
    found = set()
    msg = 'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 1\r\nST: ssdp:all\r\n\r\n'
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    s.settimeout(1.2)
    s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
    try:
        s.sendto(msg.encode(), ('239.255.255.250', 1900))
        t_end = time.time() + 1.2
        while time.time() < t_end:
            try:
                _, addr = s.recvfrom(2048)
                found.add(addr[0])
            except socket.timeout:
                break
            except:
                break
    except:
        pass
    finally:
        s.close()
    return found

def probe_mdns():
    found = set()
    query = b'\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\t_services\x07_dns-sd\x04_udp\x05local\x00\x00\x0c\x00\x01'
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    s.settimeout(1.2)
    s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 255)
    try:
        s.sendto(query, ('224.0.0.251', 5353))
        t_end = time.time() + 1.2
        while time.time() < t_end:
            try:
                _, addr = s.recvfrom(2048)
                found.add(addr[0])
            except socket.timeout:
                break
            except:
                break
    except:
        pass
    finally:
        s.close()
    return found

def resolve_name(ip, local_ip):
    if ip == local_ip:
        try:
            return socket.gethostname()
        except:
            return "Local Host"

    # mDNS
    try:
        res = subprocess.run(["avahi-resolve", "-a", ip], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=0.35, text=True)
        if res.returncode == 0 and res.stdout:
            parts = res.stdout.strip().split()
            if len(parts) >= 2 and not "Failed" in parts[1]:
                return parts[1].replace(".local", "")
    except:
        pass

    # NetBIOS
    try:
        res = subprocess.run(["nmblookup", "-A", ip], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=0.35, text=True)
        if res.returncode == 0 and res.stdout:
            for line in res.stdout.splitlines():
                if "<00>" in line and not "<GROUP>" in line:
                    nb = line.strip().split()[0]
                    if nb and "Looking" not in nb:
                        return nb
    except:
        pass

    # Reverse DNS PTR
    try:
        host, _, _ = socket.gethostbyaddr(ip)
        if host and "not found" not in host:
            return host.split(".")[0]
    except:
        pass

    # Fast HTTP Title
    for port in [80, 8080]:
        try:
            s = socket.socket()
            s.settimeout(0.3)
            s.connect((ip, port))
            s.sendall(f"GET / HTTP/1.0\r\nHost: {ip}\r\nUser-Agent: NetAudit/2.1\r\n\r\n".encode())
            data = s.recv(2048).decode(errors="ignore")
            s.close()
            m = re.search(r"<title[^>]*>(.*?)</title>", data, re.IGNORECASE | re.DOTALL)
            if m:
                t = m.group(1).strip()
                if t and len(t) < 30 and "404" not in t and "302" not in t:
                    return t
        except:
            pass

    return "-"

def classify_device(ip, name, vendor, mac, os_str, ports, is_gateway):
    if is_gateway:
        return "Gateway / Router", "🌐"
    
    all_text = f"{name} {vendor} {os_str}".lower()
    port_ids = [p["port"] if isinstance(p, dict) else p for p in ports]
    
    if any(p in port_ids for p in ["9100/tcp", "631/tcp", "515/tcp"]) or any(k in all_text for k in ["printer", "canon", "epson", "brother", "xerox", "laserjet"]):
        return "Printer / Office", "🖨️"
    
    if any(p in port_ids for p in ["8006/tcp", "2375/tcp", "2376/tcp", "9000/tcp", "9443/tcp"]) or any(k in all_text for k in ["synology", "qnap", "truenas", "proxmox", "esxi", "unraid"]):
        return "Server / NAS", "🗄️"
        
    if any(p in port_ids for p in ["554/tcp"]) or any(k in all_text for k in ["camera", "dahua", "hikvision", "amcrest", "reolink", "ring", "wyze"]):
        return "Security Camera", "📷"
        
    if any(k in all_text for k in ["playstation", "xbox", "nintendo", "switch", "steamdeck"]):
        return "Gaming Console", "🎮"
        
    if any(k in all_text for k in ["appletv", "apple tv", "roku", "chromecast", "firetv", "bravia", "webos", "tizen", "smarttv", "smart tv", "shield", "kodi"]):
        return "Smart TV / Media", "📺"
        
    if any(k in all_text for k in ["espressif", "tuya", "tasmota", "shelly", "sonoff", "hue", "philips lighting", "smart plug", "wemo", "zigbee", "matter"]):
        return "Smart Home / IoT", "💡"
        
    if any(k in all_text for k in ["iphone", "ipad", "android", "pixel", "galaxy", "oneplus", "xiaomi"]):
        return "Mobile / Tablet", "📱"
        
    if any(k in all_text for k in ["windows", "linux", "cachyos", "ubuntu", "fedora", "arch", "macos", "macbook", "desktop", "laptop", "pc"]):
        return "Workstation / PC", "💻"
        
    if any(p in port_ids for p in ["22/tcp", "3389/tcp", "5900/tcp", "445/tcp"]):
        return "Workstation / PC", "💻"
        
    return "Network Device", "🔌"

def probe_redis_unauth(ip, port=6379):
    try:
        s = socket.socket()
        s.settimeout(0.5)
        s.connect((ip, port))
        s.sendall(b"PING\r\n")
        resp = s.recv(1024)
        s.close()
        if b"+PONG" in resp:
            return True
    except:
        pass
    return False

def probe_docker_unauth(ip, port=2375):
    try:
        s = socket.socket()
        s.settimeout(0.5)
        s.connect((ip, port))
        s.sendall(b"GET /version HTTP/1.1\r\nHost: target\r\n\r\n")
        resp = s.recv(2048)
        s.close()
        if b"ApiVersion" in resp or b"docker" in resp.lower():
            return True
    except:
        pass
    return False

def probe_ftp_anon(ip, port=21):
    try:
        s = socket.socket()
        s.settimeout(0.6)
        s.connect((ip, port))
        _ = s.recv(1024)
        s.sendall(b"USER anonymous\r\n")
        _ = s.recv(1024)
        s.sendall(b"PASS anonymous@net-audit\r\n")
        resp = s.recv(1024)
        s.close()
        if b"230" in resp:
            return True
    except:
        pass
    return False

def evaluate_risks(ip, ports, is_gateway):
    risks = []
    port_ids = [p["port"] if isinstance(p, dict) else p for p in ports]
    
    if "23/tcp" in port_ids or "2323/tcp" in port_ids:
        risks.append({
            "severity": "CRITICAL",
            "title": "Telnet (port 23/2323) in use - unencrypted plaintext protocol",
            "remediation": "Disable Telnet daemon (systemctl disable --now telnet.socket) and migrate to SSH (port 22). For IoT devices, disable Telnet via device web console."
        })

    if "2375/tcp" in port_ids or "2376/tcp" in port_ids:
        p = 2375 if "2375/tcp" in port_ids else 2376
        if probe_docker_unauth(ip, p):
            risks.append({
                "severity": "CRITICAL",
                "title": f"Exposed unauthenticated Docker API on port {p} - Instant Root RCE risk!",
                "remediation": "Bind Docker daemon to 127.0.0.1 or unix socket /var/run/docker.sock. If remote access is required, enable TLS mutual authentication (dockerd --tlsverify)."
            })

    if "6379/tcp" in port_ids:
        if probe_redis_unauth(ip, 6379):
            risks.append({
                "severity": "CRITICAL",
                "title": "Redis server on port 6379 accepts unauthenticated commands (PING -> +PONG)!",
                "remediation": "Require password authentication in /etc/redis/redis.conf (requirepass <strong-pass>) and bind Redis strictly to localhost (bind 127.0.0.1 -::1)."
            })
        else:
            risks.append({
                "severity": "HIGH",
                "title": "Redis Server (port 6379) exposed to local subnet",
                "remediation": "Verify Redis is protected with requirepass and bind only to authorized management interfaces."
            })

    if "11211/tcp" in port_ids:
        risks.append({
            "severity": "CRITICAL",
            "title": "Memcached service (port 11211) exposed - data leak and DDoS amplification risk",
            "remediation": "Bind Memcached exclusively to 127.0.0.1 (-l 127.0.0.1) in /etc/memcached.conf and disable UDP listener (-U 0)."
        })

    if "554/tcp" in port_ids:
        risks.append({
            "severity": "HIGH",
            "title": "RTSP video stream (port 554) accessible on LAN - Camera video feed risk",
            "remediation": "Segregate cameras onto an isolated IoT/CCTV VLAN. Enforce authentication and disable unencrypted ONVIF/RTSP streaming."
        })

    if "21/tcp" in port_ids:
        if probe_ftp_anon(ip, 21):
            risks.append({
                "severity": "HIGH",
                "title": "FTP service on port 21 permits Anonymous login without credentials!",
                "remediation": "Disable anonymous FTP access in vsftpd.conf (anonymous_enable=NO) and migrate to SFTP (SSH port 22)."
            })
        else:
            risks.append({
                "severity": "MEDIUM",
                "title": "FTP service (port 21) active - transmits credentials in cleartext",
                "remediation": "Migrate to SFTP (SSH port 22) or FTPS (FTP over TLS) to prevent credential sniffing on local Wi-Fi."
            })

    if "27017/tcp" in port_ids:
        risks.append({
            "severity": "HIGH",
            "title": "MongoDB database (port 27017) exposed on LAN",
            "remediation": "Enable authorization (security.authorization: enabled) in mongod.conf and bind strictly to 127.0.0.1."
        })
    if "9200/tcp" in port_ids:
        risks.append({
            "severity": "HIGH",
            "title": "Elasticsearch cluster API (port 9200) exposed to subnet",
            "remediation": "Enable Elastic Security (xpack.security.enabled: true) with TLS and set strong native user passwords."
        })
    if "3306/tcp" in port_ids:
        risks.append({
            "severity": "HIGH",
            "title": "MySQL / MariaDB database (port 3306) exposed on LAN",
            "remediation": "Bind MySQL to 127.0.0.1 in my.cnf (bind-address = 127.0.0.1) or restrict access with host firewall."
        })
    if "5432/tcp" in port_ids:
        risks.append({
            "severity": "HIGH",
            "title": "PostgreSQL database (port 5432) exposed on LAN",
            "remediation": "Restrict postgresql.conf (listen_addresses = 'localhost') and configure pg_hba.conf with scram-sha-256."
        })

    if "5900/tcp" in port_ids:
        risks.append({
            "severity": "MEDIUM",
            "title": "VNC Remote Desktop (port 5900) exposed",
            "remediation": "Tunnel VNC sessions over SSH (ssh -L 5901:localhost:5900) and enforce strong VNC authentication."
        })
    if "445/tcp" in port_ids or "139/tcp" in port_ids:
        risks.append({
            "severity": "MEDIUM",
            "title": "SMB File Sharing (port 445/139) active on LAN",
            "remediation": "Ensure SMBv1 is disabled, enforce SMB signing/encryption, and require authentication for all shares."
        })
    if "3389/tcp" in port_ids:
        risks.append({
            "severity": "MEDIUM",
            "title": "RDP Remote Desktop (port 3389) accessible",
            "remediation": "Enable Network Level Authentication (NLA) for RDP and restrict access via VPN or firewall."
        })

    if "1883/tcp" in port_ids:
        risks.append({
            "severity": "MEDIUM",
            "title": "MQTT IoT message broker (port 1883) exposed unencrypted",
            "remediation": "Require password authentication in Mosquitto configuration and transition clients to MQTTS (port 8883 with TLS)."
        })
    if "8006/tcp" in port_ids or "9443/tcp" in port_ids or "9090/tcp" in port_ids:
        risks.append({
            "severity": "LOW",
            "title": "Administrative management console exposed on LAN",
            "remediation": "Ensure administrative interfaces have multi-factor authentication and use valid HTTPS certificates."
        })

    if "80/tcp" in port_ids and "443/tcp" not in port_ids:
        risks.append({
            "severity": "LOW",
            "title": "Unencrypted HTTP management (port 80) without HTTPS",
            "remediation": "Install an SSL/TLS certificate and configure HTTP to automatically redirect to HTTPS."
        })

    if is_gateway and ("1900/udp" in port_ids or "5000/tcp" in port_ids):
        risks.append({
            "severity": "MEDIUM",
            "title": "Gateway UPnP service active (WAN hole-punching risk)",
            "remediation": "Log into your router administration portal and disable UPnP (Universal Plug and Play) to prevent automatic WAN port forwarding."
        })

    return risks

def parse_nmap_xml(xml_file, hosts_list, local_ip, gateway_ip):
    results = {}
    if not os.path.isfile(xml_file):
        return results

    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        for host in root.findall("host"):
            ip = None
            mac = "-"
            nmap_vendor = "Unknown"
            
            for addr in host.findall("address"):
                if addr.get("addrtype") == "ipv4":
                    ip = addr.get("addr")
                elif addr.get("addrtype") == "mac":
                    mac = addr.get("addr", "-")
                    nmap_vendor = addr.get("vendor", "Unknown")

            if not ip or ip not in hosts_list:
                continue

            name = "-"
            hn = host.find(".//hostname")
            if hn is not None and hn.get("name"):
                name = hn.get("name").replace(".local", "")

            os_match = "Unknown"
            osm = host.find(".//osmatch")
            if osm is not None and osm.get("name"):
                os_match = osm.get("name")

            ports = []
            for p in host.findall(".//port"):
                state = p.find("state")
                if state is not None and state.get("state") == "open":
                    portid = p.get("portid")
                    proto = p.get("protocol")
                    svc_elem = p.find("service")
                    svc_name = svc_elem.get("name", "unknown") if svc_elem is not None else "unknown"
                    product = svc_elem.get("product", "") if svc_elem is not None else ""
                    version = svc_elem.get("version", "") if svc_elem is not None else ""
                    ports.append({
                        "port": f"{portid}/{proto}",
                        "service": svc_name,
                        "product": product,
                        "version": version
                    })

            results[ip] = {
                "ip": ip,
                "mac": mac,
                "nmap_vendor": nmap_vendor,
                "nmap_name": name,
                "os": os_match,
                "ports": ports
            }
    except Exception:
        pass

    return results

def fallback_port_scan(ip, scan_mode):
    if scan_mode == "quick":
        probe_ports = [21, 22, 23, 53, 80, 139, 443, 445, 3389, 8080]
    elif scan_mode == "full":
        probe_ports = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 554, 993, 995, 1433, 1723, 1883, 2375, 2376, 3306, 3389, 5000, 5353, 5357, 5432, 5900, 6379, 8000, 8006, 8080, 8443, 8888, 9000, 9200, 9443, 11211, 27017]
    else:
        probe_ports = [21, 22, 23, 53, 80, 135, 139, 443, 445, 554, 1883, 2375, 3306, 3389, 5000, 5357, 5432, 5900, 6379, 8000, 8006, 8080, 8443, 8888, 9000, 9200, 11211, 27017]

    open_ports = []
    for port in probe_ports:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(0.25)
        try:
            if s.connect_ex((ip, port)) == 0:
                open_ports.append({
                    "port": f"{port}/tcp",
                    "service": "active",
                    "product": "",
                    "version": ""
                })
        except:
            pass
        finally:
            s.close()
    return open_ports

def compute_diff(current_hosts, history_file):
    diff = {
        "has_diff": False,
        "prev_date": "",
        "new_hosts": [],
        "removed_hosts": [],
        "opened_ports": [],
        "closed_ports": []
    }
    
    if not os.path.isfile(history_file):
        return diff

    try:
        with open(history_file, "r") as f:
            prev = json.load(f)
            
        diff["prev_date"] = prev.get("scan_date", "Previous Audit")
        prev_hosts = {h["ip"]: h for h in prev.get("hosts", [])}
        curr_hosts = {h["ip"]: h for h in current_hosts}

        for ip, ch in curr_hosts.items():
            if ip not in prev_hosts:
                diff["new_hosts"].append({
                    "ip": ip,
                    "name": ch["name"],
                    "vendor": ch["vendor"],
                    "category": ch["category"]
                })
                ch["is_new"] = True

        for ip, ph in prev_hosts.items():
            if ip not in curr_hosts:
                diff["removed_hosts"].append({
                    "ip": ip,
                    "name": ph["name"],
                    "vendor": ph.get("vendor", "Unknown")
                })

        for ip in curr_hosts:
            if ip in prev_hosts:
                curr_p = set(p["port"] if isinstance(p, dict) else p for p in curr_hosts[ip]["ports"])
                prev_p = set(p["port"] if isinstance(p, dict) else p for p in prev_hosts[ip]["ports"])
                
                opened = curr_p - prev_p
                closed = prev_p - curr_p
                
                for op in opened:
                    diff["opened_ports"].append({"ip": ip, "name": curr_hosts[ip]["name"], "port": op})
                for cp in closed:
                    diff["closed_ports"].append({"ip": ip, "name": curr_hosts[ip]["name"], "port": cp})

        if diff["new_hosts"] or diff["removed_hosts"] or diff["opened_ports"] or diff["closed_ports"]:
            diff["has_diff"] = True

    except Exception:
        pass

    return diff

def generate_html_report(data, output_path):
    diff_html = ""
    if data["diff"]["has_diff"]:
        new_items = "".join([f"<li><span class='badge-pill badge-danger'>NEW DEVICE</span> <strong>{h['ip']}</strong> ({h['name']} - {h['vendor']} - {h['category']})</li>" for h in data["diff"]["new_hosts"]])
        port_items = "".join([f"<li><span class='badge-pill badge-warning'>NEW PORT</span> <strong>{p['ip']}</strong> ({p['name']}): Port <code>{p['port']}</code> opened</li>" for p in data["diff"]["opened_ports"]])
        rem_items = "".join([f"<li><span class='badge-pill badge-neutral'>OFFLINE</span> <strong>{h['ip']}</strong> ({h['name']} - {h['vendor']})</li>" for h in data["diff"]["removed_hosts"]])
        
        diff_html = f"""
        <div class="diff-card">
            <div class="diff-header">
                <h3>🚨 Network Changes Detected Since Previous Audit ({data["diff"]["prev_date"]})</h3>
            </div>
            <ul class="diff-list">
                {new_items}
                {port_items}
                {rem_items}
            </ul>
        </div>
        """

    cards_html = []
    for h in data["hosts"]:
        risk_class = "status-clean"
        risk_label = "CLEAN"
        if any(r["severity"] == "CRITICAL" for r in h["risks"]):
            risk_class = "status-critical"
            risk_label = "CRITICAL RISK"
        elif any(r["severity"] == "HIGH" for r in h["risks"]):
            risk_class = "status-high"
            risk_label = "HIGH RISK"
        elif any(r["severity"] == "MEDIUM" for r in h["risks"]):
            risk_class = "status-warning"
            risk_label = "WARNING"
        elif any(r["severity"] == "LOW" for r in h["risks"]):
            risk_class = "status-info"
            risk_label = "INFO / LOW"

        new_badge = "<span class='badge-pill badge-danger'>NEW</span>" if h.get("is_new") else ""
        ports_badges = "".join([f"<span class='port-pill'>{p['port']} {p['service']}</span>" for p in h["ports"]]) if h["ports"] else "<span class='text-muted'>None</span>"
        
        risks_detail = ""
        if h["risks"]:
            r_items = []
            for r in h["risks"]:
                sev = r["severity"]
                cls = "sev-crit" if sev == "CRITICAL" else ("sev-high" if sev == "HIGH" else ("sev-med" if sev == "MEDIUM" else "sev-low"))
                r_items.append(f"""
                <div class="risk-item">
                    <span class="badge-pill {cls}">{sev}</span>
                    <div class="risk-content">
                        <div class="risk-title">{r["title"]}</div>
                        <div class="risk-remediation"><strong>Remediation:</strong> {r["remediation"]}</div>
                    </div>
                </div>
                """)
            risks_detail = f"<div class='risk-container'>{''.join(r_items)}</div>"

        cve_detail = ""
        if h.get("cves"):
            cve_detail = f"""
            <div class="cve-container">
                <div class="cve-title">🛡️ Automated CVE & Script Findings:</div>
                <pre class="cve-code"><code>{chr(10).join(h["cves"])}</code></pre>
            </div>
            """

        ports_search = " ".join([p["port"] for p in h["ports"]])
        card = f"""
        <div class="host-card" data-category="{h['category']}" data-status="{risk_label}" data-search="{h['ip']} {h['name']} {h['vendor']} {h['mac']} {h['os']} {ports_search}">
            <div class="host-header" onclick="toggleDetails('{h['ip']}')">
                <div class="host-title">
                    <span class="device-icon">{h['icon']}</span>
                    <div>
                        <div class="host-name">{h['name']} {new_badge}</div>
                        <div class="host-ip">{h['ip']} <button class="copy-btn" onclick="event.stopPropagation(); copyText('{h['ip']}')">copy</button></div>
                    </div>
                </div>
                <div class="host-meta">
                    <span class="category-pill">{h['category']}</span>
                    <span class="badge-status {risk_class}">{risk_label}</span>
                </div>
            </div>
            <div class="host-summary">
                <div class="summary-col"><strong>Vendor:</strong> {h['vendor']}</div>
                <div class="summary-col"><strong>MAC:</strong> <code>{h['mac']}</code></div>
                <div class="summary-col"><strong>OS:</strong> {h['os']}</div>
                <div class="summary-col"><strong>Ports:</strong> {ports_badges}</div>
            </div>
            <div id="details-{h['ip'].replace('.', '-')}" class="host-details">
                {risks_detail}
                {cve_detail}
            </div>
        </div>
        """
        cards_html.append(card)

    cards_joined = "".join(cards_html)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Network Security Audit Report - {data['target_range']}</title>
    <style>
        :root {{
            --bg: #0b0f19;
            --surface: #111827;
            --surface-card: #172033;
            --border: #243049;
            --text: #f1f5f9;
            --text-muted: #94a3b8;
            --cyan: #38bdf8;
            --indigo: #6366f1;
            --green: #10b981;
            --yellow: #f59e0b;
            --orange: #f97316;
            --red: #ef4444;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            background: var(--bg);
            color: var(--text);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.5;
            padding: 24px;
        }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
        header {{
            background: linear-gradient(135deg, rgba(30, 41, 59, 0.8), rgba(15, 23, 42, 0.9));
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 28px;
            margin-bottom: 24px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            backdrop-filter: blur(10px);
        }}
        .header-top {{ display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; }}
        h1 {{ font-size: 26px; font-weight: 700; color: #fff; display: flex; align-items: center; gap: 10px; }}
        .header-meta {{ display: flex; gap: 18px; margin-top: 14px; flex-wrap: wrap; font-size: 14px; color: var(--text-muted); }}
        .header-meta span strong {{ color: var(--cyan); }}
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }}
        .stat-card {{
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }}
        .stat-title {{ font-size: 13px; font-weight: 600; text-transform: uppercase; color: var(--text-muted); letter-spacing: 0.5px; }}
        .stat-val {{ font-size: 28px; font-weight: 800; }}
        .val-total {{ color: var(--cyan); }}
        .val-danger {{ color: var(--red); }}
        .val-warning {{ color: var(--yellow); }}
        .val-clean {{ color: var(--green); }}
        .diff-card {{
            background: rgba(239, 68, 68, 0.08);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 24px;
        }}
        .diff-header h3 {{ font-size: 16px; color: #fca5a5; margin-bottom: 12px; }}
        .diff-list {{ list-style: none; display: flex; flex-direction: column; gap: 8px; font-size: 14px; }}
        .diff-list li {{ display: flex; align-items: center; gap: 8px; }}
        .controls {{
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
        }}
        .search-box {{
            flex: 1;
            min-width: 260px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 12px 16px;
            color: #fff;
            font-size: 14px;
            outline: none;
        }}
        .search-box:focus {{ border-color: var(--cyan); }}
        .filter-tabs {{ display: flex; gap: 8px; flex-wrap: wrap; }}
        .filter-tab {{
            background: var(--surface);
            border: 1px solid var(--border);
            color: var(--text-muted);
            border-radius: 8px;
            padding: 8px 14px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }}
        .filter-tab:hover, .filter-tab.active {{ background: var(--indigo); color: #fff; border-color: var(--indigo); }}
        .host-list {{ display: flex; flex-direction: column; gap: 14px; }}
        .host-card {{
            background: var(--surface-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            overflow: hidden;
            transition: transform 0.15s, border-color 0.15s;
        }}
        .host-card:hover {{ border-color: rgba(56, 189, 248, 0.4); }}
        .host-header {{
            padding: 16px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            flex-wrap: wrap;
            gap: 12px;
        }}
        .host-title {{ display: flex; align-items: center; gap: 12px; }}
        .device-icon {{ font-size: 24px; }}
        .host-name {{ font-size: 16px; font-weight: 700; color: #fff; display: flex; align-items: center; gap: 8px; }}
        .host-ip {{ font-size: 13px; color: var(--cyan); font-family: monospace; display: flex; align-items: center; gap: 6px; }}
        .copy-btn {{
            background: rgba(255, 255, 255, 0.1);
            border: none;
            color: var(--text-muted);
            border-radius: 4px;
            padding: 2px 6px;
            font-size: 10px;
            cursor: pointer;
        }}
        .copy-btn:hover {{ background: var(--cyan); color: #000; }}
        .host-meta {{ display: flex; align-items: center; gap: 10px; }}
        .category-pill {{
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 6px;
            padding: 4px 10px;
            font-size: 12px;
            color: var(--text-muted);
        }}
        .badge-status {{
            font-size: 12px;
            font-weight: 700;
            padding: 4px 10px;
            border-radius: 6px;
            text-transform: uppercase;
        }}
        .status-critical {{ background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid #ef4444; }}
        .status-high {{ background: rgba(249, 115, 22, 0.2); color: #fb923c; border: 1px solid #f97316; }}
        .status-warning {{ background: rgba(245, 158, 11, 0.2); color: #fbbf24; border: 1px solid #f59e0b; }}
        .status-info {{ background: rgba(56, 189, 248, 0.2); color: #38bdf8; border: 1px solid #0284c7; }}
        .status-clean {{ background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid #10b981; }}
        .badge-pill {{ font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 4px; text-transform: uppercase; }}
        .badge-danger {{ background: #ef4444; color: #fff; }}
        .badge-warning {{ background: #f59e0b; color: #000; }}
        .badge-neutral {{ background: #475569; color: #fff; }}
        .host-summary {{
            padding: 12px 20px;
            background: rgba(0,0,0,0.15);
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
            font-size: 13px;
        }}
        .summary-col {{ color: var(--text-muted); }}
        .summary-col strong {{ color: var(--text); }}
        .port-pill {{
            background: rgba(99, 102, 241, 0.15);
            color: #a5b4fc;
            border: 1px solid rgba(99, 102, 241, 0.3);
            border-radius: 4px;
            padding: 2px 6px;
            font-size: 11px;
            margin-right: 4px;
            display: inline-block;
            margin-top: 2px;
        }}
        .host-details {{ display: none; padding: 20px; border-top: 1px solid var(--border); }}
        .risk-container {{ display: flex; flex-direction: column; gap: 12px; }}
        .risk-item {{
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px 16px;
            display: flex;
            gap: 12px;
            align-items: flex-start;
        }}
        .sev-crit {{ background: #ef4444; color: #fff; }}
        .sev-high {{ background: #f97316; color: #fff; }}
        .sev-med {{ background: #f59e0b; color: #000; }}
        .sev-low {{ background: #38bdf8; color: #000; }}
        .risk-content {{ flex: 1; }}
        .risk-title {{ font-size: 14px; font-weight: 700; color: #fff; margin-bottom: 4px; }}
        .risk-remediation {{ font-size: 13px; color: #cbd5e1; }}
        .cve-container {{ margin-top: 16px; }}
        .cve-title {{ font-size: 13px; font-weight: 700; color: var(--cyan); margin-bottom: 6px; }}
        .cve-code {{
            background: #000;
            color: #38bdf8;
            padding: 12px;
            border-radius: 8px;
            font-size: 12px;
            overflow-x: auto;
            border: 1px solid rgba(56, 189, 248, 0.2);
        }}
        footer {{ margin-top: 36px; text-align: center; font-size: 13px; color: var(--text-muted); }}
        @media print {{
            body {{ background: #fff; color: #000; padding: 0; }}
            .controls, .copy-btn {{ display: none; }}
            .host-details {{ display: block !important; }}
            .host-card {{ border: 1px solid #ccc; break-inside: avoid; margin-bottom: 16px; }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="header-top">
                <h1>🛡️ Network Security Audit & Device Inventory</h1>
                <button class="filter-tab" onclick="window.print()">🖨️ Print / Save PDF</button>
            </div>
            <div class="header-meta">
                <span>Target: <strong>{data['target_range']}</strong></span>
                <span>Interface: <strong>{data['target_iface']}</strong></span>
                <span>Gateway: <strong>{data['gateway_ip']}</strong></span>
                <span>Auditor: <strong>{data['local_ip']}</strong></span>
                <span>Audit Date: <strong>{data['scan_date']}</strong></span>
                <span>Duration: <strong>{data['duration']}s</strong></span>
                <span>Mode: <strong>{data['scan_mode'].upper()}</strong></span>
            </div>
        </header>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-title">Total Devices</div>
                <div class="stat-val val-total">{data['metrics']['total_devices']}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">High / Critical Risks</div>
                <div class="stat-val val-danger">{data['metrics']['high_risks']}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">Warnings / Info</div>
                <div class="stat-val val-warning">{data['metrics']['warnings']}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">Clean Devices</div>
                <div class="stat-val val-clean">{data['metrics']['clean']}</div>
            </div>
        </div>

        {diff_html}

        <div class="controls">
            <input type="text" id="searchBox" class="search-box" placeholder="🔍 Search IP, Device Name, Vendor, MAC, OS, or Port..." onkeyup="filterCards()">
            <div class="filter-tabs">
                <button class="filter-tab active" onclick="setFilter('ALL', this)">All ({data['metrics']['total_devices']})</button>
                <button class="filter-tab" onclick="setFilter('RISK', this)">⚠️ Risks Only ({data['metrics']['high_risks'] + data['metrics']['warnings']})</button>
                <button class="filter-tab" onclick="setFilter('Gateway / Router', this)">🌐 Routers</button>
                <button class="filter-tab" onclick="setFilter('Workstation / PC', this)">💻 Workstations</button>
                <button class="filter-tab" onclick="setFilter('Mobile / Tablet', this)">📱 Mobile</button>
                <button class="filter-tab" onclick="setFilter('Smart Home / IoT', this)">💡 IoT</button>
                <button class="filter-tab" onclick="setFilter('Server / NAS', this)">🗄️ Servers</button>
            </div>
        </div>

        <div class="host-list" id="hostList">
            {cards_joined}
        </div>

        <footer>
            Generated automatically by ShadowHarvy Network Audit Tool v2.1.0 on {data['scan_date']}
        </footer>
    </div>

    <script>
        let currentFilter = 'ALL';

        function toggleDetails(ip) {{
            const id = 'details-' + ip.replace(/\\./g, '-');
            const el = document.getElementById(id);
            if (el) {{
                el.style.display = (el.style.display === 'block') ? 'none' : 'block';
            }}
        }}

        function copyText(text) {{
            navigator.clipboard.writeText(text);
        }}

        function setFilter(cat, btn) {{
            currentFilter = cat;
            document.querySelectorAll('.filter-tab').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            filterCards();
        }}

        function filterCards() {{
            const q = document.getElementById('searchBox').value.toLowerCase();
            const cards = document.querySelectorAll('.host-card');
            
            cards.forEach(c => {{
                const search = c.getAttribute('data-search').toLowerCase();
                const cat = c.getAttribute('data-category');
                const status = c.getAttribute('data-status');
                
                let matchesCategory = (currentFilter === 'ALL');
                if (currentFilter === 'RISK') {{
                    matchesCategory = (status.includes('RISK') || status.includes('WARNING'));
                }} else if (currentFilter !== 'ALL') {{
                    matchesCategory = (cat === currentFilter);
                }}

                const matchesSearch = !q || search.includes(q);
                c.style.display = (matchesCategory && matchesSearch) ? 'block' : 'none';
            }});
        }}
    </script>
</body>
</html>
"""
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)

def generate_markdown_report(data, output_path):
    diff_md = ""
    if data["diff"]["has_diff"]:
        diff_lines = [f"### 🚨 Network Changes Since Previous Audit ({data['diff']['prev_date']})\n"]
        for h in data["diff"]["new_hosts"]:
            diff_lines.append(f"- 🆕 **New Device Detected:** `{h['ip']}` ({h['name']} - {h['vendor']} - {h['category']})")
        for p in data["diff"]["opened_ports"]:
            diff_lines.append(f"- 🔓 **Newly Opened Port:** `{p['ip']}` ({p['name']}) -> Port `{p['port']}` opened")
        for h in data["diff"]["removed_hosts"]:
            diff_lines.append(f"- 📴 **Device Offline / Disconnected:** `{h['ip']}` ({h['name']} - {h['vendor']})")
        diff_lines.append("\n---\n")
        diff_md = "\n".join(diff_lines)

    lines = []
    lines.append("# Network Security Audit Report")
    lines.append(f"**Audit Date:** {data['scan_date']}  ")
    lines.append(f"**Target Subnet:** `{data['target_range']}` | **Interface:** `{data['target_iface']}`  ")
    lines.append(f"**Default Gateway:** `{data['gateway_ip']}` | **Auditor Host:** `{data['local_ip']}`  ")
    lines.append(f"**Scan Duration:** {data['duration']} seconds | **Mode:** `{data['scan_mode'].upper()}`\n")
    lines.append("---\n")
    lines.append("## 📊 Executive Summary\n")
    lines.append("| Metric | Value |")
    lines.append("| :--- | :--- |")
    lines.append(f"| **Total Devices Detected** | **{data['metrics']['total_devices']}** |")
    lines.append(f"| **High / Critical Risk Devices** | **{data['metrics']['high_risks']}** |")
    lines.append(f"| **Warning / Notice Devices** | **{data['metrics']['warnings']}** |")
    lines.append(f"| **Clean / No Exposed Risks** | **{data['metrics']['clean']}** |")
    lines.append("\n---\n")
    
    if diff_md:
        lines.append(diff_md)

    lines.append("## 🖥️ Device Inventory\n")
    lines.append("| IP Address | Device Name | Category | Manufacturer | Detected OS | Open Ports | Status |")
    lines.append("| :--- | :--- | :--- | :--- | :--- | :--- | :--- |")

    for h in data["hosts"]:
        status = "🟢 Clean"
        if any(r["severity"] == "CRITICAL" for r in h["risks"]):
            status = "🔴 Critical"
        elif any(r["severity"] == "HIGH" for r in h["risks"]):
            status = "🟠 High Risk"
        elif any(r["severity"] == "MEDIUM" for r in h["risks"]):
            status = "🟡 Warning"
        elif any(r["severity"] == "LOW" for r in h["risks"]):
            status = "🔵 Info"

        ports_str = ", ".join([p["port"] for p in h["ports"]]) if h["ports"] else "None"
        new_tag = " `[NEW]`" if h.get("is_new") else ""
        lines.append(f"| `{h['ip']}` | **{h['name']}**{new_tag} | {h['icon']} {h['category']} | {h['vendor']} | {h['os']} | `{ports_str}` | {status} |")

    lines.append("\n---\n")
    lines.append("## ⚠️ Detailed Security Findings & Remediation\n")

    has_findings = False
    for h in data["hosts"]:
        if h["risks"] or h.get("cves"):
            has_findings = True
            lines.append(f"### Device: `{h['ip']}` ({h['name']})")
            lines.append(f"- **Category:** {h['icon']} {h['category']}")
            lines.append(f"- **Vendor:** {h['vendor']} | **MAC Address:** `{h['mac']}`")
            lines.append(f"- **Operating System:** {h['os']}")
            ports_str = ", ".join([p["port"] for p in h["ports"]]) if h["ports"] else "None"
            lines.append(f"- **Open Ports:** `{ports_str}`\n")
            
            if h["risks"]:
                lines.append("**Identified Security Risks:**")
                for r in h["risks"]:
                    lines.append(f"- ⚠️ **[{r['severity']}] {r['title']}**")
                    lines.append(f"  - *Remediation:* {r['remediation']}")
                lines.append("")

            if h.get("cves"):
                lines.append("**Automated CVE / Script Vulnerability Output:**")
                lines.append("```text")
                for c in h["cves"][:20]:
                    lines.append(c)
                lines.append("```\n")

    if not has_findings:
        lines.append("🎉 **No critical vulnerabilities or exposed risky management services were discovered.**\n")

    lines.append("---\n")
    lines.append("## 🛡️ Defensive Hardening & Remediation Recommendations\n")
    lines.append("1. **Isolate IoT Devices on an Isolated VLAN / Guest Network:**")
    lines.append("   - Smart plugs, smart TVs, and IoT peripherals should not share the same broadcast domain as personal workstations or storage servers.\n")
    lines.append("2. **Disable Unencrypted Management Protocols:**")
    lines.append("   - Replace any remaining Telnet (23) or plain HTTP web management consoles with SSH and HTTPS.\n")
    lines.append("3. **Protect Database & Container Sockets:**")
    lines.append("   - Ensure Redis, MySQL, Postgres, and Docker API sockets are bound to `127.0.0.1` or protected with strong passwords and firewall rules.\n")
    lines.append("4. **Audit Router UPnP & Remote Administration:**")
    lines.append("   - Log into your primary gateway router and disable UPnP (Universal Plug and Play) and remote WAN administration.\n")
    lines.append("---")
    lines.append(f"*Generated automatically by ShadowHarvy Network Audit Tool v2.1.0 on {data['scan_date']}*")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

def main():
    if len(sys.argv) < 2:
        print("Usage: audit_engine.py <config.json>")
        sys.exit(1)

    with open(sys.argv[1], "r") as f:
        cfg = json.load(f)

    target_range = cfg["target_range"]
    target_iface = cfg["target_iface"]
    local_ip = cfg["local_ip"]
    gateway_ip = cfg["gateway_ip"]
    scan_mode = cfg.get("scan_mode", "standard")
    threads = cfg.get("threads", 16)
    exclude_ips = set(cfg.get("exclude_ips", []))
    reports_dir = cfg.get("reports_dir", "")
    temp_dir = cfg.get("temp_dir", "")
    action = cfg.get("action", "")

    # ACTION 1: DISCOVERY MULTICAST PROBE (SSDP + mDNS)
    if action == "probe_multicast":
        ssdp_hosts = probe_ssdp()
        mdns_hosts = probe_mdns()
        all_probed = list(ssdp_hosts | mdns_hosts)
        with open(cfg["probe_output"], "w") as f:
            for ip in all_probed:
                f.write(f"{ip}\n")
        return

    # ACTION 2: LIST STAGE 2 (DISCOVERED DEVICES KNOWN SO FAR)
    if action == "list_stage2":
        with open(cfg["hosts_file"], "r") as f:
            hosts = [line.strip() for line in f if line.strip() and line.strip() not in exclude_ips]
        
        hosts.sort(key=lambda x: [int(p) for p in x.split(".")])
        total = len(hosts)
        
        print("\033[1;37m  Stage 2 Live Devices (IP, Hardware MAC & Network Role):\033[0m")
        print("  \033[0;90m─────────────────────────────────────────────────────────────────────────────────────────────\033[0m")
        
        for idx, ip in enumerate(hosts, 1):
            mac = "-"
            try:
                res = subprocess.run(["ip", "neigh", "show", ip, "dev", target_iface], stdout=subprocess.PIPE, text=True, timeout=0.3)
                for part in res.stdout.split():
                    if re.match(r"^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", part):
                        mac = part
                        break
            except:
                pass
            if ip == local_ip and mac in ["-", "Unknown"]:
                mac = "Local Device"

            vendor = lookup_vendor(mac, ip, local_ip)
            
            role = "\033[0;36mNetwork Device\033[0m"
            if ip == gateway_ip:
                role = "\033[1;32mDefault Gateway\033[0m"
            elif ip == local_ip:
                role = "\033[1;35mLocal Auditor Host\033[0m"

            vendor_short = (vendor[:22] + "..") if len(vendor) > 24 else vendor
            print(f"  \033[0;34m[{idx:>2}/{total}]\033[0m \033[1m{ip:<15}\033[0m │ MAC: \033[0;33m{mac:<17}\033[0m │ \033[1;37m{vendor_short:<24}\033[0m │ [{role}]")
        print("  \033[0;90m─────────────────────────────────────────────────────────────────────────────────────────────\033[0m\n")
        return

    # ACTION 3: PROCESS STAGE 3 (SERVICES, OS, CATEGORIZATION & PROGRESSIVE LISTING)
    if action == "process_stage3":
        with open(cfg["hosts_file"], "r") as f:
            hosts = [line.strip() for line in f if line.strip() and line.strip() not in exclude_ips]

        nmap_xml = cfg.get("nmap_xml", "")
        nmap_data = parse_nmap_xml(nmap_xml, hosts, local_ip, gateway_ip)

        inventory = []

        def worker(ip):
            is_gw = (ip == gateway_ip)
            nd = nmap_data.get(ip, {})
            mac = nd.get("mac", "-")
            
            if mac in ["-", "Unknown"]:
                try:
                    res = subprocess.run(["ip", "neigh", "show", ip, "dev", target_iface], stdout=subprocess.PIPE, text=True, timeout=0.3)
                    for part in res.stdout.split():
                        if re.match(r"^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", part):
                            mac = part
                            break
                except:
                    pass
            if ip == local_ip and mac in ["-", "Unknown"]:
                mac = "Local Device"

            vendor = lookup_vendor(mac, ip, local_ip)
            if vendor == "Unknown Manufacturer" and nd.get("nmap_vendor") and nd.get("nmap_vendor") != "Unknown":
                vendor = nd.get("nmap_vendor")

            name = resolve_name(ip, local_ip)
            if (name == "-" or "Device" in name) and nd.get("nmap_name") and nd.get("nmap_name") != "-":
                name = nd.get("nmap_name")
            if name == "-":
                name = f"{vendor} Device" if vendor not in ["Unknown Manufacturer", "Private / Randomized MAC"] else f"Device-{ip}"

            os_detected = nd.get("os", "Unknown")
            if os_detected == "Unknown" or not os_detected:
                if ip == local_ip:
                    try:
                        with open("/etc/os-release") as f:
                            for l in f:
                                if l.startswith("PRETTY_NAME="):
                                    os_detected = l.split("=")[1].strip().strip('"')
                                    break
                    except:
                        pass
                if os_detected == "Unknown":
                    try:
                        res = subprocess.run(["ping", "-c", "1", "-W", "1", ip], stdout=subprocess.PIPE, text=True, timeout=0.5)
                        m = re.search(r"ttl=(\d+)", res.stdout)
                        if m:
                            ttl = int(m.group(1))
                            if ttl <= 64:
                                os_detected = f"Linux / Apple / Android (TTL ~{ttl})"
                            elif ttl <= 128:
                                os_detected = f"Microsoft Windows (TTL ~{ttl})"
                            else:
                                os_detected = f"Network Appliance (TTL ~{ttl})"
                    except:
                        pass

            ports = nd.get("ports", [])
            if not ports and not cfg.get("has_nmap", False):
                ports = fallback_port_scan(ip, scan_mode)

            category, icon = classify_device(ip, name, vendor, mac, os_detected, ports, is_gw)

            return {
                "ip": ip,
                "name": name,
                "vendor": vendor,
                "mac": mac,
                "category": category,
                "icon": icon,
                "os": os_detected,
                "ports": ports,
                "risks": [],
                "cves": [],
                "status": "Clean",
                "is_new": False
            }

        with ThreadPoolExecutor(max_workers=threads) as executor:
            futures = [executor.submit(worker, ip) for ip in hosts]
            for f in as_completed(futures):
                try:
                    res = f.result()
                    if res:
                        inventory.append(res)
                except:
                    pass

        inventory.sort(key=lambda x: [int(p) for p in x["ip"].split(".")])

        # Print Stage 3 Progressive Findings
        print("\033[1;37m  Stage 3 Device Signatures & Open Ports Identified:\033[0m")
        print("  \033[0;90m─────────────────────────────────────────────────────────────────────────────────────────────\033[0m")
        for h in inventory:
            ip = h["ip"]
            cat_display = f"{h['icon']} {h['category']}"
            if len(cat_display) > 19: cat_display = cat_display[:18] + ".."
            name_disp = (h["name"][:18] + "..") if len(h["name"]) > 19 else h["name"]
            os_disp = (h["os"][:18] + "..") if len(h["os"]) > 19 else h["os"]
            ports_list = [p["port"] for p in h["ports"]]
            ports_disp = ", ".join(ports_list) if ports_list else "\033[0;32mNone (Clean)\033[0m"
            if len(ports_disp) > 28: ports_disp = ports_disp[:26] + ".."

            print(f"  \033[0;32m•\033[0m \033[1m{ip:<15}\033[0m │ \033[0;36m{cat_display:<19}\033[0m │ \033[1;37m{name_disp:<18}\033[0m │ \033[0;90m{os_disp:<18}\033[0m │ Ports: \033[1;33m{ports_disp}\033[0m")
        print("  \033[0;90m─────────────────────────────────────────────────────────────────────────────────────────────\033[0m\n")

        # Save intermediate stage 3 state
        with open(os.path.join(temp_dir, "stage3_inventory.json"), "w") as f:
            json.dump(inventory, f)
        return

    # ACTION 4: AUDIT STAGE 4 VULNERABILITIES & RISKS
    if action == "audit_stage4":
        stage3_file = os.path.join(temp_dir, "stage3_inventory.json")
        if not os.path.isfile(stage3_file):
            return
        
        with open(stage3_file, "r") as f:
            inventory = json.load(f)

        has_nmap = cfg.get("has_nmap", False)
        skip_vuln = cfg.get("skip_vuln", False)

        for h in inventory:
            ip = h["ip"]
            is_gw = (ip == gateway_ip)
            ports = h["ports"]
            port_ids = [p["port"] for p in ports]
            ports_str = ",".join(port_ids)

            # Evaluate Security Risks (Redis, Docker, Telnet, RTSP, etc.)
            h["risks"] = evaluate_risks(ip, ports, is_gw)

            cves = []
            if has_nmap and not skip_vuln and ports:
                out_f = os.path.join(temp_dir, f"vuln_{ip}.txt")
                try:
                    subprocess.run([
                        'nmap', '-sV', '--version-light',
                        '--script', 'vuln and not (dos or brute)',
                        '--script-timeout', '20s',
                        '-p', ",".join([p["port"].split("/")[0] for p in ports]), ip, '-oN', out_f
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

                    if os.path.isfile(out_f):
                        with open(out_f, "r") as vf:
                            for l in vf:
                                if any(k in l for k in ["VULNERABLE", "CVE-", "State: VULNERABLE"]):
                                    cves.append(l.strip())
                except:
                    pass

            h["cves"] = cves

            # Status string
            status_str = "Clean"
            if any(r["severity"] == "CRITICAL" for r in h["risks"]):
                status_str = "Critical"
            elif any(r["severity"] == "HIGH" for r in h["risks"]):
                status_str = "High Risk"
            elif any(r["severity"] == "MEDIUM" for r in h["risks"]):
                status_str = "Warning"
            elif any(r["severity"] == "LOW" for r in h["risks"]):
                status_str = "Info"

            h["status"] = status_str

            # Progressive terminal print for Stage 4
            if ports:
                print(f"  \033[0;34m•\033[0m Auditing \033[1m{ip}\033[0m ({h['name']} │ ports: \033[1;33m{ports_str}\033[0m)...")
                for r in h["risks"]:
                    badge_color = "\033[1;31m" if r["severity"] in ["CRITICAL", "HIGH"] else "\033[1;33m"
                    print(f"    {badge_color}⚠️  [{r['severity']}]\033[0m {r['title']}")
                if cves:
                    print(f"    \033[1;31m⚠ Potential CVEs Flagged:\033[0m {cves[0][:70]}")
                elif not h["risks"]:
                    print("    \033[0;32m✓ Clean - No high-profile vulnerabilities flagged by automated scripts.\033[0m")
            else:
                print(f"  \033[0;32m•\033[0m \033[1m{ip}\033[0m ({h['name']}) ── \033[0;32mClean (No open services exposed)\033[0m")

        print()

        # Save stage 4 inventory
        with open(os.path.join(temp_dir, "stage4_inventory.json"), "w") as f:
            json.dump(inventory, f)
        return

    # ACTION 5: FINALIZE STAGE 5 (PUT IT ALL TOGETHER & GENERATE REPORTS)
    if action == "finalize_stage5":
        stage4_file = os.path.join(temp_dir, "stage4_inventory.json")
        if not os.path.isfile(stage4_file):
            return

        with open(stage4_file, "r") as f:
            inventory = json.load(f)

        history_file = os.path.join(reports_dir, ".network_audit_last.json")
        diff = compute_diff(inventory, history_file)

        high_r = sum(1 for h in inventory if any(r["severity"] in ["CRITICAL", "HIGH"] for r in h["risks"]))
        warn_r = sum(1 for h in inventory if any(r["severity"] in ["MEDIUM", "LOW"] for r in h["risks"]) and not any(r["severity"] in ["CRITICAL", "HIGH"] for r in h["risks"]))
        clean_r = len(inventory) - (high_r + warn_r)

        data = {
            "scan_date": cfg["scan_date"],
            "target_range": target_range,
            "target_iface": target_iface,
            "gateway_ip": gateway_ip,
            "local_ip": local_ip,
            "duration": cfg["duration"],
            "scan_mode": scan_mode,
            "metrics": {
                "total_devices": len(inventory),
                "high_risks": high_r,
                "warnings": warn_r,
                "clean": clean_r,
                "new_devices": len(diff["new_hosts"])
            },
            "diff": diff,
            "hosts": inventory
        }

        # Print Diff Alert if network changes detected
        if diff.get("has_diff"):
            print("\033[1;33m═══════════════════════════════════════════════════════════════════════════════════════════════\033[0m")
            print(f"\033[1;31m🚨 NETWORK CHANGES DETECTED SINCE PREVIOUS AUDIT ({diff.get('prev_date')}):\033[0m")
            for h in diff.get("new_hosts", []):
                print(f"   \033[1;32m[+] NEW DEVICE:\033[0m {h['ip']} - {h['name']} ({h['vendor']}) [{h['category']}]")
            for p in diff.get("opened_ports", []):
                print(f"   \033[1;33m[!] NEW OPEN PORT:\033[0m {p['ip']} ({p['name']}) -> Port {p['port']}")
            for h in diff.get("removed_hosts", []):
                print(f"   \033[0;90m[-] OFFLINE DEVICE:\033[0m {h['ip']} - {h['name']}")
            print("\033[1;33m═══════════════════════════════════════════════════════════════════════════════════════════════\033[0m\n")

        # Print Master Final Table
        print("\033[1;37m=== Master Device Inventory & Security Audit Summary ===\033[0m")
        print("\033[0;34mIP ADDRESS      DEVICE NAME          CATEGORY           MANUFACTURER           OPEN PORTS     RISK STATUS\033[0m")
        print("\033[0;90m─────────────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m")

        for h in inventory:
            ip = h["ip"]
            name = (h["name"][:18] + "..") if len(h["name"]) > 19 else h["name"]
            cat = (h["icon"] + " " + h["category"][:14] + "..") if len(h["category"]) > 15 else (h["icon"] + " " + h["category"])
            vendor = (h["vendor"][:20] + "..") if len(h["vendor"]) > 21 else h["vendor"]
            
            ports = [p["port"] for p in h["ports"]]
            ports_str = ",".join(ports) if ports else "None"
            if len(ports_str) > 13: ports_str = ports_str[:11] + ".."

            status_str = h["status"]
            badge = "\033[0;32mCLEAN\033[0m"
            if status_str == "Critical":
                badge = "\033[1;31mCRITICAL\033[0m"
            elif status_str == "High Risk":
                badge = "\033[0;31mHIGH RISK\033[0m"
            elif status_str == "Warning":
                badge = "\033[1;33mWARNING\033[0m"
            elif status_str == "Info":
                badge = "\033[0;36mINFO\033[0m"

            new_badge = " \033[1;31m[NEW]\033[0m" if h.get("is_new") else ""
            print(f"{ip:<15} {name:<20}{new_badge:<0} {cat:<18} {vendor:<22} {ports_str:<14} {badge}")

        print("\033[0;90m─────────────────────────────────────────────────────────────────────────────────────────────────────────────\033[0m")
        print(f"\033[1;37m📊 Executive Metrics:\033[0m Total: \033[1;36m{len(inventory)}\033[0m │ High/Critical: \033[1;31m{high_r}\033[0m │ Warnings: \033[1;33m{warn_r}\033[0m │ Clean: \033[1;32m{clean_r}\033[0m\n")

        # Save Final Reports
        with open(cfg["output_md"], "w") as f:
            generate_markdown_report(data, cfg["output_md"])

        with open(cfg["output_html"], "w") as f:
            generate_html_report(data, cfg["output_html"])

        if cfg.get("output_json"):
            with open(cfg["output_json"], "w") as f:
                json.dump(data, f, indent=2)

        try:
            with open(history_file, "w") as f:
                json.dump(data, f, indent=2)
        except:
            pass

if __name__ == "__main__":
    main()
PY_EOF

# -------------------------------------------------------------
# STEP 2: Multi-Protocol Host Discovery (ARP + ICMP + SSDP + mDNS)
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 2: Host Discovery (ARP, ICMP, SSDP & mDNS Sweep)${NC}"
echo -e "${WHITE}Sweeping subnet ${CYAN}$TARGET_RANGE${WHITE} for responsive devices...${NC}"

DISCOVERED_HOSTS_FILE="$TEMP_DIR/discovered_hosts.txt"
touch "$DISCOVERED_HOSTS_FILE"

HAS_NMAP=0
if command -v nmap >/dev/null 2>&1; then
  HAS_NMAP=1
fi

PROBE_OUT="$TEMP_DIR/probed_multicast.txt"
cat << JSON_EOF > "$TEMP_DIR/probe_cfg.json"
{
  "target_range": "$TARGET_RANGE",
  "target_iface": "$TARGET_IFACE",
  "local_ip": "$LOCAL_IP",
  "gateway_ip": "$GATEWAY_IP",
  "scan_mode": "$SCAN_MODE",
  "reports_dir": "$REPORT_DIR",
  "temp_dir": "$TEMP_DIR",
  "action": "probe_multicast",
  "probe_output": "$PROBE_OUT"
}
JSON_EOF

python3 "$TEMP_DIR/audit_engine.py" "$TEMP_DIR/probe_cfg.json" >/dev/null 2>&1 &
PROBE_PID=$!

if [[ $HAS_NMAP -eq 1 ]]; then
  echo -e "  ${BLUE}•${NC} Running high-speed Nmap host sweep..."
  nmap -sn -T4 --min-parallelism 64 "$TARGET_RANGE" -oG "$TEMP_DIR/nmap_hosts.gnmap" >/dev/null 2>&1 || true
  grep "Status: Up" "$TEMP_DIR/nmap_hosts.gnmap" 2>/dev/null | awk '{print $2}' >> "$DISCOVERED_HOSTS_FILE"
else
  echo -e "  ${BLUE}•${NC} Running multi-threaded ping sweep..."
  python3 -c "
import ipaddress, subprocess
from concurrent.futures import ThreadPoolExecutor

network = ipaddress.IPv4Network('$TARGET_RANGE', strict=False)
live = []

def ping(ip):
    r = subprocess.run(['ping', '-c', '1', '-W', '1', str(ip)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return str(ip) if r.returncode == 0 else None

with ThreadPoolExecutor(max_workers=$THREADS) as ex:
    for h in ex.map(ping, network.hosts()):
        if h: live.append(h)

with open('$DISCOVERED_HOSTS_FILE', 'a') as f:
    for h in live: f.write(f'{h}\n')
" 2>/dev/null || true
fi

wait $PROBE_PID 2>/dev/null || true
if [[ -f "$PROBE_OUT" ]]; then
  cat "$PROBE_OUT" >> "$DISCOVERED_HOSTS_FILE"
fi

if [[ -n "$LOCAL_IP" ]]; then echo "$LOCAL_IP" >> "$DISCOVERED_HOSTS_FILE"; fi
if [[ -n "$GATEWAY_IP" && "$GATEWAY_IP" != "Unknown" ]]; then echo "$GATEWAY_IP" >> "$DISCOVERED_HOSTS_FILE"; fi

ip -4 neigh show dev "$TARGET_IFACE" 2>/dev/null | grep -E 'REACHABLE|STALE|DELAY' | awk '{print $1}' >> "$DISCOVERED_HOSTS_FILE"

python3 -c "
import ipaddress
try:
    net = ipaddress.IPv4Network('$TARGET_RANGE', strict=False)
except:
    net = None

excl = set([x.strip() for x in '$EXCLUDE_IPS'.split(',') if x.strip()])
valid = set()

try:
    with open('$DISCOVERED_HOSTS_FILE', 'r') as f:
        for line in f:
            h = line.strip()
            if not h or h in excl: continue
            try:
                ip = ipaddress.IPv4Address(h)
                if net is None or ip in net:
                    valid.add(str(ip))
            except:
                pass
except:
    pass

with open('$DISCOVERED_HOSTS_FILE', 'w') as f:
    for v in sorted(valid, key=lambda x: [int(p) for p in x.split('.')]):
        f.write(f'{v}\n')
" 2>/dev/null || true

TOTAL_HOSTS=$(wc -l < "$DISCOVERED_HOSTS_FILE" 2>/dev/null || echo 0)

if [[ $TOTAL_HOSTS -eq 0 ]]; then
  echo -e "${RED}[!] No responsive devices detected on $TARGET_RANGE.${NC}"
  echo -e "    Verify your interface connection and check firewall settings."
  exit 0
fi

echo -e "  ${GREEN}✓${NC} Discovered ${BOLD}${GREEN}$TOTAL_HOSTS live device(s)${NC} on the network.\n"

# Progressive Disclosure: List Stage 2 Discovered Devices
cat << JSON_EOF > "$TEMP_DIR/stage2_cfg.json"
{
  "target_range": "$TARGET_RANGE",
  "target_iface": "$TARGET_IFACE",
  "local_ip": "$LOCAL_IP",
  "gateway_ip": "$GATEWAY_IP",
  "hosts_file": "$DISCOVERED_HOSTS_FILE",
  "exclude_ips": [$(if [[ -n "$EXCLUDE_IPS" ]]; then echo "\"${EXCLUDE_IPS//,/\",\"}\""; fi)],
  "action": "list_stage2"
}
JSON_EOF

python3 "$TEMP_DIR/audit_engine.py" "$TEMP_DIR/stage2_cfg.json"

# -------------------------------------------------------------
# STEP 3: Parallel Service, Vendor & OS Detection
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 3: Service, Vendor & Operating System Detection${NC}"
echo -e "${WHITE}Scanning service signatures, open ports, and device metadata...${NC}"

NMAP_XML="$TEMP_DIR/nmap_batch.xml"

if [[ $HAS_NMAP -eq 1 ]]; then
  scan_args=("-sV" "--version-light")
  if [[ "$EUID" -eq 0 ]]; then
    scan_args+=("-O" "--osscan-guess" "--max-os-tries" "2")
  fi

  if [[ "$SCAN_MODE" == "quick" ]]; then
    scan_args+=("-F" "-T4" "--max-retries" "1" "--host-timeout" "10s")
  elif [[ "$SCAN_MODE" == "full" ]]; then
    scan_args+=("-p-" "-T4" "--host-timeout" "120s")
  else
    scan_args+=("-p" "21,22,23,25,53,80,110,135,139,143,443,445,554,993,995,1433,1723,1883,2375,2376,3306,3389,5000,5353,5357,5432,5900,6379,8000,8006,8080,8443,8888,9000,9200,9443,11211,27017" "-T4" "--max-retries" "1" "--host-timeout" "15s")
  fi

  echo -e "  ${BLUE}•${NC} Executing batch parallel Nmap port scan on $TOTAL_HOSTS target(s)..."
  nmap "${scan_args[@]}" -iL "$DISCOVERED_HOSTS_FILE" -oX "$NMAP_XML" -oN "$TEMP_DIR/nmap_all.txt" >/dev/null 2>&1 || true
fi

# Progressive Disclosure: Process and list Stage 3 Details
cat << JSON_EOF > "$TEMP_DIR/stage3_cfg.json"
{
  "target_range": "$TARGET_RANGE",
  "target_iface": "$TARGET_IFACE",
  "local_ip": "$LOCAL_IP",
  "gateway_ip": "$GATEWAY_IP",
  "scan_mode": "$SCAN_MODE",
  "threads": $THREADS,
  "hosts_file": "$DISCOVERED_HOSTS_FILE",
  "nmap_xml": "$NMAP_XML",
  "has_nmap": $(if [[ $HAS_NMAP -eq 1 ]]; then echo "true"; else echo "false"; fi),
  "exclude_ips": [$(if [[ -n "$EXCLUDE_IPS" ]]; then echo "\"${EXCLUDE_IPS//,/\",\"}\""; fi)],
  "temp_dir": "$TEMP_DIR",
  "action": "process_stage3"
}
JSON_EOF

python3 "$TEMP_DIR/audit_engine.py" "$TEMP_DIR/stage3_cfg.json"

# -------------------------------------------------------------
# STEP 4: Vulnerability Script Assessment (Nmap NSE)
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 4: CVE & Security Risk Assessment${NC}"
echo -e "${WHITE}Executing vulnerability checks and active service probes...${NC}\n"

cat << JSON_EOF > "$TEMP_DIR/stage4_cfg.json"
{
  "target_range": "$TARGET_RANGE",
  "target_iface": "$TARGET_IFACE",
  "local_ip": "$LOCAL_IP",
  "gateway_ip": "$GATEWAY_IP",
  "has_nmap": $(if [[ $HAS_NMAP -eq 1 ]]; then echo "true"; else echo "false"; fi),
  "skip_vuln": $(if [[ $SKIP_VULN -eq 1 ]]; then echo "true"; else echo "false"; fi),
  "temp_dir": "$TEMP_DIR",
  "action": "audit_stage4"
}
JSON_EOF

python3 "$TEMP_DIR/audit_engine.py" "$TEMP_DIR/stage4_cfg.json"

# -------------------------------------------------------------
# STEP 5: Final Assembly & Audit Report Generation
# -------------------------------------------------------------
echo -e "${CYAN}${BOLD}▶ Phase 5: Final Assembly & Audit Report Generation${NC}"
echo -e "${WHITE}Putting all findings together and synthesizing reports...${NC}\n"

mkdir -p "$REPORT_DIR"
if [[ -z "$OUTPUT_MD" ]]; then
  OUTPUT_MD="$REPORT_DIR/network_audit_$(date +%Y%m%d_%H%M%S).md"
fi
if [[ -z "$OUTPUT_HTML" ]]; then
  OUTPUT_HTML="${OUTPUT_MD%.md}.html"
fi
if [[ -z "$OUTPUT_JSON" ]]; then
  OUTPUT_JSON="${OUTPUT_MD%.md}.json"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

cat << JSON_EOF > "$TEMP_DIR/stage5_cfg.json"
{
  "target_range": "$TARGET_RANGE",
  "target_iface": "$TARGET_IFACE",
  "local_ip": "$LOCAL_IP",
  "gateway_ip": "$GATEWAY_IP",
  "scan_mode": "$SCAN_MODE",
  "scan_date": "$SCAN_DATE",
  "duration": $DURATION,
  "reports_dir": "$REPORT_DIR",
  "temp_dir": "$TEMP_DIR",
  "output_md": "$OUTPUT_MD",
  "output_html": "$OUTPUT_HTML",
  "output_json": "$OUTPUT_JSON",
  "action": "finalize_stage5"
}
JSON_EOF

python3 "$TEMP_DIR/audit_engine.py" "$TEMP_DIR/stage5_cfg.json"

echo -e "${GREEN}${BOLD}✔ Network audit complete! (${DURATION}s)${NC}"
echo -e "  ${WHITE}• Markdown Report Saved :${NC} ${BLUE}${BOLD}$OUTPUT_MD${NC}"
echo -e "  ${WHITE}• Interactive Dashboard :${NC} ${CYAN}${BOLD}$OUTPUT_HTML${NC}"
if [[ -n "$OUTPUT_JSON" ]]; then
  echo -e "  ${WHITE}• JSON Structured Export:${NC} ${MAGENTA}${BOLD}$OUTPUT_JSON${NC}"
fi
echo
