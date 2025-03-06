# Pane

A simple tmux session manager available in both Elixir and Node.js implementations. Pane creates a consistent development environment across multiple project directories.

## Features

- Creates a tmux session with multiple windows
- Each window corresponds to a specific project directory
- Sets up a standardized dev environment with editor and shell panes
- Automatically attaches to sessions when created (or use `--no-attach`)
- Creates and manages independent tmux sessions with different configurations
- Enhanced preview mode with detailed diagnostic information
- Supports multiple pane layouts for different workflows
- Robust terminal detection for various terminal environments
- Available in both Elixir and Node.js implementations

## Architecture

Pane is built around these main modules:

- **Pane.CLI**: Command-line interface and entry point
- **Pane.Config**: Configuration file handling and processing
- **Pane.Layout**: Window layout management with customizable templates
- **Pane.Tmux**: Low-level tmux command integration
  - **Pane.Tmux.Session**: Session management
  - **Pane.Tmux.Window**: Window creation and management
  - **Pane.Tmux.Pane**: Individual pane operations
  - **Pane.Tmux.Layout**: Layout application
- **Pane.Layout.Templates**: Predefined layout configurations
  - **Single**: A single fullscreen pane
  - **SplitVertical**: Two equal vertical panes
  - **TopSplitBottom**: Large top pane (60%) with two equal bottom panes (40%)
  - **Quad**: Four equal panes arranged in a 2x2 grid

## Installation

### Quick Install (Recommended)

```bash
# Install both implementations using curl (requires sudo privileges)
curl -sSL https://raw.githubusercontent.com/zscott/pane/main/scripts/setup-combined.sh | sudo bash
```

This will:
1. Install the Elixir version to `/usr/local/pane`
2. Install the Node.js version to `/usr/local/pane-js`
3. Install the wrapper to `/usr/local/pane-wrapper`
4. Create a symbolic link in `/usr/local/bin/pane`
5. Add an uninstaller at `/usr/local/pane-wrapper/uninstall`

To uninstall:
```bash
sudo /usr/local/pane-wrapper/uninstall
```

### Manual Installation

```bash
# Clone the repository
git clone <repo-url>
cd pane

# For Elixir version:
mix deps.get
mix escript.build

# For Node.js version:
cd nodejs
npm install

# Run the combined setup script (requires sudo privileges)
cd ..
sudo ./scripts/setup-combined.sh
```

### Choosing the Implementation

By default, Pane uses the Node.js implementation. To use the Elixir implementation:

```bash
# Use the default Node.js implementation
pane

# Use the Elixir implementation
pane --elixir
```

Each implementation will display which version is being used when executed.

## Project Structure

```
pane/
├── config/        # Configuration files
│   └── default.yaml # Default YAML configuration
├── lib/           # Elixir source code
├── scripts/       # Shell scripts and executables
│   ├── pane.exs   # Elixir script implementation
│   ├── pane.sh    # Shell wrapper for terminal usage
│   ├── setup.sh   # Installation script
│   └── uninstall.sh # Uninstallation script
├── pane.sh        # Symlink to scripts/pane.sh
└── setup.sh       # Symlink to scripts/setup.sh
```

## Usage

### Basic Usage

```bash
# Start or attach to the default tmux session
pane

# Use a specific configuration
pane -c myconfig

# Preview the commands that would be executed without running them
pane --preview

# Show detailed logs during execution
pane --verbose
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-p, --preview` | Show diagnostic info and commands without executing them |
| `-c, --config=CONFIG` | Use specific config file (e.g., `-c myproject`) |
| `-v, --verbose` | Show detailed information during execution |
| `-a, --attach` | Directly attach to an existing session |
| `--no-attach` | Create the session without automatically attaching to it |
| `--print-session` | Print the session name from the config and exit |
| `-h, --help` | Show help information |

### Usage Examples

```bash
# Start/attach to the default tmux session
pane

# Use a specific configuration
pane -c myproject

# Preview with diagnostic information (useful for troubleshooting)
pane -p -v -c myproject

# Create session but don't attach
pane --no-attach

# Create one session and then another independent session
pane -c config1 --no-attach
pane -c config2 --no-attach

# Directly attach to an existing session
pane -a -c myproject

# Display help information
pane --help
```

### Development Usage

When developing Pane, you can run it without installing:

```bash
# From the project root directory
./pane.sh

# Build the executable
mix escript.build
./pane
```

## Configuration

Pane uses YAML configuration files to define your tmux session setup. The configuration is loaded from these locations in order:

