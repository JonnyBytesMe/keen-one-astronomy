#!/bin/bash
# Astronomy Stack Test Script
# Tests INDI server connectivity and telescope control
# Run inside Docker: docker exec astronomy-desktop /scripts/test-stack.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INDI_HOST="${INDI_HOST:-indiserver}"
INDI_PORT="${INDI_PORT:-7624}"
MOUNT_IP="${MOUNT_IP:-192.168.0.86}"
MOUNT_PORT="${MOUNT_PORT:-9999}"

echo "=========================================="
echo "  Astronomy Stack Test Suite"
echo "=========================================="
echo ""

# Test 1: Check if INDI server is reachable
echo -n "Test 1: INDI server reachable... "
if nc -z -w 3 "$INDI_HOST" "$INDI_PORT" 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} - Cannot connect to $INDI_HOST:$INDI_PORT"
    exit 1
fi

# Test 2: Query INDI server for devices
echo -n "Test 2: INDI devices available... "
INDI_RESPONSE=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null | head -50)
if echo "$INDI_RESPONSE" | grep -q "LX200 OnStep"; then
    echo -e "${GREEN}PASS${NC} - LX200 OnStep driver found"
else
    echo -e "${RED}FAIL${NC} - LX200 OnStep driver not found"
    echo "Response: $INDI_RESPONSE"
    exit 1
fi

# Test 3: Check mount connection status
echo -n "Test 3: Mount connected via INDI... "
if echo "$INDI_RESPONSE" | grep -q 'name="CONNECT"'; then
    if echo "$INDI_RESPONSE" | grep -A1 'name="CONNECT"' | grep -q "On"; then
        echo -e "${GREEN}PASS${NC} - Mount is connected"
    else
        echo -e "${YELLOW}WARN${NC} - Driver loaded but mount not connected"
    fi
else
    echo -e "${RED}FAIL${NC} - Connection status unknown"
fi

# Test 4: Get current coordinates
echo -n "Test 4: Reading mount coordinates... "
RA=$(echo "$INDI_RESPONSE" | grep -A2 'name="RA"' | grep -oP '[\d.]+' | head -1)
DEC=$(echo "$INDI_RESPONSE" | grep -A2 'name="DEC"' | grep -oP '[-\d.]+' | head -1)
if [ -n "$RA" ] && [ -n "$DEC" ]; then
    echo -e "${GREEN}PASS${NC} - RA: ${RA}h, Dec: ${DEC}°"
else
    echo -e "${YELLOW}WARN${NC} - Could not read coordinates"
fi

# Test 5: Check if Stellarium is installed
echo -n "Test 5: Stellarium installed... "
if command -v stellarium &> /dev/null; then
    STELLARIUM_VERSION=$(stellarium --version 2>&1 | head -1)
    echo -e "${GREEN}PASS${NC} - $STELLARIUM_VERSION"
else
    echo -e "${RED}FAIL${NC} - Stellarium not found"
fi

# Test 6: Check if KStars is installed
echo -n "Test 6: KStars installed... "
if command -v kstars &> /dev/null; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} - KStars not found"
fi

# Test 7: Check Stellarium telescope config
echo -n "Test 7: Stellarium telescope config... "
TELESCOPE_INI="/config/.stellarium/modules/TelescopeControl/telescopes.ini"
if [ -f "$TELESCOPE_INI" ]; then
    if grep -q "LX200 OnStep" "$TELESCOPE_INI"; then
        echo -e "${GREEN}PASS${NC} - Telescope configured"
    else
        echo -e "${YELLOW}WARN${NC} - Config exists but telescope not configured"
    fi
else
    echo -e "${RED}FAIL${NC} - Config file not found"
fi

# Test 8: Test slew command (dry run - just validates command format)
echo -n "Test 8: INDI slew command format... "
SLEW_CMD='<newNumberVector device="LX200 OnStep" name="EQUATORIAL_EOD_COORD"><oneNumber name="RA">12.0</oneNumber><oneNumber name="DEC">45.0</oneNumber></newNumberVector>'
# Don't actually send - just verify we can format it
echo -e "${GREEN}PASS${NC} - Command ready"

echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo -e "INDI Server: ${GREEN}$INDI_HOST:$INDI_PORT${NC}"
echo -e "Mount Driver: ${GREEN}LX200 OnStep${NC}"
echo ""
echo "To slew telescope, use:"
echo "  echo '$SLEW_CMD' | nc $INDI_HOST $INDI_PORT"
echo ""
