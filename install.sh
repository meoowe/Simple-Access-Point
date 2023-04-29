#!/bin/sh
echo "Hi! This script will install a wifi hotspot for you"
if ! [ $(id -u) = 0 ]; then
   echo "I am not root! Run me as root please :|"
   exit 1
fi
if command -v iwconfig > /dev/null; then  #Checking presence of iwconfig
    INTERFACE_WLAN=$(iwconfig 2>&1 | grep "^wlan" | sed -e 's/ .*//g' | tail -n 1) #Assuming interface uses old wlan convention
    if [[ ! $INTERFACE_WLAN ]]; then
        INTERFACE_WLAN=$(iwconfig 2>&1 | grep "^wlp" | sed -e 's/ .*//g' | tail -n 1)  #Assuming interface uses new wlp convention
    fi
elif command -v iw > /dev/null; then
    INTERFACE_WLAN=$(iw dev 2>&1 | grep "wlan" | awk '{print $2}' | tail -n 1)
    if [[ ! $INTERFACE_WLAN ]]; then
        INTERFACE_WLAN=$(iwconfig 2>&1 | grep "^wlp" | sed -e 's/ .*//g' | tail -n 1)
    fi
fi

apt-get update  # To get the latest package lists
apt-get install hostapd -y #hostapd to actualy broadcast the network
apt-get install dnsmasq -y #A dns server
systemctl stop hostapd #Stop services
systemctl stop dnsmasq
hotspotconfig="/etc/hostapd/hostapd.conf"
dnsmasqconfig="/etc/dnsmasq.conf"
# Hotspot SSID
show_msg "Enter the desired Access Point name ($SSID):"
read ssid
[[ "$ssid" ]] && SSID="$ssid"
# WPA Password
show_msg "Enter the desired Wifi Password NOTE: Make sure it is at least 6 characters long($PASSWD):"
read PASSWD
[[ "$wpapass" ]] && PASSWD="$PASSWD"
# Write the hostapd config file
cat <<EOF | tee "$hotspotconfig" > /dev/null 2>&1
# WiFi Hotspot
interface=$INTERFACE_WLAN
driver=nl80211 
#Access Point
ssid=$SSID
hw_mode=g # g = 2.4Ghz
# WiFi Channel:
channel=11
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WPAPASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF 
if [[ ! $(grep "Bind to only one interface" "$dnsmasqconfig" > /dev/null 2>&1) ]]; then
cat <<EOF | tee "$dnsmasqconfig" > /dev/null 2>&1
# Bind to only one interface
bind-interfaces
# Choose interface for binding
interface=$INTERFACE_WLAN
# Specify range of IP addresses for DHCP leases
dhcp-range=192.168.0.1,192.168.150.10,12h
#INTERFACE_NET=$INTERFACE_NET
EOF
chmod +x "$dnsmasqconfig"
fi