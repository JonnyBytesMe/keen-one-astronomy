#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Initialization Script
# ============================================================================
# This script runs on container startup to configure astronomy software
# Pre-configures Stellarium and KStars for INDI telescope control
#
# Environment Variables:
#   LOG_LEVEL          - 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG (default: 2)
#   MOUNT_IP           - Mount IP address (blank = auto-discover)
#   MOUNT_PORT         - Mount port (default: 9999)
#   INDI_HOST          - INDI server hostname (default: indiserver)
#   INDI_PORT          - INDI server port (default: 7624)
#   USE_GPS_LOCATION   - Use GPS from mount for location (default: true)
#   LATITUDE           - Manual latitude (used if GPS unavailable)
#   LONGITUDE          - Manual longitude (used if GPS unavailable)
#   ELEVATION          - Manual elevation (used if GPS unavailable)
#   SELF_TEST_ON_BOOT  - Run self-test after init (default: false)
#   SELF_TEST_ON_RESTART - Run self-test on every restart (default: false)
# ============================================================================

# Exit on error, but allow error handling
set -e

# ============================================================================
# Logging System
# ============================================================================
LOG_LEVEL=${LOG_LEVEL:-2}  # Default to INFO
LOG_FILE="/config/.astronomy-init.log"

# ANSI colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(timestamp) $1" | tee -a "$LOG_FILE"
}

log_warn() {
    [[ $LOG_LEVEL -ge 1 ]] && echo -e "${YELLOW}[WARN]${NC}  $(timestamp) $1" | tee -a "$LOG_FILE"
}

log_info() {
    [[ $LOG_LEVEL -ge 2 ]] && echo -e "${GREEN}[INFO]${NC}  $(timestamp) $1" | tee -a "$LOG_FILE"
}

log_debug() {
    [[ $LOG_LEVEL -ge 3 ]] && echo -e "${BLUE}[DEBUG]${NC} $(timestamp) $1" | tee -a "$LOG_FILE"
}

# ============================================================================
# Configuration
# ============================================================================
USER_HOME="/config"
INDI_HOST="${INDI_HOST:-indiserver}"
INDI_PORT="${INDI_PORT:-7624}"
MOUNT_IP="${MOUNT_IP:-}"
MOUNT_PORT="${MOUNT_PORT:-9999}"
MOUNT_DRIVER="${MOUNT_DRIVER:-LX200 OnStep}"
USE_GPS_LOCATION="${USE_GPS_LOCATION:-true}"
LATITUDE="${LATITUDE:-54.8}"
LONGITUDE="${LONGITUDE:-6.13}"
ELEVATION="${ELEVATION:-0}"
SELF_TEST_ON_BOOT="${SELF_TEST_ON_BOOT:-false}"
SELF_TEST_ON_RESTART="${SELF_TEST_ON_RESTART:-false}"

# Track if this is first boot
FIRST_BOOT_MARKER="${USER_HOME}/.astronomy-initialized"

# ============================================================================
# Header
# ============================================================================
echo ""
echo "=============================================="
echo "  Keen-One Astronomy Desktop Initialization"
echo "=============================================="
echo ""
log_info "Starting initialization..."
log_debug "LOG_LEVEL=$LOG_LEVEL"
log_debug "INDI_HOST=$INDI_HOST, INDI_PORT=$INDI_PORT"
log_debug "MOUNT_IP=$MOUNT_IP, MOUNT_PORT=$MOUNT_PORT"

# ============================================================================
# Wait for INDI Server
# ============================================================================
log_info "Waiting for INDI server..."
INDI_READY=false
for i in {1..30}; do
    if nc -z "$INDI_HOST" "$INDI_PORT" 2>/dev/null; then
        log_info "INDI server available at $INDI_HOST:$INDI_PORT"
        INDI_READY=true
        break
    fi
    log_debug "Attempt $i/30 - INDI server not ready, waiting..."
    sleep 1
done

if [ "$INDI_READY" = false ]; then
    log_warn "INDI server not available after 30 seconds - continuing anyway"
fi

# ============================================================================
# Mount Discovery (if MOUNT_IP not set)
# ============================================================================
if [ -z "$MOUNT_IP" ] && [ -f "/scripts/discover-mount.sh" ]; then
    log_info "MOUNT_IP not set, attempting auto-discovery..."
    source /scripts/discover-mount.sh
    DISCOVERED_IP=$(discover_mount)
    if [ -n "$DISCOVERED_IP" ]; then
        MOUNT_IP="$DISCOVERED_IP"
        log_info "Discovered mount at $MOUNT_IP"
    else
        log_warn "Mount auto-discovery failed - mount may need manual configuration"
    fi
elif [ -n "$MOUNT_IP" ]; then
    log_debug "Using configured MOUNT_IP=$MOUNT_IP"
