# Credits & Acknowledgments

This project stands on the shoulders of giants. We gratefully acknowledge the following projects, creators, and communities whose work made this possible.

---

## Hardware Projects

### Keen-One EQ Mount
- **Designer:** Luke (astrophoto.lionbit.com)
- **Website:** [astrophoto.lionbit.com](https://astrophoto.lionbit.com)
- **Description:** Open-source German Equatorial Mount design, the foundation of this project

### 79:1 Harmonic Drive
- **Designer:** cncferdi (Printables)
- **Model:** [Printables #309144](https://www.printables.com/model/309144-791-harmonic-drive-for-keen-one-eq)
- **Description:** 3D-printable harmonic drive specifically designed for the Keen-One EQ mount
- **Related:** [Shrinkfactor Calibration Tool](https://www.printables.com/model/308591-shrinkfactor-calibation) for accurate ABS printing

### FYSETC E4 Controller Board
- **Manufacturer:** FYSETC
- **Product:** [FYSETC E4 on GitHub](https://github.com/FYSETC/FYSETC-E4)
- **Description:** ESP32-based 3D printer/CNC controller with integrated TMC2209 drivers
- **License:** Open Hardware

---

## Firmware

### OnStepX
- **Creator:** Howard Dutton ([@hjd1964](https://github.com/hjd1964))
- **Repository:** [github.com/hjd1964/OnStepX](https://github.com/hjd1964/OnStepX)
- **License:** GPL-3.0
- **Description:** Open-source telescope controller firmware supporting multiple mount types, GOTO, tracking, and extensive customization

### OnStep (Original)
- **Creator:** Howard Dutton
- **Repository:** [github.com/hjd1964/OnStep](https://github.com/hjd1964/OnStep)
- **Description:** The original OnStep project that OnStepX evolved from

---

## Software

### INDI Library
- **Project:** Instrument Neutral Distributed Interface
- **Website:** [indilib.org](https://www.indilib.org)
- **Repository:** [github.com/indilib/indi](https://github.com/indilib/indi)
- **License:** LGPL-2.1
- **Description:** Open-source astronomy device control library and server

### INDI Web Manager
- **Repository:** [github.com/indilib/indi-web](https://github.com/indilib/indi-web)
- **Description:** Browser-based INDI driver management interface

### Stellarium
- **Website:** [stellarium.org](https://stellarium.org)
- **License:** GPL-2.0
- **Description:** Free open-source planetarium software with telescope control capabilities

### KStars / Ekos
- **Website:** [kstars.kde.org](https://kstars.kde.org)
- **License:** GPL-2.0
- **Description:** Desktop planetarium and Ekos astrophotography suite

---

## Docker Images

### silfreed/indilib
- **Maintainer:** silfreed (Docker Hub)
- **Image:** [hub.docker.com/r/silfreed/indilib](https://hub.docker.com/r/silfreed/indilib)
- **Description:** Docker image containing INDI server with drivers including indi_lx200_OnStep
- **Used for:** Running INDI server in containerized environment

### nicolaka/netshoot
- **Maintainer:** Nicola Kabar
- **Repository:** [github.com/nicolaka/netshoot](https://github.com/nicolaka/netshoot)
- **Image:** [hub.docker.com/r/nicolaka/netshoot](https://hub.docker.com/r/nicolaka/netshoot)
- **Description:** Network troubleshooting container with various networking tools
- **Used for:** Testing TCP connections to mount and INDI server

---

## Development Tools

### Arduino CLI
- **Website:** [arduino.cc/pro/cli](https://www.arduino.cc/pro/cli)
- **Repository:** [github.com/arduino/arduino-cli](https://github.com/arduino/arduino-cli)
- **Description:** Command-line interface for Arduino development
- **Used for:** Compiling and uploading OnStepX firmware

### ESP32 Arduino Core
- **Repository:** [github.com/espressif/arduino-esp32](https://github.com/espressif/arduino-esp32)
- **Version Used:** 2.0.17 (CRITICAL - later versions have compatibility issues)
- **Description:** Arduino core for ESP32 microcontrollers

### Docker
- **Website:** [docker.com](https://www.docker.com)
- **Description:** Container platform for running INDI stack
- **Used for:** Portable, reproducible deployment

### Git / GitHub
- **Website:** [github.com](https://github.com)
- **Description:** Version control and project hosting

---

## Communities

### OnStep Groups.io
- **Forum:** [onstep.groups.io/g/main](https://onstep.groups.io/g/main)
- **Description:** Active community for OnStep/OnStepX users and developers
- **Contribution:** Invaluable troubleshooting help, configuration advice, and documentation

### INDI Forum
- **Forum:** [indilib.org/forum](https://www.indilib.org/forum/)
- **Description:** Official INDI library community forum
- **Contribution:** Driver development discussions, configuration help

### Printables Community
- **Website:** [printables.com](https://www.printables.com)
- **Description:** 3D printing community and model repository
- **Contribution:** Harmonic drive designs, print settings advice

---

## Motors & Hardware Suppliers

### MannHwa / AliExpress
- **Product:** 17HD4401D-PG27 Stepper Motors (27:1 planetary gearbox)
- **Note:** Wire colors are non-standard - see [MOTOR_WIRING.md](docs/MOTOR_WIRING.md)

### Adafruit
- **Product:** Ultimate GPS Breakout (MTK3339 chipset)
- **Website:** [adafruit.com](https://www.adafruit.com)
- **Used for:** Automatic time/date/location for the mount

---

## Documentation Resources

### LX200 Protocol Documentation
- **Source:** Meade LX200 Command Set
- **Description:** Serial/TCP command protocol used by OnStepX for telescope control

### TMC2209 Datasheet
- **Manufacturer:** Trinamic (now ADI)
- **Description:** Stepper driver IC documentation for current settings and configuration

---

## AI Assistance

### Claude Code (Anthropic)
- **Website:** [claude.ai](https://claude.ai)
- **Description:** AI assistant used for documentation, troubleshooting, and project organization
- **Note:** AI-generated content is marked with the robot emoji in commit messages

---

## How to Add Credits

When adding new components or dependencies to this project, please update this file with:

1. **Project/Product Name**
2. **Creator/Maintainer** (with link if available)
3. **Repository/Website URL**
4. **License** (if applicable)
5. **Brief description** of what it provides
6. **How we use it** in this project

---

## License Notice

This credits file documents third-party projects used in keen-one-astronomy. Each project maintains its own license:

| Component | License |
|-----------|---------|
| OnStepX | GPL-3.0 |
| INDI Library | LGPL-2.1 |
| Stellarium | GPL-2.0 |
| KStars | GPL-2.0 |
| Arduino ESP32 Core | LGPL-2.1 |
| This Documentation | MIT |

Please respect the licenses of all components when using or distributing this project.

---

**Thank you to everyone who contributes to open-source astronomy!**
