# Docker Stack Guide

This guide covers deploying the INDI server stack using Docker for telescope control.

## Overview

The Docker stack provides:
- **INDI Server** - Core protocol for telescope/camera communication
- **INDI Web Manager** - Browser-based driver management
- **Astrometry.net** - Local plate solving (optional)

## Prerequisites

- Docker Engine 20.x+
- Docker Compose 2.x+
- 2GB+ free disk space (more if using Astrometry)

### Windows (Docker Desktop)
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Enable WSL2 backend (recommended)

### Linux
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### macOS
Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/JonnyBytesMe/keen-one-astronomy.git
cd keen-one-astronomy
```

### 2. Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit with your settings
nano .env  # or use your preferred editor
```

Key settings:
```bash
TIMEZONE=Europe/London
ONSTEP_IP=192.168.0.86
ONSTEP_PORT=9999
```

### 3. Start Stack

```bash
docker compose up -d
```

### 4. Verify

```bash
# Check containers are running
docker compose ps

# View logs
docker compose logs -f
```

## Accessing Services

| Service | URL | Purpose |
|---------|-----|---------|
| INDI Web Manager | http://localhost:8624 | Driver management UI |
| INDI Server | localhost:7624 | Protocol connection (for Stellarium/KStars) |
| Astrometry | http://localhost:8090 | Plate solving (if enabled) |

## INDI Web Manager Usage

1. Open http://localhost:8624 in browser
2. Click "Profiles" → "Add Profile"
3. Add your devices:
   - **Mount:** Select "LX200 OnStep" or "LX200 Basic"
   - Configure connection: TCP, your mount IP, port 9999
4. Click "Start" to launch INDI server with selected profile

## Connecting from Desktop Software

### Stellarium

1. Open Stellarium
2. Press F2 → Plugins → Telescope Control
3. Click "Configure telescopes"
4. Add new telescope:
   - **Type:** INDI
   - **Host:** localhost (or Docker host IP)
   - **Port:** 7624
5. Click Connect
6. Click any object → "Slew telescope to object"

### KStars/Ekos

1. Open KStars
2. Tools → Ekos
3. Create new profile
4. Set INDI Server:
   - **Host:** localhost
   - **Port:** 7624
5. Add equipment (Mount: LX200 OnStep)
6. Click Start

### NINA (Windows)

1. Open NINA
2. Equipment → Telescope
3. Select "ASCOM Telescope"
4. Choose "OnStep" from ASCOM selector
5. Configure connection to your mount IP

## Docker Compose Configuration

### Basic Stack (docker-compose.yml)

```yaml
services:
  indiserver:
    image: silfreed/indilib:latest
    container_name: indiserver
    restart: unless-stopped
    ports:
      - "7624:7624"
    # Entrypoint is 'indiserver', so just specify arguments
    command: ["-v", "indi_lx200_OnStep"]
```

**Note:** The `silfreed/indilib` image includes INDI Library 1.9.8 with the `indi_lx200_OnStep` driver and many other drivers. The entrypoint is already `indiserver`, so the command only needs the driver arguments.

### Available INDI Drivers

| Driver | Device Type |
|--------|-------------|
| `indi_lx200_OnStep` | OnStep/OnStepX mounts |
| `indi_lx200generic` | Generic LX200 mounts |
| `indi_eqmod_telescope` | EQMod compatible mounts |
| `indi_asi_ccd` | ZWO ASI cameras |
| `indi_qhy_ccd` | QHY cameras |
| `indi_gpsd` | GPS devices |
| `indi_watchdog` | Session watchdog |

## Network Considerations

### host Network Mode

The default configuration uses `network_mode: host` which:
- Shares the host's network stack
- Required for USB device passthrough
- Required for multicast discovery
- Simplifies port management

### Bridge Network Mode

If you need isolation:
```yaml
services:
  indiserver:
    ports:
      - "7624:7624"
    # Remove network_mode: host
```

### Firewall Rules

Ensure these ports are accessible:
- **7624/TCP** - INDI protocol
- **8624/TCP** - INDI Web Manager
- **9999/TCP** - OnStepX command port

## Persistent Configuration

Mount configuration survives container restarts:

```yaml
volumes:
  - ./indi/config:/root/.indi
  - ./indi/web-config:/root/.indi-web
```

## Enabling Astrometry (Plate Solving)

Astrometry.net provides local plate solving for accurate GoTo.

### Enable in docker-compose.yml

```yaml
services:
  astrometry:
    image: dm90/astrometry:latest
    ports:
      - "8090:8090"
    volumes:
      - astrometry-data:/data
```

### Download Index Files

First run downloads required star catalogs (~2GB):
```bash
docker compose up astrometry
# Wait for download to complete (may take 30+ minutes)
```

### Configure in KStars/Ekos

1. Ekos → Options → Solver
2. Set API URL: http://localhost:8090/api

## Updating

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs indiserver

# Common issues:
# - Port already in use
# - Insufficient permissions
# - Image pull failed
```

### Can't Connect from Stellarium

1. Verify containers are running: `docker compose ps`
2. Check INDI server is listening: `telnet localhost 7624`
3. Verify firewall allows port 7624
4. Try using host IP instead of localhost

### USB Devices Not Detected

1. Ensure `privileged: true` in compose file
2. Verify USB device is connected: `lsusb`
3. Check device permissions
4. On Windows, may need USB/IP passthrough

### Mount Not Connecting

1. Verify mount IP is reachable: `ping 192.168.0.86`
2. Check mount port is open: `telnet 192.168.0.86 9999`
3. Verify OnStepX is running: send `:GVN#` should return version
4. Check INDI driver settings in Web Manager

## Advanced: Traefik Integration

For external access with SSL:

```yaml
services:
  indi-web:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.astronomy.rule=Host(`astronomy.example.com`)"
      - "traefik.http.routers.astronomy.entrypoints=https"
      - "traefik.http.routers.astronomy.tls=true"
      - "traefik.http.routers.astronomy.tls.certresolver=cloudflare"
      - "traefik.http.services.astronomy.loadbalancer.server.port=8624"
    networks:
      - proxy

networks:
  proxy:
    external: true
```

## Resource Usage

Typical resource consumption:

| Container | RAM | CPU | Disk |
|-----------|-----|-----|------|
| indiserver | ~50MB | Low | Minimal |
| indi-web | ~100MB | Low | Minimal |
| astrometry | ~500MB | Medium | 2GB+ (indexes) |

## Stopping the Stack

```bash
# Stop containers
docker compose down

# Stop and remove volumes (data loss!)
docker compose down -v
```
