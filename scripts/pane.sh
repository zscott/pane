#!/bin/bash
#
# pane.sh - Wrapper script for both development and production use
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

# Function to properly handle tmux attachment
tmux_attach() {
    local session_name="$1"
    if [[ -z $TMUX ]]; then
        # Not in a tmux session, attach directly
        exec tmux attach-session -t "$session_name"
    else
        # Already in a tmux session, switch client
        exec tmux switch-client -t "$session_name"
    fi
}

SCRIPT_PATH=$(get_script_path)
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Parse arguments (preserving all original args for passing to the executable)
DEBUG=0
VERBOSE=0
PREVIEW=0
ATTACH=1  # Default to always attach if session exists

# Process command line arguments (without shifting, so we can pass all args)
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG=1
            ;;
        --verbose|-v)
            VERBOSE=1
            ;;
        --preview|-p)
            PREVIEW=1
            ;;
        --no-attach)
            ATTACH=0
            ;;
    esac
done

# Print debug info if requested
if [ $DEBUG -eq 1 ]; then
    echo "Debug: Script path: $SCRIPT_PATH"
    echo "Debug: Script dir: $SCRIPT_DIR"
fi

# Check if we're in development or production mode
if [ -f "$SCRIPT_DIR/../mix.exs" ]; then
    # DEVELOPMENT MODE
    if [ $DEBUG -eq 1 ]; then
        echo "Debug: Development mode detected"
    fi
    
    # Change to project root directory
    cd "$SCRIPT_DIR/.."
    
    if [ $PREVIEW -eq 1 ]; then
        # Preview mode (development)
        if [ $DEBUG -eq 1 ]; then
            echo "Debug: Running preview with mix"
        fi
        
        # Use mix to run preview mode, passing all command-line arguments to CLI
        # Set application environment variables based on command line flags
        ELIXIR_CODE="Application.put_env(:pane, :preview_mode, true); "
        
        if [ $VERBOSE -eq 1 ]; then
            ELIXIR_CODE="${ELIXIR_CODE}Application.put_env(:pane, :verbose, true); "
            echo "Running preview with verbose output (development)"
        else
            echo "Running in preview mode (development)"
        fi
        
        # Pass the no_attach flag to the Elixir app
        if [ $ATTACH -eq 0 ]; then
            ELIXIR_CODE="${ELIXIR_CODE}Application.put_env(:pane, :no_attach, true); "
        fi
        
        # Execute with the appropriate environment settings
        ELIXIR_CODE="${ELIXIR_CODE}Pane.CLI.main(System.argv())"
        exec mix run -e "$ELIXIR_CODE" -- "$@"
    else
        # Normal execution mode (development)
        if [ $DEBUG -eq 1 ]; then
            echo "Debug: Running with mix"
        fi
        
        # If we should attach to existing sessions
        if [ $ATTACH -eq 1 ]; then
            # Get session name from config (default to "default" if not found)
            SESSION_NAME=$(mix run -e "config = Pane.Config.load_config(); IO.puts(config.session)" 2>/dev/null || echo "default")
            
            # Check if the session already exists
            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                if [ $DEBUG -eq 1 ]; then
                    echo "Debug: Session '$SESSION_NAME' already exists, attaching"
                fi
                tmux_attach "$SESSION_NAME"
            fi
        fi
        
        # Create the session through mix and attach after
        if [ $VERBOSE -eq 1 ]; then
            mix run -e "Application.put_env(:pane, :verbose, true); Pane.CLI.main(System.argv())" -- "$@"
        else
            mix run -e "Pane.CLI.main(System.argv())" -- "$@"
        fi
        
        # Extract session name from the processed config
        SESSION_NAME=$(mix run -e "config = Pane.Config.load_config(); IO.puts(config.session)" 2>/dev/null || echo "default")
        
        # Attach to the session if it exists and we should attach
        if [ $ATTACH -eq 1 ] && tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            if [ $DEBUG -eq 1 ]; then
                echo "Debug: Attaching to session '$SESSION_NAME'"
            fi
            tmux_attach "$SESSION_NAME"
        fi
    fi
else
    # PRODUCTION MODE
    if [ $DEBUG -eq 1 ]; then
        echo "Debug: Production mode detected"
    fi
    
    # In production, the executable should be in the bin directory
    PANE_EXECUTABLE="$SCRIPT_DIR/bin/pane"
    
    if [ ! -f "$PANE_EXECUTABLE" ]; then
        echo "Error: Could not find pane executable at $PANE_EXECUTABLE"
        exit 1
    fi
    
    # Verify the executable is a proper escript
    if ! head -n 1 "$PANE_EXECUTABLE" | grep -q "escript"; then
        echo "Error: The pane executable appears to be corrupted"
        echo "Please reinstall: sudo /usr/local/pane/bin/uninstall && sudo ./setup.sh"
        exit 1
    fi
    
    if [ $PREVIEW -eq 1 ]; then
        # Preview mode (production)
        if [ $DEBUG -eq 1 ]; then
            echo "Debug: Running preview with escript"
        fi
        
        if [ $VERBOSE -eq 1 ]; then
            echo "Running preview with verbose output (production)"
            exec "$PANE_EXECUTABLE" --preview --verbose "$@"
        else
            echo "Running in preview mode (production)"
            exec "$PANE_EXECUTABLE" --preview "$@"
        fi
    else
        # Normal execution mode (production)
        
        # If we should attach to existing sessions, check if it exists first
        if [ $ATTACH -eq 1 ]; then
            # First, get session name from config
            SESSION_NAME=$("$PANE_EXECUTABLE" --print-session 2>/dev/null || echo "default")
            
            # Check if the session already exists
            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                if [ $DEBUG -eq 1 ]; then
                    echo "Debug: Session '$SESSION_NAME' already exists, attaching"
                fi
                tmux_attach "$SESSION_NAME"
            fi
        fi
        
        # Create the session
        if [ $DEBUG -eq 1 ]; then
            echo "Debug: Running escript executable"
        fi
        
        # Run the executable to create session
        if [ $VERBOSE -eq 1 ]; then
            "$PANE_EXECUTABLE" --verbose "$@"
        else
            "$PANE_EXECUTABLE" "$@"
        fi
        
        # Get session name for attaching
        SESSION_NAME=$("$PANE_EXECUTABLE" --print-session 2>/dev/null || echo "default")
        
        # Attach to the session if it exists and we should attach
        if [ $ATTACH -eq 1 ] && tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            if [ $DEBUG -eq 1 ]; then
                echo "Debug: Attaching to session '$SESSION_NAME'"
            fi
            tmux_attach "$SESSION_NAME"
        fi
    fi
fi
