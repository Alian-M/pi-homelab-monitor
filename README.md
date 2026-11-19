# Pi Homelab Monitor

Lightweight Bash health-check script for a Raspberry Pi running Home Assistant or Docker services (also runs on macOS for local testing).

## Usage

    chmod +x pi_health.sh
    ./pi_health.sh

To check a custom Home Assistant URL:

    HA_URL="http://192.168.1.10:8123" ./pi_health.sh

## What It Checks
- Hostname, uptime, and CPU load average
- CPU temperature, GPU memory/info, and under-voltage/throttling status
- RAM, free memory, swap, and root disk usage
- Network interfaces (Ethernet, Wi-Fi, Bluetooth), Internet ping, and DNS
- Home Assistant reachability (HTTP) and local service/container status
