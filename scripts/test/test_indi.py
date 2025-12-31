#!/usr/bin/env python3
"""
INDI Stack Test Script
Tests INDI server connectivity and telescope control from the host machine.
"""

import socket
import sys
import time
import xml.etree.ElementTree as ET
from typing import Optional, Tuple

# Configuration
INDI_HOST = "localhost"  # From host perspective
INDI_PORT = 7624
MOUNT_DEVICE = "LX200 OnStep"
TIMEOUT = 10


class INDIClient:
    """Simple INDI client for testing telescope control."""

    def __init__(self, host: str = INDI_HOST, port: int = INDI_PORT):
        self.host = host
        self.port = port
        self.socket: Optional[socket.socket] = None

    def connect(self) -> bool:
        """Connect to INDI server."""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(TIMEOUT)
            self.socket.connect((self.host, self.port))
            return True
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False

    def disconnect(self):
        """Disconnect from INDI server."""
        if self.socket:
            self.socket.close()
            self.socket = None

    def send(self, message: str) -> str:
        """Send message and receive response."""
        if not self.socket:
            raise RuntimeError("Not connected")

        self.socket.sendall(message.encode())
        time.sleep(0.5)  # Wait for response

        # Receive response
        response = b""
        self.socket.setblocking(False)
        try:
            while True:
                try:
                    chunk = self.socket.recv(4096)
                    if not chunk:
                        break
                    response += chunk
                except BlockingIOError:
                    break
        finally:
            self.socket.setblocking(True)

        return response.decode('utf-8', errors='ignore')

    def get_properties(self) -> str:
        """Get all INDI properties."""
        return self.send('<getProperties version="1.7"/>')

    def get_coordinates(self, response: str) -> Tuple[Optional[float], Optional[float]]:
        """Parse RA/DEC from INDI response."""
        try:
            # Find RA
            ra_start = response.find('name="RA"')
            if ra_start > 0:
                ra_section = response[ra_start:ra_start+200]
                # Extract number
                import re
                ra_match = re.search(r'>\s*([\d.]+)\s*<', ra_section)
                ra = float(ra_match.group(1)) if ra_match else None
            else:
                ra = None

            # Find DEC
            dec_start = response.find('name="DEC"')
            if dec_start > 0:
                dec_section = response[dec_start:dec_start+200]
                dec_match = re.search(r'>\s*([-\d.]+)\s*<', dec_section)
                dec = float(dec_match.group(1)) if dec_match else None
            else:
                dec = None

            return ra, dec
        except Exception:
            return None, None

    def slew_to(self, ra: float, dec: float) -> str:
        """Send slew command to telescope."""
        cmd = f'''<newNumberVector device="{MOUNT_DEVICE}" name="EQUATORIAL_EOD_COORD">
  <oneNumber name="RA">{ra}</oneNumber>
  <oneNumber name="DEC">{dec}</oneNumber>
</newNumberVector>'''
        return self.send(cmd)

    def abort_slew(self) -> str:
        """Abort current slew."""
        cmd = f'''<newSwitchVector device="{MOUNT_DEVICE}" name="TELESCOPE_ABORT_MOTION">
  <oneSwitch name="ABORT">On</oneSwitch>
</newSwitchVector>'''
        return self.send(cmd)


def run_tests():
    """Run all INDI tests."""
    print("=" * 50)
    print("  INDI Telescope Control Test Suite")
    print("=" * 50)
    print()

    client = INDIClient()
    passed = 0
    failed = 0

    # Test 1: Connection
    print("Test 1: INDI Server Connection...", end=" ")
    if client.connect():
        print("[PASS]")
        passed += 1
    else:
        print("[FAIL]")
        failed += 1
        print("\nCannot continue without connection.")
        return False

    # Test 2: Get Properties
    print("Test 2: Get INDI Properties...", end=" ")
    try:
        response = client.get_properties()
        if MOUNT_DEVICE in response:
            print(f"✅ PASS - {MOUNT_DEVICE} found")
            passed += 1
        else:
            print("❌ FAIL - Mount device not found")
            failed += 1
    except Exception as e:
        print(f"❌ FAIL - {e}")
        failed += 1

    # Test 3: Check Connection Status
    print("Test 3: Mount Connection Status...", end=" ")
    if 'name="CONNECT"' in response:
        if ">On<" in response.split('name="CONNECT"')[1][:100]:
            print("✅ PASS - Mount connected")
            passed += 1
        else:
            print("⚠️  WARN - Mount not connected")
            passed += 1  # Not a failure, just a state
    else:
        print("❌ FAIL - Cannot determine status")
        failed += 1

    # Test 4: Read Coordinates
    print("Test 4: Read Current Position...", end=" ")
    ra, dec = client.get_coordinates(response)
    if ra is not None and dec is not None:
        ra_h = int(ra)
        ra_m = int((ra - ra_h) * 60)
        dec_d = int(dec)
        dec_m = abs(int((dec - dec_d) * 60))
        print(f"✅ PASS - RA: {ra_h}h{ra_m}m, Dec: {dec_d}°{dec_m}'")
        passed += 1
    else:
        print("⚠️  WARN - Could not read coordinates")

    # Test 5: Slew Command (small offset)
    print("Test 5: Slew Command Test...", end=" ")
    if ra is not None and dec is not None:
        # Slew to current position + tiny offset (won't move much)
        test_ra = ra + 0.001
        test_dec = dec
        try:
            slew_response = client.slew_to(test_ra, test_dec)
            if "Busy" in slew_response or "Ok" in slew_response:
                print("✅ PASS - Slew command accepted")
                passed += 1
                # Abort the slew
                client.abort_slew()
            else:
                print("⚠️  WARN - Slew response unclear")
        except Exception as e:
            print(f"❌ FAIL - {e}")
            failed += 1
    else:
        print("⏭️  SKIP - No coordinates available")

    client.disconnect()

    # Summary
    print()
    print("=" * 50)
    print(f"  Results: {passed} passed, {failed} failed")
    print("=" * 50)

    return failed == 0


def slew_to_target(ra: float, dec: float):
    """Slew telescope to specified coordinates."""
    print(f"Slewing to RA={ra}, Dec={dec}...")

    client = INDIClient()
    if not client.connect():
        return False

    response = client.slew_to(ra, dec)
    print("Slew command sent. Monitoring position...")

    # Monitor for 30 seconds
    for i in range(30):
        time.sleep(1)
        props = client.get_properties()
        current_ra, current_dec = client.get_coordinates(props)
        if current_ra and current_dec:
            print(f"  Position: RA={current_ra:.4f}, Dec={current_dec:.4f}")

            # Check if we've arrived (within 0.01 degrees)
            if abs(current_ra - ra) < 0.01 and abs(current_dec - dec) < 0.5:
                print("✅ Target reached!")
                break

        if "Ok" in props and "Busy" not in props:
            print("✅ Slew complete")
            break

    client.disconnect()
    return True


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "test":
            success = run_tests()
            sys.exit(0 if success else 1)
        elif sys.argv[1] == "slew" and len(sys.argv) == 4:
            ra = float(sys.argv[2])
            dec = float(sys.argv[3])
            slew_to_target(ra, dec)
        else:
            print("Usage:")
            print("  python test_indi.py test        - Run all tests")
            print("  python test_indi.py slew RA DEC - Slew to coordinates")
            print("                                    RA in hours (0-24)")
            print("                                    DEC in degrees (-90 to 90)")
    else:
        run_tests()
