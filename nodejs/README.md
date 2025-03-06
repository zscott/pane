# Pane for Node.js

A Node.js port of the Pane tmux session manager. This version brings the same functionality as the original Elixir implementation but with improved portability across different platforms.

## Features

- Creates a tmux session with multiple windows
- Each window corresponds to a specific project directory
- Sets up a standardized dev environment with editor and shell panes
- Automatically attaches to sessions when created (or use `--no-attach`)
- Creates and manages independent tmux sessions with different configurations
- Enhanced preview mode with detailed diagnostic information
- Supports multiple pane layouts for different workflows
- Robust terminal detection for various terminal environments

## Installation

### Quick Install (Recommended)

```bash
# Install using curl
curl -sSL https://raw.githubusercontent.com/zscott/pane/main/nodejs/scripts/setup.sh | bash
```

This will:
1. Install pane to `/usr/local/pane`
2. Create a symbolic link in `/usr/local/bin/pane`
3. Add an uninstaller at `/usr/local/pane/bin/uninstall`

To uninstall:
```bash
/usr/local/pane/bin/uninstall
```

### Manual Installation

```bash
# Clone the repository
git clone <repo-url>
cd pane/nodejs

# Install dependencies
npm install

# Run setup script
./scripts/setup.sh
```

## Usage

The usage is identical to the original Elixir version:

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

## Configuration

The configuration format remains identical to the original implementation. See the main README for details.

## Development

### Prerequisites

- Node.js 18 or later
- npm
- tmux

### Running during development

```bash
# From the nodejs directory
node bin/pane.js [options]

# Or use the shell script
./bin/pane.sh [options]
```

### Testing

```bash
# Run tests
npm test
```

## License

This project is licensed under the MIT License.