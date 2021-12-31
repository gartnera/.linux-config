#!/bin/bash

# configuration required
# 1) set HandleLidSwitch and HandleLidSwitchExternalPower = ignore in logind.conf
# 2) install and enable acpid
# 3) route all acpi events to this script

# if ac power, discard
if [[ $(cat /sys/class/power_supply/AC/online) == "1" ]]; then
  exit
fi

# sleep 1 and check if lid is open to debounce
sleep 1
if grep open /proc/acpi/button/lid/LID/state >/dev/null 2>/dev/null; then
  exit
fi

# ok so now lid is confirmed actually closed

# execute swaylock if not already running (load env from waybar)
if ! pgrep swaylock; then
  while IFS= read -rd '' var; do export "$var"; done </proc/$(pgrep waybar)/environ;
  # this should ensure swaylock is running as user
  swaymsg exec '$lock'
fi

systemctl suspend
