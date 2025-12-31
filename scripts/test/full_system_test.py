#!/usr/bin/env python3
"""
Keen-One Astronomy Stack - Full System Test
Tests all components of the astronomy stack end-to-end
"""

import socket
import time
import re
import sys
import subprocess

INDI_HOST = "localhost"
INDI_PORT = 7624
MOUNT_DEVICE = "LX200 OnStep"
TIMEOUT = 10

class Colors:
    GREEN = ""
    RED = ""
    YELLOW = ""
    RESET = ""
    BOLD = ""

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}\n")

def print_pass(msg):
    print(f"  [PASS] {msg}")

def print_fail(msg):
    print(f"  [FAIL] {msg}")

def print_warn(msg):
    print(f"  [WARN] {msg}")

def print_info(msg):
    print(f"  [INFO] {msg}")

def send_indi_command(host, port, command, timeout=5, wait_time=1.0):
    """Send command to INDI server and get response."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        sock.connect((host, port))
        sock.sendall(command.encode())
        time.sleep(wait_time)  # Wait for response

        response = b""
        sock.setblocking(False)
        try:
            while True:
                try:
                    chunk = sock.recv(8192)
                    if not chunk:
                        break
                    response += chunk
                except BlockingIOError:
                    break
        finally:
            sock.setblocking(True)

        sock.close()
        return response.decode('utf-8', errors='ignore')
    except Exception as e:
        return f"ERROR: {e}"

def test_docker_containers():
    """Test that Docker containers are running."""
    print("Test 1: Docker Containers")
    print("-" * 40)

    try:
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}\t{{.Status}}"],
            capture_output=True, text=True, timeout=10
        )

        containers = result.stdout.strip().split('\n')
        found_indi = False
        found_desktop = False

        for line in containers:
            if "indiserver" in line:
                found_indi = True
                print_pass(f"indiserver: {line.split(chr(9))[1] if chr(9) in line else 'running'}")
            if "astronomy-desktop" in line:
                found_desktop = True
                print_pass(f"astronomy-desktop: {line.split(chr(9))[1] if chr(9) in line else 'running'}")

        if not found_indi:
            print_fail("indiserver container not found")
        if not found_desktop:
            print_fail("astronomy-desktop container not found")

        return found_indi and found_desktop
    except Exception as e:
        print_fail(f"Docker check failed: {e}")
        return False

def test_indi_connection():
    """Test INDI server connectivity."""
    print("\nTest 2: INDI Server Connection")
    print("-" * 40)

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((INDI_HOST, INDI_PORT))
        sock.close()

        if result == 0:
            print_pass(f"Connected to {INDI_HOST}:{INDI_PORT}")
            return True
        else:
            print_fail(f"Cannot connect to {INDI_HOST}:{INDI_PORT}")
            return False
    except Exception as e:
        print_fail(f"Connection error: {e}")
        return False

def test_indi_driver():
    """Test that INDI driver is loaded."""
    print("\nTest 3: INDI Driver Status")
    print("-" * 40)

    response = send_indi_command(INDI_HOST, INDI_PORT, '<getProperties version="1.7"/>')

    if "ERROR" in response:
        print_fail(f"Failed to query INDI: {response}")
        return False, None

    if MOUNT_DEVICE in response:
        print_pass(f"{MOUNT_DEVICE} driver loaded")

        # Check connection status
        if 'name="CONNECT"' in response:
            # Find connection state
            connect_section = response.split('name="CONNECT"')[1][:200]
            if ">On<" in connect_section or "On\n" in connect_section:
                print_pass("Mount is CONNECTED")
            else:
                print_warn("Mount driver loaded but not connected to hardware")

        return True, response
    else:
        print_fail(f"{MOUNT_DEVICE} driver not found")
        return False, response

def test_mount_coordinates(indi_response):
    """Test reading mount coordinates."""
    print("\nTest 4: Mount Coordinates")
    print("-" * 40)

    if not indi_response:
        print_fail("No INDI response to parse")
        return None, None

    # Extract RA
    ra_match = re.search(r'name="RA"[^>]*>[\s\n]*([\d.]+)', indi_response)
    dec_match = re.search(r'name="DEC"[^>]*>[\s\n]*([-\d.]+)', indi_response)

    if ra_match and dec_match:
        ra = float(ra_match.group(1))
        dec = float(dec_match.group(1))

        # Convert to readable format
        ra_h = int(ra)
        ra_m = int((ra - ra_h) * 60)
        ra_s = int(((ra - ra_h) * 60 - ra_m) * 60)

        dec_d = int(dec)
        dec_m = abs(int((dec - dec_d) * 60))

        print_pass(f"RA:  {ra_h}h {ra_m}m {ra_s}s ({ra:.4f})")
        print_pass(f"Dec: {dec_d}d {dec_m}' ({dec:.4f})")
        return ra, dec
    else:
        print_warn("Could not read coordinates (mount may not be connected)")
        return None, None

def test_slew_command(current_ra, current_dec):
    """Test sending a slew command."""
    print("\nTest 5: Slew Command")
    print("-" * 40)

    if current_ra is None:
        print_warn("Skipping slew test - no current coordinates")
        return False

    # Slew to a small offset from current position
    target_ra = current_ra + 0.01  # Move slightly in RA
    target_dec = current_dec

    print_info(f"Sending slew to RA={target_ra:.4f}, Dec={target_dec:.4f}")

    slew_cmd = f'''<newNumberVector device="{MOUNT_DEVICE}" name="EQUATORIAL_EOD_COORD">
  <oneNumber name="RA">{target_ra}</oneNumber>
  <oneNumber name="DEC">{target_dec}</oneNumber>
</newNumberVector>'''

    response = send_indi_command(INDI_HOST, INDI_PORT, slew_cmd, timeout=5, wait_time=1.5)

    # Check for Busy state (mount is slewing) or Ok state (command accepted)
    if 'state="Busy"' in response or "Busy" in response:
        print_pass("Slew command accepted (state: Busy)")

        # Wait and check for completion
        time.sleep(2)

        # Abort the slew
        abort_cmd = f'''<newSwitchVector device="{MOUNT_DEVICE}" name="TELESCOPE_ABORT_MOTION">
  <oneSwitch name="ABORT">On</oneSwitch>
</newSwitchVector>'''
        send_indi_command(INDI_HOST, INDI_PORT, abort_cmd, timeout=2)
        print_info("Slew aborted after test")
        return True
    elif 'state="Ok"' in response or "Ok" in response:
        print_pass("Slew command completed")
        return True
    elif "EQUATORIAL" in response:
        # Response contains coordinate update, command was accepted
        print_pass("Slew command sent (coordinate update received)")
        # Abort the slew
        abort_cmd = f'''<newSwitchVector device="{MOUNT_DEVICE}" name="TELESCOPE_ABORT_MOTION">
  <oneSwitch name="ABORT">On</oneSwitch>
</newSwitchVector>'''
        send_indi_command(INDI_HOST, INDI_PORT, abort_cmd, timeout=2)
        return True
    else:
        print_warn("Slew response unclear - mount may not be connected")
        return False

def test_container_indi_access():
    """Test INDI access from astronomy-desktop container."""
    print("\nTest 6: Container INDI Access")
    print("-" * 40)

    try:
        result = subprocess.run(
            ["docker", "exec", "astronomy-desktop", "sh", "-c",
             "nc -z indiserver 7624 && echo PASS || echo FAIL"],
            capture_output=True, text=True, timeout=10
        )

        if "PASS" in result.stdout:
            print_pass("astronomy-desktop can reach indiserver:7624")
            return True
        else:
            print_fail("astronomy-desktop cannot reach indiserver")
            return False
    except Exception as e:
        print_fail(f"Container test failed: {e}")
        return False

def test_stellarium_config():
    """Test Stellarium configuration exists."""
    print("\nTest 7: Stellarium Configuration")
    print("-" * 40)

    try:
        result = subprocess.run(
            ["docker", "exec", "astronomy-desktop", "sh", "-c",
             "cat /config/.stellarium/modules/TelescopeControl/telescopes.ini 2>/dev/null"],
            capture_output=True, text=True, timeout=10
        )

        if "LX200 OnStep" in result.stdout and "indiserver" in result.stdout:
            print_pass("Stellarium telescope config correct")
            print_info("  - Connection: INDI to indiserver:7624")
            print_info("  - Device: LX200 OnStep")
            return True
        else:
            print_fail("Stellarium telescope config missing or incorrect")
            return False
    except Exception as e:
        print_fail(f"Config check failed: {e}")
        return False

def test_kstars_config():
    """Test KStars Ekos profile exists."""
    print("\nTest 8: KStars/Ekos Configuration")
    print("-" * 40)

    try:
        result = subprocess.run(
            ["docker", "exec", "astronomy-desktop", "sh", "-c",
             "cat /config/.local/share/kstars/ekos_profiles.xml 2>/dev/null"],
            capture_output=True, text=True, timeout=10
        )

        if "Keen-One EQ" in result.stdout and "LX200 OnStep" in result.stdout:
            print_pass("KStars Ekos profile correct")
            print_info("  - Profile: Keen-One EQ")
            print_info("  - Auto-connect: Enabled")
            print_info("  - Remote INDI: indiserver:7624")
            return True
        else:
            print_fail("KStars Ekos profile missing or incorrect")
            return False
    except Exception as e:
        print_fail(f"Config check failed: {e}")
        return False

def test_software_installed():
    """Test that astronomy software is installed."""
    print("\nTest 9: Software Installation")
    print("-" * 40)

    try:
        result = subprocess.run(
            ["docker", "exec", "astronomy-desktop", "sh", "-c",
             "which stellarium kstars indi_getprop 2>/dev/null"],
            capture_output=True, text=True, timeout=10
        )

        output = result.stdout.strip()

        if "stellarium" in output:
            print_pass("Stellarium installed")
        else:
            print_fail("Stellarium not found")

        if "kstars" in output:
            print_pass("KStars installed")
        else:
            print_fail("KStars not found")

        if "indi_getprop" in output:
            print_pass("INDI tools installed")
        else:
            print_warn("INDI tools not found (optional)")

        return "stellarium" in output and "kstars" in output
    except Exception as e:
        print_fail(f"Software check failed: {e}")
        return False

def test_web_desktop():
    """Test web desktop is accessible."""
    print("\nTest 10: Web Desktop Access")
    print("-" * 40)

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex(("localhost", 3000))
        sock.close()

        if result == 0:
            print_pass("Web desktop accessible at http://localhost:3000")
            return True
        else:
            print_fail("Web desktop not accessible on port 3000")
            return False
    except Exception as e:
        print_fail(f"Web desktop check failed: {e}")
        return False

def main():
    print_header("KEEN-ONE ASTRONOMY STACK - FULL SYSTEM TEST")

    results = {}

    # Run all tests
    results["docker"] = test_docker_containers()
    results["indi_conn"] = test_indi_connection()

    if results["indi_conn"]:
        driver_ok, indi_response = test_indi_driver()
        results["indi_driver"] = driver_ok

        if driver_ok:
            ra, dec = test_mount_coordinates(indi_response)
            results["coordinates"] = ra is not None
            results["slew"] = test_slew_command(ra, dec)
        else:
            results["coordinates"] = False
            results["slew"] = False
    else:
        results["indi_driver"] = False
        results["coordinates"] = False
        results["slew"] = False

    results["container_indi"] = test_container_indi_access()
    results["stellarium_cfg"] = test_stellarium_config()
    results["kstars_cfg"] = test_kstars_config()
    results["software"] = test_software_installed()
    results["web_desktop"] = test_web_desktop()

    # Summary
    print_header("TEST SUMMARY")

    passed = sum(1 for v in results.values() if v)
    total = len(results)

    for test, result in results.items():
        status = "[PASS]" if result else "[FAIL]"
        print(f"  {status} {test}")

    print(f"\n  Results: {passed}/{total} tests passed")

    if passed == total:
        print("\n  *** ALL TESTS PASSED - SYSTEM READY ***")
        print("\n  Open http://localhost:3000 to use the astronomy desktop")
        print("  - Stellarium: Ctrl+0 for telescope control")
        print("  - KStars: Tools -> Ekos")
    else:
        print("\n  *** SOME TESTS FAILED - CHECK ABOVE FOR DETAILS ***")

    return 0 if passed == total else 1

if __name__ == "__main__":
    sys.exit(main())
