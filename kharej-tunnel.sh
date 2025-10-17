#!/bin/bash

# =================================================================
#        اسکریپت هوشمند مدیریت تونل (نسخه ۱.۰)
# =================================================================

# --- بررسی اجرای اسکریپت با دسترسی روت ---
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n\033[1;31mخطا: این اسکریپت باید با دسترسی روت (root) اجرا شود.\033[0m"
    echo -e "لطفاً با دستور 'sudo' آن را اجرا کنید.\n"
    exit 1
fi

# --- تابع پاکسازی تمام تونل‌های ساخته شده ---
function delete_all_tunnels() {
    echo -e "\n\033[1;33mدر حال حذف تمام تونل‌های قبلی...\033[0m"
    for i in {1..5}; do
        ip link del "IRAN${i}_SIT" &>/dev/null
        ip link del "IRAN${i}_GRE" &>/dev/null
    done
    iptables -t nat -F POSTROUTING &>/dev/null
    netfilter-persistent save &>/dev/null
    echo -e "\033[1;32m✅ تمام تونل‌ها با موفقیت حذف شدند.\033[0m"
}

# --- تابع اصلی برای ساخت تونل‌ها ---
function create_tunnels() {
    # --- دریافت اطلاعات از کاربر ---
    echo ""
    read -p "لطفاً آدرس IP عمومی سرور خارج (همین سرور) را وارد کنید: " IP_KHAREJ
    if [ -z "$IP_KHAREJ" ]; then
        echo -e "\n\033[1;31mخطا: آدرس IP سرور خارج نمی‌تواند خالی باشد.\033[0m"
        exit 1
    fi

    # تعریف آرایه‌ها برای نگهداری اطلاعات
    declare -a IP_IRAN_LIST
    declare -a IPV6_SUBNETS=("fd45:f7a7:539a" "fda5:d72a:4e2f" "fd11:e4fd:f055" "fd76:2917:72d9" "fdce:8ee9:a813")
    declare -a IPV4_SUBNETS=("172.16.1" "172.16.2" "172.16.3" "172.16.4" "172.16.5")

    echo ""
    for i in {1..5}; do
        read -p "آدرس IP عمومی سرور ایران شماره $i را وارد کنید: " current_ip
        if [ -z "$current_ip" ]; then
            echo -e "\n\033[1;31mخطا: آدرس IP سرور ایران نمی‌تواند خالی باشد.\033[0m"
            exit 1
        fi
        IP_IRAN_LIST+=("$current_ip")
    done

    # --- پاکسازی قبل از ساخت ---
    delete_all_tunnels

    # --- تنظیمات اولیه فایروال و شبکه ---
    echo -e "\n\033[1;33mدر حال انجام تنظیمات اولیه شبکه و فایروال...\033[0m"
    iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
    iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf

    # --- حلقه ساخت تونل‌ها ---
    echo -e "\033[1;33mدر حال ساخت ۵ تونل...\033[0m"
    for i in {0..4}; do
        server_num=$((i + 1))
        IP_IRAN=${IP_IRAN_LIST[$i]}
        IPV6_PREFIX=${IPV6_SUBNETS[$i]}
        IPV4_PREFIX=${IPV4_SUBNETS[$i]}

        # ساخت تونل SIT
        ip tunnel add "IRAN${server_num}_SIT" mode sit remote "$IP_IRAN" local "$IP_KHAREJ"
        ip -6 addr add "${IPV6_PREFIX}::1/64" dev "IRAN${server_num}_SIT"
        ip link set "IRAN${server_num}_SIT" mtu 1480 up

        # ساخت تونل GRE
        ip -6 tunnel add "IRAN${server_num}_GRE" mode ip6gre remote "${IPV6_PREFIX}::2" local "${IPV6_PREFIX}::1"
        ip addr add "${IPV4_PREFIX}.1/30" dev "IRAN${server_num}_GRE"
        ip link set "IRAN${server_num}_GRE" mtu 1436 up
        echo " تونل برای سرور $server_num با موفقیت ساخته شد."
    done

    # --- تنظیمات نهایی و ذخیره ---
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    netfilter-persistent save > /dev/null 2>&1
    
    # --- نمایش جدول نهایی اطلاعات ---
    echo -e "\n\033[1;32m===============================================================================\033[0m"
    echo -e "\033[1;32m            ✅ عملیات با موفقیت انجام شد! مشخصات تونل‌ها: ✅\033[0m"
    echo -e "\033[1;32m===============================================================================\033[0m"
    printf "\033[1;34m%-10s | %-20s | %-20s | %-30s\n\033[0m" "سرور" "IP عمومی ایران" "IP داخلی (IPv4)" "IP داخلی (IPv6)"
    echo -e "\033[1;32m-------------------------------------------------------------------------------\033[0m"
    for i in {0..4}; do
        server_num=$((i + 1))
        printf "%-10s | %-20s | %-20s | %-30s\n" \
               "ایران $server_num" \
               "${IP_IRAN_LIST[$i]}" \
               "${IPV4_SUBNETS[$i]}.2" \
               "${IPV6_SUBNETS[$i]}::2"
    done
    echo -e "\033[1;32m===============================================================================\033[0m\n"
}

# --- منوی اصلی اسکریپت ---
function main_menu() {
    clear
    echo -e "\033[1;36m"
    echo "=========================================="
    echo "       اسکریپت هوشمند مدیریت تونل"
    echo "=========================================="
    echo -e "\033[0m"
    echo "لطفاً گزینه‌ی مورد نظر خود را انتخاب کنید:"
    echo ""
    echo -e "  \033[1;32m1)\033[0m راه‌اندازی و ساخت تمام تونل‌ها"
    echo -e "  \033[1;31m2)\033[0m حذف تمام تونل‌های ساخته شده"
    echo -e "  \033[1;33m3)\033[0m خروج"
    echo ""
    read -p "گزینه (1-3): " choice
    
    case $choice in
        1)
            create_tunnels
            ;;
        2)
            delete_all_tunnels
            ;;
        3)
            echo -e "\n\033[1;33mخدا نگهدار!\033[0m\n"
            exit 0
            ;;
        *)
            echo -e "\n\033[1;31mخطا: گزینه‌ی نامعتبر!\033[0m"
            sleep 2
            main_menu
            ;;
    esac
}

# --- اجرای منوی اصلی ---
main_menu
