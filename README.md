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

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/stElmitchay/wifi-auto-switch.git
cd wifi-auto-switch

# 2. Make it executable
chmod +x wifi-auto-switch.sh

# 3. Run it
sudo bash wifi-auto-switch.sh
```

Press `Ctrl+C` to stop.

> `sudo` may be required for `networksetup` commands depending on your macOS version.

## Run on Login (LaunchAgent)

To have the script start automatically when you log in:

```bash
# Copy script to a permanent location
sudo cp wifi-auto-switch.sh /usr/local/bin/wifi-auto-switch.sh
sudo chmod +x /usr/local/bin/wifi-auto-switch.sh

# Install the LaunchAgent
cp com.user.wifi-auto-switch.plist ~/Library/LaunchAgents/

# Load it
launchctl load ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist
```

To stop:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.wifi-auto-switch.plist
```

## Configuration

Edit the variables at the top of `wifi-auto-switch.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_NETWORKS` | `CF1, CF_STARLINK, Mars Butterfly` | Fallback SSIDs in priority order |
| `CHECK_INTERVAL` | `10` | Seconds between connectivity checks |
| `FAIL_THRESHOLD` | `3` | Failed pings before switching |
| `PRIMARY_RECHECK_INTERVAL` | `120` | Seconds before retrying the primary network |
| `PING_TARGETS` | `8.8.8.8, 1.1.1.1` | Hosts used for connectivity checks |

## Logs

| Log | Location |
|-----|----------|
| Script log | `~/.wifi-auto-switch.log` |
| LaunchAgent stdout | `/tmp/wifi-auto-switch.stdout.log` |
| LaunchAgent stderr | `/tmp/wifi-auto-switch.stderr.log` |

## Requirements

- macOS (uses `networksetup` and `airport` under the hood)
- Backup networks must have been joined at least once so macOS has their passwords saved
- May require `sudo` depending on system permissions

## License

MIT
