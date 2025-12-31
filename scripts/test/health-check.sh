#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Docker Health Check
# ============================================================================
# Quick health check for Docker healthcheck directive
# Returns 0 (healthy) or 1 (unhealthy)
#
# Checks:
#   1. INDI server reachable
#   2. Configuration files exist
# ============================================================================

INDI_HOST="${INDI_HOST:-indiserver}"
INDI_PORT="${INDI_PORT:-7624}"

# Check 1: INDI server reachable
if ! nc -z -w 3 "$INDI_HOST" "$INDI_PORT" 2>/dev/null; then
    echo "UNHEALTHY: INDI server not reachable"
    exit 1
fi

# Check 2: Stellarium config exists
if [ ! -f "/config/.stellarium/modules/TelescopeControl/telescopes.json" ]; then
    echo "UNHEALTHY: Stellarium config missing"
    exit 1
fi

# Check 3: KStars profile exists
if [ ! -f "/config/.local/share/kstars/ekos_profiles.xml" ]; then
    echo "UNHEALTHY: KStars profile missing"
    exit 1
fi

echo "HEALTHY: All checks passed"
exit 0
