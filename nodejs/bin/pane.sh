#!/bin/sh

# Wrapper script for the Pane tmux session manager
# This detects the script location regardless of symlinks

# Find the real path to the script
if command -v realpath &> /dev/null; then
  SCRIPT_PATH=$(realpath "$0")
else
  # Fallback for systems without realpath
  SCRIPT_PATH="$0"
  while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
  done
fi

# Get the script directory
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# Execute the Node.js script
node "$SCRIPT_DIR/pane.js" "$@"