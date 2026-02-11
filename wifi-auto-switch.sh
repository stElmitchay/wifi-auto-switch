#!/bin/bash

# ============================================
# WiFi Auto-Switch Script for macOS
# Monitors internet connectivity and switches
# to a backup WiFi network when connection drops.
# ============================================

# --- Configuration ---

# Backup networks in priority order (will try top to bottom)
BACKUP_NETWORKS=("CF1" "CF_STARLINK" "Mars Butterfly")

# How often to check connectivity (seconds)
CHECK_INTERVAL=10

# Number of failed pings before switching
FAIL_THRESHOLD=3

# Hosts to ping for connectivity check
PING_TARGETS=("8.8.8.8" "1.1.1.1")

# How long to wait before checking if primary network is back (seconds)
PRIMARY_RECHECK_INTERVAL=120

# Log file
LOG_FILE="$HOME/.wifi-auto-switch.log"

# --- End Configuration ---

WIFI_INTERFACE=""
PRIMARY_NETWORK=""
CURRENT_FAIL_COUNT=0
SWITCHED_AWAY=false

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

detect_wifi_interface() {
    WIFI_INTERFACE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
    if [[ -z "$WIFI_INTERFACE" ]]; then
        log "ERROR: Could not detect WiFi interface. Exiting."
        exit 1
    fi
    log "WiFi interface: $WIFI_INTERFACE"
}

get_current_network() {
    networksetup -getairportnetwork "$WIFI_INTERFACE" 2>/dev/null | sed 's/Current Wi-Fi Network: //'
}

check_internet() {
    for target in "${PING_TARGETS[@]}"; do
        if ping -c 1 -W 2 "$target" &>/dev/null; then
            return 0
        fi
    done
    return 1
}

switch_to_network() {
    local ssid="$1"
    log "Attempting to switch to: $ssid"
    networksetup -setairportnetwork "$WIFI_INTERFACE" "$ssid" 2>/dev/null
    sleep 5

    local connected_to
    connected_to=$(get_current_network)
    if [[ "$connected_to" == "$ssid" ]]; then
        log "Connected to $ssid. Checking internet..."
        sleep 3
        if check_internet; then
            log "Internet is working on $ssid"
            return 0
        else
            log "Connected to $ssid but no internet"
            return 1
        fi
    else
        log "Failed to connect to $ssid"
        return 1
    fi
}

switch_to_backup() {
    for network in "${BACKUP_NETWORKS[@]}"; do
        if switch_to_network "$network"; then
            SWITCHED_AWAY=true
            return 0
        fi
    done
    log "WARNING: All backup networks failed. Will retry next cycle."
    return 1
}

try_primary() {
    log "Checking if primary network ($PRIMARY_NETWORK) is back..."
    if switch_to_network "$PRIMARY_NETWORK"; then
        log "Primary network is back! Reconnected to $PRIMARY_NETWORK"
        SWITCHED_AWAY=false
        CURRENT_FAIL_COUNT=0
        return 0
    else
        log "Primary network still down. Staying on backup."
        # Reconnect to whichever backup works
        switch_to_backup
        return 1
    fi
}

cleanup() {
    log "Script stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM

# --- Main ---

log "========================================="
log "WiFi Auto-Switch starting..."
detect_wifi_interface

PRIMARY_NETWORK=$(get_current_network)
if [[ -z "$PRIMARY_NETWORK" || "$PRIMARY_NETWORK" == *"not associated"* ]]; then
    log "WARNING: Not connected to any WiFi. Will monitor for connectivity."
    PRIMARY_NETWORK=""
else
    log "Primary network detected: $PRIMARY_NETWORK"
fi

log "Backup networks: ${BACKUP_NETWORKS[*]}"
log "Check interval: ${CHECK_INTERVAL}s | Fail threshold: $FAIL_THRESHOLD"
log "========================================="

LAST_PRIMARY_CHECK=$(date +%s)

while true; do
    if check_internet; then
        CURRENT_FAIL_COUNT=0

        # If we're on a backup, periodically try to go back to primary
        if $SWITCHED_AWAY && [[ -n "$PRIMARY_NETWORK" ]]; then
            NOW=$(date +%s)
            ELAPSED=$((NOW - LAST_PRIMARY_CHECK))
            if [[ $ELAPSED -ge $PRIMARY_RECHECK_INTERVAL ]]; then
                LAST_PRIMARY_CHECK=$NOW
                try_primary
            fi
        fi
    else
        CURRENT_FAIL_COUNT=$((CURRENT_FAIL_COUNT + 1))
        log "Ping failed ($CURRENT_FAIL_COUNT/$FAIL_THRESHOLD)"

        if [[ $CURRENT_FAIL_COUNT -ge $FAIL_THRESHOLD ]]; then
            CURRENT_NETWORK=$(get_current_network)
            log "Internet down on '$CURRENT_NETWORK'. Switching to backup..."
            CURRENT_FAIL_COUNT=0
            switch_to_backup
            LAST_PRIMARY_CHECK=$(date +%s)
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
