#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Comprehensive Self-Test
# ============================================================================
# Runs diagnostic tests on all components of the astronomy stack
# Can be run manually or automatically on startup
#
# Usage:
#   ./self-test.sh              # Run all tests
#   ./self-test.sh --quick      # Run quick tests only
#   ./self-test.sh --verbose    # Extra verbose output
# ============================================================================

set -o pipefail

# ============================================================================
# Configuration
# ============================================================================
INDI_HOST="${INDI_HOST:-indiserver}"
INDI_PORT="${INDI_PORT:-7624}"
MOUNT_IP="${MOUNT_IP:-}"
MOUNT_PORT="${MOUNT_PORT:-9999}"
MOUNT_DRIVER="${MOUNT_DRIVER:-LX200 OnStep}"

VERBOSE=false
QUICK_MODE=false
LOG_FILE="/config/.self-test.log"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            ;;
        --quick|-q)
            QUICK_MODE=true
            ;;
    esac
done

# ============================================================================
# Colors and Formatting
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0
TESTS_SKIPPED=0

# ============================================================================
# Output Functions
# ============================================================================
print_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_test() {
    printf "  %-40s " "$1"
}

print_pass() {
    echo -e "[${GREEN}PASS${NC}]"
    ((TESTS_PASSED++))
    echo "[PASS] $1" >> "$LOG_FILE"
}

print_fail() {
    echo -e "[${RED}FAIL${NC}] $1"
    ((TESTS_FAILED++))
    echo "[FAIL] $1 - $2" >> "$LOG_FILE"
}

print_warn() {
    echo -e "[${YELLOW}WARN${NC}] $1"
    ((TESTS_WARNED++))
    echo "[WARN] $1 - $2" >> "$LOG_FILE"
}

print_skip() {
    echo -e "[${BLUE}SKIP${NC}] $1"
    ((TESTS_SKIPPED++))
    echo "[SKIP] $1" >> "$LOG_FILE"
}

print_info() {
    if [ "$VERBOSE" = true ]; then
        echo -e "       ${BLUE}→${NC} $1"
    fi
}

# ============================================================================
# Test Functions
# ============================================================================

# Test: INDI Server Reachable
test_indi_server() {
    print_test "INDI server reachable"

    if nc -z -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null; then
        print_pass
        print_info "Connected to $INDI_HOST:$INDI_PORT"
        return 0
    else
        print_fail "Cannot connect to $INDI_HOST:$INDI_PORT"
        return 1
    fi
}

# Test: INDI Server Responding
test_indi_responding() {
    print_test "INDI server responding"

    local response=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null | head -5)

    if [ -n "$response" ]; then
        print_pass
        print_info "Received INDI protocol response"
        return 0
    else
        print_fail "No response from INDI server"
        return 1
    fi
}

# Test: Mount Driver Loaded
test_mount_driver() {
    print_test "Mount driver loaded ($MOUNT_DRIVER)"

    local response=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null)

    if echo "$response" | grep -q "$MOUNT_DRIVER"; then
        print_pass
        print_info "Driver $MOUNT_DRIVER found in INDI"
        return 0
    else
        print_fail "Driver not found"
        return 1
    fi
}

# Test: Mount Connected
test_mount_connected() {
    print_test "Mount connected"

    local response=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null)

    # Check CONNECTION property - look for CONNECT switch being On
    if echo "$response" | grep -A5 'name="CONNECTION"' | grep -q 'state="Ok"'; then
        local connect_state=$(echo "$response" | grep -A10 'name="CONNECTION"' | grep -A2 'name="CONNECT"' | grep -o '>.*<' | tr -d '><' | tr -d '[:space:]')
        if [ "$connect_state" = "On" ]; then
            print_pass
            print_info "Mount is connected and responding"
            return 0
        fi
    fi

    print_warn "Mount driver loaded but not connected"
    return 1
}

# Test: Can Read Coordinates
test_read_coordinates() {
    print_test "Can read mount coordinates"

    local response=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null)

    local ra=$(echo "$response" | grep -A5 'name="EQUATORIAL_EOD_COORD"' | grep -A2 'name="RA"' | grep -oP '[-0-9.]+' | head -1)
    local dec=$(echo "$response" | grep -A5 'name="EQUATORIAL_EOD_COORD"' | grep -A2 'name="DEC"' | grep -oP '[-0-9.]+' | head -1)

    if [ -n "$ra" ] && [ -n "$dec" ]; then
        print_pass
        # Convert RA to hours:minutes format
        local ra_h=$(echo "$ra" | cut -d. -f1)
        local ra_m=$(echo "scale=0; ($ra - $ra_h) * 60" | bc 2>/dev/null || echo "??")
        print_info "Current position: RA ${ra_h}h${ra_m}m, Dec ${dec}°"
        return 0
    else
        print_fail "Could not read coordinates"
        return 1
    fi
}

