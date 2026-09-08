# Setup Guide

This guide recreates the tested topology from a clean RouterOS 7 configuration.

> Adapt interface names, subnets and firewall rules to your hardware/environment.

## 1. Target topology

- BASE LAN: `192.168.88.0/24`
- REMOTE LAN: `192.168.89.0/24`
- WireGuard: `10.66.66.0/24`
- BASE WG: `10.66.66.1`
- REMOTE WG: `10.66.66.2`
- UDP port: `51820`
- WAN: `ether1`
- LAN ports: `ether2-ether5`

The BASE side must be reachable by the REMOTE side at a public IPv4 endpoint (or by an equivalent upstream port-forwarding design).

## 2. Build the LAN bridge

On each router create `bridge-LAN` and add `ether2`, `ether3`, `ether4`, and `ether5`.

Assign:

**BASE**

```text
192.168.88.1/24 → bridge-LAN
```

**REMOTE**

```text
192.168.89.1/24 → bridge-LAN
```

## 3. Configure DHCP

Example pools:

```text
BASE:   192.168.88.100-192.168.88.200
REMOTE: 192.168.89.100-192.168.89.200
```

Set the corresponding router LAN address as the DHCP gateway.

## 4. Configure WAN

Create a DHCP client on `ether1` on both routers.

Verify basic connectivity:

```routeros
/ping 8.8.8.8
/ping google.com
```

## 5. Configure source NAT for Internet access

On both routers:

```routeros
/ip firewall nat
add chain=srcnat out-interface=ether1 action=masquerade
```

## 6. Create WireGuard interfaces

Create `wg-site-to-site` on both routers:

```text
MTU:         1420
Listen Port: 51820
```

RouterOS generates a private/public key pair for each interface.

**Never exchange or publish private keys. Exchange only public keys.**

## 7. Assign tunnel addresses

**BASE**

```routeros
/ip address
add address=10.66.66.1/24 interface=wg-site-to-site
```

**REMOTE**

```routeros
/ip address
add address=10.66.66.2/24 interface=wg-site-to-site
```

## 8. Create the BASE peer

On BASE, create a peer using the **REMOTE public key**.

```text
Public Key:      <REMOTE_PUBLIC_KEY>
Allowed Address: 10.66.66.2/32
                 192.168.89.0/24
Responder:       yes
Endpoint:        empty
```

The BASE does not need to know the REMOTE public WAN address when REMOTE initiates the connection.

## 9. Create the REMOTE peer

On REMOTE, create a peer using the **BASE public key**.

```text
Public Key:           <BASE_PUBLIC_KEY>
Endpoint:             <BASE_PUBLIC_IP>
Endpoint Port:        51820
Allowed Address:      10.66.66.1/32
                      192.168.88.0/24
Persistent Keepalive: 25s
```

Persistent keepalive is useful when REMOTE is behind NAT/CGNAT.

## 10. Firewall requirement on BASE

The BASE router must permit inbound UDP `51820` to the router itself.

If you have a restrictive input firewall, add an appropriate rule **in the correct position for your ruleset**, for example:

```routeros
/ip firewall filter
add chain=input action=accept protocol=udp dst-port=51820 comment="Allow WireGuard"
```

> Do not blindly paste firewall rules into a production router. Evaluate your existing input policy first.

## 11. Verify the WireGuard handshake

On both routers:

```routeros
/interface/wireguard/peers print detail
```

Check that:

- `last-handshake` updates
- `rx` increases
- `tx` increases

From REMOTE:

```routeros
/ping 10.66.66.1
```

From BASE:

```routeros
/ping 10.66.66.2
```

## 12. Add LAN routes

A working WireGuard handshake does not by itself provide the opposite LAN route.

On REMOTE:

```routeros
/ip route
add dst-address=192.168.88.0/24 gateway=10.66.66.1
```

On BASE:

```routeros
/ip route
add dst-address=192.168.89.0/24 gateway=10.66.66.2
```

The resulting routing is:

```text
REMOTE
192.168.88.0/24 → 10.66.66.1 → WireGuard → BASE

BASE
192.168.89.0/24 → 10.66.66.2 → WireGuard → REMOTE
```

## 13. Test router-to-router connectivity

From REMOTE:

```routeros
/ping 192.168.88.1
```

From BASE:

```routeros
/ping 192.168.89.1
```

Both should respond.

## 14. Test LAN-to-LAN connectivity

Connect a client to the REMOTE LAN.

Example DHCP configuration:

```text
IPv4:    192.168.89.200
Mask:    255.255.255.0
Gateway: 192.168.89.1
```

From the REMOTE LAN client:

```cmd
ping 192.168.88.1
```

Then connect a client to the BASE LAN and verify the reverse direction:

```cmd
ping 192.168.89.1
```

If both tests succeed, the site-to-site VPN is operational.

## Result

The final topology provides bidirectional Layer-3 connectivity:

```text
192.168.88.0/24
       │
   MAXX-BASE
   10.66.66.1
       │
       │ WireGuard
       │ UDP 51820
       │
   10.66.66.2
  MAXX-REMOTE
       │
192.168.89.0/24
```

Both sites retain normal Internet access while traffic destined for the opposite LAN is routed through the WireGuard tunnel.
