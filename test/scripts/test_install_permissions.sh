#!/bin/bash
# Test script for installation privilege requirements

echo "=== Testing Installation Permission Requirements ==="

# Get directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"
SETUP_SCRIPT="$PROJECT_ROOT/scripts/setup-combined.sh"

# Test 1: Script correctly checks for sudo permissions
echo "Test 1: Script requires sudo privileges to /usr/local"
# Run script as non-sudo user
if [ "$(whoami)" == "root" ]; then
  echo "WARNING: Test is running as root. This test is meant to be run as a non-root user."
  echo "SKIPPING TEST"
  exit 0
fi

output=$("$SETUP_SCRIPT" 2>&1)

echo "$output" | grep -q "This script requires sudo privileges to install to /usr/local"
if [ $? -eq 0 ]; then
  echo "PASS: Setup script correctly detects missing sudo privileges"
  echo "Error message displayed: $(echo "$output" | grep "This script requires sudo privileges")"
else
  echo "FAIL: Setup script doesn't properly check for sudo privileges"
  echo "Output received:"
  echo "$output" | head -10
fi

# Test 2: Uninstall script also checks for sudo privileges
echo "Test 2: Uninstall script checks for sudo permissions"

# Read uninstall script content without writing to disk
uninstall_script=$(sed -n '/^cat > "\/usr\/local\/pane-wrapper\/uninstall" << '\''EOF'\''/,/^EOF/p' "$SETUP_SCRIPT" | sed '1d;$d')

echo "$uninstall_script" | grep -q "This script requires sudo privileges"
if [ $? -eq 0 ]; then
  echo "PASS: Uninstall script correctly checks for sudo privileges"
else
  echo "FAIL: Uninstall script doesn't check for sudo privileges"
fi

# Test 3: README instructions use sudo
echo "Test 3: README instructions use sudo for installation"

README_CONTENT=$(cat "$PROJECT_ROOT/README.md")

echo "$README_CONTENT" | grep -q "curl -sSL .* -o pane-setup.sh"
if [ $? -eq 0 ]; then
  echo "PASS: README uses safer download-then-run approach with curl"
else
  echo "FAIL: README doesn't use the safer download-then-run approach with curl"
fi

echo "$README_CONTENT" | grep -q "sudo ./pane-setup.sh"
if [ $? -eq 0 ]; then
  echo "PASS: README uses sudo to run the downloaded setup script"
else
  echo "FAIL: README doesn't use sudo to run the downloaded setup script"
fi

echo "$README_CONTENT" | grep -q "sudo ./scripts/setup-combined.sh"
if [ $? -eq 0 ]; then
  echo "PASS: README uses sudo for manual installation"
else
  echo "FAIL: README doesn't use sudo for manual installation"
fi

echo "$README_CONTENT" | grep -q "sudo /usr/local/pane-wrapper/uninstall"
if [ $? -eq 0 ]; then
  echo "PASS: README uses sudo for uninstallation"
else
  echo "FAIL: README doesn't use sudo for uninstallation"
fi

echo "All tests completed."