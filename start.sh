#!/bin/sh
echo "Hi! This script will install a wifi hotspot for you"
if ! [ $(id -u) = 0 ]; then
   echo "I am not root! Run me as root please :|"
   exit 1
fi
echo "Starting your new hotspot!"
systemctl start dnsmasq
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd
ip addr flush dev wlan0
ip addr add 192.168.150.1 dev wlan0
# Enable routing
sysctl net.ipv4.ip_forward=1
# Enable NAT
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
