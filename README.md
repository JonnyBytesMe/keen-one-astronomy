# Keen-One Astronomy

Open-source telescope control system for the Keen-One EQ mount with FYSETC E4 controller, OnStepX firmware, and Docker-based INDI server stack.

**Goal:** Make amateur astronomy accessible and reproducible through open-source hardware and software.

## Overview

This project provides a complete, reproducible setup for controlling a Keen-One EQ German Equatorial Mount using:

- **FYSETC E4** - ESP32-based motor controller with integrated TMC2209 drivers
- **OnStepX** - Open-source telescope firmware (LX200 compatible)
- **79:1 Harmonic Drive** - High-precision gear reduction (3D printed)
- **INDI Server** - Linux-based telescope control protocol (Dockerized)
- **Stellarium/KStars** - Desktop planetarium for GoTo control

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Desktop PC                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  Stellarium  │  │    NINA      │  │    PHD2      │               │
│  │ (Planetarium)│  │  (Imaging)   │  │  (Guiding)   │               │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘               │
│         └────────────┬────┴─────────────────┘                        │
│                      │ INDI Protocol (TCP:7624)                      │
└──────────────────────┼───────────────────────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │   Docker Stack          │
          │  ┌────────────────────┐ │
          │  │   INDI Server      │ │  ← Manages mount communication
          │  │   (indi_lx200)     │ │
          │  ├────────────────────┤ │
          │  │   INDI Web Manager │ │  ← Browser UI (port 8624)
          │  └────────────────────┘ │
          └────────────┬────────────┘
                       │ WiFi (LX200 Protocol)
                       │
          ┌────────────▼────────────┐
          │     FYSETC E4           │
          │   (OnStepX Firmware)    │
          │         ↓               │
          │   Stepper Motors        │
          │   79:1 Harmonic Drive   │
          │   Keen-One EQ Mount     │
          └─────────────────────────┘
```

## Hardware Requirements

### Controller
- **FYSETC E4** board ([AliExpress](https://www.aliexpress.com/item/1005002011852093.html))
  - ESP32-WROOM-32 microcontroller
  - 4x integrated TMC2209 stepper drivers
  - WiFi + Bluetooth connectivity
  - USB-C for programming

### Motors (Tested Configuration)
- **17HD4401D-PG27** NEMA17 with 27:1 planetary gearbox
  - Rated current: 1.3A
  - Step angle: 1.8° (200 steps/rev)
  - Output torque: ~3.5 N.m

### Harmonic Drive
- **79:1 Harmonic Drive** - [Printables Model #309144](https://www.printables.com/model/309144-791-harmonic-drive-for-keen-one-eq)
  - 158 teeth FlexSpline
  - 160 teeth CircularSpline
  - Module 0.5 gear teeth (requires 0.25mm nozzle for printing)

### Mount
- **Keen-One EQ** German Equatorial Mount

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/JonnyBytesMe/keen-one-astronomy.git
cd keen-one-astronomy
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env with your settings (WiFi, location, etc.)
```

### 3. Start the Docker Stack
```bash
docker compose up -d
```

### 4. Connect from Stellarium
1. Open Stellarium
2. Press F2 → Plugins → Telescope Control → Configure
3. Add telescope:
   - Connection: INDI
   - Host: localhost (or Docker host IP)
   - Port: 7624
4. Click any object → Slew telescope

## Documentation

| Document | Description |
|----------|-------------|
| [Hardware Setup](docs/HARDWARE_SETUP.md) | Wiring, assembly, motor configuration |
| [Firmware Guide](docs/FIRMWARE_GUIDE.md) | OnStepX compilation and configuration |
| [Motor Wiring](docs/MOTOR_WIRING.md) | Critical motor coil wiring information |
| [Docker Stack](docs/DOCKER_STACK.md) | INDI server deployment guide |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [3D Printing](docs/3D_PRINTING.md) | Print settings for harmonic drive parts |

## Key Discoveries

