#!/bin/bash

# Installation des prés requit
echo "==> Installation des prés requit:"
echo ""
apt update
apt install iptables-persistent
apt install isc-dhcp-server
apt install dnsmasq
apt install nginx
apt install fail2ban
apt update
apt upgrade
echo ""

# Configuré notre réseau
echo "nameserver 8.8.8.8" > /etc/resolve.conf

if [ "$SetGateway" = "true" ];then
    echo ">>> operation steel active <<<"
else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Configuaration des IPtables
if [ "$SetGateway" = "true" ];then
    echo ">>> operation steel active <<<"
else
    echo "=> Configuaration des IPtables"
    /sbin/sysctl net.ipv4.ip_forward=1
    /sbin/iptables -t nat -A POSTROUTING ! -d 192.168.0.2/24 -o enp0s3 -j MASQUERADE
fi

# Sauvegarde des IPtables
if [ "$SetGateway" = "true" ];then
    echo ">>> operation steel active <<<"
else
    echo "=> sauvegarde des IPtables"
    /sbin/iptables-save > /etc/iptables/rules.v4
fi

# Configuration du dhcpd
echo "=> Configuration du dhcp server"
echo "INTERFACESv4=\"enp0s3\"
INTERFACESv6=\"\"
" > /etc/default/isc-dhcp-server

echo "=> Configuration du dhcpd conf"

echo "# dhcpd.conf

option domain-name \"res1.local\";
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;

authoritative;

subnet  192.168.0.2 netmask 255.255.255.0 {
   option routers  192.168.0.2;
   range  192.168.0.10  192.168.0.110;
}
" > /etc/dhcp/dhcpd.conf

echo "=> Démarage du serveur dhcp"
systemctl start isc-dhcp-server

echo "=> Ajout du service au démarrage"
systemctl enable isc-dhcp-server

# Configuration de DnsMasq
echo "=> Configuration de DnsMasq"
echo "domain-needed
expand-hosts
bogus-priv

interface=eth0
domain=client.res1.local
cache-size=0

dhcp-range=192.168.0.10,192.168.0.110,24h
" > /etc/dnsmasq.conf

echo "=> Démarage du serveur DnsMasq"
/etc/init.d/dnsmasq restart

echo "=> Ajout du service au démarrage"
/etc/init.d/dnsmasq enable

# Configuration de l'interface Web
echo "=> Configuration de l'interface Web"
rm /var/www/http/index.http
touch /var/www/http/index.http
echo "Hello World" > /var/www/http/index.http
rm /var/www/private/index.http
touch /var/www/private/index.http
echo "Hello Admin" > /var/www/private/index.http

# Configuration de fail2ban
echo "=> Création de l'utilisateur tester avec le mots de passe password"
sudo sh -c "echo -n 'tester:password' >> /etc/nginx/.htpasswd"
echo ""
echo "=> Configuration de fail2ban"
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www;
        index index.html index.htm index.nginx-debian.html;
        server_name localhost;
        location /http {
                 try_files $uri $uri/ =404;
                 server_name              web.res1.local;
        }
        location /private {
        	 try_files $uri $uri/ =404;
                 server_name              admin.res1.local;
                 auth_basic               \"Administrator's Area\";
                 auth_basic_user_file     /etc/nginx/conf.d/.htpasswd;	
        }
        location /*.php {
		 deny all;
        }
}" > /etc/nginx/sites-available/default

echo "[Definition]
action = iptables-multiport[name=banbadrequests, port=\"http,https\", protocol=tcp]

[banbadrequest]
enabled = true
port = http,https
filter = banbadrequest
logpath = /var/log/nginx/error.log
logpath = /var/log/nginx/access.log
maxretry = 3

[apache-noscript]

enabled  = true" >> /etc/fail2ban/jail.conf

if [ "$SetWeb" = "true" ];then
    echo ">>> operation steel active <<<"
else
    echo "=> Demarage de fail2ban"
    systemctl start fail2ban
    systemctl enable fail2ban
fi

# Fin de l'installation
echo ""
echo "===== configuration terminé                                                            ====="
echo ""
echo "=> redémarage"
i=5
s=true
while $s
do
    echo "=> $i"
    sleep 1
    i=$(($i-1))
    if [ $i -lt 1 ]
    then
        s=false
    fi
done
systemctl reboot
