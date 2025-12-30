# 3D Printing Guide

Print settings for the 79:1 Harmonic Drive parts (Printables Model #309144).

## Overview

The harmonic drive requires precise printing. The V5 parts use Module 0.5 gear teeth which **require a 0.25mm nozzle** for proper definition.

## Parts List (Per Axis)

| Part | Nozzle | Material | Quantity |
|------|--------|----------|----------|
| FlexSpline | 0.4mm | PETG or ABS | 1 |
| CircularSpline | 0.25mm | ABS | 1 |
| WaveGenerator V5 | 0.25mm | ABS | 1 |
| Coupler V5 | 0.25mm | ABS | 1 |
| AssemblyHelper | Any | Any | 1 (reusable) |

**Total for complete mount (2 axes):** 2x each part except AssemblyHelper

## General Settings

### All Parts

| Setting | Value |
|---------|-------|
| Layer Height | 0.10mm |
| First Layer Height | 0.15mm |
| Seam Position | **Random** (critical for gears!) |
| External Perimeters First | Yes |
| Brim | 3-5mm |

### Why Random Seams?

A visible seam line on gear teeth causes:
- Periodic tracking errors
- Increased wear
- Noise during operation

Random seams distribute any imperfections evenly.

## Material Settings

### ABS (Recommended for V5 Parts)

| Setting | Value |
|---------|-------|
| Nozzle - First Layer | 250°C |
| Nozzle - Other Layers | 245°C |
| Bed - First Layer | 105°C |
| Bed - Other Layers | 100°C |
| Fan | 0-15% (off for first 3 layers) |
| Enclosure | Required |

### Shrinkage Compensation

ABS shrinks during cooling. Calibrate your shrinkage factor:
- Use [Shrinkfactor Calibration Tool](https://www.printables.com/model/308591)
- Typical value: **0.4% XY**
- Apply in slicer: Filament Settings → Advanced → Shrinkage

### PETG (FlexSpline Only)

| Setting | Value |
|---------|-------|
| Nozzle | 240°C |
| Bed | 80°C |
| Fan | 50-100% |
| Enclosure | Optional |

## Part-Specific Settings

### FlexSpline

The flexible component of the harmonic drive.

| Setting | Value |
|---------|-------|
| Material | PETG or ABS |
| Nozzle | 0.4mm |
| Layer Height | 0.10-0.15mm |
| Perimeters | 4 |
| Infill | 60% Gyroid |
| Top/Bottom Layers | 5/4 |

**Notes:**
- Must flex without cracking
- PETG is more forgiving
- ABS provides better wear resistance

### CircularSpline

The outer ring with internal gear teeth.

| Setting | Value |
|---------|-------|
| Material | ABS |
| Nozzle | **0.25mm** |
| Layer Height | 0.10mm |
| Perimeters | 6 |
| Infill | 60% Gyroid |
| Top/Bottom Layers | 7/5 |

**Notes:**
- Gear teeth must be precisely defined
- 6 perimeters ensure tooth strength
- Random seam essential

### WaveGenerator V5

The bearing race that balls roll on.

| Setting | Value |
|---------|-------|
| Material | ABS |
| Nozzle | **0.25mm** |
| Layer Height | 0.10mm |
| Perimeters | 5 |
| Infill | **100%** |
| Top/Bottom Layers | 7/5 |

**Notes:**
- Surface finish critical (balls roll on this)
- 100% infill for strength
- Sand lightly if needed, then lubricate

### Coupler V5

Connects motor shaft to wave generator.

| Setting | Value |
|---------|-------|
| Material | ABS |
| Nozzle | **0.25mm** |
| Layer Height | 0.10mm |
| Perimeters | 5 |
| Infill | **100%** |
| Top/Bottom Layers | 7/5 |

## Speed Settings

Slow speeds improve precision for gear teeth:

| Setting | Value |
|---------|-------|
| Perimeters | 30-40 mm/s |
| External Perimeters | 20-25 mm/s |
| Infill | 40 mm/s |
| First Layer | 15-20 mm/s |
| Travel | 120 mm/s |

## 0.25mm Nozzle Tips

### Extrusion Widths

| Setting | Value |
|---------|-------|
| Default | 0.25mm |
| First Layer | 0.30mm |
| External Perimeter | 0.25mm |
| Infill | 0.25mm |

### Retraction (Direct Drive)

| Setting | Value |
|---------|-------|
| Length | 0.6mm |
| Speed | 30 mm/s |
| Z-hop | 0.15mm |

### Max Volumetric Speed

Limit to prevent under-extrusion:

| Setting | Value |
|---------|-------|
| Max Volumetric Speed | 3.0-3.5 mm³/s |

## Printer Preparation

### Before Printing ABS

1. **Preheat enclosure:**
   - Set bed to 100°C
   - Wait 15-20 minutes
   - Target chamber temp: 35-45°C

2. **Dry filament:**
   - ABS: 4-8 hours at 70-80°C
   - Wet ABS causes bubbles and poor layer adhesion

3. **Clean bed:**
   - IPA wipe for PETG
   - Acetone wipe for ABS

4. **Calibrate:**
   - First layer Z-offset at printing temperature
   - Flow rate for 0.25mm nozzle

### MMU Considerations

If using Prusa MK4S with MMU3:
- ABS is not officially supported with MMU3 in PrusaSlicer
- **Workaround:** Use standard MK4S profile (not MMU3)
- Select ABS filament slot when print starts

## Quality Checks

### Before Assembly

| Check | Method |
|-------|--------|
| Gear tooth definition | Visual - teeth should be clearly defined |
| Surface finish | Feel - should be smooth, not rough |
| Dimensional accuracy | Calipers - within 0.1mm of design |
| Layer adhesion | Try to delaminate - should be solid |
| Warping | Flat surface - should sit flat |

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Poor tooth definition | Over-extrusion or wrong nozzle | Calibrate flow, use 0.25mm |
| Warping | Insufficient bed/chamber temp | Increase temps, add brim |
| Delamination | Too much cooling | Reduce fan, increase temp |
| Stringing | Retraction too low | Increase retraction |
| Elephant's foot | First layer too squished | Adjust Z-offset |

## Post-Processing

### WaveGenerator Surface

The ball race surface should be smooth:
1. Light sanding with 400-600 grit if needed
2. Clean thoroughly
3. Apply thin layer of lithium or PTFE grease

### Gear Teeth

Do NOT sand or modify gear teeth - this affects gear mesh.

### Assembly

1. Use AssemblyHelper to position WaveGenerator during ball installation
2. Add steel balls (44 per drive)
3. Apply grease to ball races
4. Do NOT overtighten screws - this warps the WaveGenerator

## Print Time Estimates (0.25mm nozzle)

| Part | Approximate Time |
|------|------------------|
| FlexSpline | 4-6 hours |
| CircularSpline | 8-10 hours |
| WaveGenerator V5 | 6-8 hours |
| Coupler V5 | 2-3 hours |
| **Total per axis** | ~20-27 hours |

## References

- [79:1 Harmonic Drive - Printables](https://www.printables.com/model/309144-791-harmonic-drive-for-keen-one-eq)
- [Shrinkfactor Calibration - Printables](https://www.printables.com/model/308591-shrinkfactor-calibation)
- [Prusa ABS Guide](https://help.prusa3d.com/article/abs_2058)
- [0.25mm Nozzle Profiles](https://help.prusa3d.com/article/creating-profiles-for-different-nozzles_127540)
