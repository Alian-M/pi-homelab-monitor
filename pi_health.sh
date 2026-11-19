#!/usr/bin/env bash
set -euo pipefail

echo "=== Homelab Health Check ==="
echo "Hostname : $(hostname)"
echo "Uptime   : $(uptime -p 2>/dev/null || uptime)"

if command -v vcgencmd >/dev/null 2>&1; then
  echo "CPU Temp : $(vcgencmd measure_temp)"
elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
  TEMP=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
  echo "CPU Temp : $TEMP"
fi

echo "Disk     : $(df -h / | awk 'NR==2 {print $3 " used / " $2 " (" $5 ")"}')"
echo "Memory   : $(free -h 2>/dev/null | awk '/Mem:/ {print $3 " / " $2}' || vm_stat | head -n 5)"
