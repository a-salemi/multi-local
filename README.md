# Multi-Local
راه‌اندازی تونل IPv6 (اتصال ۱ سرور خارج به ۵ سرور ایران)
این راهنما به شما کمک می‌کند تا با استفاده از تونل‌های SIT (6to4) و IP6GRE، یک شبکه‌ی خصوصی و امن بین یک سرور خارج (به عنوان مرکز) و پنج سرور ایران (به عنوان کلاینت) ایجاد کنید.

# نصب خودکار ( فقط سرور خارج ) :
```
bash <(curl -sL https://raw.githubusercontent.com/a-salemi/multi-local/main/kharej-tunnel.sh)
```





بخش اول: پیش‌نیاز (برای تمام سرورها)
قبل از هر کاری، باید ابزار لازم برای ذخیره دائمی تنظیمات فایروال را نصب کنیم. این دستور را روی تمام ۶ سرور اجرا کنید.



```
apt-get update && apt-get install -y iptables-persistent
```
نکته: در حین نصب، برای هر دو سوالی که پرسیده می‌شود (Save current IPv4 rules? و Save current IPv6 rules?)، گزینه‌ی <Yes> را انتخاب کنید.

بخش دوم: تنظیمات سرور خارج (سرور مرکزی)
این اسکریپت کامل و بی‌نقص برای سرور اصلی شما است. تمام مشکلات قبلی مانند تداخل نام و قوانین فایروال در آن حل شده است.

۱. ایجاد فایل تنظیمات
دستور زیر را برای ایجاد و ویرایش فایل rc.local در سرور خارج اجرا کنید:

```
nano /etc/rc.local
```
۲. کپی کردن اسکریپت
محتوای زیر را به طور کامل در فایل rc.local کپی کنید.

```
#!/bin/bash

# =================================================================
#           اسکریپت نهایی و کامل برای سرور خارج (مرکزی)
# =================================================================

# --- بخش ۱: تعریف آدرس‌های IP ---
IP_KHAREJ="91.107.xxx.xxx"
IP_IRAN_1="178.239.xxx.xxx"
IP_IRAN_2="178.239.xxx.xxx"
IP_IRAN_3="178.239.xxx.xxx"
IP_IRAN_4="178.239.xxx.xxx"
IP_IRAN_5="178.239.xxx.xxx"

# --- بخش ۲: پاکسازی و تنظیم اولیه فایروال ---
iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X;
iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT;

# --- بخش ۳: ساخت تونل‌ها با نام‌های منحصر به فرد ---

# تونل برای سرور ایران ۱
ip tunnel add IRAN1_SIT mode sit remote $IP_IRAN_1 local $IP_KHAREJ
ip -6 addr add fd45:f7a7:539a::1/64 dev IRAN1_SIT
ip link set IRAN1_SIT mtu 1480 up
ip -6 tunnel add IRAN1_GRE mode ip6gre remote fd45:f7a7:539a::2 local fd45:f7a7:539a::1
ip addr add 172.16.1.1/30 dev IRAN1_GRE
ip link set IRAN1_GRE mtu 1436 up

# تونل برای سرور ایران ۲
ip tunnel add IRAN2_SIT mode sit remote $IP_IRAN_2 local $IP_KHAREJ
ip -6 addr add fda5:d72a:4e2f::1/64 dev IRAN2_SIT
ip link set IRAN2_SIT mtu 1480 up
ip -6 tunnel add IRAN2_GRE mode ip6gre remote fda5:d72a:4e2f::2 local fda5:d72a:4e2f::1
ip addr add 172.16.2.1/30 dev IRAN2_GRE
ip link set IRAN2_GRE mtu 1436 up

# تونل برای سرور ایران ۳
ip tunnel add IRAN3_SIT mode sit remote $IP_IRAN_3 local $IP_KHAREJ
ip -6 addr add fd11:e4fd:f055::1/64 dev IRAN3_SIT
ip link set IRAN3_SIT mtu 1480 up
ip -6 tunnel add IRAN3_GRE mode ip6gre remote fd11:e4fd:f055::2 local fd11:e4fd:f055::1
ip addr add 172.16.3.1/30 dev IRAN3_GRE
ip link set IRAN3_GRE mtu 1436 up

# تونل برای سرور ایران ۴
ip tunnel add IRAN4_SIT mode sit remote $IP_IRAN_4 local $IP_KHAREJ
ip -6 addr add fd76:2917:72d9::1/64 dev IRAN4_SIT
ip link set IRAN4_SIT mtu 1480 up
ip -6 tunnel add IRAN4_GRE mode ip6gre remote fd76:2917:72d9::2 local fd76:2917:72d9::1
ip addr add 172.16.4.1/30 dev IRAN4_GRE
ip link set IRAN4_GRE mtu 1436 up

# تونل برای سرور ایران ۵
ip tunnel add IRAN5_SIT mode sit remote $IP_IRAN_5 local $IP_KHAREJ
ip -6 addr add fdce:8ee9:a813::1/64 dev IRAN5_SIT
ip link set IRAN5_SIT mtu 1480 up
ip -6 tunnel add IRAN5_GRE mode ip6gre remote fdce:8ee9:a813::2 local fdce:8ee9:a813::1
ip addr add 172.16.5.1/30 dev IRAN5_GRE
ip link set IRAN5_GRE mtu 1436 up

# --- بخش ۴: فعال‌سازی مسیریابی و ذخیره نهایی ---
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save

exit 0
```


