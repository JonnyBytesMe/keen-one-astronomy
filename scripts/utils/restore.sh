#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Restore Utility
# ============================================================================
# Restores astronomy stack data from a backup
#
# Usage:
#   ./restore.sh /path/to/backup
# ============================================================================

set -e

# Configuration
BACKUP_DIR="$1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 /path/to/backup"
    echo ""
    echo "Available backups:"
    ls -d ./backups/*/ 2>/dev/null || echo "  No backups found in ./backups/"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Error:${NC} Backup directory not found: $BACKUP_DIR"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Keen-One Astronomy Stack - Restore"
echo "=============================================="
echo ""
echo -e "${YELLOW}WARNING:${NC} This will overwrite current configuration!"
echo ""
echo "Backup to restore: $BACKUP_DIR"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""

# Stop containers
echo "  [1/4] Stopping containers..."
docker compose down 2>/dev/null || true
echo "        → Containers stopped"

# Restore Docker volume
echo "  [2/4] Restoring Docker volume..."
if [ -f "$BACKUP_DIR/docker-volumes/astronomy-desktop-config.tar.gz" ]; then
    # Remove existing volume
    docker volume rm astronomy-desktop-config 2>/dev/null || true

    # Create fresh volume
    docker volume create astronomy-desktop-config >/dev/null

    # Restore data
    docker run --rm \
        -v astronomy-desktop-config:/data \
        -v "$(cd "$BACKUP_DIR/docker-volumes" && pwd)":/backup:ro \
        alpine sh -c "cd /data && tar xzf /backup/astronomy-desktop-config.tar.gz"

    echo -e "        ${GREEN}→ Volume restored${NC}"
else
    echo -e "        ${YELLOW}→ No volume backup found (skipped)${NC}"
fi

# Restore INDI config
echo "  [3/4] Restoring INDI configuration..."
if [ -f "$BACKUP_DIR/indi-config/indi-settings.tar.gz" ]; then
    # Create indi config directory in local mount
    mkdir -p ./indi/config

    # Extract to local directory
    tar xzf "$BACKUP_DIR/indi-config/indi-settings.tar.gz" -C ./indi/config/

    echo -e "        ${GREEN}→ INDI config restored${NC}"
else
    echo -e "        ${YELLOW}→ No INDI config backup found (skipped)${NC}"
fi

# Restart containers
echo "  [4/4] Starting containers..."
docker compose up -d
echo "        → Containers started"

# Wait for startup
echo ""
echo "  Waiting for services to initialize..."
sleep 10

# Verify
echo ""
echo "=============================================="
echo "  Restore Complete!"
echo "=============================================="
echo ""
echo "  Run self-test to verify:"
echo "    docker exec astronomy-desktop /scripts/self-test.sh"
echo ""
