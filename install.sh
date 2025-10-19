#!/bin/bash

# =================================================================
#      Universal IPv6 Tunnel Script (HUB & CLIENT) v1.0
# =================================================================

# --- Color Codes ---
C_RESET='\033[0m'
C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'

# --- Root Check ---
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${C_RED}[!] ERROR: This script must be run as root.${C_RESET}"
    echo -e "      Please use 'sudo' to execute.\n"
    exit 1
fi

# --- Global Subnet Definitions ---
declare -a IPV6_SUBNETS=("fd45:f7a7:539a" "fda5:d72a:4e2f" "fd11:e4fd:f055" "fd76:2917:72d9" "fdce:8ee9:a813")
declare -a IPV4_SUBNETS=("172.16.1" "172.16.2" "172.16.3" "172.16.4" "172.16.5")

# --- Function: Cleanup HUB (Kharej) ---
function cleanup_hub() {
    echo -e "${C_YELLOW}[*] Purging all HUB (Kharej) tunnels...${C_RESET}"
    for i in {1..5}; do
        ip link del "IRAN${i}_SIT" &>/dev/null
        ip link del "IRAN${i}_GRE" &>/dev/null
    done
    ip link del sit0 &>/dev/null
    ip link del ip6gre0 &>/dev/null
    iptables -t nat -F POSTROUTING &>/dev/null
    netfilter-persistent save &>/dev/null
    echo -e "${C_GREEN}[+] HUB cleanup complete.${C_RESET}"
}

# --- Function: Cleanup CLIENT (Iran) ---
function cleanup_client() {
    echo -e "${C_YELLOW}[*] Purging all CLIENT (Iran) tunnels...${C_RESET}"
    ip link del KHAREJ_SIT &>/dev/null
    ip link del KHAREJ_GRE &>/dev/null
    ip link del TUNNEL_IRAN_SIT &>/dev/null
    ip link del TUNNEL_IRAN_GRE &>/dev/null
    ip link del sit0 &>/dev/null
    ip link del ip6gre0 &>/dev/null
    iptables -t nat -F POSTROUTING &>/dev/null
    netfilter-persistent save &>/dev/null
    echo -e "${C_GREEN}[+] CLIENT cleanup complete.${C_RESET}"
}

# --- Function: Setup HUB (Kharej) ---
function setup_hub() {
    clear
    echo -e "${C_CYAN}=== HUB Server (Kharej) Setup ===${C_RESET}\n"
    read -p ">> Enter Public IP for this HUB Server: " IP_KHAREJ
    read -p ">> Enter Public Interface Name (e.g., eth0, ens160): " IFACE_NAME

    if [ -z "$IP_KHAREJ" ] || [ -z "$IFACE_NAME" ]; then
        echo -e "\n${C_RED}[!] FATAL: IP Address and Interface Name are required. Aborting.${C_RESET}"
        exit 1
    fi

    declare -a IP_IRAN_LIST
    echo ""
    for i in {1..5}; do
        read -p ">> Enter Public IP for CLIENT Server #$i: " current_ip
        if [ -z "$current_ip" ]; then
            echo -e "\n${C_RED}[!] FATAL: Client IP cannot be empty. Aborting.${C_RESET}"
            exit 1
        fi
        IP_IRAN_LIST+=("$current_ip")
    done

    cleanup_hub

    echo -e "\n${C_YELLOW}[*] Initializing network core & firewall...${C_RESET}"
    iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
    iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf

    echo -e "${C_YELLOW}[*] Deploying 5 secure tunnels...${C_RESET}"
    for i in {0..4}; do
        server_num=$((i + 1))
        IP_IRAN=${IP_IRAN_LIST[$i]}
        IPV6_PREFIX=${IPV6_SUBNETS[$i]}
        IPV4_PREFIX=${IPV4_SUBNETS[$i]}

        ip tunnel add "IRAN${server_num}_SIT" mode sit remote "$IP_IRAN" local "$IP_KHAREJ"
        ip -6 addr add "${IPV6_PREFIX}::1/64" dev "IRAN${server_num}_SIT"
        ip link set "IRAN${server_num}_SIT" mtu 1480 up
        ip -6 tunnel add "IRAN${server_num}_GRE" mode ip6gre remote "${IPV6_PREFIX}::2" local "${IPV6_PREFIX}::1"
        ip addr add "${IPV4_PREFIX}.1/30" dev "IRAN${server_num}_GRE"
        ip link set "IRAN${server_num}_GRE" mtu 1436 up
        echo -e "  ${C_GREEN}[+] Tunnel link to Client #$server_num established.${C_RESET}"
    done

    iptables -t nat -A POSTROUTING -o "$IFACE_NAME" -j MASQUERADE
    netfilter-persistent save > /dev/null 2>&1
    
    echo -e "\n${C_GREEN}>>> [ HUB DEPLOYMENT COMPLETE ] <<<\n${C_RESET}"
}