# اجرای اسکریپت برای برقراری تونل
```
chmod +x /etc/rc.local
/etc/rc.local
```
بخش سوم: تنظیمات سرورهای ایران (کلاینت‌ها)
برای هر کدام از ۵ سرور ایران، اسکریپت مخصوص به خودش را در فایل /etc/rc.local آن سرور قرار دهید.

۱. اسکریپت سرور ایران ۱
IP: 178.239.xxx.xxx

```
nano /etc/rc.local
```

```
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


# اجرای اسکریپت برای برقراری تونل
```
chmod +x /etc/rc.local
/etc/rc.local
```
۲. اسکریپت سرور ایران ۲
IP: 178.239.xxx.xxx

```
nano /etc/rc.local
```

```
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


# اجرای اسکریپت برای برقراری تونل
```
chmod +x /etc/rc.local
/etc/rc.local
```
۳. اسکریپت سرور ایران ۳
IP: 178.239.xxx.xxx

```
nano /etc/rc.local
```

```
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


# اجرای اسکریپت برای برقراری تونل
```
chmod +x /etc/rc.local
/etc/rc.local
```
۴. اسکریپت سرور ایران ۴
IP: 178.239.xxx.xxx

```
nano /etc/rc.local
```

```
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


# اجرای اسکریپت برای برقراری تونل
```
chmod +x /etc/rc.local
/etc/rc.local
```
۵. اسکریپت سرور ایران ۵
IP: 178.239.xxx.xxx

```
nano /etc/rc.local
```

```
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


# اجرای اسکریپت برای برقراری تونل
```
chmod +x /etc/rc.local
/etc/rc.local
```
بخش چهارم: اجرا و تست نهایی
۱. اجرای اسکریپت‌ها
بعد از قرار دادن اسکریپت‌ها در فایل /etc/rc.local هر سرور، این دو دستور را به ترتیب روی تمام ۶ سرور اجرا کنید:




۲. تست اتصال
لیست ایپی های سرور های ایران ( لوکال ).


# سرور ایران 1

```
ping 172.16.1.2
```
```
ping fd45:f7a7:539a::2
```
# سرور ایران 2

```
ping 172.16.2.2
```
```
ping fda5:d72a:4e2f::2
```
# سرور ایران 3
```
ping 172.16.3.2
```
```
ping fd11:e4fd:f055::2
```
# سرور ایران 4
```
ping 172.16.4.2
```
```
ping fd76:2917:72d9::2
```
# سرور ایران 5
```
ping 172.16.5.2
```
```
ping fdce:8ee9:a813::2
```


اگر از تمام پینگ‌ها پاسخ گرفتید، شبکه‌ی شما با موفقیت کامل راه‌اندازی شده است. 🎉
