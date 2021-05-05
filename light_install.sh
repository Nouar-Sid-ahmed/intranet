#!/bin/bash

# Installation des prés requit
echo "==> Installation des prés requit:"
echo ""
apt update
apt install iptables-persistent -Y
apt install isc-dhcp-server -Y
apt install dnsmasq -Y
apt install nginx -Y
apt install fail2ban -Y
apt update
apt upgrade
echo ""

echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug enp0s8
iface enp0s8 inet static
address 10.242.0.1
netmask 255.255.0.0
allow-hotplug enp0s3
iface enp0s3 inet dhcp
" > /etc/network/interfaces

/usr/sbin/ifup enp0s3 enp0s8

/sbin/sysctl net.ipv4.ip_forward=1

sudo /sbin/iptables -t nat -A POSTROUTING ! -d 10.242.0.0/16 -o enp0s3 -j MASQUERADE

iptables-save > /etc/iptables/rules.v4

echo "# Defaults for isc-dhcp-server (sourced by /etc/init.d/isc-dhcp-server)

# Path to dhcpd's config file (default: /etc/dhcp/dhcpd.conf).
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
#DHCPDv6_CONF=/etc/dhcp/dhcpd6.conf

# Path to dhcpd's PID file (default: /var/run/dhcpd.pid).
#DHCPDv4_PID=/var/run/dhcpd.pid
#DHCPDv6_PID=/var/run/dhcpd6.pid

# Additional options to start dhcpd with.
#       Don't use options -cf or -pf here; use DHCPD_CONF/ DHCPD_PID instead
#OPTIONS=""

# On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
#       Separate multiple interfaces with spaces, e.g. \"eth0 eth1\".
INTERFACESv4=\"enp0s8\"
INTERFACESv6=\"\"
" > /etc/default/isc-dhcp-server

echo "
# dhcpd.conf
#
# Sample configuration file for ISC dhcpd

option domain-name \"LePetitRobinson\";
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;

authoritative;

subnet 10.242.0.0 netmask 255.255.0.0 {
option routers 10.242.0.1;
range 10.242.0.10 10.242.0.255;
  #option routers rtr-239-0-1.example.org, rtr-239-0-2.example.org;
}
" > /etc/dhcp/dhcpd.conf

systemctl start isc-dhcp-server

systemctl enable isc-dhcp-server

# Configuration de DnsMasq
echo "=> Configuration de dnsmasq"
echo "=> Configuration des paramètres dns"
echo "domain-needed
expand-hosts
bogus-priv
resolv-file=/etc/resolv.conf
user=dnsmasq
group=dnsmasq
addn-hosts=/etc/dnsmasq-hosts.conf
expand-hosts
 
interface=eth0
domain=client.res1.local
cache-size=0
 
" > /etc/dnsmasq.conf
 
echo "Configuration des paramètres DHCP"
echo "
log-dhcp
dhcp-range=10.242.0.10,10.242.0.255,24h
dhcp-option=option:netmask,255.255.0.0
dhcp-option=option:router,10.242.0.1
dhcp-option=option:domain-name,\"LePetitRobinson\"
" >> /etc/dnsmasq.conf
 
#On autorise les requêtes dns dans le firewall
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload
