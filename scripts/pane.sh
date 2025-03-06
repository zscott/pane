#!/bin/bash
#
# pane.sh - Wrapper script for both development and production use
#

# Script now delegates to the wrapper.sh script which handles implementation selection.
# The wrapper selects between Node.js (default) and Elixir implementations.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the wrapper script with all arguments
exec "$PROJECT_DIR/scripts/wrapper.sh" "$@"