fi

# ============================================================================
# GPS Location Query
# ============================================================================
if [ "$USE_GPS_LOCATION" = "true" ] && [ "$INDI_READY" = true ]; then
    log_info "Querying GPS location from mount..."

    GPS_DATA=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null | grep -A20 "GEOGRAPHIC_COORD" || true)

    if [ -n "$GPS_DATA" ]; then
        # Extract latitude
        GPS_LAT=$(echo "$GPS_DATA" | grep -A2 'name="LAT"' | grep -oP '[-0-9.]+' | head -1)
        GPS_LONG=$(echo "$GPS_DATA" | grep -A2 'name="LONG"' | grep -oP '[-0-9.]+' | head -1)
        GPS_ELEV=$(echo "$GPS_DATA" | grep -A2 'name="ELEV"' | grep -oP '[-0-9.]+' | head -1)

        if [ -n "$GPS_LAT" ] && [ -n "$GPS_LONG" ]; then
            LATITUDE="$GPS_LAT"
            LONGITUDE="$GPS_LONG"
            [ -n "$GPS_ELEV" ] && ELEVATION="$GPS_ELEV"
            log_info "GPS location acquired: Lat=$LATITUDE, Long=$LONGITUDE, Elev=$ELEVATION"
        else
            log_warn "GPS data incomplete, using defaults: Lat=$LATITUDE, Long=$LONGITUDE"
        fi
    else
        log_warn "No GPS data available from mount, using defaults"
    fi
else
    log_debug "GPS query disabled or INDI not ready, using configured location"
fi

# ============================================================================
# Stellarium Configuration
# ============================================================================
STELLARIUM_DIR="${USER_HOME}/.stellarium"
STELLARIUM_MODULES="${STELLARIUM_DIR}/modules/TelescopeControl"

log_info "Configuring Stellarium..."
log_debug "Stellarium directory: $STELLARIUM_DIR"

mkdir -p "${STELLARIUM_MODULES}"

# Main config - enable TelescopeControl plugin
# Stellarium 24.x uses [plugins_load_at_startup] section
if [ ! -f "${STELLARIUM_DIR}/config.ini" ]; then
    log_debug "Creating Stellarium config.ini with TelescopeControl enabled"
    cat > "${STELLARIUM_DIR}/config.ini" << 'EOF'
[plugins_load_at_startup]
TelescopeControl = true

[TelescopeControl]
flag_telescope_circles = true
flag_telescope_labels = true
flag_telescope_reticles = true
use_telescope_server_logs = false
use_executable_telescopes = false
use_telescope_server = false
EOF
    log_info "Created Stellarium config with TelescopeControl enabled"
elif ! grep -q "\[plugins_load_at_startup\]" "${STELLARIUM_DIR}/config.ini" 2>/dev/null; then
    log_debug "Adding plugins_load_at_startup section to existing config.ini"
    cat >> "${STELLARIUM_DIR}/config.ini" << 'EOF'

[plugins_load_at_startup]
TelescopeControl = true

[TelescopeControl]
flag_telescope_circles = true
flag_telescope_labels = true
flag_telescope_reticles = true
use_telescope_server_logs = false
use_executable_telescopes = false
use_telescope_server = false
EOF
    log_info "Added TelescopeControl to existing config"
elif ! grep -q "TelescopeControl = true" "${STELLARIUM_DIR}/config.ini" 2>/dev/null; then
    log_debug "Enabling TelescopeControl plugin in config.ini"
    sed -i 's/\[plugins_load_at_startup\]/[plugins_load_at_startup]\nTelescopeControl = true/' "${STELLARIUM_DIR}/config.ini"
    log_info "Enabled TelescopeControl plugin"
else
    log_debug "TelescopeControl already configured in config.ini"
fi

# Telescope configuration for Stellarium TelescopeControl plugin
# Note: Stellarium uses LX200 protocol over TCP, not INDI protocol
# Connect directly to mount if MOUNT_IP is set, otherwise show instructions
log_debug "Creating telescopes.json for Stellarium"

if [ -n "$MOUNT_IP" ]; then
    # Direct connection to mount using LX200 protocol
    cat > "${STELLARIUM_MODULES}/telescopes.json" << EOF
{
    "version": "0.4.1",
    "1": {
        "name": "Keen-One EQ Mount",
        "connection": "external",
        "equinox": "JNow",
        "host_name": "${MOUNT_IP}",
        "tcp_port": ${MOUNT_PORT},
        "delay": 500000,
        "connect_at_startup": false,
        "circles": [0.5, 1.0, 2.0]
    }
}
EOF
    log_info "Created Stellarium telescope config (LX200: ${MOUNT_IP}:${MOUNT_PORT})"
