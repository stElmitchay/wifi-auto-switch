#!/bin/bash

# ============================================
# WiFi Auto-Switch — Installer
# Double-click this file to install.
# ============================================

# Move to the directory where this script lives (so we can find wifi-auto-switch.sh)
cd "$(dirname "$0")"

INSTALL_DIR="$HOME/.wifi-auto-switch"
PLIST_NAME="com.user.wifi-auto-switch"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SCRIPT_NAME="wifi-auto-switch.sh"

echo ""
echo "========================================"
echo "  WiFi Auto-Switch — Installer"
echo "========================================"
echo ""

# --- Check that the script file exists ---
if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo "ERROR: Could not find $SCRIPT_NAME in the same folder as this installer."
    echo "Make sure Install.command and wifi-auto-switch.sh are in the same folder."
    echo ""
    read -n 1 -s -r -p "Press any key to close."
    exit 1
fi

# --- Stop existing service if running ---
if launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "Stopping existing WiFi Auto-Switch service..."
    launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || \
        launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist" 2>/dev/null
    echo "  Done."
    echo ""
fi

# --- Create install directory ---
echo "Setting up install directory..."
mkdir -p "$INSTALL_DIR"
echo "  Created $INSTALL_DIR"

# --- Copy script ---
echo ""
echo "Copying WiFi auto-switch script..."
cp "$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "  Installed to $INSTALL_DIR/$SCRIPT_NAME"

# --- Create and install LaunchAgent plist ---
echo ""
echo "Installing login service (LaunchAgent)..."
mkdir -p "$LAUNCH_AGENTS_DIR"

cat > "$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$INSTALL_DIR/$SCRIPT_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/wifi-auto-switch.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/wifi-auto-switch.stderr.log</string>
</dict>
</plist>
EOF

echo "  Installed to $LAUNCH_AGENTS_DIR/$PLIST_NAME.plist"

# --- Load the service ---
echo ""
echo "Starting the service..."
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist" 2>/dev/null || \
    launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME.plist" 2>/dev/null

# Verify it's running
sleep 1
if launchctl list "$PLIST_NAME" &>/dev/null; then
    echo "  WiFi Auto-Switch is now running!"
else
    echo "  WARNING: Service may not have started. Try logging out and back in,"
    echo "  or double-click Status.command to check."
fi

echo ""
echo "========================================"
echo "  Installation complete!"
echo ""
echo "  What happens now:"
echo "    - WiFi Auto-Switch is running in the background"
echo "    - It will start automatically when you log in"
echo "    - If your WiFi drops, it will switch to a backup network"
echo ""
echo "  Other tools:"
echo "    - Double-click Status.command to check if it's running"
echo "    - Double-click Uninstall.command to remove it"
echo "========================================"
echo ""
read -n 1 -s -r -p "Press any key to close."