# Test: GPS Data Available
test_gps_data() {
    print_test "GPS location data"

    local response=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null)

    local lat=$(echo "$response" | grep -A20 "GEOGRAPHIC_COORD" | grep -A2 'name="LAT"' | grep -oP '[-0-9.]+' | head -1)
    local lon=$(echo "$response" | grep -A20 "GEOGRAPHIC_COORD" | grep -A2 'name="LONG"' | grep -oP '[-0-9.]+' | head -1)

    if [ -n "$lat" ] && [ -n "$lon" ]; then
        print_pass
        print_info "Location: Lat $lat, Long $lon"
        return 0
    else
        print_warn "GPS data not available"
        return 1
    fi
}

# Test: Stellarium Config Exists
test_stellarium_config() {
    print_test "Stellarium telescope config"

    local config_file="/config/.stellarium/modules/TelescopeControl/telescopes.json"

    if [ -f "$config_file" ]; then
        # Validate JSON and check for required fields
        if grep -q '"version": "0.4.1"' "$config_file" && grep -q '"connection": "INDI"' "$config_file"; then
            print_pass
            print_info "Valid telescopes.json with INDI connection"
            return 0
        else
            print_warn "Config exists but may be invalid"
            return 1
        fi
    else
        print_fail "Config file not found"
        return 1
    fi
}

# Test: KStars Ekos Profile
test_kstars_profile() {
    print_test "KStars Ekos profile"

    local profile_file="/config/.local/share/kstars/ekos_profiles.xml"

    if [ -f "$profile_file" ]; then
        if grep -q "Keen-One EQ" "$profile_file" && grep -q "<mode>1</mode>" "$profile_file"; then
            print_pass
            print_info "Keen-One EQ profile configured for remote INDI"
            return 0
        else
            print_warn "Profile exists but may be misconfigured"
            return 1
        fi
    else
        print_fail "Profile file not found"
        return 1
    fi
}

