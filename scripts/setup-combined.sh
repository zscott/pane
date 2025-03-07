#!/bin/bash

# Setup script for Pane (combined Node.js and Elixir versions)

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Pane (Combined Node.js and Elixir versions)...${NC}"

# Define installation paths
ELIXIR_INSTALL_DIR="/usr/local/pane"
NODE_INSTALL_DIR="/usr/local/pane-js"
INSTALL_BIN="/usr/local/bin/pane"

# Check for root/sudo access if needed
if [ ! -w "/usr/local" ]; then
  echo -e "${RED}This script requires sudo privileges to install to /usr/local${NC}"
  echo "Please run: sudo $0"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# ====== Install Elixir version ======
echo "Installing Elixir version..."

# Create installation directory for Elixir version
mkdir -p "$ELIXIR_INSTALL_DIR"
mkdir -p "$ELIXIR_INSTALL_DIR/bin"

# Build the escript
echo "Building Elixir executable..."
cd "$PROJECT_DIR" && mix deps.get && mix escript.build

# Copy files for Elixir version
echo "Copying Elixir files to installation directory..."
cp "$PROJECT_DIR/pane" "$ELIXIR_INSTALL_DIR/bin/"

# ====== Install Node.js version ======
echo "Installing Node.js version..."

# Create installation directory for Node.js version
mkdir -p "$NODE_INSTALL_DIR"
mkdir -p "$NODE_INSTALL_DIR/bin"
mkdir -p "$NODE_INSTALL_DIR/src"
mkdir -p "$NODE_INSTALL_DIR/config"

# Install dependencies for Node.js version
if [ -f "$PROJECT_DIR/nodejs/package.json" ]; then
  echo "Installing Node.js dependencies..."
  cd "$PROJECT_DIR/nodejs" && npm install --production
fi

# Copy files for Node.js version
echo "Copying Node.js files to installation directory..."
cp -R "$PROJECT_DIR/nodejs/package.json" "$NODE_INSTALL_DIR/"
cp -R "$PROJECT_DIR/nodejs/node_modules" "$NODE_INSTALL_DIR/"
cp -R "$PROJECT_DIR/nodejs/bin"/* "$NODE_INSTALL_DIR/bin/"
cp -R "$PROJECT_DIR/nodejs/src"/* "$NODE_INSTALL_DIR/src/"
cp -R "$PROJECT_DIR/nodejs/config"/* "$NODE_INSTALL_DIR/config/"

# Create wrapper script
echo "Installing wrapper script..."
mkdir -p "/usr/local/pane-wrapper"
cp "$PROJECT_DIR/scripts/wrapper.sh" "/usr/local/pane-wrapper/wrapper.sh"
cp "$PROJECT_DIR/pane" "/usr/local/pane-wrapper/pane"
chmod +x "/usr/local/pane-wrapper/wrapper.sh"
chmod +x "/usr/local/pane-wrapper/pane"

# Create uninstall script
echo "Creating uninstall script..."
cat > "/usr/local/pane-wrapper/uninstall" << 'EOF'
#!/bin/bash
# Uninstaller for Pane (combined version)

# Check for root/sudo access
if [ ! -w "/usr/local" ]; then
  echo -e "\033[0;31mThis script requires sudo privileges to uninstall from /usr/local\033[0m"
  echo "Please run: sudo $0"
  exit 1
fi

echo "Uninstalling Pane (combined version)..."
rm -f /usr/local/bin/pane
rm -rf /usr/local/pane
rm -rf /usr/local/pane-js
rm -rf /usr/local/pane-wrapper

echo "Pane has been uninstalled."
EOF

chmod +x "/usr/local/pane-wrapper/uninstall"

# Create symlink to executable
echo "Creating symlink to executable..."
ln -sf "/usr/local/pane-wrapper/pane" "$INSTALL_BIN"

# Create configuration directory
echo "Creating configuration directory..."
CONFIG_DIR=~/.config/pane
mkdir -p "$CONFIG_DIR"

# Copy default config if it doesn't exist yet
if [ ! -f "$CONFIG_DIR/default.yaml" ]; then
  echo "Creating default configuration..."
  cp "$PROJECT_DIR/config/default.yaml" "$CONFIG_DIR/default.yaml"
fi

echo -e "${GREEN}Pane has been installed successfully!${NC}"
echo -e "Try it out with: ${BLUE}pane --help${NC}"
echo -e "Use the Node.js version (default): ${BLUE}pane${NC}"
echo -e "Use the Elixir version: ${BLUE}pane --elixir${NC}"