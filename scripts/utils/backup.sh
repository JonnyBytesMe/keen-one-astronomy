#!/bin/bash
# ============================================================================
# Keen-One Astronomy Stack - Backup Utility
# ============================================================================
# Creates a timestamped backup of all astronomy stack data
#
# Usage:
#   ./backup.sh                  # Create backup in default location
#   ./backup.sh /path/to/backup  # Create backup in specified location
# ============================================================================

set -e

# Configuration
BACKUP_BASE="${1:-./backups}"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE}/${TIMESTAMP}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=============================================="
echo "  Keen-One Astronomy Stack - Backup"
echo "=============================================="
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR/docker-volumes"
mkdir -p "$BACKUP_DIR/indi-config"
mkdir -p "$BACKUP_DIR/mount-config"

echo -e "${GREEN}Creating backup:${NC} $BACKUP_DIR"
echo ""

# Backup Docker volume
echo "  [1/4] Backing up Docker volume..."
if docker volume inspect astronomy-desktop-config >/dev/null 2>&1; then
    docker run --rm \
        -v astronomy-desktop-config:/data:ro \
        -v "$(cd "$BACKUP_DIR/docker-volumes" && pwd)":/backup \
        alpine tar czf /backup/astronomy-desktop-config.tar.gz -C /data .
    echo "        → astronomy-desktop-config.tar.gz"
else
    echo -e "        ${YELLOW}→ Volume not found (skipped)${NC}"
fi

# Backup INDI config
echo "  [2/4] Backing up INDI configuration..."
if docker ps --format '{{.Names}}' | grep -q "^indiserver$"; then
    docker exec indiserver tar czf - -C /root/.indi . 2>/dev/null > "$BACKUP_DIR/indi-config/indi-settings.tar.gz" || true
    if [ -s "$BACKUP_DIR/indi-config/indi-settings.tar.gz" ]; then
        echo "        → indi-settings.tar.gz"
    else
        rm -f "$BACKUP_DIR/indi-config/indi-settings.tar.gz"
        echo -e "        ${YELLOW}→ No INDI config to backup${NC}"
    fi
else
    echo -e "        ${YELLOW}→ INDI server not running (skipped)${NC}"
fi

# Backup mount INDI properties
echo "  [3/4] Backing up mount properties..."
if docker ps --format '{{.Names}}' | grep -q "^astronomy-desktop$"; then
    timeout 10 docker exec astronomy-desktop sh -c 'echo "<getProperties version=\"1.7\"/>" | nc -w 5 indiserver 7624' > "$BACKUP_DIR/mount-config/indi-properties.xml" 2>/dev/null || true
    if [ -s "$BACKUP_DIR/mount-config/indi-properties.xml" ]; then
        echo "        → indi-properties.xml"
    else
        rm -f "$BACKUP_DIR/mount-config/indi-properties.xml"
        echo -e "        ${YELLOW}→ Could not get mount properties${NC}"
    fi
else
    echo -e "        ${YELLOW}→ Desktop container not running (skipped)${NC}"
fi

# Create README
echo "  [4/4] Creating backup documentation..."
cat > "$BACKUP_DIR/README.md" << EOF
# Backup: ${TIMESTAMP}

Created: $(date)

## Contents

### docker-volumes/
- \`astronomy-desktop-config.tar.gz\` - Desktop container configuration
  - Stellarium settings and telescope config
  - KStars/Ekos profiles and settings
  - Desktop shortcuts

### indi-config/
- \`indi-settings.tar.gz\` - INDI server saved configurations

### mount-config/
- \`indi-properties.xml\` - Full INDI property dump from mount

## Restore Instructions

### Full Restore
\`\`\`bash
# Stop containers
docker compose down

# Restore Docker volume
docker run --rm \\
    -v astronomy-desktop-config:/data \\
    -v \$(pwd)/docker-volumes:/backup:ro \\
    alpine sh -c "cd /data && rm -rf * && tar xzf /backup/astronomy-desktop-config.tar.gz"

# Restart
docker compose up -d
\`\`\`

### Restore INDI Config Only
\`\`\`bash
docker run --rm \\
    -v keen-one-astronomy_indi-config:/data \\
    -v \$(pwd)/indi-config:/backup:ro \\
    alpine sh -c "cd /data && tar xzf /backup/indi-settings.tar.gz"
\`\`\`
EOF
echo "        → README.md"

# Summary
echo ""
echo "=============================================="
echo "  Backup Complete!"
echo "=============================================="
echo ""
echo "  Location: $BACKUP_DIR"
echo ""
echo "  To restore, run:"
echo "    ./scripts/utils/restore.sh $BACKUP_DIR"
echo ""
