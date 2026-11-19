#!/usr/bin/env bash
set -euo pipefail

HA_URL="${HA_URL:-http://homeassistant.local:8123}"

echo "=== Homelab Health Check ==="
echo "Hostname  : $(hostname)"
echo "Uptime    : $(uptime -p 2>/dev/null || uptime)"

if [[ -f /proc/loadavg ]]; then
  echo "CPU Load  : $(awk '{print $1, $2, $3}' /proc/loadavg)"
fi

if command -v vcgencmd >/dev/null 2>&1; then
  echo "CPU Temp  : $(vcgencmd measure_temp | cut -d= -f2)"
  echo "GPU Mem   : $(vcgencmd get_mem gpu | cut -d= -f2)"
  echo "Throttled : $(vcgencmd get_throttled | cut -d= -f2) (0x0 = OK)"
elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
  echo "CPU Temp  : $(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)"
elif command -v system_profiler >/dev/null 2>&1; then
  GPU=$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model/{print $2; exit}')
  echo "GPU       : ${GPU:-N/A}"
fi

if command -v free >/dev/null 2>&1; then
  echo "RAM       : $(free -h | awk '/Mem:/ {print $3 " used / " $2 " total (" $7 " available)"}')"
  echo "Swap      : $(free -h | awk '/Swap:/ {print $3 " used / " $2 " total"}')"
elif command -v memory_pressure >/dev/null 2>&1; then
  echo "RAM       : $(sysctl -n hw.memsize | awk '{printf "%.0f GB total", $1/1073741824}') ($(memory_pressure | awk -F': ' '/System-wide memory free percentage/{print $2 " free"}'))"
fi

echo "Disk      : $(df -h / | awk 'NR==2 {print $3 " used / " $2 " (" $5 ")"}')"

if command -v ip >/dev/null 2>&1; then
  ETH_IP=$(ip -4 -o addr show eth0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)
  WIFI_IP=$(ip -4 -o addr show wlan0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)
  WIFI_SSID=$(iwgetid -r 2>/dev/null || true)
  echo "Ethernet  : ${ETH_IP:-disconnected}"
  echo "Wi-Fi     : ${WIFI_IP:-disconnected}${WIFI_SSID:+ ($WIFI_SSID)}"
else
  WIFI_IP=$(ipconfig getifaddr en0 2>/dev/null || true)
  echo "Wi-Fi     : ${WIFI_IP:-disconnected}"
fi

if command -v bluetoothctl >/dev/null 2>&1; then
  BT=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}')
  echo "Bluetooth : ${BT:-unavailable}"
elif command -v system_profiler >/dev/null 2>&1; then
  BT=$(system_profiler SPBluetoothDataType 2>/dev/null | awk -F': ' '/State:/{print $2; exit}')
  echo "Bluetooth : ${BT:-unavailable}"
fi

ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 && echo "Internet  : UP" || echo "Internet  : DOWN"
ping -c 1 -W 2 github.com >/dev/null 2>&1 && echo "DNS       : OK" || echo "DNS       : FAILED"

if command -v curl >/dev/null 2>&1; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$HA_URL" || true)
  if [[ "$HTTP_CODE" =~ ^(200|301|302|401|403)$ ]]; then
    echo "HA Web    : UP ($HA_URL -> HTTP $HTTP_CODE)"
  else
    echo "HA Web    : DOWN or unreachable ($HA_URL)"
  fi
fi

if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' 2>/dev/null | grep -qi 'homeassistant'; then
  echo "HA Docker : running"
elif command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet home-assistant@homeassistant 2>/dev/null; then
  echo "HA Svc    : active"
fi
