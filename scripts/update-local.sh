#!/bin/bash
# 
# update-local.sh - Update the local installation with the current code
#
# This script updates the installed version at /usr/local/pane with your
# current development code, so you can test your changes.

# Set up error handling
set -e

# Backup your current ~/.config/pane directory
echo "Backing up your config..."
cp -r ~/.config/pane ~/.config/pane.bak.$(date +"%Y%m%d%H%M%S")

# Build the package
echo "Building package..."
mix deps.get
mix compile
mix escript.build

# Check if we need sudo
INSTALL_DIR="/usr/local/pane"
USE_SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
  USE_SUDO="sudo"
  echo "Need sudo to update files in $INSTALL_DIR"
fi

# Update the installed version
echo "Updating installed version..."
$USE_SUDO cp pane "$INSTALL_DIR/bin/"
$USE_SUDO cp -R lib "$INSTALL_DIR/"

# Update scripts if needed
$USE_SUDO cp scripts/pane.sh "$INSTALL_DIR/"
$USE_SUDO cp scripts/pane.exs "$INSTALL_DIR/"

# Set permissions
$USE_SUDO chmod +x "$INSTALL_DIR/pane.sh"
$USE_SUDO chmod +x "$INSTALL_DIR/pane.exs"
$USE_SUDO chmod +x "$INSTALL_DIR/bin/pane"

echo "Update complete! Run 'pane --preview --verbose' to test."