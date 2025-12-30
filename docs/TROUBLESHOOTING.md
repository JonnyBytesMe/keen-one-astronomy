# Troubleshooting Guide

Common issues and solutions for the Keen-One Astronomy system.

## Motor Issues

### Motors Buzz But Don't Spin

**Cause:** Incorrect motor coil wiring

**Solution:**
1. Disconnect motors from controller
2. Verify coil pairs with multimeter (see [Motor Wiring Guide](MOTOR_WIRING.md))
3. Rewire JST connector to correct order: `[Red] [Green] [Blue] [Black]`

### Motors Don't Move At All

**Possible causes:**
1. **Wrong ESP32 core version**
   - Must use ESP32 core 2.0.17, NOT 3.x
   - Fix: `arduino-cli core install esp32:esp32@2.0.17`

2. **NV storage has old settings**
   - Send `:ENVRESET#` command
   - Power cycle controller

3. **12V power not connected**
   - USB alone doesn't power motors
   - Connect 12V supply

4. **Motor current too low**
   - Increase IRUN in Config.h

### Motors Move Wrong Direction

**Solution:** Either:
1. Swap two wires within one coil pair in connector, OR
2. Set in Config.h:
   ```cpp
   #define AXIS1_DRIVER_REVERSE ON
   #define AXIS2_DRIVER_REVERSE ON
   ```

### Motors Very Hot

**Cause:** Current set too high

**Solution:** Reduce in Config.h:
```cpp
#define AXIS1_DRIVER_IRUN 1050   // Try lower values
#define AXIS2_DRIVER_IRUN 1050
```

Rule: Run current should be 70-80% of motor rated current.

## WiFi Issues

### Not Connecting to Home Network

**Possible causes:**

1. **5GHz network**
   - ESP32 only supports 2.4GHz
   - Ensure router has 2.4GHz band enabled

2. **Credentials cached**
   - Send `:ENVRESET#` and reboot

3. **AP mode conflict**
   - Default AP IP (192.168.0.1) may conflict with router
   - Change `AP_IP_ADDR` in Config.h to 192.168.4.1

### Web Interface Not Accessible

**If web server is enabled but inaccessible:**

1. Verify IP address: `ping <mount-ip>`
2. Check if port 80 is open: `telnet <mount-ip> 80`
3. Ensure WEB_SERVER is ON in Config.h
4. Enable website plugin in Plugins.config.h:
   ```cpp
   #define PLUGIN1 website
   #include "website/Website.h"
   ```

## Serial Communication

### Serial Not Responding After Upload

**Cause:** Board stuck in download mode or still booting

**Solution:**
1. Wait 10+ seconds after upload
2. Power cycle the board
3. Try different baud rate (default is 9600)

### Empty Responses to Commands

**Solutions:**
1. Clear input buffer before sending commands
2. Add delay after sending command (0.5s)
3. Verify correct line endings (most commands end with #)

### Garbled Output

**Cause:** Baud rate mismatch

**Solution:** Ensure serial terminal matches Config.h:
```cpp
#define SERIAL_A_BAUD_DEFAULT 9600
```

## GoTo Issues

### GoTo Inaccurate

**Possible causes:**

1. **Steps per degree wrong**
   - Verify calculation: `(200 × microsteps × planetary × harmonic) / 360`
   - Send `:ENVRESET#` after changing

2. **Mount not aligned**
   - Perform star alignment (sync on 2-3 stars)
   - Ensure polar alignment is correct

3. **Time/location incorrect**
   - Verify GPS is working: `:GW#` should NOT show "G" flag
   - Set manually via web interface if no GPS

### Mount Slews to Wrong Position

**Solutions:**
1. Check axis reversal settings
2. Verify hemisphere setting
3. Recalibrate home position

### Tracking Drifts Quickly

**Possible causes:**
1. Incorrect steps per degree
2. Mechanical backlash
3. Polar alignment error
4. Periodic error (normal for harmonic drives)

## Docker Stack Issues

### Container Won't Start

```bash
# Check logs
docker compose logs indiserver

# Common fixes:
# Port already in use
sudo lsof -i :7624
# Kill conflicting process or change port

# Permission denied
# Ensure privileged: true in docker-compose.yml
```

### Can't Connect from Stellarium

1. Verify INDI server is running:
   ```bash
   telnet localhost 7624
   ```

2. Check firewall:
   ```bash
   # Windows
   netsh advfirewall firewall add rule name="INDI" dir=in action=allow protocol=tcp localport=7624

   # Linux
   sudo ufw allow 7624/tcp
   ```

3. Use Docker host IP instead of localhost

### Mount Not Found in INDI

1. Verify mount is reachable:
   ```bash
   telnet 192.168.0.86 9999
   ```

2. Send test command:
   ```
   :GVN#
   ```
   Should return version (e.g., `10.24c#`)

3. Check INDI driver selection (use `indi_lx200_OnStep`)

## Firmware Issues

### Compilation Errors

**"SoftwareSerial.h not found"**
- Wrong ESP32 core version
- Fix: `arduino-cli core install esp32:esp32@2.0.17`

**"Config.h: No such file"**
- Copy Config.h.example to Config.h

**"Multiple definitions"**
- Check for duplicate includes

### Upload Fails

1. **Wrong COM port**
   - Check Device Manager (Windows) or `ls /dev/tty*` (Linux)

2. **Board in download mode**
   - Power cycle board
   - Hold BOOT button during upload if needed

3. **Driver not installed**
   - Install CP2102 or CH340 driver for your board

## Mechanical Issues

### Harmonic Drive Binding

**Causes:**
1. Screws overtightened (warps WaveGenerator)
2. Insufficient lubrication
3. Misalignment
4. Debris in ball race

**Solutions:**
1. Loosen screws slightly
2. Add grease to ball races
3. Realign components
4. Clean and reassemble

### Inconsistent Tracking

**Possible causes:**
1. Backlash in coupling
2. Loose set screws
3. Harmonic drive not properly meshed

**Solutions:**
1. Tighten coupler to motor shaft
2. Check all set screws
3. Verify smooth rotation by hand

## Quick Diagnostic Commands

Send these via serial (9600 baud) to diagnose issues:

| Command | Purpose | Expected Response |
|---------|---------|-------------------|
| `:GVN#` | Get firmware version | `10.24c#` |
| `:GW#` | Get mount status | `GNH#` or similar |
| `:GXE5#` | Get steps/degree | Your configured value |
| `:GR#` | Get RA position | RA coordinates |
| `:GD#` | Get Dec position | Dec coordinates |
| `:Te#` | Enable tracking | `1` (success) |
| `:Td#` | Disable tracking | `1` (success) |

## Getting Help

If this guide doesn't solve your issue:

1. **OnStep Community:** [groups.io/g/main](https://onstep.groups.io/g/main)
2. **GitHub Issues:** [JonnyBytesMe/keen-one-astronomy/issues](https://github.com/JonnyBytesMe/keen-one-astronomy/issues)
3. **Include in your report:**
   - Firmware version (`:GVN#`)
   - Mount status (`:GW#`)
   - Hardware configuration
   - Steps to reproduce
   - Error messages or logs
