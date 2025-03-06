#!/bin/bash

# Setup script for Pane

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Pane...${NC}"

# Define installation paths
INSTALL_DIR="/usr/local/pane"
INSTALL_BIN="/usr/local/bin/pane"

# Check for root/sudo access if needed
if [ ! -w "/usr/local" ]; then
  echo -e "${RED}This script requires sudo privileges to install to /usr/local${NC}"
  echo "Please run: sudo $0"
  exit 1
fi

# Create installation directory
echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/src"
mkdir -p "$INSTALL_DIR/config"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Install dependencies
if [ -f "$PROJECT_DIR/package.json" ]; then
  echo "Installing Node.js dependencies..."
  cd "$PROJECT_DIR" && npm install --production
fi

# Copy files
echo "Copying files to installation directory..."
cp -R "$PROJECT_DIR/package.json" "$INSTALL_DIR/"
cp -R "$PROJECT_DIR/node_modules" "$INSTALL_DIR/"
cp -R "$PROJECT_DIR/bin"/* "$INSTALL_DIR/bin/"
cp -R "$PROJECT_DIR/src"/* "$INSTALL_DIR/src/"
cp -R "$PROJECT_DIR/config"/* "$INSTALL_DIR/config/"

# Create uninstall script
echo "Creating uninstall script..."
cat > "$INSTALL_DIR/bin/uninstall" << 'EOF'
#!/bin/bash
# Uninstaller for Pane

echo "Uninstalling Pane..."
rm -f /usr/local/bin/pane
rm -rf /usr/local/pane

echo "Pane has been uninstalled."
EOF

chmod +x "$INSTALL_DIR/bin/uninstall"

# Create symlink to executable
echo "Creating symlink to executable..."
ln -sf "$INSTALL_DIR/bin/pane.sh" "$INSTALL_BIN"

# Create configuration directory
echo "Creating configuration directory..."
CONFIG_DIR=~/.config/pane
mkdir -p "$CONFIG_DIR"

# Copy default config if it doesn't exist yet
if [ ! -f "$CONFIG_DIR/default.yaml" ]; then
  echo "Creating default configuration..."
  cp "$INSTALL_DIR/config/default.yaml" "$CONFIG_DIR/default.yaml"
fi

echo -e "${GREEN}Pane has been installed successfully!${NC}"
echo -e "Try it out with: ${BLUE}pane --help${NC}"