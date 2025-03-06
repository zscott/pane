#!/bin/bash
#
# wrapper.sh - Main script to select between Node.js and Elixir implementations
#

# Get the real script directory (resolving symlinks)
get_script_path() {
    local source="${BASH_SOURCE[0]}"
    # Resolve $source until the file is no longer a symlink
    while [ -L "$source" ]; do
        local dir="$( cd -P "$( dirname "$source" )" && pwd )"
        source="$(readlink "$source")"
        # If $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$source"
}

SCRIPT_PATH=$(get_script_path)
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
PROJECT_DIR=$(dirname "$SCRIPT_DIR")

# Default to Node.js implementation unless --elixir flag is specified
USE_ELIXIR=0
NEW_ARGS=()

# Process command line arguments to look for --elixir flag
for arg in "$@"; do
    if [ "$arg" == "--elixir" ]; then
        USE_ELIXIR=1
    else
        NEW_ARGS+=("$arg")
    fi
done

# Check if we're in development or production mode
IN_DEVELOPMENT=0
if [ -f "$PROJECT_DIR/mix.exs" ]; then
    IN_DEVELOPMENT=1
fi

if [ $USE_ELIXIR -eq 1 ]; then
    # Use the Elixir implementation
    echo "[pane] Using Elixir implementation"
    
    if [ $IN_DEVELOPMENT -eq 1 ]; then
        # In development, use the original pane.sh script
        "$PROJECT_DIR/pane.sh" "${NEW_ARGS[@]}"
    else
        # In production, use the installed Elixir binary
        # Assuming it's installed in a standard location
        "/usr/local/pane/bin/pane" "${NEW_ARGS[@]}"
    fi
else
    # Use the Node.js implementation
    echo "[pane] Using Node.js implementation"
    
    NODE_SCRIPT="$PROJECT_DIR/nodejs/bin/pane.js"
    
    if [ $IN_DEVELOPMENT -eq 1 ]; then
        # In development, run the JS script directly
        node "$NODE_SCRIPT" "${NEW_ARGS[@]}"
    else
        # In production, use the installed Node.js binary
        # Assuming it's installed to a standard location
        "/usr/local/pane-js/bin/pane" "${NEW_ARGS[@]}"
    fi
fi