else
    # No mount IP - create placeholder config
    cat > "${STELLARIUM_MODULES}/telescopes.json" << EOF
{
    "version": "0.4.1",
    "1": {
        "name": "Configure in Stellarium",
        "connection": "external",
        "equinox": "JNow",
        "host_name": "localhost",
        "tcp_port": 10001,
        "delay": 500000,
        "connect_at_startup": false,
        "circles": [0.5, 1.0]
    }
}
EOF
    log_warn "MOUNT_IP not set - Stellarium telescope requires manual configuration"
    log_info "Use KStars/Ekos for telescope control via INDI, or configure Stellarium manually"
fi

chown -R abc:abc "${STELLARIUM_DIR}" 2>/dev/null || true

# ============================================================================
# KStars / Ekos Configuration
# ============================================================================
KSTARS_DIR="${USER_HOME}/.local/share/kstars"
KSTARS_CONFIG="${USER_HOME}/.config/kstarsrc"

log_info "Configuring KStars/Ekos..."
log_debug "KStars directory: $KSTARS_DIR"

mkdir -p "${KSTARS_DIR}"
mkdir -p "$(dirname ${KSTARS_CONFIG})"

# Create Ekos profile for remote INDI server
log_debug "Creating Ekos profiles"
cat > "${KSTARS_DIR}/ekos_profiles.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE profiles>
<profiles>
  <profile id="keen-one" name="Keen-One EQ">
    <auto_connect>1</auto_connect>
    <port_selector>0</port_selector>
    <mode>1</mode>
    <remote_indi_host>${INDI_HOST}</remote_indi_host>
    <remote_indi_port>${INDI_PORT}</remote_indi_port>
    <remote_indi_web_manager>0</remote_indi_web_manager>
    <drivers>
      <mount>${MOUNT_DRIVER}</mount>
    </drivers>
    <guider_type>0</guider_type>
  </profile>
  <profile id="simulators" name="Simulators">
    <auto_connect>1</auto_connect>
    <port_selector>0</port_selector>
    <mode>0</mode>
    <drivers>
      <mount>Telescope Simulator</mount>
      <ccd>CCD Simulator</ccd>
    </drivers>
    <guider_type>0</guider_type>
  </profile>
</profiles>
EOF
log_info "Created Ekos profile 'Keen-One EQ'"

# KStars config with INDI settings and location
log_debug "Creating KStars config with location: Lat=$LATITUDE, Long=$LONGITUDE"
cat > "${KSTARS_CONFIG}" << EOF
[Ekos]
profile=Keen-One EQ
DefaultProfile=Keen-One EQ

[INDI]
INDIServerHost=${INDI_HOST}
INDIServerPort=${INDI_PORT}

[Location]
CityName=Observatory
CountryName=
Elevation=${ELEVATION}
Latitude=${LATITUDE}
Longitude=${LONGITUDE}
TimeZone=0
DST=EU
EOF
log_info "Set KStars location: Lat=$LATITUDE, Long=$LONGITUDE, Elev=$ELEVATION"

chown -R abc:abc "${KSTARS_DIR}" 2>/dev/null || true
chown -R abc:abc "$(dirname ${KSTARS_CONFIG})" 2>/dev/null || true

# ============================================================================
# ASTAP Plate Solving Setup
# ============================================================================
# D50 star database enables fast offline plate solving (~2-8 second solves)
#
# Pre-built image: Catalog is at /usr/share/astap/data (baked into image)
# Dev mode: Download to user config dir if not present
#
ASTAP_SYSTEM_DATA="/usr/share/astap/data"
ASTAP_USER_DATA="${USER_HOME}/.local/share/astap"
ASTAP_D50_MARKER="${ASTAP_USER_DATA}/.d50_installed"