# Test: Desktop Shortcuts
test_desktop_shortcuts() {
    print_test "Desktop shortcuts"

    local desktop="/config/Desktop"
    local missing=()

    [ ! -f "$desktop/Stellarium.desktop" ] && missing+=("Stellarium")
    [ ! -f "$desktop/KStars.desktop" ] && missing+=("KStars")
    [ ! -f "$desktop/System-Diagnostics.desktop" ] && missing+=("Diagnostics")

    if [ ${#missing[@]} -eq 0 ]; then
        print_pass
        return 0
    elif [ ${#missing[@]} -lt 3 ]; then
        print_warn "Missing: ${missing[*]}"
        return 1
    else
        print_fail "Shortcuts not created"
        return 1
    fi
}

# Test: Slew Command (dry run - doesn't actually slew)
test_slew_capability() {
    if [ "$QUICK_MODE" = true ]; then
        print_test "Slew capability"
        print_skip "Quick mode"
        return 0
    fi

    print_test "Slew command capability"

    # Get current coordinates first
    local response=$(echo '<getProperties version="1.7"/>' | nc -w 5 "$INDI_HOST" "$INDI_PORT" 2>/dev/null)
    local ra=$(echo "$response" | grep -A10 'name="EQUATORIAL_EOD_COORD"' | grep -A2 'name="RA"' | grep -oP '[-0-9.]+' | head -1)
    local dec=$(echo "$response" | grep -A10 'name="EQUATORIAL_EOD_COORD"' | grep -A2 'name="DEC"' | grep -oP '[-0-9.]+' | head -1)

    if [ -z "$ra" ] || [ -z "$dec" ]; then
        print_skip "No coordinates available"
        return 0
    fi

    # Send a tiny slew (0.001 degree offset - barely moves)
    local test_ra=$(echo "$ra + 0.0001" | bc 2>/dev/null || echo "$ra")

    local slew_response=$(echo "<newNumberVector device=\"$MOUNT_DRIVER\" name=\"EQUATORIAL_EOD_COORD\"><oneNumber name=\"RA\">$test_ra</oneNumber><oneNumber name=\"DEC\">$dec</oneNumber></newNumberVector>" | nc -w 3 "$INDI_HOST" "$INDI_PORT" 2>/dev/null)

    if echo "$slew_response" | grep -qE "(Ok|Busy)"; then
        print_pass
        print_info "Slew command accepted by mount"

        # Abort the slew immediately
        echo "<newSwitchVector device=\"$MOUNT_DRIVER\" name=\"TELESCOPE_ABORT_MOTION\"><oneSwitch name=\"ABORT\">On</oneSwitch></newSwitchVector>" | nc -w 2 "$INDI_HOST" "$INDI_PORT" >/dev/null 2>&1
        return 0
    else
        print_warn "Slew response unclear"
        return 1
    fi
}

# Test: Mount Direct Connection (if IP known)
test_mount_direct() {
    if [ -z "$MOUNT_IP" ]; then
        print_test "Direct mount connection"
        print_skip "MOUNT_IP not set"
        return 0
    fi

    print_test "Direct mount connection ($MOUNT_IP)"

    if nc -z -w 3 "$MOUNT_IP" "$MOUNT_PORT" 2>/dev/null; then
        # Try to get OnStepX version
        local version=$(echo -e ":GVN#" | nc -w 2 "$MOUNT_IP" "$MOUNT_PORT" 2>/dev/null | tr -d '#')
        if [ -n "$version" ]; then
            print_pass
            print_info "OnStepX version: $version"
            return 0
        else
            print_pass
            print_info "Port open, mount responding"
            return 0
        fi
    else
        print_fail "Cannot reach $MOUNT_IP:$MOUNT_PORT"
        return 1
    fi
}

# ============================================================================
# Main Test Runner
# ============================================================================
run_tests() {
    # Initialize log
    echo "Self-Test Run: $(date)" > "$LOG_FILE"
    echo "========================" >> "$LOG_FILE"

    echo ""
    echo "=============================================="
    echo "  Keen-One Astronomy Stack - Self Test"
    echo "=============================================="
    echo "  $(date)"
    [ "$QUICK_MODE" = true ] && echo "  Mode: Quick"
    [ "$VERBOSE" = true ] && echo "  Mode: Verbose"
    echo ""

    # Network Tests
    print_header "Network Connectivity"
    test_indi_server
    INDI_OK=$?

    if [ $INDI_OK -eq 0 ]; then
        test_indi_responding
    fi

    test_mount_direct

    # INDI Tests (only if server is reachable)
    if [ $INDI_OK -eq 0 ]; then
        print_header "INDI Telescope Control"
        test_mount_driver
        test_mount_connected
        test_read_coordinates
        test_gps_data
        test_slew_capability
    else
        print_header "INDI Telescope Control"
        echo "  Skipping - INDI server not reachable"
        ((TESTS_SKIPPED+=5))
    fi

    # Configuration Tests
    print_header "Configuration Files"
    test_stellarium_config
    test_kstars_profile
    test_desktop_shortcuts

    # Summary
    print_header "Test Summary"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Warnings:${NC} $TESTS_WARNED"
    echo -e "  ${BLUE}Skipped:${NC} $TESTS_SKIPPED"
    echo ""

    # Overall result
    if [ $TESTS_FAILED -eq 0 ]; then
        if [ $TESTS_WARNED -eq 0 ]; then
            echo -e "  ${GREEN}${BOLD}All tests passed!${NC}"
            echo ""
            echo "  Your astronomy stack is ready to use."
        else
            echo -e "  ${YELLOW}${BOLD}Tests passed with warnings${NC}"
            echo ""
            echo "  Stack is functional but some features may need attention."
        fi
        RESULT=0
    else
        echo -e "  ${RED}${BOLD}Some tests failed${NC}"
        echo ""
        echo "  Please check the issues above and consult TROUBLESHOOTING.md"
        RESULT=1
    fi

    echo ""
    echo "  Log saved to: $LOG_FILE"
    echo ""

    # Save summary to log
    echo "" >> "$LOG_FILE"
    echo "Summary: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_WARNED warnings, $TESTS_SKIPPED skipped" >> "$LOG_FILE"

    return $RESULT
}

# ============================================================================
# Suggested Fixes
# ============================================================================
suggest_fixes() {
    if [ $TESTS_FAILED -gt 0 ]; then
        echo ""
        print_header "Suggested Fixes"

        if ! nc -z "$INDI_HOST" "$INDI_PORT" 2>/dev/null; then
            echo "  • INDI server not reachable:"
            echo "    - Check if indiserver container is running: docker ps"
            echo "    - Check container logs: docker logs indiserver"
            echo "    - Verify network: docker network inspect astronomy"
            echo ""
        fi

        if [ -n "$MOUNT_IP" ] && ! nc -z "$MOUNT_IP" "$MOUNT_PORT" 2>/dev/null; then
            echo "  • Mount not reachable at $MOUNT_IP:$MOUNT_PORT:"
            echo "    - Verify mount is powered on"
            echo "    - Check WiFi connection on mount"
            echo "    - Verify IP address is correct"
            echo "    - Try: ping $MOUNT_IP"
            echo ""
        fi

        if [ ! -f "/config/.stellarium/modules/TelescopeControl/telescopes.json" ]; then
            echo "  • Stellarium config missing:"
            echo "    - Restart the astronomy-desktop container"
            echo "    - Check init script logs: docker logs astronomy-desktop"
            echo ""
        fi
    fi
}

# ============================================================================
# Entry Point
# ============================================================================
run_tests
EXIT_CODE=$?

suggest_fixes

exit $EXIT_CODE
