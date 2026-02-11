#!/bin/bash

# ============================================
# WiFi Auto-Switch — Status Check
# Double-click this file to see if it's running.
# ============================================

PLIST_NAME="com.user.wifi-auto-switch"
LOG_FILE="$HOME/.wifi-auto-switch.log"

echo ""
echo "========================================"
echo "  WiFi Auto-Switch — Status"
echo "========================================"
echo ""

# --- Check if the service is running ---
if launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "  Status: RUNNING"
else
    echo "  Status: NOT RUNNING"
    echo ""
    echo "  To start it, double-click Install.command"
fi

# --- Show current WiFi network ---
echo ""
WIFI_IF=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
if [[ -n "$WIFI_IF" ]]; then
    CURRENT=$(networksetup -getairportnetwork "$WIFI_IF" 2>/dev/null | sed 's/Current Wi-Fi Network: //')
    echo "  Current WiFi network: $CURRENT"
fi

# --- Show recent log entries ---
echo ""
echo "========================================"
echo "  Recent Log (last 20 entries)"
echo "========================================"
echo ""

if [[ -f "$LOG_FILE" ]]; then
    tail -20 "$LOG_FILE"
else
    echo "  No log file found yet."
    echo "  (Logs appear after the service runs for the first time.)"
fi

echo ""
echo "========================================"
echo ""
read -n 1 -s -r -p "Press any key to close."
