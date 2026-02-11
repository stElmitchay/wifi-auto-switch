# WiFi Auto-Switch

A lightweight macOS script that automatically switches to a backup WiFi network when your primary connection loses internet — and switches back when it recovers.

Built for environments like offices where a power outage can take down the main router while a backup network (e.g. Starlink) stays online.

## How It Works

1. On startup, the script detects your **current WiFi network** as the primary
2. Every **10 seconds**, it pings `8.8.8.8` and `1.1.1.1` to check connectivity
3. After **3 consecutive failures**, it switches to the first available backup network
4. Once on a backup, it checks every **2 minutes** if the primary is back — and reconnects automatically

```
Primary down → try CF1 → try CF_STARLINK → try Mars Butterfly
                         ↑ stays on first one that works
```

## Setup (One-Time)

1. Download or clone this folder to your Mac
2. Double-click **`Install.command`**
3. That's it — WiFi Auto-Switch is now running and will start automatically on login

### Other Tools

| File | What it does |
|------|-------------|
| **`Install.command`** | Double-click to install and start the service |
| **`Uninstall.command`** | Double-click to stop and remove everything |
| **`Status.command`** | Double-click to check if it's running + see recent logs |

> **First time running a `.command` file?** macOS may show a security warning. Right-click the file, choose "Open", then click "Open" in the dialog. You only need to do this once.

## Configuration

Edit the variables at the top of `wifi-auto-switch.sh` **before** running Install.command:

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_NETWORKS` | `CF1, CF_STARLINK, Mars Butterfly` | Fallback SSIDs in priority order |
| `CHECK_INTERVAL` | `10` | Seconds between connectivity checks |
| `FAIL_THRESHOLD` | `3` | Failed pings before switching |
| `PRIMARY_RECHECK_INTERVAL` | `120` | Seconds before retrying the primary network |
| `PING_TARGETS` | `8.8.8.8, 1.1.1.1` | Hosts used for connectivity checks |

After changing configuration, double-click `Install.command` again to apply changes.

## Logs

| Log | Location |
|-----|----------|
| Script log | `~/.wifi-auto-switch.log` |
| LaunchAgent stdout | `/tmp/wifi-auto-switch.stdout.log` |
| LaunchAgent stderr | `/tmp/wifi-auto-switch.stderr.log` |

## Where Files Are Installed

The installer puts files in these locations (all in your home folder, no admin access needed):

| File | Location |
|------|----------|
| Script | `~/.wifi-auto-switch/wifi-auto-switch.sh` |
| Login service | `~/Library/LaunchAgents/com.user.wifi-auto-switch.plist` |

## Advanced: Manual Setup

If you prefer using Terminal instead of the `.command` files:

```bash
# Install
mkdir -p ~/.wifi-auto-switch
cp wifi-auto-switch.sh ~/.wifi-auto-switch/
chmod +x ~/.wifi-auto-switch/wifi-auto-switch.sh
cp com.user.wifi-auto-switch.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist

# Uninstall
launchctl unload ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist
rm ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist
rm -rf ~/.wifi-auto-switch
```

## Requirements

- macOS (uses `networksetup` under the hood)
- Backup networks must have been joined at least once so macOS has their passwords saved

## License

MIT
