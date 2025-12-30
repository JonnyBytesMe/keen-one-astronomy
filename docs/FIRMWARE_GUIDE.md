# OnStepX Firmware Guide

This guide covers compiling and uploading OnStepX firmware to the FYSETC E4 controller for the Keen-One EQ mount.

## Prerequisites

### Software
- [Arduino CLI](https://arduino.github.io/arduino-cli/latest/installation/) or Arduino IDE 2.x
- [Git](https://git-scm.com/downloads)
- Python 3.x (for testing scripts)
- Serial terminal (PuTTY, screen, or Arduino Serial Monitor)

### Hardware
- FYSETC E4 board
- USB-C cable
- Computer with USB port

## 1. Install Arduino CLI

### Windows (PowerShell)
```powershell
# Using Chocolatey
choco install arduino-cli

# Or download from GitHub releases
# https://github.com/arduino/arduino-cli/releases
```

### Linux/macOS
```bash
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
```

## 2. Install ESP32 Core

**CRITICAL:** Use ESP32 core version **2.0.17**. Newer versions (3.x) are incompatible with OnStepX.

```bash
# Install the correct version
arduino-cli core install esp32:esp32@2.0.17

# Verify installation
arduino-cli core list
```

## 3. Download OnStepX

```bash
# Clone OnStepX repository
git clone https://github.com/hjd1964/OnStepX.git
cd OnStepX

# Optionally checkout a specific release
git checkout v10.24c
```

## 4. Configure Config.h

Copy the template and edit for your setup:

```bash
cp Config.h.example Config.h
```

### Key Settings for Keen-One EQ with 79:1 Harmonic Drive

```cpp
// =============================================================================
// PINMAP - FYSETC E4 Board
// =============================================================================
#define PINMAP FYSETC_E4

// =============================================================================
// MOUNT TYPE
// =============================================================================
#define MOUNT_TYPE GEM                    // German Equatorial Mount

// =============================================================================
// STEPS PER DEGREE
// =============================================================================
// Formula: (motor_steps × microsteps × planetary × harmonic) / 360
// 17HD4401D-PG27: (200 × 32 × 27 × 79) / 360 = 37920

#define AXIS1_STEPS_PER_DEGREE 37920      // RA axis
#define AXIS2_STEPS_PER_DEGREE 37920      // DEC axis

// =============================================================================
// MOTOR DRIVER SETTINGS
// =============================================================================
#define AXIS1_DRIVER_MODEL TMC2209
#define AXIS1_DRIVER_MICROSTEPS 32
#define AXIS1_DRIVER_MICROSTEPS_GOTO 16

// Motor current (17HD4401D-PG27 rated at 1.3A)
#define AXIS1_DRIVER_IHOLD 520            // 40% of rated
#define AXIS1_DRIVER_IRUN 1050            // 80% of rated
#define AXIS1_DRIVER_IGOTO 1050

// TMC2209 specific
#define AXIS1_DRIVER_STATUS OFF           // CRITICAL: TMC2209 uses UART, not SPI
#define AXIS1_DRIVER_DECAY STEALTHCHOP    // Silent operation
#define AXIS1_DRIVER_DECAY_GOTO SPREADCYCLE

// Repeat for AXIS2 (DEC)
#define AXIS2_DRIVER_MODEL TMC2209
#define AXIS2_DRIVER_MICROSTEPS 32
#define AXIS2_DRIVER_MICROSTEPS_GOTO 16
#define AXIS2_DRIVER_IHOLD 520
#define AXIS2_DRIVER_IRUN 1050
#define AXIS2_DRIVER_IGOTO 1050
#define AXIS2_DRIVER_STATUS OFF
#define AXIS2_DRIVER_DECAY STEALTHCHOP
#define AXIS2_DRIVER_DECAY_GOTO SPREADCYCLE

// =============================================================================
// WIFI SETTINGS (Optional - for headless operation, set to OFF)
// =============================================================================
#define SERIAL_RADIO WIFI_STATION         // Connect to home WiFi
// WiFi credentials go in Config.h but should NOT be committed to Git!
// #define STA_SSID "YourWiFi"
// #define STA_PASSWORD "YourPassword"

// =============================================================================
// WEB SERVER (Disable to save resources)
// =============================================================================
#define WEB_SERVER OFF                    // OFF saves ~87KB flash
```

## 5. Compile the Firmware

```bash
# Navigate to OnStepX directory
cd /path/to/OnStepX

# Compile for ESP32
arduino-cli compile \
  --fqbn esp32:esp32:esp32:UploadSpeed=921600 \
  --build-path build
```

Expected output:
```
Sketch uses 1146753 bytes (87%) of program storage space.
Global variables use 57108 bytes (17%) of dynamic memory.
```

## 6. Upload to FYSETC E4

1. Connect FYSETC E4 via USB-C
2. Identify the COM port:
   ```bash
   # Windows
   mode

   # Linux
   ls /dev/ttyUSB*

   # macOS
   ls /dev/cu.*
   ```

3. Upload:
   ```bash
   arduino-cli upload \
     -p COM10 \
     --fqbn esp32:esp32:esp32:UploadSpeed=921600 \
     --input-dir build
   ```

## 7. Clear NV Storage (After Config Changes)

OnStepX stores settings in non-volatile memory. After changing Config.h values like steps/degree, you must clear NV:

1. Connect via serial (9600 baud)
2. Send command: `:ENVRESET#`
3. Reboot the controller (power cycle or send reset command)

```bash
# Using Python
python -c "
import serial
import time
ser = serial.Serial('COM10', 9600, timeout=2)
time.sleep(1)
ser.write(b':ENVRESET#')
time.sleep(0.5)
print(ser.read(100).decode())
ser.close()
print('NV will be cleared on next boot. Power cycle the controller.')
"
```

## 8. Verify Configuration

After uploading and clearing NV, verify settings:

```bash
# Test commands (9600 baud)
:GVN#          # Get firmware version → "10.24c#"
:GW#           # Get mount status
:GXE5#         # Get Axis2 steps/degree → "37920#"
:Te#           # Enable tracking
:Td#           # Disable tracking
```

## Useful LX200 Commands

| Command | Description | Response |
|---------|-------------|----------|
| `:GVN#` | Get version | `10.24c#` |
| `:GW#` | Get status | `GNH#` (GPS, Not tracking, Home) |
| `:Te#` | Enable tracking | `1` (success) |
| `:Td#` | Disable tracking | `1` |
| `:Me#` | Move East | - |
| `:Mw#` | Move West | - |
| `:Mn#` | Move North | - |
| `:Ms#` | Move South | - |
| `:Q#` | Stop all movement | - |
| `:RS#` | Set slew rate (max) | - |
| `:RG#` | Set guide rate (min) | - |
| `:ENVRESET#` | Clear NV on next boot | Message |

## Troubleshooting

### Motors Don't Move
1. Check ESP32 core version (must be 2.0.17)
2. Verify motor wiring (see [Motor Wiring Guide](MOTOR_WIRING.md))
3. Check NV was cleared after config change

### WiFi Not Connecting
1. ESP32 only supports 2.4GHz (not 5GHz)
2. Send `:ENVRESET#` and reboot
3. Check credentials in Config.h

### Serial Not Responding
1. Wait 10+ seconds after upload for full boot
2. Use correct baud rate (9600)
3. Try power cycling the board

### Compilation Errors
1. Ensure ESP32 core 2.0.17 (not 3.x)
2. Check all required libraries are installed
3. Verify Config.h syntax

## References

- [OnStepX GitHub](https://github.com/hjd1964/OnStepX)
- [OnStep Wiki](https://onstep.groups.io/g/main/wiki)
- [FYSETC E4 Wiki](https://onstep.groups.io/g/main/wiki/32747)
- [LX200 Command Reference](http://www.meade.com/support/LX200CommandSet.pdf)