if command -v astap &> /dev/null; then
    # Check if D50 is already installed (system or user location)
    if [ -d "$ASTAP_SYSTEM_DATA" ] && ls "$ASTAP_SYSTEM_DATA"/*.1476 &>/dev/null 2>&1; then
        log_info "ASTAP D50 database found (system location)"
        log_debug "Plate solving ready: 2-8 second solves for most fields"
    elif [ -f "$ASTAP_D50_MARKER" ]; then
        log_debug "ASTAP D50 database already installed (user location)"
    else
        # Dev mode - download catalog
        log_info "ASTAP found - downloading D50 star database (this may take a few minutes)..."
        mkdir -p "${ASTAP_USER_DATA}"

        D50_URL="https://downloads.sourceforge.net/project/astap-program/star_databases/d50_star_database.zip"
        D50_ZIP="/tmp/d50_star_database.zip"

        if curl -fsSL --connect-timeout 30 --max-time 600 -o "$D50_ZIP" "$D50_URL" 2>/dev/null; then
            log_info "Download complete, extracting..."
            if unzip -q -o "$D50_ZIP" -d "${ASTAP_USER_DATA}/" 2>/dev/null; then
                touch "$ASTAP_D50_MARKER"
                rm -f "$D50_ZIP"
                log_info "ASTAP D50 star database installed successfully"
            else
                log_warn "Failed to extract D50 database - plate solving may be slower"
                rm -f "$D50_ZIP"
            fi
        else
            log_warn "Failed to download D50 database - plate solving will use online solver"
        fi
    fi

    chown -R abc:abc "${ASTAP_USER_DATA}" 2>/dev/null || true
else
    log_debug "ASTAP not installed - skipping star database setup"
fi

# ============================================================================
# Desktop Shortcuts
# ============================================================================
DESKTOP="${USER_HOME}/Desktop"
mkdir -p "${DESKTOP}"

log_info "Creating desktop shortcuts..."

# Stellarium
cat > "${DESKTOP}/Stellarium.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Stellarium
Comment=Planetarium - Telescope Control Enabled
GenericName=Planetarium
Exec=stellarium
Icon=stellarium
Terminal=false
Categories=Education;Science;Astronomy;
StartupNotify=true
EOF
chmod +x "${DESKTOP}/Stellarium.desktop"
log_debug "Created Stellarium shortcut"

# KStars
cat > "${DESKTOP}/KStars.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=KStars
Comment=Desktop Planetarium with Ekos Astrophotography Suite
GenericName=Desktop Planetarium
Exec=kstars
Icon=kstars
Terminal=false
Categories=Education;Science;Astronomy;
StartupNotify=true
EOF
chmod +x "${DESKTOP}/KStars.desktop"
log_debug "Created KStars shortcut"

# System Diagnostics
cat > "${DESKTOP}/System-Diagnostics.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=System Diagnostics
Comment=Run astronomy stack self-test
Exec=bash -c '/scripts/self-test.sh; echo ""; echo "Press Enter to close..."; read'
Icon=dialog-information
Terminal=true
Categories=Utility;
EOF
chmod +x "${DESKTOP}/System-Diagnostics.desktop"
log_debug "Created System Diagnostics shortcut"

# INDI Status
cat > "${DESKTOP}/Check-INDI.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Check INDI Status
Comment=View INDI server and mount status
Exec=bash -c 'echo "=== INDI Server Status ===" && echo "" && echo "Checking ${INDI_HOST}:${INDI_PORT}..." && nc -z ${INDI_HOST} ${INDI_PORT} && echo "INDI Server: ONLINE" || echo "INDI Server: OFFLINE"; echo "" && echo "Press Enter to close..." && read'
Icon=network-server
Terminal=true
Categories=Utility;
EOF
chmod +x "${DESKTOP}/Check-INDI.desktop"
log_debug "Created INDI Status shortcut"

chown -R abc:abc "${DESKTOP}" 2>/dev/null || true

# ============================================================================
# First Boot Marker
# ============================================================================
IS_FIRST_BOOT=false
if [ ! -f "$FIRST_BOOT_MARKER" ]; then
    IS_FIRST_BOOT=true
    touch "$FIRST_BOOT_MARKER"
    log_debug "First boot detected, created marker file"
fi

# ============================================================================
# Self-Test (if enabled)
# ============================================================================
RUN_SELF_TEST=false

if [ "$IS_FIRST_BOOT" = true ] && [ "$SELF_TEST_ON_BOOT" = "true" ]; then
    RUN_SELF_TEST=true
    log_debug "Self-test enabled for first boot"
elif [ "$IS_FIRST_BOOT" = false ] && [ "$SELF_TEST_ON_RESTART" = "true" ]; then
    RUN_SELF_TEST=true
    log_debug "Self-test enabled for restart"
fi

if [ "$RUN_SELF_TEST" = true ] && [ -f "/scripts/self-test.sh" ]; then
    log_info "Running self-test..."
    /scripts/self-test.sh || log_warn "Self-test reported issues"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=============================================="
echo "  Initialization Complete!"
echo "=============================================="
echo ""
log_info "Configuration summary:"
echo "  INDI Server:    ${INDI_HOST}:${INDI_PORT}"
echo "  Mount Driver:   ${MOUNT_DRIVER}"
[ -n "$MOUNT_IP" ] && echo "  Mount IP:       ${MOUNT_IP}:${MOUNT_PORT}"
echo "  Location:       Lat ${LATITUDE}, Long ${LONGITUDE}, Elev ${ELEVATION}m"
echo "  Log File:       ${LOG_FILE}"
echo ""
echo "To use:"
echo "  1. Launch Stellarium or KStars from desktop"
echo "  2. Stellarium: Press Ctrl+0 for Telescope Control"
echo "  3. KStars: Tools -> Ekos (profile pre-configured)"
echo "  4. Run 'System Diagnostics' to test the stack"
echo ""
log_info "Initialization completed successfully"
