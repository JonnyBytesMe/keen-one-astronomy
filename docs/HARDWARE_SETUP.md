# Hardware Setup Guide

Complete hardware assembly guide for the Keen-One EQ mount with FYSETC E4 controller and 79:1 harmonic drive.

## Bill of Materials

### Electronics

| Item | Quantity | Notes |
|------|----------|-------|
| FYSETC E4 Board | 1 | ESP32 + 4x TMC2209 |
| 17HD4401D-PG27 Motors | 2 | 27:1 planetary gearbox, 1.3A |
| Power Supply | 1 | 12V 5A minimum |
| USB-C Cable | 1 | For programming |
| JST-XH Connectors | 4 | Motor connections |
| Adafruit Ultimate GPS | 1 | Optional, for auto time/location |

### Mechanical

| Item | Quantity | Notes |
|------|----------|-------|
| 79:1 Harmonic Drive | 2 | RA and DEC axes |
| 5mm Chrome Steel Balls | 88 | 44 per harmonic drive |
| M4x30 Screws | 8 | Harmonic drive assembly |
| Couplers | 2 | Motor to harmonic drive |

### 3D Printed Parts (per axis)

| Part | Material | Infill |
|------|----------|--------|
| FlexSpline | PETG or ABS | 60% |
| CircularSpline | ABS | 60% |
| WaveGenerator V5 | ABS | 100% |
| Coupler V5 | ABS | 100% |
| AssemblyHelper | Any | 20% |

## FYSETC E4 Board Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                        FYSETC E4 Board                          │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                               │
│  │ X   │ │ Y   │ │ Z   │ │ E   │  ← Motor Connectors           │
│  │Motor│ │Motor│ │Motor│ │Motor│    (RA=X, DEC=Y)              │
│  └─────┘ └─────┘ └─────┘ └─────┘                               │
│                                                                 │
│  [USB-C]                                    [Power 12-24V]      │
│                                                                 │
│  ┌────────────────┐                                            │
│  │    ESP32       │                        [P17 Header]        │
│  │   WROOM-32     │                         GPIO21 (SDA)       │
│  │                │                         GPIO22 (SCL)       │
│  └────────────────┘                         3.3V               │
│                                             GND                │
└─────────────────────────────────────────────────────────────────┘
```

## Motor Connections

### Axis Assignment

| OnStepX Axis | FYSETC E4 Port | Function |
|--------------|----------------|----------|
| AXIS1 | X Motor | RA (Right Ascension) |
| AXIS2 | Y Motor | DEC (Declination) |
| AXIS3 | Z Motor | Rotator (unused) |
| AXIS4 | E Motor | Focuser (unused) |

### Motor Wiring

**CRITICAL:** See [Motor Wiring Guide](MOTOR_WIRING.md) for wire color mapping.

The 17HD4401D-PG27 requires this wire order in the JST connector:

```
[Red] [Green] [Blue] [Black]
```

**Before connecting, verify coil pairs with a multimeter!**

## GPS Module (Optional)

The Adafruit Ultimate GPS provides automatic time and location synchronization.

### Wiring

| GPS Module | FYSETC E4 (P17 Header) |
|------------|------------------------|
| VIN | 3.3V or 5V |
| GND | GND |
| TX | GPIO21 (SDA) |
| RX | GPIO22 (SCL) |

### OnStepX Configuration

```cpp
#define TIME_LOCATION_SOURCE GPS
#define SERIAL_GPS Serial2
#define SERIAL_GPS_BAUD 9600
#define SERIAL_GPS_RX 21    // GPS TX → GPIO21
#define SERIAL_GPS_TX 22    // GPS RX → GPIO22
```

## Power Supply

### Requirements

- Voltage: 12V DC (12-24V supported)
- Current: 5A minimum (motors draw ~2A each under load)
- Connector: 5.5mm x 2.1mm barrel jack

### Power Calculation

```
Per motor (17HD4401D-PG27):
  - Running: 1.05A @ 12V = 12.6W
  - Peak: 1.3A @ 12V = 15.6W

Total system:
  - 2 motors running: ~25W
  - With margin: 50W (5A @ 12V) recommended
```

## Assembly Steps

### 1. Motor Preparation

1. Verify motor wire colors and coil pairs
2. Rewire JST connectors if needed (see [Motor Wiring](MOTOR_WIRING.md))
3. Test motors individually before mounting

### 2. Harmonic Drive Assembly

See [3D Printing Guide](3D_PRINTING.md) for print settings.

1. Print all parts for both axes
2. Assemble with steel balls using AssemblyHelper
3. Do NOT overtighten screws (warps WaveGenerator)
4. Lubricate ball races with light grease
5. Test smooth rotation before mounting

### 3. Mount Integration

1. Remove original Keen-One gearbox (if present)
2. Install harmonic drives on each axis
3. Attach motors via printed couplers
4. Ensure alignment - misalignment causes binding

### 4. Electronics

1. Mount FYSETC E4 in enclosure (3D printed or commercial)
2. Connect motors to X (RA) and Y (DEC) ports
3. Connect GPS module if using
4. Connect 12V power supply
5. Connect USB for initial programming

### 5. Initial Testing

1. Power on with USB only (no 12V) - verify ESP32 boots
2. Connect 12V power
3. Test motor movement via serial commands
4. Verify direction and speed
5. Test tracking mode

## Wiring Diagram

```
                    ┌──────────────┐
   12V Power ──────►│              │
                    │              │
                    │   FYSETC E4  │
   USB-C ──────────►│              │
  (Programming)     │              │
                    │    ┌──────┐  │
                    │    │ESP32 │  │
                    │    └──────┘  │
                    │              │
                    │  X    Y      │
                    │  │    │      │
                    └──┼────┼──────┘
                       │    │
              ┌────────┘    └────────┐
              │                      │
              ▼                      ▼
        ┌──────────┐          ┌──────────┐
        │RA Motor  │          │DEC Motor │
        │17HD4401D │          │17HD4401D │
        │ -PG27    │          │ -PG27    │
        └────┬─────┘          └────┬─────┘
             │                     │
             ▼                     ▼
        ┌──────────┐          ┌──────────┐
        │  79:1    │          │  79:1    │
        │ Harmonic │          │ Harmonic │
        │  Drive   │          │  Drive   │
        └────┬─────┘          └────┬─────┘
             │                     │
             ▼                     ▼
        RA Axis                DEC Axis
        (Polar)                (Altitude)
```

## Troubleshooting

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| No power LED | Power supply issue | Check 12V connection |
| ESP32 not booting | USB power insufficient | Connect 12V supply |
| Motors buzzing | Wrong wiring | Check coil pairs |
| Binding/grinding | Misalignment | Realign harmonic drive |
| Inconsistent tracking | Loose coupling | Tighten motor coupler |
| Overheating motors | Current too high | Reduce IRUN in Config.h |

## Safety Notes

- Always power off before making wiring changes
- Never connect/disconnect motors while powered
- Use appropriate gauge wire for power (18 AWG minimum)
- Ensure good ventilation for electronics
- Consider weatherproofing for outdoor use
