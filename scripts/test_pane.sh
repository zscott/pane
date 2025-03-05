#!/bin/bash
# Basic test script for pane functionality

echo "=== Pane Basic Tests ==="

# Get directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANE_DIR="$(dirname "$SCRIPT_DIR")"
PANE_SCRIPT="$PANE_DIR/pane.sh"

# Use the shell script instead of the binary for testing
# This ensures we're using the same environment as the user would
PANE_BIN="$PANE_SCRIPT"

# Set up test config path
TEST_CONFIG_PATH="$SCRIPT_DIR/../config/test-config.yaml"

# Test 1: --no-attach flag respected
echo "Test 1: --no-attach flag"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --preview --no-attach"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --preview --no-attach)

echo "$output" | grep -q "# --no-attach specified?: true"
if [ $? -eq 0 ]; then
  echo "PASS: --no-attach flag correctly detected"
else
  echo "FAIL: --no-attach flag not correctly detected"
  echo "--- Output snippet ---"
  echo "$output" | grep -A 3 "# Flag processing"
  echo "--------------------"
fi

# Test 2: Auto-attach enabled by default
echo "Test 2: Auto-attach enabled by default"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --preview"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --preview)

echo "$output" | grep -q "# auto_attach_enabled?: true"
if [ $? -eq 0 ]; then
  echo "PASS: Auto-attach enabled by default"
else
  echo "FAIL: Auto-attach not enabled by default"
  echo "--- Output snippet ---"
  echo "$output" | grep -A 3 "# Flag processing"
  echo "--------------------"
fi

# Test 3: Terminal detection
echo "Test 3: Terminal detection"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --preview"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --preview)

echo "$output" | grep -q "is_tty_0?"
if [ $? -eq 0 ]; then
  echo "PASS: Terminal detection performed"
  result=$(echo "$output" | grep "is_terminal_interactive" | awk '{print $3}')
  echo "Terminal interactive: $result"
else
  echo "FAIL: Terminal detection not reported"
fi

# Test 4: Session detection
echo "Test 4: Session detection"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --preview"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --preview)

echo "$output" | grep -q "session_running?: "
if [ $? -eq 0 ]; then
  echo "PASS: Session detection performed"
  session_exists=$(echo "$output" | grep "session_running?: " | awk '{print $3}')
  echo "Session exists: $session_exists"
else
  echo "FAIL: Session detection not reported"
fi

# Test 5: Commands generated correctly
echo "Test 5: Commands generated correctly"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --preview"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --preview)

echo "$output" | grep -q "tmux new-session"
if [ $? -eq 0 ]; then
  echo "PASS: tmux new-session command generated"
else
  echo "FAIL: tmux new-session command not found"
fi

echo "$output" | grep -q "tmux attach-session"
if [ $? -eq 0 ]; then
  echo "PASS: tmux attach-session command generated"
else
  echo "FAIL: tmux attach-session command not found"
fi

# More tests...

# Test 6: Session status message
echo "Test 6: Session status message"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --preview"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --preview)

echo "$output" | grep -q "# Creating new session\|# Session already exists"
if [ $? -eq 0 ]; then
  echo "PASS: Session status message shown"
  status_msg=$(echo "$output" | grep "# Creating new session\|# Session already exists")
  echo "Status message: $status_msg"
else
  echo "FAIL: Session status message not found"
fi

# Test 7: --no-attach flag in real mode (output only)
echo "Test 7: --no-attach flag in real mode"
echo "Running: $PANE_BIN --config="$TEST_CONFIG_PATH" --no-attach --verbose"
output=$("$PANE_BIN" --config="$TEST_CONFIG_PATH" --no-attach --verbose)

echo "$output" | grep -q "Auto-attach enabled: false"
if [ $? -eq 0 ]; then
  echo "PASS: --no-attach flag correctly processed in real mode"
else
  echo "FAIL: --no-attach flag not respected in real mode"
  echo "--- Output snippet ---"
  echo "$output" | grep -A 3 "Auto-attach"
  echo "--------------------"
fi

echo "All tests completed."