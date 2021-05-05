# Étape 1 : Creation de la VM template

Dans cette étape, je vais installer une VM et la configurer

## Installation de la VM

ajout du nom de celle-ci et de ses caractéristiques nottamenent ici ou on choisis l'option Linux et debian x64.

## Configuration de la VM

* Tout d'abord, vous devrez installer sudo
```
su
```
```
apt-get install sudo
```
```
chmod +w /etc/sudoers
```
```
nano /etc/sudoers
```
* Dans le fichier, ajoutez après la ligne 20 la même ligne, mais avec votre utilisateur au lieu de root. Disons que votre utilisateur l'est toto, et le résultat devrait ressembler à ceci:
```
# User privilege specification
root	ALL=(ALL:ALL) ALL
toto	ALL=(ALL:ALL) ALL
```
## Clonage du Template

changement des noms de celle-ci en gateway,web,manager et client.
## Connection aux gateway

* allez dans les configurations réseau de votre gateway réglé:
* adapter 1 sur:
```
Accés par pont
```
```
en0: Wi-Fi (AirPort)
```
* adapter 2 sur:
```
Réseau privé hôte
```
```
vboxnet0
```
* lancez la VM gateway, puit entrez la commande:
```
ssh localhost
```
```
exit
```
* les autres VM reste en Réseau privé

## Changement du hostname

pour chaqu'une des nouvelles VM créée vous devrez changer le hostname de sorte à le fair correspondre avec le nom de la vm par exemple pour client:
```
sudo hostnamectl set-hostname client.res1.local
```

## Bloqué l'addresse IP

* pour le gateway fait la commande:
```
sudo nano /etc/network/interfaces
```
* changez le contenu par:
```
# This file describes the network interfaces available on your system
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
```
* pour la suite faite:
```
sudo nano /etc/sysctl.conf
```
* décommentez la ligne:
```
net.ipv4.ip_forward=1
```
* voiçi la configuaration des IPtables à faire:
```
sudo /sbin/iptables -t nat -A POSTROUTING ! -d 10.242.0.0/16 -o enp0s3 -j MASQUERADE
```
* installez :
```
apt install iptables-persistent
```
* faite :
```
iptables-save > /etc/iptables/rules.v4
```
## pour les VMs web et manager, nous allons bloqué les addresses IP mais de manier plus simple
* commencer par fair:
```
sudo nano /etc/network/interfaces
```
* puit dans le finier nous allons ecrir:
```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug enp0s8
iface enp0s8 inet static
address 10.242.0.2
netmask 255.255.0.0
gateway 10.242.0.1
```
* ATTENTION: changé bien l'address entre les 2 VMS pour ma part manager a pour address 10.242.0.2 et web a pour address 10.242.0.3

* je vous conseil aussi de bloqué les clefs SSH dans la foulet avec la commande sur chaqu'une des 2 VMs:
```
ssh-keygen -t rsa
```
* sur les 2 VMs toujour fait:
```
sudo nano /etc/resolv.conf
```
* changez le contenu du fichier par:
```
nameserver 8.8.8.8
```
## Création et installation du server dhcp
* installation
```
apt install isc-dhcp-server
```
* configuration:
```
sudo nano /etc/default/isc-dhcp-server
```
* remplacez le contenu par:
```
# Defaults for isc-dhcp-server (sourced by /etc/init.d/isc-dhcp-server)

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
#       Separate multiple interfaces with spaces, e.g. "eth0 eth1".
INTERFACESv4="enp0s3"
INTERFACESv6=""
```
* puit ouvrez:
```
sudo nano /etc/dhcp/dhcpd.conf
```
* remplacer simplement le contenu par:
```
# dhcpd.conf
#
# Sample configuration file for ISC dhcpd
#

# option definitions common to all supported networks...
option domain-name "res1.local";
option domain-name-servers 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;

# The ddns-updates-style parameter controls whether or not the server will
# attempt to do a DNS update when a lease is confirmed. We default to the
# behavior of the version 2 packages ('none', since DHCP v2 didn't
# have support for DDNS.)
ddns-update-style none;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
authoritative;

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
#log-facility local7;

# No service will be given on this subnet, but declaring it helps the 
# DHCP server to understand the network topology.

#subnet 10.152.187.0 netmask 255.255.255.0 {
#}

# This is a very basic subnet declaration.

subnet 10.242.0.0 netmask 255.255.0.0 {
option routers 10.242.0.1;
range 10.242.0.38 10.242.255.254;
  #option routers rtr-239-0-1.example.org, rtr-239-0-2.example.org;
}

# This declaration allows BOOTP clients to get dynamic addresses,
# which we don't really recommend.

#subnet 10.254.239.32 netmask 255.255.255.224 {
#  range dynamic-bootp 10.254.239.40 10.254.239.60;
#  option broadcast-address 10.254.239.31;
#  option routers rtr-239-32-1.example.org;
#}

# A slightly different configuration for an internal subnet.
#subnet 10.5.5.0 netmask 255.255.255.224 {
#  range 10.5.5.26 10.5.5.30;
#  option domain-name-servers ns1.internal.example.org;
#  option domain-name "internal.example.org";
#  option routers 10.5.5.1;
#  option broadcast-address 10.5.5.31;
#  default-lease-time 600;
#  max-lease-time 7200;
#}

# Hosts which require special configuration options can be listed in
# host statements.   If no address is specified, the address will be
# allocated dynamically (if possible), but the host-specific information
# will still come from the host declaration.

#host passacaglia {
#  hardware ethernet 0:0:c0:5d:bd:95;
#  filename "vmunix.passacaglia";
#  server-name "toccata.example.com";
#}

# Fixed IP addresses can also be specified for hosts.   These addresses
# should not also be listed as being available for dynamic assignment.
# Hosts for which fixed IP addresses have been specified can boot using
# BOOTP or DHCP.   Hosts for which no fixed address is specified can only
# be booted with DHCP, unless there is an address range on the subnet
# to which a BOOTP client is connected which has the dynamic-bootp flag
# set.
#host fantasia {
#  hardware ethernet 08:00:07:26:c0:a5;
#  fixed-address fantasia.example.com;
#}

# You can declare a class of clients and then do address allocation
# based on that.   The example below shows a case where all clients
# in a certain class get addresses on the 10.17.224/24 subnet, and all
# other clients get addresses on the 10.0.29/24 subnet.

#class "foo" {
#  match if substring (option vendor-class-identifier, 0, 4) = "SUNW";
#}

#shared-network 224-29 {
#  subnet 10.17.224.0 netmask 255.255.255.0 {
#    option routers rtr-224.example.org;
#  }
#  subnet 10.0.29.0 netmask 255.255.255.0 {
#    option routers rtr-29.example.org;
#  }
#  pool {
#    allow members of "foo";
#    range 10.17.224.10 10.17.224.250;
#  }
#  pool {
#    deny members of "foo";
#    range 10.0.29.10 10.0.29.230;
#  }
#}
```
* une fois la config terminée, on lance notre DHCP:
```
systemctl start isc-dhcp-server
```
* on ajoute le service au démarrage:
```
systemctl enable isc-dhcp-server
```
## Connexion sans mode passe en ssh depuis la gateway:
* si vous avez bien suivie le tuto depuis le debut la seul chose à fair est cette simple commande pour chaque VM web et manager:
```
ssh-copy-id root@10.242.0.2
```
## 