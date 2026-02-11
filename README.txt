WiFi Auto-Switch Setup Guide
=============================

WHAT IT DOES
- Monitors your internet every 10 seconds
- After 3 failed pings, switches WiFi to the first working backup network
- Tries: CF1 → CF_STARLINK → Mars Butterfly (in order)
- Every 2 minutes, checks if your primary network is back and reconnects

QUICK START (manual run)
------------------------
1. Copy the script to the target Mac
2. Make it executable:
     chmod +x wifi-auto-switch.sh
3. Run it:
     sudo bash wifi-auto-switch.sh
   (sudo may be needed for networksetup commands)
4. Stop it with Ctrl+C

AUTO-START ON LOGIN (LaunchAgent)
---------------------------------
1. Copy the script to a permanent location:
     sudo cp wifi-auto-switch.sh /usr/local/bin/wifi-auto-switch.sh
     sudo chmod +x /usr/local/bin/wifi-auto-switch.sh

2. Copy the plist to LaunchAgents:
     cp com.user.wifi-auto-switch.plist ~/Library/LaunchAgents/

3. Load it:
     launchctl load ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist

4. To stop/unload:
     launchctl unload ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist

CONFIGURATION
-------------
Edit the top of wifi-auto-switch.sh to change:
  - BACKUP_NETWORKS    : list of fallback SSIDs in priority order
  - CHECK_INTERVAL     : seconds between connectivity checks (default: 10)
  - FAIL_THRESHOLD     : failed pings before switching (default: 3)
  - PRIMARY_RECHECK_INTERVAL : seconds before trying primary again (default: 120)

LOGS
----
  - Script log: ~/.wifi-auto-switch.log
  - LaunchAgent stdout: /tmp/wifi-auto-switch.stdout.log
  - LaunchAgent stderr: /tmp/wifi-auto-switch.stderr.log

NOTES
-----
  - The script auto-detects your WiFi interface and current network on startup
  - Backup networks must already be saved (joined at least once) on the Mac
  - If networksetup requires elevated permissions, you may need to run with sudo
    or adjust the LaunchAgent to run as root (use LaunchDaemons instead)
