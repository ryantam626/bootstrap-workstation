# nmcli Reference Guide

A little reminder of how to use nmcli.

## Wi-Fi Management

### List nearby Wi-Fi networks:
```bash
nmcli device wifi list
```

### Connect to a Wi-Fi network:
```bash
nmcli device wifi connect SSID_or_BSSID password password
```

### Connect to a hidden Wi-Fi network:
```bash
nmcli device wifi connect SSID_or_BSSID password password hidden yes
```

### Connect to a Wi-Fi on the wlan1 interface:
```bash
nmcli device wifi connect SSID_or_BSSID password password ifname wlan1 profile_name
```

## Connection Management

### Get a list of connections with their names, UUIDs, types and backing devices:
```bash
nmcli connection show
```

### Activate a connection (i.e. connect to a network with an existing profile):
```bash
nmcli connection up name_or_uuid
```

### Delete a connection:
```bash
nmcli connection delete name_or_uuid
```

## Device Management

### See a list of network devices and their state:
```bash
nmcli device
```

### Disconnect an interface:
```bash
nmcli device disconnect ifname eth0
```

### Turn off Wi-Fi:
```bash
nmcli radio wifi off
```
