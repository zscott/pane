defmodule Pane.Command do
  @moduledoc """
  Command generator for tmux operations.
  """
  alias Pane.Tmux
  
  @doc """
  Extract window options for layout from a window configuration.
  
  Returns a map with the command if present, or an empty map otherwise.
  """
  @spec get_window_opts(map()) :: map()
  def get_window_opts(window) do
    if Map.has_key?(window, :command) do
      %{command: window.command}
    else
      %{}
    end
  end

  @doc """
  Generate all tmux commands needed for the session, but only print them.
  Shows enhanced diagnostic information in the preview mode.
  """
  def preview(config) do
    # Get real command list
    real_commands = generate_commands(config)
    
    # Extract session name for further use (used in messages)
    _session_name = config.session
    
    # Check if we're running in a terminal (but don't execute any commands)
    # Run the terminal detection tests directly
    terminal_detection_output = """
    # is_tty_0?
    test -t 0
    # result: #{if System.cmd("test", ["-t", "0"], stderr_to_stdout: true) |> elem(1) == 0, do: "0 (0=true, 1=false)", else: "1 (0=true, 1=false)"}

    # has_tty_device?
    tty | grep -v "not a tty" > /dev/null
    # result: #{if System.cmd("sh", ["-c", "tty | grep -v 'not a tty' > /dev/null"], stderr_to_stdout: true) |> elem(1) == 0, do: "0 (0=true, 1=false)", else: "1 (0=true, 1=false)"}

    # is_stdin_char_device?
    test -c /dev/stdin
    # result: #{if System.cmd("test", ["-c", "/dev/stdin"], stderr_to_stdout: true) |> elem(1) == 0, do: "0 (0=true, 1=false)", else: "1 (0=true, 1=false)"}

    # has_term_env?
    [ -n "$TERM" ]
    # result: #{if System.get_env("TERM") && System.get_env("TERM") != "", do: "0 (0=true, 1=false)", else: "1 (0=true, 1=false)"}
    """
    
    # Determine if terminal is interactive based on the tests
    is_terminal_interactive = Pane.is_interactive_terminal?()
    
    # Check if --no-attach flag was specified (ensure it's a boolean)
    no_attach_specified = !!Application.get_env(:pane, :no_attach, false)
    
    # Determine if auto-attach would be attempted
    would_auto_attach = !no_attach_specified && is_terminal_interactive
    
    # Check if session exists using first command and run it
    session_check_cmd = List.first(real_commands)
    
    # Actually check if the session exists
    session_exists? =
      case System.cmd("sh", ["-c", session_check_cmd], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end
      
    # Configuration section
    IO.puts("\n# Configuration")
    IO.puts("# -------------")
    IO.puts("# Session: #{config.session}")
    IO.puts("# Config file: #{config.config_path}")
    IO.puts("#   root: #{config.root}")
    window_names = Enum.map(config.windows, fn window -> 
      window[:label] || Path.basename(window[:path] || "command")
    end)
    IO.puts("#   windows: [#{Enum.join(window_names, ", ")}]")
    
    # Terminal detection section
    IO.puts("\n\n# Terminal detection")
    IO.puts("# ------------------")
    IO.puts(terminal_detection_output)
    
    # Flag processing section
    IO.puts("\n# Flag processing")
    IO.puts("# --------------")
    IO.puts("# --no-attach specified?: #{no_attach_specified}")
    IO.puts("# can_auto_attach?: #{is_terminal_interactive}")
    IO.puts("# auto_attach_enabled?: #{would_auto_attach}")
    
    # Session detection section
    IO.puts("\n\n# Session detection")
    IO.puts("# -----------------")
    IO.puts("# check for running session")
    IO.puts("#{session_check_cmd}")
    IO.puts("# session_running?: #{session_exists?}")
    
    # TMux commands section
    IO.puts("\n\n# TMux commands that would be executed")
    existing_msg = if session_exists?, do: "# Session already exists, only missing windows will be created", else: "# Creating new session"
    IO.puts("# -----------------------------------")
    IO.puts(existing_msg)
    # Skip the session check command (already shown) and attach command (shown separately)
    Enum.slice(real_commands, 1, length(real_commands) - 2)
    |> Enum.each(fn cmd -> IO.puts(cmd) end)
    
    # Auto attach section
    attach_cmd = List.last(real_commands)
    IO.puts("\n# Auto attach command")
    IO.puts("# -----------------")
    if would_auto_attach do
      IO.puts("#{attach_cmd}")
    else
      IO.puts("# Would not auto-attach (--no-attach specified or not in an interactive terminal)")
      IO.puts("# To manually attach, you would run:")
      IO.puts("#{attach_cmd}")
    end
  end

  @doc """
  Generate all tmux commands for the given configuration.
  """
  def generate_commands(config) do
    %{session: session, root: root, windows: windows, layouts: _layouts} = config

    # Check if session exists command
    session_check = Tmux.session_exists?(session)

    # Generate window creation commands
    window_commands =
      windows
      |> Enum.with_index()
      |> Enum.flat_map(fn {window, index} ->
        # Determine if this is a path-based or command-only window
        {full_path, window_label} =
          if Map.has_key?(window, :path) && window.path do
            path = Path.expand(Path.join(root, window.path))
            {path, get_window_label(window)}
          else
            # For command-only windows, use root dir and derive label from command
            label =
              window[:label] || (window[:command] && String.split(window.command) |> List.first()) ||
                "cmd"

            {Path.expand(root), label}
          end

        # Get layout name for this window
        layout_name = window[:layout] || config[:defaultLayout] || "dev"

        # Log window creation if verbose mode
        if Application.get_env(:pane, :verbose, false) do
          window_type = if index == 0, do: "first window", else: "window"
          IO.puts("[INFO] Creating #{window_type}: #{window_label} (layout: #{layout_name})")
        end

        # Get the layout configuration
        layout_config = Pane.Layout.get_layout_config(config, layout_name)

        if index == 0 do
          # First window - create session with a window
          # Add -A flag to attach-or-create in a single command
          session_cmd =
            Tmux.new_session(session,
              cwd: full_path,
              window_name: window_label,
              create_or_attach: true
            )

          # Apply layout to the first window
          window_target = "#{session}:0"

          # Get window options for layout
          window_opts = get_window_opts(window)

          # Use the layout system for all layouts
          layout_cmds = Pane.Layout.apply_layout(window_target, full_path, layout_config, window_opts)

          [session_cmd] ++ layout_cmds
        else
          # Other windows - create a new window using index
          window_cmd =
            Tmux.new_window(window_label,
              target_session: session,
              cwd: full_path,
              window_index: index
            )

          # Apply layout to this window
          window_target = "#{session}:#{index}"

          # Get window options for layout
          window_opts = get_window_opts(window)

          # Use the layout system for all layouts
          layout_cmds = Pane.Layout.apply_layout(window_target, full_path, layout_config, window_opts)

          [window_cmd] ++ layout_cmds
        end
      end)

    # Select first window and attach
    final_commands = [
      Tmux.select_window("#{session}:0"),
      Tmux.attach_session(target: session)
    ]

    # Full command set
    [session_check] ++ window_commands ++ final_commands
  end

  @doc """
  Process a template command for command-only windows.

  This sends the command to the first pane (index 0) of the window.
  All templates use the same approach for command-only windows.
  """
  def process_template_command(command, _layout_config, window_target) do
    # For all layouts, send the command to the first pane (index 0)
    Tmux.send_keys(command, target: "#{window_target}.0")
  end

  @doc """
  Get the window label, either from the config or derived from the path.
  """
  def get_window_label(window) do
    cond do
      window[:label] ->
        window.label

      window[:path] ->
        # Use the last part of the path as the label
        window.path |> String.split("/") |> List.last()

      window[:command] ->
        # Use the first word of the command as the label
        window.command |> String.split() |> List.first()

      true ->
        "window"
    end
  end
end