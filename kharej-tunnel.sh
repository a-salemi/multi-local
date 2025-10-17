#!/bin/bash

# ANSI Color Codes
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

# --- Function: Delete All Tunnels ---
function delete_all_tunnels() {
    echo -e "\n${C_YELLOW}[*] Terminating all existing tunnel interfaces...${C_RESET}"
    for i in {1..5}; do
        ip link del "IRAN${i}_SIT" &>/dev/null
        ip link del "IRAN${i}_GRE" &>/dev/null
    done
    iptables -t nat -F POSTROUTING &>/dev/null
    netfilter-persistent save &>/dev/null
    echo -e "${C_GREEN}[+] All tunnel links successfully purged from the system.${C_RESET}"
}

# --- Function: Create Tunnels ---
function create_tunnels() {
    echo ""
    read -p ">> Enter Public IP for this Host (HUB Server): " IP_KHAREJ
    if [ -z "$IP_KHAREJ" ]; then
        echo -e "\n${C_RED}[!] FATAL: Host IP cannot be empty. Aborting.${C_RESET}"
        exit 1
    fi

    declare -a IP_IRAN_LIST
    declare -a IPV6_SUBNETS=("fd45:f7a7:539a" "fda5:d72a:4e2f" "fd11:e4fd:f055" "fd76:2917:72d9" "fdce:8ee9:a813")
    declare -a IPV4_SUBNETS=("172.16.1" "172.16.2" "172.16.3" "172.16.4" "172.16.5")

    echo ""
    for i in {1..5}; do
        read -p ">> Enter Public IP for Iran Client Server #$i: " current_ip
        if [ -z "$current_ip" ]; then
            echo -e "\n${C_RED}[!] FATAL: Client IP cannot be empty. Aborting.${C_RESET}"
            exit 1
        fi
        IP_IRAN_LIST+=("$current_ip")
    done

    delete_all_tunnels

    echo -e "\n${C_YELLOW}[*] Initializing network core... Enabling IP Forwarding...${C_RESET}"
    iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
    iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf

    echo -e "${C_YELLOW}[*] Deploying 5 secure tunnels... Stand by...${C_RESET}"
    for i in {0..4}; do
        server_num=$((i + 1))
        IP_IRAN=${IP_IRAN_LIST[$i]}
        IPV6_PREFIX=${IPV6_SUBNETS[$i]}
        IPV4_PREFIX=${IPV4_SUBNETS[$i]}

        # SIT Tunnel Deployment
        ip tunnel add "IRAN${server_num}_SIT" mode sit remote "$IP_IRAN" local "$IP_KHAREJ"
        ip -6 addr add "${IPV6_PREFIX}::1/64" dev "IRAN${server_num}_SIT"
        ip link set "IRAN${server_num}_SIT" mtu 1480 up

        # GRE Tunnel Deployment
        ip -6 tunnel add "IRAN${server_num}_GRE" mode ip6gre remote "${IPV6_PREFIX}::2" local "${IPV6_PREFIX}::1"
        ip addr add "${IPV4_PREFIX}.1/30" dev "IRAN${server_num}_GRE"
        ip link set "IRAN${server_num}_GRE" mtu 1436 up
        echo -e "  ${C_GREEN}[+] Tunnel link to Client #$server_num established.${C_RESET}"
    done

    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    netfilter-persistent save > /dev/null 2>&1
    
    echo -e "\n${C_GREEN}================================================================================${C_RESET}"
    echo -e "${C_GREEN}     >>> [ DEPLOYMENT COMPLETE: NETWORK MAPPING ESTABLISHED ] <<<${C_RESET}"
    echo -e "${C_GREEN}================================================================================${C_RESET}"
    printf "${C_CYAN}%-12s | %-18s | %-18s | %-32s\n${C_RESET}" "CLIENT" "PUBLIC IP" "LOCAL IP (v4)" "LOCAL IP (v6)"
    echo -e "${C_BLUE}-------------+--------------------+--------------------+----------------------------------${C_RESET}"
    for i in {0..4}; do
        server_num=$((i + 1))
        printf "%-12s | %-18s | %-18s | %-32s\n" \
               "Iran #$server_num" \
               "${IP_IRAN_LIST[$i]}" \
               "${IPV4_SUBNETS[$i]}.2" \
               "${IPV6_SUBNETS[$i]}::2"
    done
    echo -e "${C_GREEN}================================================================================${C_RESET}\n"
}

# --- Main Menu ---
function main_menu() {
    clear
    echo -e "${C_CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║     ___  __  ___  __   __   __  ___  __   ___  __             ║"
    echo "  ║    |__  |  \|__  |  \ |  \ /  \  |  /  \ |__  |  \            ║"
    echo "  ║    |___ |__/|___ |__/ |__/ \__/  |  \__/ |___ |__/ ver 1.0    ║"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -e "${C_BLUE}                  A Multi-Tunnel Management Interface${C_RESET}"
    echo ""
    echo "  Select an operation:"
    echo ""
    echo -e "  ${C_GREEN}[1]${C_RESET} Deploy & Configure All Tunnels"
    echo -e "  ${C_RED}[2]${C_RESET} Purge All Existing Tunnels"
    echo -e "  ${C_YELLOW}[3]${C_RESET} Exit"
    echo ""
    read -p "  >> Enter your choice [1-3]: " choice
    
    case $choice in
        1)
            create_tunnels
            ;;
        2)
            delete_all_tunnels
            ;;
        3)
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
