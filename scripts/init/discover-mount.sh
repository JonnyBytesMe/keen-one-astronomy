#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Mount Discovery Script
# ============================================================================
# Scans the local network for OnStepX mounts
# Can be sourced by init script or run standalone
#
# Usage:
#   source discover-mount.sh && discover_mount
#   OR
#   ./discover-mount.sh
# ============================================================================

# Default port for OnStepX
ONSTEP_PORT="${MOUNT_PORT:-9999}"

# Logging (use init script's logging if available, otherwise basic echo)
if ! declare -f log_info > /dev/null 2>&1; then
    log_info() { echo "[INFO]  $1"; }
    log_debug() { echo "[DEBUG] $1"; }
    log_warn() { echo "[WARN]  $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

# ============================================================================
# Get local network range
# ============================================================================
get_network_range() {
    # Get the primary IP address and derive network range
    local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$ip" ]; then
        ip=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
    fi

    if [ -n "$ip" ]; then
        # Convert to /24 network range (e.g., 192.168.0.1 -> 192.168.0)
        echo "$ip" | sed 's/\.[0-9]*$//'
    fi
}

# ============================================================================
# Check if a host has OnStepX running
# ============================================================================
check_onstep() {
    local host="$1"
    local port="${2:-$ONSTEP_PORT}"

    # Quick port check first
    if ! nc -z -w 1 "$host" "$port" 2>/dev/null; then
        return 1
    fi

    # Try to get OnStepX product name
    local response=$(echo -e ":GVP#" | nc -w 2 "$host" "$port" 2>/dev/null)

    # OnStepX responds with product name ending in #
    if [[ "$response" == *"OnStep"* ]] || [[ "$response" == *"#" ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# Scan network for OnStepX devices
# ============================================================================
scan_network() {
    local network_base="$1"
    local found_mounts=()

    log_info "Scanning network ${network_base}.0/24 for OnStepX devices..."

    # Scan common IP ranges (skip .0 and .255)
    for i in {1..254}; do
        local ip="${network_base}.${i}"

        # Quick parallel scan - check port first
        if nc -z -w 1 "$ip" "$ONSTEP_PORT" 2>/dev/null; then
            log_debug "Port $ONSTEP_PORT open on $ip, checking for OnStepX..."

            if check_onstep "$ip" "$ONSTEP_PORT"; then
                log_info "Found OnStepX mount at $ip:$ONSTEP_PORT"
                found_mounts+=("$ip")
            fi
        fi
    done &

    # Wait for background scan (with timeout)
    local scan_pid=$!
    local timeout=60
    local count=0

    while kill -0 $scan_pid 2>/dev/null && [ $count -lt $timeout ]; do
        sleep 1
        ((count++))
    done

    # Kill if still running
    kill $scan_pid 2>/dev/null || true

    echo "${found_mounts[@]}"
}

# ============================================================================
# Quick scan of common/likely IPs
# ============================================================================
quick_scan() {
    local network_base="$1"
    local common_endings=(86 100 101 102 1 2 10 20 50 150 200)
    local found=""

    log_debug "Quick scan of common IP addresses..."

    for ending in "${common_endings[@]}"; do
        local ip="${network_base}.${ending}"
        log_debug "Checking $ip..."

        if check_onstep "$ip" "$ONSTEP_PORT"; then
            log_info "Found OnStepX mount at $ip"
            found="$ip"
            break
        fi
    done

    echo "$found"
}

# ============================================================================
# Main discovery function
# ============================================================================
discover_mount() {
    local network_base=$(get_network_range)

    if [ -z "$network_base" ]; then
        log_warn "Could not determine network range"
        return 1
    fi

    log_debug "Network base: $network_base"

    # Try quick scan first (common IPs)
    local mount_ip=$(quick_scan "$network_base")

    if [ -n "$mount_ip" ]; then
        echo "$mount_ip"
        return 0
    fi

    # If quick scan fails, try known default (192.168.0.86)
    if [ "$network_base" = "192.168.0" ]; then
        log_debug "Trying default OnStepX IP 192.168.0.86..."
        if check_onstep "192.168.0.86" "$ONSTEP_PORT"; then
            echo "192.168.0.86"
            return 0
        fi
    fi

    log_warn "No OnStepX mount found on network"
    return 1
}

# ============================================================================
# Interactive mode (when run directly)
# ============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=============================================="
    echo "  OnStepX Mount Discovery"
    echo "=============================================="
    echo ""

    MOUNT_IP=$(discover_mount)

    if [ -n "$MOUNT_IP" ]; then
        echo ""
        echo "Found mount at: $MOUNT_IP:$ONSTEP_PORT"
        echo ""
        echo "To use this mount, set in your .env file:"
        echo "  MOUNT_IP=$MOUNT_IP"
        echo "  MOUNT_PORT=$ONSTEP_PORT"
    else
        echo ""
        echo "No OnStepX mount found on the network."
        echo ""
        echo "Please ensure:"
        echo "  1. Your mount is powered on"
        echo "  2. Mount is connected to the same network"
        echo "  3. OnStepX WiFi is configured correctly"
        echo ""
        echo "You can manually set the mount IP in .env:"
        echo "  MOUNT_IP=<your-mount-ip>"
        echo "  MOUNT_PORT=9999"
    fi
fi
