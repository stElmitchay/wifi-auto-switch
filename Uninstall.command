#!/bin/bash

# ============================================
# WiFi Auto-Switch — Uninstaller
# Double-click this file to remove everything.
# ============================================

INSTALL_DIR="$HOME/.wifi-auto-switch"
PLIST_NAME="com.user.wifi-auto-switch"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist"

echo ""
echo "========================================"
echo "  WiFi Auto-Switch — Uninstaller"
echo "========================================"
echo ""

# --- Stop the service ---
if launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "Stopping the service..."
    launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || \
        launchctl unload "$PLIST_PATH" 2>/dev/null
    echo "  Stopped."
else
    echo "Service is not currently running. (That's fine.)"
fi

# --- Remove the LaunchAgent plist ---
echo ""
if [[ -f "$PLIST_PATH" ]]; then
    echo "Removing login service..."
    rm "$PLIST_PATH"
    echo "  Removed $PLIST_PATH"
else
    echo "No login service found. (Already removed.)"
fi

# --- Remove the install directory ---
echo ""
if [[ -d "$INSTALL_DIR" ]]; then
    echo "Removing installed files..."
    rm -rf "$INSTALL_DIR"
    echo "  Removed $INSTALL_DIR"
else
    echo "No installed files found. (Already removed.)"
fi

echo ""
echo "========================================"
echo "  WiFi Auto-Switch has been removed."
echo ""
echo "  Your WiFi settings are unchanged —"
echo "  this only removed the auto-switch tool."
echo "========================================"
echo ""
read -n 1 -s -r -p "Press any key to close."
