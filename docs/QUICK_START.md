# Quick Start Guide

Get your Keen-One EQ telescope working in 5 minutes.

## Prerequisites

- Docker installed and running
- Keen-One EQ mount with OnStepX firmware
- Mount connected to WiFi (default IP: 192.168.0.86)

## Step 1: Start the Stack

```bash
cd keen-one-astronomy
docker compose up -d
```

Wait ~30 seconds for containers to start.

## Step 2: Open Web Desktop

Open http://localhost:3000 in your browser.

You'll see a Linux desktop with Stellarium and KStars icons.

## Step 3: Connect Mount to INDI

1. Open **KStars** from the desktop
2. Click **Tools → Ekos**
3. Click **INDI Control Panel** button (wrench icon)
4. Find **LX200 OnStep** device
5. Go to **Connection** tab
6. Set:
   - Address: `192.168.0.86` (your mount IP)
   - Port: `9999`
7. Click **Connect**

You should see "Connection: Ok" status.

## Step 4: Slew with Stellarium

1. Open **Stellarium** from the desktop
2. Press **Ctrl+0** to open Telescope Control
3. Your mount should show as "Keen-One EQ Mount" (connected)
4. Click on any star in the sky
5. Press **Ctrl+1** to slew telescope

The telescope will move to the selected star!

## Step 5: Slew with KStars/Ekos

1. Open **KStars** from the desktop
2. Click **Tools → Ekos**
3. Select profile: **Keen-One EQ**
4. Click **Start**
5. Once connected, use **Mount** tab to:
   - Click "Slew" on any object
   - Use the directional arrows
   - Enter coordinates manually

## Verify It's Working

Check mount position changed:

```bash
docker exec astronomy-desktop sh -c "echo '<getProperties version=\"1.7\"/>' | nc -w 3 indiserver 7624 | grep -A5 EQUATORIAL_EOD_COORD"
```

## Troubleshooting

### Can't access http://localhost:3000?
```bash
docker compose ps  # Check containers are running
docker compose logs astronomy-desktop  # Check for errors
```

### Mount not connecting?
```bash
# Test mount is reachable
ping 192.168.0.86

# Test mount port
telnet 192.168.0.86 9999
```

### INDI server not responding?
```bash
docker compose logs indiserver
```

## Common Commands

| Task | Command |
|------|---------|
| Start stack | `docker compose up -d` |
| Stop stack | `docker compose down` |
| View logs | `docker compose logs -f` |
| Restart | `docker compose restart` |

## Next Steps

- Read [DOCKER_STACK.md](DOCKER_STACK.md) for detailed configuration
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Check [FIRMWARE_GUIDE.md](FIRMWARE_GUIDE.md) for OnStepX setup

---

**Clear Skies!**
