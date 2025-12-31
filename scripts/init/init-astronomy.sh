#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Initialization Script
# ============================================================================
# This script runs on container startup to configure astronomy software
# Pre-configures Stellarium and KStars for INDI telescope control
# ============================================================================

set -e

echo "=============================================="
echo "  Keen-One Astronomy Desktop Initialization"
echo "=============================================="

# Configuration
USER_HOME="/config"
INDI_HOST="indiserver"
INDI_PORT="7624"
MOUNT_DEVICE="LX200 OnStep"

# ============================================================================
# Wait for INDI Server
# ============================================================================
echo "Waiting for INDI server..."
for i in {1..30}; do
    if nc -z "$INDI_HOST" "$INDI_PORT" 2>/dev/null; then
        echo "  INDI server is available at $INDI_HOST:$INDI_PORT"
        break
    fi
    sleep 1
done

# ============================================================================
# Stellarium Configuration
# ============================================================================
STELLARIUM_DIR="${USER_HOME}/.stellarium"
STELLARIUM_MODULES="${STELLARIUM_DIR}/modules/TelescopeControl"

echo ""
echo "Configuring Stellarium..."

mkdir -p "${STELLARIUM_MODULES}"

# Main config - enable TelescopeControl plugin
if [ ! -f "${STELLARIUM_DIR}/config.ini" ] || ! grep -q "TelescopeControl" "${STELLARIUM_DIR}/config.ini" 2>/dev/null; then
    cat >> "${STELLARIUM_DIR}/config.ini" << 'EOF'

[plugins]
TelescopeControl = true
TelescopeControl_autoEnableAtStartup = false

[TelescopeControl]
flag_telescope_circles = true
flag_telescope_labels = true
flag_telescope_reticles = true
use_telescope_server_logs = false
EOF
    echo "  - Enabled TelescopeControl plugin"
fi

# Telescope configuration for INDI (JSON format for Stellarium 24.4+)
cat > "${STELLARIUM_MODULES}/telescopes.json" << EOF
{
    "version": "0.4.1",
    "1": {
        "name": "Keen-One EQ Mount",
        "connection": "INDI",
        "equinox": "JNow",
        "host_name": "${INDI_HOST}",
        "tcp_port": ${INDI_PORT},
        "device_model": "${MOUNT_DEVICE}",
        "delay": 500000,
        "connect_at_startup": true,
        "circles": [0.5, 1.0]
    }
}
EOF
echo "  - Created telescope configuration (INDI: ${INDI_HOST}:${INDI_PORT})"

chown -R abc:abc "${STELLARIUM_DIR}"

# ============================================================================
# KStars / Ekos Configuration
# ============================================================================
KSTARS_DIR="${USER_HOME}/.local/share/kstars"
KSTARS_CONFIG="${USER_HOME}/.config/kstarsrc"

echo ""
echo "Configuring KStars/Ekos..."

mkdir -p "${KSTARS_DIR}"
mkdir -p "$(dirname ${KSTARS_CONFIG})"

# Create Ekos profile for remote INDI server
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
      <mount>LX200 OnStep</mount>
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
echo "  - Created Ekos profile 'Keen-One EQ'"

# KStars config with INDI settings
cat > "${KSTARS_CONFIG}" << EOF
[Ekos]
profile=Keen-One EQ
DefaultProfile=Keen-One EQ

[INDI]
INDIServerHost=${INDI_HOST}
INDIServerPort=${INDI_PORT}

[Location]
CityName=Custom
CountryName=
Elevation=0
Latitude=54.8
Longitude=-6.13
TimeZone=0
DST=EU
EOF
echo "  - Set default Ekos profile and INDI server"

chown -R abc:abc "${KSTARS_DIR}"
chown -R abc:abc "$(dirname ${KSTARS_CONFIG})"

# ============================================================================
# Desktop Shortcuts
# ============================================================================
DESKTOP="${USER_HOME}/Desktop"
mkdir -p "${DESKTOP}"

echo ""
echo "Creating desktop shortcuts..."

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

# INDI Status script
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

chown -R abc:abc "${DESKTOP}"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=============================================="
echo "  Initialization Complete!"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  INDI Server: ${INDI_HOST}:${INDI_PORT}"
echo "  Mount Device: ${MOUNT_DEVICE}"
echo "  GPS: Available via mount (auto time/location sync)"
echo ""
echo "To use:"
echo "  1. Launch Stellarium or KStars from desktop"
echo "  2. Stellarium: Press Ctrl+0 for Telescope Control"
echo "  3. KStars: Tools -> Ekos (profile pre-configured)"
echo ""
echo "Mount is configured with GPS - time and location sync automatically"
echo ""
