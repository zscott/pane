#!/bin/bash
#
# setup.sh - Professional installation script for Pane
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/zscott/pane/main/scripts/setup.sh | bash
#   or locally:
#   ./setup.sh
#

# Exit on any error
set -e

# Define constants
INSTALL_DIR="/usr/local/pane"
BIN_DIR="/usr/local/bin"
SYMLINK_NAME="pane"
CONFIG_DIR="$HOME/.config/pane"
REPO_OWNER="zscott"
REPO_NAME="pane"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"
RELEASES_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
RELEASE_DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download"
VERSION_FILE="$INSTALL_DIR/VERSION"

# Colors for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}Pane - Installation"
echo -e "Tmux Session Manager${NC}"
echo

# Logging functions
log_info() {
  echo -e "${BLUE}INFO: $1${NC}"
}

log_success() {
  echo -e "${GREEN}SUCCESS: $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

log_error() {
  echo -e "${RED}ERROR: $1${NC}"
}

# Progress spinner
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Check for required commands
check_command() {
  if ! command -v "$1" &> /dev/null; then
    log_warning "$1 is not installed."
    return 1
  fi
  return 0
}

# Detect OS type
detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [ -f /etc/debian_version ]; then
      DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
      DISTRO="redhat"
    elif [ -f /etc/arch-release ]; then
      DISTRO="arch"
    else
      DISTRO="unknown"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  else
    OS="unknown"
  fi
}

# Check dependencies
log_info "Checking system dependencies..."
detect_os
missing_deps=()

# Installation dependencies
if ! check_command curl; then missing_deps+=("curl"); fi
if ! check_command file; then missing_deps+=("file"); fi

# Runtime dependencies (required for Pane to run)
if ! check_command tmux; then missing_deps+=("tmux"); fi
if ! check_command readlink; then missing_deps+=("coreutils"); fi
if ! check_command grep; then missing_deps+=("grep"); fi

# Check for Erlang runtime (required for the escript to run)
if ! command -v erl &> /dev/null; then
  log_warning "Erlang runtime not found - required to run the Pane executable"
  missing_deps+=("erlang")
fi