1. The file specified with `--config=FILE`
2. `~/.config/pane/default.yaml`
3. The built-in default configuration

### Configuration Format

Here's an example configuration file:

```yaml
# Session name
session: "my-project"

# Root directory for all project paths
root: "~/projects/my-project/"

# Default layout to use for windows (if not specified per window)
default_layout: "dev"

# Available layouts (can be referenced by name in windows)
layouts:
  # Simple single pane layout
  single: 
    template: "single"
  
  # Developer layout with editor on top, two shell panes below
  dev:
    template: "TopSplitBottom"
    commands:
      - "cd $DIR && nvim"
      - "zsh"
      - "zsh"

  # Layout for AI coding with editor on left, AI on right
  aiCoding:
    template: "SplitVertical"
    commands:
      - "cd $DIR && nvim"
      - "cd $DIR && claude code"

# Windows to create in the tmux session
windows:
  # Simple window with just a path
  - path: frontend
  
  # Window with custom label and specific layout
  - path: backend/api
    label: api
    layout: aiCoding
  
  # Window with a command to run after creation
  - path: scripts
    command: "ls -la"
```

### Configuration Options

| Option | Description |
|--------|-------------|
| `session` | Name of the tmux session |
| `root` | Base directory for all window paths |
| `default_layout` | Default layout to use for windows (if not specified per window) |
| `layouts` | Map of named layouts that can be referenced in windows |
| `layouts[name].template` | Layout template to use (e.g., "single", "TopSplitBottom", "SplitVertical") |
| `layouts[name].commands` | Commands to run in each pane of the layout |
| `layouts[name].shell` | Optional shell to use for panes (defaults to system shell) |
| `windows` | List of windows to create |
| `windows[].path` | Path relative to root |
| `windows[].label` | Optional window name (defaults to last part of path) |
| `windows[].layout` | Optional layout name to use for this window |
| `windows[].command` | Optional command to run in the window |

### Layout Templates

Pane comes with several built-in layout templates:

#### Single (single)
A layout with a single fullscreen pane.

Pane names:
- main

#### Split Vertical (SplitVertical)
A layout with two equal vertical panes.

Pane names:
- left
- right

#### Top Split Bottom (TopSplitBottom) 
A layout with a large top pane (60%) and two equal bottom panes (40% total).

Pane names:
- top
- bottomLeft
- bottomRight

#### Quad (Quad)
A layout with four equal panes arranged in a 2x2 grid.

Pane names:
- topLeft
- topRight
- bottomLeft
- bottomRight

### Advanced Configuration Example

```yaml
# Layout configurations using predefined templates
layouts:
  dev:
    template: "TopSplitBottom"
    shell: "zsh"
    commands:
      - "cd $DIR && nvim"      # top pane
      - "zsh"                  # bottomLeft pane
      - "zsh"                  # bottomRight pane
  
  aiCoding:
    template: "SplitVertical"
    commands:
      - "cd $DIR && nvim"      # left pane
      - "cd $DIR && claude code" # right pane
  
  single:
    template: "Single"
    commands:
      - "{command}"            # Uses the window's command
      
  quadDev:
    template: "Quad"
    commands:
      - "cd $DIR && nvim"      # topLeft pane
      - "cd $DIR && npm test"  # topRight pane
      - "cd $DIR && npm run build" # bottomLeft pane
      - "cd $DIR && git status" # bottomRight pane
```

## Development

### Prerequisites

- Elixir 1.17 or later
- Tmux

### Testing

```bash
# Run the standard test suite
mix test

# Run the functionality test script (tests command-line options)
./test/scripts/test_pane.sh

# Test terminal detection
./test/scripts/detect_terminal.sh --verbose

# Run YAML parsing tests
mix run test/test_yaml_parsing.exs
```

### Building

```bash
# Complete build process
mix clean
mix deps.get
mix compile
mix escript.build
```

### Troubleshooting

If you encounter issues with Pane, refer to the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) file for common problems and solutions. Common issues addressed include:

- Terminal compatibility issues
- Auto-attachment not working in certain environments
- Creating multiple independent sessions
- Debugging with preview mode

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Additional Documentation

- [TMUX.md](TMUX.md) - Comprehensive reference of tmux commands and options
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Solutions for common issues
- [PANE.md](PANE.md) - Detailed documentation for Pane's features and design
- [AUTO-ATTACH.md](AUTO-ATTACH.md) - Technical details on the auto-attach functionality

