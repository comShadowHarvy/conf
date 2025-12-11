#!/bin/bash

# Network Information Script
# Shows useful network information in a human-readable format

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${BOLD}${WHITE}                    NETWORK INFORMATION                         ${RESET}${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
echo

# Main network interfaces (excluding docker/veth)
echo -e "${BOLD}${GREEN}📡 Active Network Interfaces:${RESET}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
ip -brief a | grep -v "veth\|br-" | while read iface state addr rest; do
    if [ "$state" = "UP" ] || [ "$iface" = "lo" ]; then
        # Extract IPv4 address only
        ipv4=$(echo "$addr $rest" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+' | head -1)
        
        if [ "$iface" = "lo" ]; then
            echo -e "  ${GRAY}🔄 Loopback${RESET} ${YELLOW}(lo)${RESET}:     ${CYAN}$ipv4${RESET}"
        elif [[ $iface == eth* ]]; then
            echo -e "  ${GREEN}🔌 Ethernet${RESET} ${YELLOW}($iface)${RESET}:  ${CYAN}$ipv4${RESET}"
        elif [[ $iface == wlan* ]] || [[ $iface == wlp* ]]; then
            echo -e "  ${GREEN}📶 WiFi${RESET} ${YELLOW}($iface)${RESET}:      ${CYAN}$ipv4${RESET}"
        else
            echo -e "  ${GRAY}🌐 $iface${RESET}:            ${CYAN}$ipv4${RESET}"
        fi
    fi
done
echo

# Default gateway
echo -e "${BOLD}${MAGENTA}🚪 Default Gateway:${RESET}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
default_gw=$(ip route | grep default | awk '{print $3, "via", $5}')
if [ -n "$default_gw" ]; then
    gateway_ip=$(echo $default_gw | awk '{print $1}')
    gateway_dev=$(echo $default_gw | awk '{print $3}')
    echo -e "  ${CYAN}$gateway_ip${RESET} ${GRAY}via${RESET} ${YELLOW}$gateway_dev${RESET}"
else
    echo -e "  ${RED}No default gateway configured${RESET}"
fi
echo

# Routing table
echo -e "${BOLD}${BLUE}🗺️  Routing Table:${RESET}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
ip r | while read line; do
    if [[ $line == default* ]]; then
        # Highlight default route in green
        echo -e "  ${GREEN}$line${RESET}"
    elif [[ $line == *"linkdown"* ]]; then
        # Gray out inactive routes
        echo -e "  ${GRAY}$line${RESET}"
    else
        # Regular routes
        echo -e "  $line"
    fi
done
echo

# DNS servers
echo -e "${BOLD}${YELLOW}🔍 DNS Servers:${RESET}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
if [ -f /etc/resolv.conf ]; then
    grep "^nameserver" /etc/resolv.conf | awk -v cyan="$CYAN" -v reset="$RESET" -v gray="$GRAY" '{printf "  %s%d.%s %s%s%s\n", gray, NR, reset, cyan, $2, reset}'
else
    echo -e "  ${RED}No DNS configuration found${RESET}"
fi
echo

# Public IP (if connected)
echo -e "${BOLD}${GREEN}🌍 Public IP Address:${RESET}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
public_ip=$(timeout 2 curl -s ifconfig.me 2>/dev/null)
if [ -n "$public_ip" ]; then
    echo -e "  ${CYAN}$public_ip${RESET}"
else
    echo -e "  ${YELLOW}Unable to fetch (not connected or timeout)${RESET}"
fi
echo

# Network statistics
echo -e "${BOLD}${MAGENTA}📊 Connection Summary:${RESET}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
active_count=$(ip -brief a | grep -c "UP")
echo -e "  ${WHITE}Active interfaces:${RESET} ${GREEN}$active_count${RESET}"
if command -v ss &> /dev/null; then
    established=$(ss -tan | grep ESTAB | wc -l)
    listening=$(ss -tln | grep LISTEN | wc -l)
    echo -e "  ${WHITE}Established connections:${RESET} ${CYAN}$established${RESET}"
    echo -e "  ${WHITE}Listening ports:${RESET} ${YELLOW}$listening${RESET}"
fi
echo

# Ask if user wants to see detailed port info
echo -e "${GRAY}Show detailed listening ports? (y/n)${RESET}"
read -t 5 -n 1 -r show_ports
echo

if [[ $show_ports =~ ^[Yy]$ ]]; then
    echo
    echo -e "${BOLD}${CYAN}🔌 Listening Ports & Services:${RESET}"
    echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
    
    if command -v ss &> /dev/null; then
        # Header
        printf "${WHITE}%-6s %-22s %-22s %s${RESET}\n" "Proto" "Local Address:Port" "Process" "PID"
        echo -e "${GRAY}─────────────────────────────────────────────────────────────────${RESET}"
        
        # Run ss -tulpn and format output
        sudo ss -tulpn 2>/dev/null | grep LISTEN | while read -r line; do
            proto=$(echo "$line" | awk '{print $1}')
            local=$(echo "$line" | awk '{print $5}')
            process=$(echo "$line" | awk '{print $7}' | sed 's/users:((//' | sed 's/))//' | cut -d',' -f1)
            pid=$(echo "$line" | awk '{print $7}' | grep -oP 'pid=\K[0-9]+')
            
            # Color code by protocol
            if [[ $proto == tcp* ]]; then
                printf "${GREEN}%-6s${RESET} ${CYAN}%-22s${RESET} ${YELLOW}%-22s${RESET} ${WHITE}%s${RESET}\n" "$proto" "$local" "$process" "$pid"
            else
                printf "${BLUE}%-6s${RESET} ${CYAN}%-22s${RESET} ${YELLOW}%-22s${RESET} ${WHITE}%s${RESET}\n" "$proto" "$local" "$process" "$pid"
            fi
        done
        echo
        echo -e "${GRAY}Note: Requires sudo for process names${RESET}"
    else
        echo -e "  ${RED}ss command not available${RESET}"
    fi
    echo
fi