# --- Function: Setup CLIENT (Iran) ---
function setup_client() {
    clear
    echo -e "${C_CYAN}=== CLIENT Server (Iran) Setup ===${C_RESET}\n"
    read -p ">> Which CLIENT number is this? (1-5): " SERVER_NUM
    
    # Validate input
    if ! [[ "$SERVER_NUM" =~ ^[1-5]$ ]]; then
        echo -e "\n${C_RED}[!] FATAL: Invalid selection. Must be a number between 1 and 5. Aborting.${C_RESET}"
        exit 1
    fi

    read -p ">> Enter this CLIENT's Public IP: " IP_IRAN
    read -p ">> Enter the HUB (Kharej) server's Public IP: " IP_KHAREJ
    read -p ">> Enter this server's Public Interface Name (e.g., eth0, ens160): " IFACE_NAME

    if [ -z "$IP_IRAN" ] || [ -z "$IP_KHAREJ" ] || [ -z "$IFACE_NAME" ]; then
        echo -e "\n${C_RED}[!] FATAL: All fields are required. Aborting.${C_RESET}"
        exit 1
    fi

    cleanup_client

    echo -e "\n${C_YELLOW}[*] Initializing network core & firewall...${C_RESET}"
    iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
    iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf

    # --- Get subnet info from array ---
    INDEX=$((SERVER_NUM - 1))
    IPV6_PREFIX=${IPV6_SUBNETS[$INDEX]}
    IPV4_PREFIX=${IPV4_SUBNETS[$INDEX]}

    echo -e "${C_YELLOW}[*] Deploying tunnel link to HUB...${C_RESET}"
    
    ip tunnel add KHAREJ_SIT mode sit remote "$IP_KHAREJ" local "$IP_IRAN"
    ip -6 addr add "${IPV6_PREFIX}::2/64" dev KHAREJ_SIT
    ip link set KHAREJ_SIT mtu 1480 up

    ip -6 tunnel add KHAREJ_GRE mode ip6gre remote "${IPV6_PREFIX}::1" local "${IPV6_PREFIX}::2"
    ip addr add "${IPV4_PREFIX}.2/30" dev KHAREJ_GRE
    ip link set KHAREJ_GRE mtu 1436 up

    iptables -t nat -A POSTROUTING -o "$IFACE_NAME" -j MASQUERADE
    netfilter-persistent save > /dev/null 2>&1

    echo -e "\n${C_GREEN}>>> [ CLIENT DEPLOYMENT COMPLETE ] <<<${C_RESET}"
    echo -e "This server is now connected to the HUB as Client #$SERVER_NUM.\n"
}

# --- Function: Purge Tunnels Menu ---
function purge_menu() {
    clear
    echo -e "${C_RED}=== PURGE ALL TUNNELS ===${C_RESET}\n"
    echo -e "${C_YELLOW}[!] WARNING: This will delete all tunnels managed by this script.${C_RESET}\n"
    echo "Which type of server is this?"
    echo "  [1] HUB Server (Kharej)"
    echo "  [2] CLIENT Server (Iran)"
    echo "  [3] Cancel"
    read -p "  >> Enter your choice [1-3]: " purge_choice

    case $purge_choice in
        1)
            cleanup_hub
            ;;
        2)
            cleanup_client
            G           ;;
        3)
            echo -e "\n${C_YELLOW}[*] Purge cancelled.${C_RESET}"
            ;;
        *)
            echo -e "\n${C_RED}[!] Invalid option. Aborting.${C_RESET}"
            ;;
    esac
}

# --- Main Menu ---
function main_menu() {
    clear
    echo -e "${C_CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║     ___  __  ___  __   __   __  ___  __   ___  __             ║"
    echo "  ║    |__  |  \|__  |  \ |  \ /  \  |  /  \ |__  |  \            ║"
    echo "  ║    |___ |__/|___ |__/ |__/ \__/  |  \__/ |___ |__/ ver 2.0    ║"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "${C_BLUE}                Universal Multi-Tunnel Management Script${C_RESET}"
    echo ""
    echo "  Select an operation:"
    echo ""
    echo -e "  ${C_GREEN}[1]${C_RESET} Setup as HUB Server (Kharej)"
    echo -e "  ${C_BLUE}[2]${C_RESET} Setup as CLIENT Server (Iran)"
    echo -e "  ${C_RED}[3]${C_RESET} Purge All Tunnels"
    echo -e "  ${C_YELLOW}[4]${C_RESET} Exit"
    echo ""
    read -p "  >> Enter your choice [1-4]: " choice
    
    case $choice in
        1)
            setup_hub
            ;;
        2)
            setup_client
            ;;
        3)
            purge_menu
            ;;
        4D           4)
            echo -e "\n${C_YELLOW}[*] Disconnecting... Stay safe.${C_RESET}\n"
            exit 0
            ;;
        *)
            echo -e "\n${C_RED}[!] Invalid option. Please try again.${C_RESET}"
            sleep 2
            main_menu
            ;;
    esac
}

# --- Execute Main Menu ---
main_menu
