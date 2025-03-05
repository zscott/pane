#!/bin/bash
#
# uninstall.sh - Uninstall pane
#

set -e

INSTALL_DIR="/usr/local/pane"
BIN_LINK="/usr/local/bin/pane"
CONFIG_DIR="$HOME/.config/pane"

echo "Uninstalling pane..."

# Check for sudo access if needed
need_sudo=false
if [ ! -w "$INSTALL_DIR" ] || [ ! -w "$BIN_LINK" ] || [ ! -e "$BIN_LINK" ]; then
  need_sudo=true
  echo "This script needs to remove files in $INSTALL_DIR and $BIN_LINK"
  echo "You may be prompted for your password."
  echo
fi

# Remove symlink
if [ -L "$BIN_LINK" ]; then
  echo "Removing symbolic link $BIN_LINK..."
  if [ "$need_sudo" = true ]; then
    sudo rm "$BIN_LINK"
  else
    rm "$BIN_LINK"
  fi
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
  echo "Removing installation directory $INSTALL_DIR..."
  if [ "$need_sudo" = true ]; then
    sudo rm -rf "$INSTALL_DIR"
  else
    rm -rf "$INSTALL_DIR"
  fi
fi

# Ask about configuration files
if [ -d "$CONFIG_DIR" ]; then
  echo
  echo "Configuration directory found at $CONFIG_DIR"
  read -p "Do you want to keep configuration files? [Y/n] " response
  response=${response:-Y}  # Default to Y
  if [[ $response =~ ^[Nn]$ ]]; then
    echo "Removing configuration files..."
    rm -rf "$CONFIG_DIR"
    echo "Configuration files removed."
  else
    echo "Configuration files have been kept in $CONFIG_DIR."
  fi
fi

echo "Pane has been uninstalled."
