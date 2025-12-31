# ============================================================================
# Keen-One Astronomy Desktop
# ============================================================================
# Custom Docker image for astronomy software with pre-installed tools
# Based on LinuxServer.io Webtop (Ubuntu KDE)
#
# Includes:
#   - KStars/Ekos: Full astrophotography suite with INDI support
#   - Stellarium: Planetarium with telescope control
#   - ASTAP: Fast plate solving with D50 star catalog
#   - INDI tools: Command-line INDI utilities
#
# Build:
#   docker build -t keen-one-astronomy:latest .
#
# ============================================================================

FROM linuxserver/webtop:ubuntu-kde

LABEL maintainer="Keen-One Astronomy"
LABEL org.opencontainers.image.source="https://github.com/JonnyBytesMe/keen-one-astronomy"
LABEL org.opencontainers.image.description="Astronomy Desktop with KStars, Stellarium, ASTAP, and INDI"
LABEL org.opencontainers.image.licenses="MIT"

# ============================================================================
# Install Astronomy Software
# ============================================================================
# Run as root for package installation
USER root

# Install packages in a single layer to reduce image size
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        # Astronomy software
        kstars \
        stellarium \
        indi-bin \
        # ASTAP plate solver
        astap \
        # Utilities
        netcat-openbsd \
        bc \
        curl \
        unzip \
        wget \
        # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ============================================================================
# Download ASTAP D50 Star Catalog
# ============================================================================
# Pre-download the D50 star database for fast offline plate solving
# This enables 2-8 second plate solves (similar to ASIAir)
# Size: ~400MB compressed, ~1GB extracted
#
ARG DOWNLOAD_CATALOG=true
ENV ASTAP_DATA_DIR=/usr/share/astap/data

RUN if [ "$DOWNLOAD_CATALOG" = "true" ]; then \
        echo "Downloading ASTAP D50 star database..." && \
        mkdir -p ${ASTAP_DATA_DIR} && \
        curl -fsSL --connect-timeout 60 --max-time 1200 \
            -o /tmp/d50.zip \
            "https://downloads.sourceforge.net/project/astap-program/star_databases/d50_star_database.zip" && \
        echo "Extracting database..." && \
        unzip -q -o /tmp/d50.zip -d ${ASTAP_DATA_DIR}/ && \
        rm -f /tmp/d50.zip && \
        echo "D50 star database installed successfully"; \
    else \
        echo "Skipping D50 catalog download (DOWNLOAD_CATALOG=false)"; \
    fi

# ============================================================================
# Copy Initialization Scripts
# ============================================================================
# These scripts configure KStars, Stellarium, and desktop shortcuts on startup

COPY scripts/init/init-astronomy.sh /custom-cont-init.d/50-init-astronomy.sh
COPY scripts/init/discover-mount.sh /custom-cont-init.d/discover-mount.sh
COPY scripts/test/self-test.sh /scripts/self-test.sh
COPY scripts/test/health-check.sh /scripts/health-check.sh

RUN chmod +x /custom-cont-init.d/*.sh /scripts/*.sh

# ============================================================================
# Default Environment Variables
# ============================================================================
# These can be overridden at runtime via docker-compose or Portainer

ENV LOG_LEVEL=2 \
    INDI_HOST=indiserver \
    INDI_PORT=7624 \
    MOUNT_IP= \
    MOUNT_PORT=9999 \
    MOUNT_DRIVER="LX200 OnStep" \
    USE_GPS_LOCATION=true \
    LATITUDE= \
    LONGITUDE= \
    ELEVATION= \
    SELF_TEST_ON_BOOT=false \
    SELF_TEST_ON_RESTART=false \
    # Multi-client sharing
    SELKIES_ENABLE_SHARING=true \
    SELKIES_ENABLE_COLLAB=true

# ============================================================================
# Healthcheck
# ============================================================================
HEALTHCHECK --interval=60s --timeout=15s --start-period=120s --retries=3 \
    CMD bash /scripts/health-check.sh || exit 1

# ============================================================================
# Expose Ports
# ============================================================================
# 3000 - HTTP web desktop
# 3001 - HTTPS web desktop (self-signed)
EXPOSE 3000 3001
