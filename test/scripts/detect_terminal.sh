#!/bin/bash
# Terminal detection script for pane tool
# Returns 0 if terminal is interactive, 1 otherwise
# With --verbose, prints detailed detection info

VERBOSE=false
if [ "$1" = "--verbose" ]; then
  VERBOSE=true
fi

# Test method 1: standard tty check
echo "check: is_tty_0?"
echo "cmd: test -t 0"
test -t 0
TTY_0_RESULT=$?
echo "result: $TTY_0_RESULT (0=true, 1=false)"

# Test method 2: tty command
echo "check: has_tty_device?"
echo "cmd: tty | grep -v \"not a tty\" > /dev/null"
tty | grep -v "not a tty" > /dev/null
TTY_DEVICE_RESULT=$?
echo "result: $TTY_DEVICE_RESULT (0=true, 1=false)"

# Test method 3: stdin character device
echo "check: is_stdin_char_device?"
echo "cmd: test -c /dev/stdin"
test -c /dev/stdin
STDIN_CHAR_RESULT=$?
echo "result: $STDIN_CHAR_RESULT (0=true, 1=false)"

# Test method 4: environment variable check
echo "check: has_term_env?"
echo "cmd: [ -n \"$TERM\" ]"
[ -n "$TERM" ]
TERM_ENV_RESULT=$?
echo "result: $TERM_ENV_RESULT (0=true, 1=false)"

# Combine results
if [ $TTY_0_RESULT -eq 0 ] || [ $TTY_DEVICE_RESULT -eq 0 ] || [ $STDIN_CHAR_RESULT -eq 0 ]; then
  echo "detect: terminal_is_interactive=true"
  exit 0
else
  echo "detect: terminal_is_interactive=false"
  exit 1
fi