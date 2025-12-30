# Current System Status

> **Last Updated:** December 30, 2024

## Working Configuration

### Hardware
| Component | Model | Status |
|-----------|-------|--------|
| Controller | FYSETC E4 (ESP32 + TMC2209) | Working |
| Motors | 17HD4401D-PG27 (27:1 planetary, 1.3A) | Working |
| Harmonic Drive | 78:1 (testing - 79:1 pending) | Working |
| GPS | Adafruit Ultimate GPS (GPIO21/22) | Configured |

### Firmware
- **Version:** OnStepX 10.24c
- **Web Server:** Disabled (using INDI instead)
- **WiFi:** Station mode (connects to home network)
- **IP Address:** 192.168.0.86 (DHCP)
- **Command Port:** 9999 (TCP)

### Motor Configuration
| Setting | Value |
|---------|-------|
| Steps Per Degree | 37,440 (will be 37,920 with 79:1 HD) |
| Microstepping (tracking) | 32x |
| Microstepping (slewing) | 16x |
| Run Current | 1,050mA (80% of 1.3A rating) |
| Hold Current | 520mA (40% of rating) |

### Motor Wiring (CRITICAL)
The 17HD4401D-PG27 motors have non-standard wire colors:
- **Coil A:** Red + Green (NOT Red + Blue!)
- **Coil B:** Blue + Black (NOT Green + Black!)
- **JST Connector:** `[Red] [Green] [Blue] [Black]`

## Docker Stack

### Running Services
| Container | Image | Port | Status |
|-----------|-------|------|--------|
| indiserver | silfreed/indilib:latest | 7624 | Running |

### INDI Driver
- **Driver:** indi_lx200_OnStep (v1.16)
- **Connection:** TCP to 192.168.0.86:9999
- **Protocol:** LX200 compatible

## Verification Commands

### Test Mount Connection (LX200 Protocol)
```bash
# Via Docker
echo ":GVN#" | docker run --rm -i nicolaka/netshoot nc 192.168.0.86 9999
# Expected: 10.24c#
```

### Test INDI Server
```bash
# Check container status
docker ps --filter "name=indiserver"

# Test port
docker run --rm nicolaka/netshoot nc -zv host.docker.internal 7624
```

### Common LX200 Commands
| Command | Purpose | Expected Response |
|---------|---------|-------------------|
| `:GVN#` | Get firmware version | `10.24c#` |
| `:GW#` | Get mount status | Status flags |
| `:GR#` | Get RA position | RA coordinates |
| `:GD#` | Get Dec position | Dec coordinates |
| `:Te#` | Enable tracking | `1` |
| `:Td#` | Disable tracking | `1` |

## Client Software Configuration

### Stellarium
1. Open Stellarium
2. Press F2 → Plugins → Telescope Control
3. Configure telescope:
   - Type: INDI
   - Host: localhost
   - Port: 7624
4. Connect

### KStars/Ekos
1. Tools → Ekos
2. Create profile with:
   - INDI Host: localhost
   - INDI Port: 7624
   - Mount: LX200 OnStep
3. Start profile

## Known Issues

### Pending Upgrades
1. **79:1 Harmonic Drive:** Parts being printed, will require updating `AXIS1_STEPS_PER_DEGREE` and `AXIS2_STEPS_PER_DEGREE` from 37,440 to 37,920

### Limitations
1. No limit switches installed
2. No home sensors installed
3. Polar alignment must be done manually

## Next Steps

1. Complete 79:1 harmonic drive printing
2. Install drives and update firmware
3. Test with Stellarium GoTo
4. Polar alignment
5. First light observation

## Quick Start

```bash
# Start the stack
cd keen-one-astronomy
docker compose up -d

# Verify connection
docker logs indiserver

# Connect from client software to localhost:7624
```
