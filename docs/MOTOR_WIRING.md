# Motor Wiring Guide

This guide documents the critical motor wiring configuration for NEMA17 stepper motors with planetary gearboxes, specifically tested with the **17HD4401D-PG27** motors.

## The Problem

Stepper motor wire colors are **NOT standardized** across manufacturers. Connecting wires incorrectly causes the motor to buzz/vibrate instead of rotating.

## Symptom of Incorrect Wiring

- Motor makes noise (buzzing/humming)
- Motor shaft does not rotate
- Motor may vibrate or oscillate

## Wire Color Discovery

Through testing, we discovered the **17HD4401D-PG27** motors have non-standard coil assignments:

### Actual Coil Pairs (17HD4401D-PG27)

| Coil | Wire Colors |
|------|-------------|
| **Coil A** | Red + Green |
| **Coil B** | Blue + Black |

### What Many Guides Say (WRONG for this motor)

| Coil | Wire Colors |
|------|-------------|
| Coil A | Red + Blue |
| Coil B | Green + Black |

## How to Verify Your Motor's Coils

### Method 1: Multimeter (Recommended)

1. Disconnect the motor from everything
2. Set multimeter to **resistance (Ω)** or **continuity** mode
3. Test wire pairs:

| Test | Result if Same Coil |
|------|---------------------|
| Red ↔ Green | Low resistance (1-10Ω) |
| Blue ↔ Black | Low resistance (1-10Ω) |
| Red ↔ Blue | No continuity (∞) |
| Red ↔ Black | No continuity (∞) |

### Method 2: Spin Test (No Multimeter)

1. Disconnect motor from controller
2. Spin the motor shaft by hand - note how easy it is
3. Short two wires together (touch bare ends)
4. Spin shaft again:
   - **Much harder to turn** = Same coil (correct pair)
   - **No change** = Different coils (wrong pair)

## FYSETC E4 Connector Pinout

The FYSETC E4 motor connector expects wires in this order:

```
Position: [1]    [2]    [3]    [4]
Pin Name: [2B]   [2A]   [1A]   [1B]
Coil:     ←─ Coil 2 ─→  ←─ Coil 1 ─→
```

## Correct Wiring for 17HD4401D-PG27

For the FYSETC E4 with 17HD4401D-PG27 motors:

```
Position:  [1]   [2]    [3]    [4]
Wire:      Red   Green  Blue   Black
           ←─ Coil A ─→ ←─ Coil B ─→
```

### JST Connector Order

Looking at the connector with the clip facing you:

```
        ┌─────────────────┐
        │  ▼ (clip side)  │
        │ [R] [G] [Bl][Bk]│
        └─────────────────┘
         Red Green Blue Black
```

## Motor Connector Pin Layout (6-Pin)

The 17HD4401D-PG27 has a 6-pin connector with only 4 pins populated:

```
Pin: [1]  [2]  [3]  [4]  [5]  [6]
     Red  ---  Blue Green --- Black

(Pins 2 and 5 are empty - these would be center taps for unipolar operation)
```

## Rewiring the JST Connector

If your motor came pre-wired with the wrong order:

### Tools Needed
- Small pin or needle
- Steady hands

### Steps

1. **Identify current order** - Note which color is in each position
2. **Release the pins:**
   - Look at the connector from the wire side
   - Each wire has a tiny metal tab holding it in
   - Use a pin to press down the tab while gently pulling the wire
3. **Rearrange to correct order:** `Red, Green, Blue, Black`
4. **Push pins back in** until they click

## Wiring Diagrams

### Incorrect Wiring (Common Mistake)

```
FYSETC E4           Motor
─────────           ─────
Pin 2B ──── Red  ──── Red (Coil A)     ┐
Pin 2A ──── Blue ──── Blue (Coil B)    ┤ WRONG - Mixed coils!
Pin 1A ──── Green ─── Green (Coil A)   ┤
Pin 1B ──── Black ─── Black (Coil B)   ┘

Result: Motor buzzes but doesn't rotate
```

### Correct Wiring

```
FYSETC E4           Motor
─────────           ─────
Pin 2B ──── Red  ──── Red (Coil A)     ┐
Pin 2A ──── Green ─── Green (Coil A)   ┤ CORRECT - Coils paired!
Pin 1A ──── Blue ──── Blue (Coil B)    ┤
Pin 1B ──── Black ─── Black (Coil B)   ┘

Result: Motor rotates smoothly
```

## Other Common Motor Models

Different motors may have different color codes. Always verify with a multimeter!

### 17HS4401 (Standard)
- Coil A: Black + Green
- Coil B: Red + Blue

### 17HS4401S (Some variants)
- Coil A: Red + Blue
- Coil B: Green + Black

### Generic 6-Wire (Unipolar)
- Coil A: Black + Yellow, center tap Orange
- Coil B: Red + Blue, center tap White
- (Don't connect center taps for bipolar operation)

## Troubleshooting

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Motor buzzes, no rotation | Coils mixed | Verify and rewire |
| Motor runs backwards | Coils swapped | Swap entire Coil A with Coil B, or use software reverse |
| Motor runs rough | One coil reversed | Swap two wires within one coil |
| No sound at all | No power or broken wire | Check connections and power |
| Motor very hot | Current too high | Reduce IRUN in Config.h |

## Software Reversal (Alternative)

If the motor direction is wrong but it runs smoothly, you can reverse in software instead of rewiring:

In OnStepX `Config.h`:
```cpp
#define AXIS1_DRIVER_REVERSE ON   // Reverse RA axis
#define AXIS2_DRIVER_REVERSE ON   // Reverse DEC axis
```

This does NOT fix mixed coils - only direction after coils are correctly paired.

## References

- [RepRap Stepper Wiring Guide](https://reprap.org/wiki/Stepper_wiring)
- [FYSETC E4 Documentation](https://onstep.groups.io/g/main/wiki/32747)
- [OnStepX GitHub](https://github.com/hjd1964/OnStepX)
