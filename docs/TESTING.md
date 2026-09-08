# Testing Checklist

Test the network progressively. This makes it much easier to identify which layer is causing a problem.

## 1. WAN connectivity

First verify Internet access on both MikroTik routers.

```routeros
/ping 8.8.8.8
```

Then verify DNS:

```routeros
/ping google.com
```

Expected result:

```text
BASE   → Internet ✅
REMOTE → Internet ✅
```

## 2. WireGuard handshake

On both routers:

```routeros
/interface/wireguard/peers print detail
```

Check that:

- `last-handshake` shows a recent value
- `rx` is increasing
- `tx` is increasing

Expected:

```text
Last Handshake: active
Rx: > 0
Tx: > 0
```

## 3. Test the WireGuard tunnel

From REMOTE:

```routeros
/ping 10.66.66.1
```

From BASE:

```routeros
/ping 10.66.66.2
```

Expected:

```text
10.66.66.1 ↔ 10.66.66.2 ✅
```

If this works, the WireGuard tunnel itself is operational.

## 4. Test router-to-router LAN routing

From REMOTE:

```routeros
/ping 192.168.88.1
```

From BASE:

```routeros
/ping 192.168.89.1
```

Expected:

```text
MAXX-REMOTE → 192.168.88.1 ✅
MAXX-BASE   → 192.168.89.1 ✅
```

If the WireGuard IP responds but the opposite LAN gateway does not, check the static routes.

## 5. Test from a REMOTE LAN client

Connect a laptop or other device to the REMOTE MikroTik LAN.

In the tested configuration DHCP assigned:

```text
IPv4 Address: 192.168.89.200
Subnet Mask:  255.255.255.0
Gateway:      192.168.89.1
```

Verify the local gateway:

```cmd
ping 192.168.89.1
```

Then test the BASE router through WireGuard:

```cmd
ping 192.168.88.1
```

During the real test:

```text
Packets: Sent = 4
Received = 4
Lost = 0

Packet loss = 0%
```

Result:

```text
REMOTE LAN client
192.168.89.200
       │
       ▼
MAXX-REMOTE
192.168.89.1
       │
       ▼
WireGuard
10.66.66.2 ↔ 10.66.66.1
       │
       ▼
MAXX-BASE
192.168.88.1

✅ SUCCESS
```

## 6. Test the reverse direction

Connect a client to the BASE LAN.

It should receive an address from:

```text
192.168.88.100-192.168.88.200
```

Then test:

```cmd
ping 192.168.89.1
```

Expected:

```text
BASE LAN → WireGuard → REMOTE LAN ✅
```

## 7. Test actual devices

After router-to-router connectivity works, test devices behind both routers.

Examples:

```text
192.168.88.x → 192.168.89.x
192.168.89.x → 192.168.88.x
```

If the routers can reach each other but an individual device cannot be reached, check the firewall on that device.

## Final verification

A fully working installation should pass all tests:

- [x] BASE has Internet access
- [x] REMOTE has Internet access
- [x] WireGuard handshake established
- [x] BASE can ping `10.66.66.2`
- [x] REMOTE can ping `10.66.66.1`
- [x] BASE can ping `192.168.89.1`
- [x] REMOTE can ping `192.168.88.1`
- [x] BASE LAN can reach REMOTE LAN
- [x] REMOTE LAN can reach BASE LAN

At this point the MikroTik WireGuard Site-to-Site VPN is operational.