### Motor Wiring (CRITICAL)

The 17HD4401D-PG27 motors have **non-standard wire colors**:

| Coil | Wires | NOT the usual |
|------|-------|---------------|
| **Coil A** | Red + Green | ~~Red + Blue~~ |
| **Coil B** | Blue + Black | ~~Green + Black~~ |

**Symptom of wrong wiring:** Motors buzz but don't spin

**Correct JST connector order for FYSETC E4:**
```
[Red] [Green] [Blue] [Black]
```

Always verify with a multimeter before connecting!

### Steps Per Degree Calculation

```
Steps/Degree = (Motor_Steps × Microsteps × Planetary_Ratio × Harmonic_Ratio) / 360
             = (200 × 32 × 27 × 79) / 360
             = 37,920 steps/degree
```

## Project Structure

```
keen-one-astronomy/
├── docker-compose.yml      # Main Docker stack
├── .env.example            # Environment template (copy to .env)
├── onstepx/
│   └── Config.h.template   # OnStepX configuration template
├── docs/
│   ├── HARDWARE_SETUP.md   # Hardware assembly guide
│   ├── FIRMWARE_GUIDE.md   # Firmware setup guide
│   ├── MOTOR_WIRING.md     # Motor wiring details
│   ├── DOCKER_STACK.md     # Docker deployment guide
│   ├── 3D_PRINTING.md      # Print settings for parts
│   └── TROUBLESHOOTING.md  # Common issues
└── scripts/
    └── test_motor.py       # Motor testing script
```

## Software Components

| Component | Purpose | Source |
|-----------|---------|--------|
| OnStepX | Telescope firmware | [GitHub](https://github.com/hjd1964/OnStepX) |
| INDI Server | Device control protocol | [indilib.org](https://indilib.org) |
| INDI Web Manager | Browser-based management | [GitHub](https://github.com/indilib/indi-web) |
| Stellarium | Desktop planetarium | [stellarium.org](https://stellarium.org) |
| KStars/Ekos | Astronomy suite | [kstars.kde.org](https://kstars.kde.org) |

## Contributing

Contributions are welcome! This project aims to make astronomy more accessible.

- **Found an issue?** Open a GitHub issue
- **Have improvements?** Submit a pull request
- **Built your own?** Share your experience in Discussions

## License

This project is open source. See individual components for their licenses:
- OnStepX: GPL-3.0
- INDI: LGPL-2.1
- This documentation: MIT

## Acknowledgments

This project is built upon the incredible work of the open-source astronomy community:

### Core Projects
- **[OnStepX](https://github.com/hjd1964/OnStepX)** by Howard Dutton - The telescope firmware that makes everything work
- **[INDI Library](https://indilib.org)** - Cross-platform astronomy device control
- **[Keen-One EQ Mount](https://astrophoto.lionbit.com)** by Luke - The mount design this project is built for

### Hardware & 3D Printing
- **[79:1 Harmonic Drive](https://www.printables.com/model/309144)** by cncferdi - Precision gear reduction
- **[FYSETC E4](https://github.com/FYSETC/FYSETC-E4)** - Open hardware controller board

### Docker Images
- **[silfreed/indilib](https://hub.docker.com/r/silfreed/indilib)** - INDI server container
- **[nicolaka/netshoot](https://github.com/nicolaka/netshoot)** - Network troubleshooting tools

### Communities
- **[OnStep Groups.io](https://onstep.groups.io/g/main)** - Invaluable troubleshooting and advice
- **[INDI Forum](https://indilib.org/forum/)** - Driver and configuration support
- **[Printables Community](https://www.printables.com)** - 3D printing expertise

**See [CREDITS.md](CREDITS.md) for a complete list of all projects, tools, and contributors.**

---

## Support This Project

If this project helped you:
- Give it a star on GitHub
- Share your build in the Discussions
- Contribute improvements via Pull Requests
- Help others in the OnStep community

---

**Clear Skies!**
