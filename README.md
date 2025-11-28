<div align="center">

# 🌐 Multi-Local Tunneling
### اتصال پایدار و امن: ۱ سرور خارج ↔ ۵ سرور ایران
استفاده از تکنولوژی‌های **SIT (6to4)** و **IP6GRE** برای ایجاد شبکه خصوصی

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/OS-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![IPv6](https://img.shields.io/badge/Network-IPv6-blue?style=for-the-badge&logo=internet-explorer&logoColor=white)

</div>

---

## 📖 درباره پروژه
این پروژه راهکاری برای ایجاد یک شبکه تونلینگ پایدار بین **یک سرور مرکزی (خارج)** و **پنج سرور کلاینت (ایران)** است. با استفاده از این اسکریپت‌ها، تداخلات معمول روتینگ برطرف شده و ارتباط امن از طریق IPv6 برقرار می‌شود.

### 🗺️ معماری شبکه
```mermaid
graph TD
    K[🌍 سرور خارج (Center)]
    I1[🇮🇷 سرور ایران ۱]
    I2[🇮🇷 سرور ایران ۲]
    I3[🇮🇷 سرور ایران ۳]
    I4[🇮🇷 سرور ایران ۴]
    I5[🇮🇷 سرور ایران ۵]

    K <==>|Tunnel 1| I1
    K <==>|Tunnel 2| I2
    K <==>|Tunnel 3| I3
    K <==>|Tunnel 4| I4
    K <==>|Tunnel 5| I5
```

---

## 🚀 نصب سریع (Auto Install)
اگر حوصله تنظیمات دستی را ندارید، از دستور زیر استفاده کنید:

```bash
bash <(curl -sL [https://raw.githubusercontent.com/a-salemi/multi-local/main/ir7.sh](https://raw.githubusercontent.com/a-salemi/multi-local/main/ir7.sh))
```

---

## 🛠️ پیش‌نیازها (روی تمام سرورها)
قبل از شروع، پکیج `iptables-persistent` را روی **تمام ۶ سرور** نصب کنید تا تنظیمات بعد از ریبوت باقی بمانند.

```bash
apt-get update && apt-get install -y iptables-persistent
```
> **نکته:** در حین نصب، به هر دو سوال (`Save IPv4/IPv6 rules`) پاسخ **Yes** بدهید.

---

## ⚙️ بخش اول: تنظیمات سرور خارج (Center)
فایل `/etc/rc.local` را ویرایش کرده و اسکریپت زیر را جایگزین کنید.
*(فراموش نکنید که IPهای داخل اسکریپت را با IPهای واقعی خود جایگزین کنید)*

```bash
nano /etc/rc.local
```

<details>
<summary><b>📄 مشاهده کد کامل سرور خارج (کلیک کنید)</b></summary>

```bash
#!/bin/bash

# =================================================================
#            اسکریپت نهایی و کامل برای سرور خارج (مرکزی)
# =================================================================

# --- بخش ۱: تعریف آدرس‌های IP (این بخش را ویرایش کنید) ---
IP_KHAREJ="91.107.xxx.xxx"
IP_IRAN_1="178.239.xxx.xxx"
IP_IRAN_2="178.239.xxx.xxx"
IP_IRAN_3="178.239.xxx.xxx"
IP_IRAN_4="178.239.xxx.xxx"
IP_IRAN_5="178.239.xxx.xxx"

# --- بخش ۲: پاکسازی و تنظیم اولیه فایروال ---
iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

# --- بخش ۳: ساخت تونل‌ها ---

# تونل سرور ایران ۱
ip tunnel add IRAN1_SIT mode sit remote $IP_IRAN_1 local $IP_KHAREJ
ip -6 addr add fd45:f7a7:539a::1/64 dev IRAN1_SIT
ip link set IRAN1_SIT mtu 1480 up
ip -6 tunnel add IRAN1_GRE mode ip6gre remote fd45:f7a7:539a::2 local fd45:f7a7:539a::1
ip addr add 172.16.1.1/30 dev IRAN1_GRE
ip link set IRAN1_GRE mtu 1436 up

# تونل سرور ایران ۲
ip tunnel add IRAN2_SIT mode sit remote $IP_IRAN_2 local $IP_KHAREJ
ip -6 addr add fda5:d72a:4e2f::1/64 dev IRAN2_SIT
ip link set IRAN2_SIT mtu 1480 up
ip -6 tunnel add IRAN2_GRE mode ip6gre remote fda5:d72a:4e2f::2 local fda5:d72a:4e2f::1
ip addr add 172.16.2.1/30 dev IRAN2_GRE
ip link set IRAN2_GRE mtu 1436 up

# تونل سرور ایران ۳
ip tunnel add IRAN3_SIT mode sit remote $IP_IRAN_3 local $IP_KHAREJ
ip -6 addr add fd11:e4fd:f055::1/64 dev IRAN3_SIT
ip link set IRAN3_SIT mtu 1480 up
ip -6 tunnel add IRAN3_GRE mode ip6gre remote fd11:e4fd:f055::2 local fd11:e4fd:f055::1
ip addr add 172.16.3.1/30 dev IRAN3_GRE
ip link set IRAN3_GRE mtu 1436 up

# تونل سرور ایران ۴
ip tunnel add IRAN4_SIT mode sit remote $IP_IRAN_4 local $IP_KHAREJ
ip -6 addr add fd76:2917:72d9::1/64 dev IRAN4_SIT
ip link set IRAN4_SIT mtu 1480 up
ip -6 tunnel add IRAN4_GRE mode ip6gre remote fd76:2917:72d9::2 local fd76:2917:72d9::1
ip addr add 172.16.4.1/30 dev IRAN4_GRE
ip link set IRAN4_GRE mtu 1436 up

# تونل سرور ایران ۵
ip tunnel add IRAN5_SIT mode sit remote $IP_IRAN_5 local $IP_KHAREJ
ip -6 addr add fdce:8ee9:a813::1/64 dev IRAN5_SIT
ip link set IRAN5_SIT mtu 1480 up
ip -6 tunnel add IRAN5_GRE mode ip6gre remote fdce:8ee9:a813::2 local fdce:8ee9:a813::1
ip addr add 172.16.5.1/30 dev IRAN5_GRE
ip link set IRAN5_GRE mtu 1436 up

# --- بخش ۴: ذخیره نهایی ---
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save

exit 0
```
</details>

**فعال‌سازی:**
```bash
chmod +x /etc/rc.local
/etc/rc.local
```

---

## 🇮🇷 بخش دوم: تنظیمات سرورهای ایران (Clients)
اسکریپت مربوط به هر سرور را در فایل `/etc/rc.local` همان سرور قرار دهید.

<details>
<summary><b>1️⃣ سرور ایران ۱ (کلیک کنید)</b></summary>

```bash
#!/bin/bash
IP_IRAN="178.239.xxx.xxx"
IP_KHAREJ="91.107.xxx.xxx"

iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

ip tunnel add KHAREJ_SIT mode sit remote $IP_KHAREJ local $IP_IRAN
ip -6 addr add fd45:f7a7:539a::2/64 dev KHAREJ_SIT
ip link set KHAREJ_SIT mtu 1480 up
ip -6 tunnel add KHAREJ_GRE mode ip6gre remote fd45:f7a7:539a::1 local fd45:f7a7:539a::2
ip addr add 172.16.1.2/30 dev KHAREJ_GRE
ip link set KHAREJ_GRE mtu 1436 up
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save
exit 0
```
</details>

<details>
<summary><b>2️⃣ سرور ایران ۲ (کلیک کنید)</b></summary>

```bash
#!/bin/bash
IP_IRAN="178.239.xxx.xxx"
IP_KHAREJ="91.107.xxx.xxx"

iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

ip tunnel add KHAREJ_SIT mode sit remote $IP_KHAREJ local $IP_IRAN
ip -6 addr add fda5:d72a:4e2f::2/64 dev KHAREJ_SIT
ip link set KHAREJ_SIT mtu 1480 up
ip -6 tunnel add KHAREJ_GRE mode ip6gre remote fda5:d72a:4e2f::1 local fda5:d72a:4e2f::2
ip addr add 172.16.2.2/30 dev KHAREJ_GRE
ip link set KHAREJ_GRE mtu 1436 up
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save
exit 0
```
</details>

<details>
<summary><b>3️⃣ سرور ایران ۳ (کلیک کنید)</b></summary>

```bash
#!/bin/bash
IP_IRAN="178.239.xxx.xxx"
IP_KHAREJ="91.107.xxx.xxx"

iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

ip tunnel add KHAREJ_SIT mode sit remote $IP_KHAREJ local $IP_IRAN
ip -6 addr add fd11:e4fd:f055::2/64 dev KHAREJ_SIT
ip link set KHAREJ_SIT mtu 1480 up
ip -6 tunnel add KHAREJ_GRE mode ip6gre remote fd11:e4fd:f055::1 local fd11:e4fd:f055::2
ip addr add 172.16.3.2/30 dev KHAREJ_GRE
ip link set KHAREJ_GRE mtu 1436 up
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save
exit 0
```
</details>

<details>
<summary><b>4️⃣ سرور ایران ۴ (کلیک کنید)</b></summary>

```bash
#!/bin/bash
IP_IRAN="178.239.xxx.xxx"
IP_KHAREJ="91.107.xxx.xxx"

iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

ip tunnel add KHAREJ_SIT mode sit remote $IP_KHAREJ local $IP_IRAN
ip -6 addr add fd76:2917:72d9::2/64 dev KHAREJ_SIT
ip link set KHAREJ_SIT mtu 1480 up
ip -6 tunnel add KHAREJ_GRE mode ip6gre remote fd76:2917:72d9::1 local fd76:2917:72d9::2
ip addr add 172.16.4.2/30 dev KHAREJ_GRE
ip link set KHAREJ_GRE mtu 1436 up
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save
exit 0
```
</details>

<details>
<summary><b>5️⃣ سرور ایران ۵ (کلیک کنید)</b></summary>

```bash
#!/bin/bash
IP_IRAN="178.239.xxx.xxx"
IP_KHAREJ="91.107.xxx.xxx"

iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

ip tunnel add KHAREJ_SIT mode sit remote $IP_KHAREJ local $IP_IRAN
ip -6 addr add fdce:8ee9:a813::2/64 dev KHAREJ_SIT
ip link set KHAREJ_SIT mtu 1480 up
ip -6 tunnel add KHAREJ_GRE mode ip6gre remote fdce:8ee9:a813::1 local fdce:8ee9:a813::2
ip addr add 172.16.5.2/30 dev KHAREJ_GRE
ip link set KHAREJ_GRE mtu 1436 up
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save
exit 0
```
</details>

**فعال‌سازی در سرورهای ایران:**
```bash
chmod +x /etc/rc.local
/etc/rc.local
```

---

## 🧪 تست و عیب‌یابی (Testing)

### 📌 پینگ گرفتن از داخل سرورهای ایران
برای اطمینان از صحت اتصال، دستورات زیر را در هر سرور اجرا کنید:

| سرور | IPv4 پینگ | IPv6 پینگ |
| :--- | :--- | :--- |
| **ایران ۱** | `ping 172.16.1.2` | `ping fd45:f7a7:539a::2` |
| **ایران ۲** | `ping 172.16.2.2` | `ping fda5:d72a:4e2f::2` |
| **ایران ۳** | `ping 172.16.3.2` | `ping fd11:e4fd:f055::2` |
| **ایران ۴** | `ping 172.16.4.2` | `ping fd76:2917:72d9::2` |
| **ایران ۵** | `ping 172.16.5.2` | `ping fdce:8ee9:a813::2` |

اگر پینگ دارید، تبریک! شبکه شما آماده است. 🎉
