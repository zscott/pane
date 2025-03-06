#!/bin/bash
# Test script for implementation switching functionality

echo "=== Pane Implementation Switching Tests ==="

# Get directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"
PANE_SCRIPT="$PROJECT_ROOT/pane.sh"
PANE_BIN="$PROJECT_ROOT/pane"

# Test 1: Default implementation is Node.js
echo "Test 1: Default implementation is Node.js"
echo "Running: $PANE_SCRIPT --preview"
output=$("$PANE_SCRIPT" --preview)

echo "$output" | grep -q "\[pane\] Using Node.js implementation"
if [ $? -eq 0 ]; then
  echo "PASS: Default implementation is Node.js"
else
  echo "FAIL: Default implementation is not Node.js"
  echo "--- Output snippet (first 10 lines) ---"
  echo "$output" | head -10
  echo "--------------------"
fi

# Test 2: Elixir implementation with --elixir flag
echo "Test 2: Switch to Elixir implementation with --elixir flag"
echo "Running: $PANE_SCRIPT --elixir --preview"
output=$("$PANE_SCRIPT" --elixir --preview)

echo "$output" | grep -q "\[pane\] Using Elixir implementation"
if [ $? -eq 0 ]; then
  echo "PASS: Successfully switched to Elixir implementation"
else
  echo "FAIL: Could not switch to Elixir implementation"
  echo "--- Output snippet (first 10 lines) ---"
  echo "$output" | head -10
  echo "--------------------"
fi

# Test 3: Help text includes --elixir flag
echo "Test 3: Help text includes --elixir flag"
echo "Running: $PANE_SCRIPT --help"
output=$("$PANE_SCRIPT" --help)

echo "$output" | grep -q -- "--elixir"
if [ $? -eq 0 ]; then
  echo "PASS: Help text includes --elixir flag"
else
  echo "FAIL: Help text does not include --elixir flag"
  echo "--- Output snippet (options section) ---"
  echo "$output" | grep -A 10 "Options:"
  echo "--------------------"
fi

echo "All implementation switching tests completed."