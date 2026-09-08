# MAXX-REMOTE.example.rsc
# MikroTik WireGuard Site-to-Site VPN
# REMOTE router
# Tested on RouterOS 7.21.5
#
# Replace <BASE_PUBLIC_KEY> and <BASE_PUBLIC_IP> before use.

/interface bridge
add name=bridge-LAN

/interface wireguard
add listen-port=51820 mtu=1420 name=wg-site-to-site

/ip pool
add name=dhcp_pool0 ranges=192.168.89.100-192.168.89.200

/ip dhcp-server
add address-pool=dhcp_pool0 interface=bridge-LAN lease-time=1d name=dhcp1

/interface bridge port
add bridge=bridge-LAN interface=ether2
add bridge=bridge-LAN interface=ether3
add bridge=bridge-LAN interface=ether4
add bridge=bridge-LAN interface=ether5

/interface wireguard peers
add allowed-address=10.66.66.1/32,192.168.88.0/24 \
    endpoint-address=<BASE_PUBLIC_IP> endpoint-port=51820 \
    interface=wg-site-to-site name=base-peer persistent-keepalive=25s \
    public-key="<BASE_PUBLIC_KEY>"

/ip address
add address=192.168.89.1/24 interface=bridge-LAN network=192.168.89.0
add address=10.66.66.2/24 interface=wg-site-to-site network=10.66.66.0

/ip dhcp-client
add interface=ether1

/ip dhcp-server network
add address=192.168.89.0/24 gateway=192.168.89.1

/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1

/ip route
add dst-address=192.168.88.0/24 gateway=10.66.66.1

/system identity
set name=MAXX-REMOTE
