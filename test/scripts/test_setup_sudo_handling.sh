#!/bin/bash
# Test script for installation sudo handling

echo "=== Testing Installation sudo handling ==="

# Get directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"
SETUP_SCRIPT="$PROJECT_ROOT/scripts/setup.sh"

# Test 1: Check that setup.sh has proper sudo handling
echo "Test 1: setup.sh handles sudo permissions properly"

grep -q "setup_permissions" "$SETUP_SCRIPT"
if [ $? -eq 0 ]; then
  echo "PASS: setup.sh contains setup_permissions function"
else
  echo "FAIL: setup.sh doesn't have a setup_permissions function"
fi

grep -q "USE_SUDO=" "$SETUP_SCRIPT"
if [ $? -eq 0 ]; then
  echo "PASS: setup.sh uses USE_SUDO variable for privilege escalation"
else
  echo "FAIL: setup.sh doesn't use USE_SUDO variable for privilege escalation"
fi

# Test 2: Check that setup.sh informs users about sudo requirements
echo "Test 2: setup.sh informs users about sudo requirements"

grep -q "You may be prompted for your password during installation" "$SETUP_SCRIPT"
if [ $? -eq 0 ]; then
  echo "PASS: setup.sh informs users about password prompts"
else
  echo "FAIL: setup.sh doesn't inform users about password prompts"
fi

# Test 3: Check that README uses the correct installation command
echo "Test 3: README uses the correct installation command"

README_CONTENT=$(cat "$PROJECT_ROOT/README.md")

echo "$README_CONTENT" | grep -q "curl -sSL .*/scripts/setup.sh | bash"
if [ $? -eq 0 ]; then
  echo "PASS: README uses setup.sh for installation"
else
  echo "FAIL: README doesn't use setup.sh for installation"
fi

echo "All tests completed."