# Prompt for installation if dependencies are missing
if [ ${#missing_deps[@]} -gt 0 ]; then
  echo
  log_warning "The following dependencies are required but not installed:"
  for dep in "${missing_deps[@]}"; do
    echo "  - $dep"
  done
  
  echo
  echo "Would you like to install the missing dependencies?"
  echo "Type 'y' for yes or press Enter to cancel: "
  read INSTALL_DEPS
  
  if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
    log_info "Installing dependencies..."
    
    # Determine which package manager to use based on OS detection
    if [[ "$OS" == "linux" ]]; then
      if [[ "$DISTRO" == "debian" ]]; then
        $USE_SUDO apt-get update && $USE_SUDO apt-get install -y "${missing_deps[@]}"
      elif [[ "$DISTRO" == "redhat" ]]; then
        $USE_SUDO dnf install -y "${missing_deps[@]}" || $USE_SUDO yum install -y "${missing_deps[@]}"
      elif [[ "$DISTRO" == "arch" ]]; then
        $USE_SUDO pacman -S --noconfirm "${missing_deps[@]}"
      else
        log_error "Unable to determine package manager for your Linux distribution."
        log_warning "Please install these packages manually: ${missing_deps[*]}"
        exit 1
      fi
    elif [[ "$OS" == "macos" ]]; then
      if command -v brew &> /dev/null; then
        brew install "${missing_deps[@]}"
      else
        log_warning "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew install "${missing_deps[@]}"
      fi
    else
      log_error "Unsupported operating system: $OSTYPE"
      log_warning "Please install these packages manually: ${missing_deps[*]}"
      exit 1
    fi
    
    # Verify installation
    still_missing=()
    for dep in "${missing_deps[@]}"; do
      if ! command -v "$dep" &> /dev/null; then
        still_missing+=("$dep")
      fi
    done
    
    if [ ${#still_missing[@]} -gt 0 ]; then
      log_error "Failed to install some dependencies: ${still_missing[*]}"
      log_warning "Please install these packages manually and run this script again."
      exit 1
    else
      log_success "All dependencies installed successfully."
    fi
  else
    log_error "Installation aborted."
    log_warning "Please install these packages manually and run this script again: ${missing_deps[*]}"
    exit 1
  fi
fi

# Check for existing installation
check_existing_installation() {
  if [ -d "$INSTALL_DIR" ]; then
    if [ -f "$VERSION_FILE" ]; then
      INSTALLED_VERSION=$(cat "$VERSION_FILE")
      log_warning "Pane version $INSTALLED_VERSION is already installed at $INSTALL_DIR"
    else
      log_warning "Pane is already installed at $INSTALL_DIR (unknown version)"
    fi
    
    echo
    echo "Would you like to reinstall/upgrade Pane?"
    echo "Type 'y' for yes or press Enter to cancel: "
    read REINSTALL
    if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
      log_info "Installation canceled."
      exit 0
    fi
    
    log_info "Proceeding with reinstallation..."
  fi
}

# Set up permissions and sudo if needed
setup_permissions() {
  USE_SUDO=""
  
  # We need sudo if any of these directories aren't writable:
  # 1. $BIN_DIR (for creating symlinks)
  # 2. $INSTALL_DIR parent directory (for creating install directory)
  # 3. $INSTALL_DIR itself (if it exists but isn't writable)
  
  PARENT_DIR=$(dirname "$INSTALL_DIR")
  
  if [ ! -w "$BIN_DIR" ] || [ ! -w "$PARENT_DIR" ] || [ -d "$INSTALL_DIR" -a ! -w "$INSTALL_DIR" ]; then
    USE_SUDO="sudo"
    log_info "This installer needs to create/modify files in:"
    echo "  - $INSTALL_DIR (installation directory)"
    echo "  - $BIN_DIR (for executable symlinks)"
    
    # Just inform the user about sudo and continue
    echo
    echo "This requires sudo privileges. You'll be prompted for your password."
    echo "Press Enter to continue..."
    read -r
    
    log_info "You may be prompted for your password during installation."
  fi
}

# Check for existing installation
check_existing_installation

# Setup permissions
setup_permissions

# Create temporary directory for download
log_info "Preparing for installation..."
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download the latest release
log_info "Fetching the latest release information..."
RELEASE_INFO=$(curl -s -H "Accept: application/vnd.github.v3+json" "$RELEASES_URL")

# Check for GitHub API rate limiting
if echo "$RELEASE_INFO" | grep -q "API rate limit exceeded"; then
  log_error "GitHub API rate limit exceeded. Try again later or use manual installation."
  log_info "You can download the latest release directly from: $REPO_URL/releases/latest"
  exit 1
fi

# Check if the API returned an error
if echo "$RELEASE_INFO" | grep -q "\"message\""; then
  error_message=$(echo "$RELEASE_INFO" | grep -o '"message": "[^"]*' | head -n 1 | cut -d'"' -f4)
  log_error "GitHub API error: $error_message"
  log_info "You can download the latest release directly from: $REPO_URL/releases/latest"
  exit 1
fi

# Extract version
VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*' | head -n 1 | cut -d'"' -f4)
if [ -z "$VERSION" ]; then
  log_error "Could not determine the latest version"
  log_info "Please check manually at: $REPO_URL/releases/latest"
  exit 1
fi

# Skip if reinstalling the same version
if [ -f "$VERSION_FILE" ]; then
  INSTALLED_VERSION=$(cat "$VERSION_FILE")
  if [ "$INSTALLED_VERSION" = "$VERSION" ]; then
    log_warning "You already have the latest version ($VERSION) installed."
    echo
    echo "Would you like to reinstall the same version?"
    echo "Type 'y' for yes or press Enter to cancel: "
    read REINSTALL_SAME
    if [[ ! "$REINSTALL_SAME" =~ ^[Yy]$ ]]; then
      log_info "Installation canceled."
      exit 0
    fi
  fi
fi

# Construct download URL directly using the known format
DOWNLOAD_URL="${RELEASE_DOWNLOAD_URL}/${VERSION}/pane.tar.gz"

log_info "Downloading Pane $VERSION..."
echo "  From: $DOWNLOAD_URL"
echo
# Show progress bar during download
if ! curl -L --progress-bar -o pane.tar.gz "$DOWNLOAD_URL"; then
  log_error "Failed to download release package"
  log_info "You can download it manually from: $REPO_URL/releases/latest"
  exit 1
fi

# Verify the downloaded file is not empty and is a valid tarball
if [ ! -s pane.tar.gz ]; then
  log_error "Downloaded file is empty"
  exit 1
fi

if ! file pane.tar.gz | grep -q "gzip compressed data"; then
  log_error "Downloaded file is not a valid gzip archive"
  exit 1
fi

# Extract the archive
log_info "Extracting release package..."
if ! tar -xzf pane.tar.gz; then
  log_error "Failed to extract release package"
  exit 1
fi

# Create installation directories
log_info "Setting up installation directories..."
$USE_SUDO mkdir -p "$INSTALL_DIR" || {
  log_error "Failed to create installation directory: $INSTALL_DIR"
  log_info "Please ensure you have the necessary permissions or run with sudo."
  exit 1
}

# Remove old files if reinstalling
if [ -d "$INSTALL_DIR" ] && [ "$(ls -A "$INSTALL_DIR")" ]; then
  log_info "Backing up previous configuration..."
  # Backup config if needed
  if [ -d "$INSTALL_DIR/config" ]; then
    $USE_SUDO cp -R "$INSTALL_DIR/config" "${INSTALL_DIR}_config_backup"
  fi
  
  log_info "Removing previous installation..."
  $USE_SUDO rm -rf "$INSTALL_DIR"/*
  $USE_SUDO mkdir -p "$INSTALL_DIR"
fi

# Create config directory
log_info "Setting up user configuration..."
mkdir -p "$CONFIG_DIR"

# Install default configuration if it doesn't exist
DEFAULT_CONFIG="$CONFIG_DIR/default.yaml"
if [ ! -f "$DEFAULT_CONFIG" ]; then
  log_info "Installing default configuration file..."
  cp "./pane/config/default.yaml" "$DEFAULT_CONFIG"
else
  log_info "Using existing configuration at $DEFAULT_CONFIG"
fi

# Copy core files to installation directory
log_info "Installing Pane $VERSION..."
$USE_SUDO cp -R "./pane/"* "$INSTALL_DIR/"

# Save version information
echo "$VERSION" | $USE_SUDO tee "$VERSION_FILE" > /dev/null

# Set proper permissions
log_info "Setting permissions..."
$USE_SUDO chmod +x "$INSTALL_DIR/pane.sh"
$USE_SUDO chmod +x "$INSTALL_DIR/bin/pane"
$USE_SUDO chmod +x "$INSTALL_DIR/bin/uninstall"

# Create symlink
log_info "Creating system links..."
if [ -L "$BIN_DIR/$SYMLINK_NAME" ]; then
  $USE_SUDO rm "$BIN_DIR/$SYMLINK_NAME"
fi
$USE_SUDO ln -sf "$INSTALL_DIR/pane.sh" "$BIN_DIR/$SYMLINK_NAME"

# Verify installation
if command -v pane &> /dev/null; then
  log_success "Symlink created successfully at $BIN_DIR/$SYMLINK_NAME"
else
  log_warning "Symlink creation may have failed. You may need to manually add the executable to your PATH."
fi

# Verify runtime dependencies again
log_info "Verifying runtime dependencies..."
MISSING_RUNTIME=()
if ! command -v tmux &> /dev/null; then MISSING_RUNTIME+=("tmux"); fi
if ! command -v readlink &> /dev/null; then MISSING_RUNTIME+=("readlink (coreutils)"); fi
if ! command -v grep &> /dev/null; then MISSING_RUNTIME+=("grep"); fi
if ! command -v erl &> /dev/null; then MISSING_RUNTIME+=("erlang runtime"); fi

if [ ${#MISSING_RUNTIME[@]} -gt 0 ]; then
  log_warning "Some runtime dependencies are still missing:"
  for dep in "${MISSING_RUNTIME[@]}"; do
    echo "  - $dep"
  done
  echo
  log_warning "Pane may not work correctly until these are installed."
  echo "You can install them using your system's package manager."
else
  log_success "All runtime dependencies are satisfied."
fi

# Clean up temporary directory
log_info "Cleaning up..."
cd
rm -rf "$TMP_DIR"

# Restore configs if needed
if [ -d "${INSTALL_DIR}_config_backup" ]; then
  log_info "Restoring configuration files..."
  $USE_SUDO cp -R "${INSTALL_DIR}_config_backup/"* "$INSTALL_DIR/config/"
  $USE_SUDO rm -rf "${INSTALL_DIR}_config_backup"
fi

echo
echo -e "${GREEN}Installation Complete!${NC}"
echo
log_success "Pane $VERSION has been installed to $INSTALL_DIR"
echo
echo -e "${BLUE}Usage:${NC}"
echo "  • Run 'pane' to start or attach to a tmux session"
echo "  • Run 'pane --help' to see all available options"
echo
echo -e "${BLUE}Verification:${NC}"
echo "  • Run 'which pane' to verify installation path"
echo "  • Run 'pane --version' to verify installed version"
echo
echo -e "${BLUE}Uninstallation:${NC}"
echo "  • Run '/usr/local/pane/bin/uninstall' to remove Pane"
echo
log_success "Thank you for installing Pane!"