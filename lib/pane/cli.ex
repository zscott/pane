defmodule Pane.CLI do
  @moduledoc """
  Command-line interface for Pane.
  """
  
  @doc """
  Determines if the no-attach mode was requested based on command-line options.
  
  Returns true if either:
  - no_attach: true was specified, or
  - attach: false was specified
  
  This handles the two ways a user can request not to attach to the session.
  """
  @spec no_attach_requested?(Keyword.t()) :: boolean()
  def no_attach_requested?(opts) do
    (opts[:no_attach] == true) or (opts[:attach] == false)
  end

  def parse_args(args) do
    # Parse options with strict validation
    {opts, invalid, unknown} =
      OptionParser.parse(args,
        strict: [
          preview: :boolean,
          help: :boolean,
          attach: :boolean,
          config: :string,
          verbose: :boolean,
          print_session: :boolean,
          no_attach: :boolean,
          elixir: :boolean,
          auto_save: :boolean,
          auto_save_interval: :string,
          restore: :boolean,
          restore_file: :string,
          list_sessions: :boolean
        ],
        aliases: [
          p: :preview,
          h: :help,
          a: :attach,
          c: :config,
          v: :verbose,
          r: :restore
        ]
      )
      
    # Handle restore parameter with value
    opts = case Enum.find(args, fn arg -> String.starts_with?(arg, "--restore=") end) do
      nil -> opts
      restore_arg ->
        session_name = String.replace(restore_arg, "--restore=", "")
        Keyword.put(opts, :restore, session_name)
    end
    
    {opts, invalid, unknown}
  end

  def main(args) do
    # Print a small indicator this is the Elixir version
    IO.puts("[pane] Elixir implementation")
    
    # Parse arguments
    {opts, invalid, unknown} = parse_args(args)
    
    # Set global flags
    if opts[:verbose] do
      Application.put_env(:pane, :verbose, true)
    end
    
    # Store the no_attach flag in the application environment for preview mode
    Application.put_env(:pane, :no_attach, !!opts[:no_attach])
    
    # Validate arguments and show help for errors
    cond do
      opts[:help] ->
        show_help()
        :ok
      
      opts[:print_session] ->
        config = Pane.Config.load_config(opts[:config])
        IO.puts(config.session)
        :ok
      
      invalid != [] ->
        IO.puts("Error: Invalid option format: #{inspect invalid}")
        show_help()
        System.halt(1)
      
      unknown != [] ->
        IO.puts("Error: Unknown options: #{inspect unknown}")
        show_help()
        System.halt(1)
      
      true ->
        process(opts)
    end
  end

  def process(opts) do
    # Get config file name from command line options
    config_path = opts[:config]

    cond do
      opts[:list_sessions] ->
        # List available sessions
        IO.puts("Available sessions:")
        Pane.Restore.list_available_sessions()
        |> Enum.each(fn session -> IO.puts("  #{session}") end)
        :ok
        
      opts[:restore_file] ->
        # Restore session from file
        file_path = opts[:restore_file]
        
        case Pane.Restore.restore_file(file_path) do
          {:ok, session, _commands} ->
            IO.puts("Restoring session from file: #{file_path}")
            Pane.Restore.restore_session(session)
            
          {:error, reason} ->
            IO.puts("Error: Could not restore session: #{inspect(reason)}")
            System.halt(1)
        end
        
      opts[:restore] ->
        # Get session name for restore
        session_name = if is_binary(opts[:restore]), do: opts[:restore], else: nil
        
        # If no session name provided, get from config
        session_name = if is_nil(session_name) do
          case Pane.Config.load_config(config_path) do
            {:error, _reason} -> nil
            config -> config.session
          end
        else
          session_name
        end
        
        # Restore the session
        if is_nil(session_name) do
          IO.puts("Error: No session name provided for restore. Use --restore=SESSION_NAME or a valid config.")
          System.halt(1)
        else
          case Pane.Restore.restore_latest(session_name) do
            {:ok, session, _commands} ->
              if opts[:preview] do
                IO.puts("Preview mode: Would restore session #{session_name}")
                commands = Pane.Restore.generate_restore_commands(session)
                IO.puts("\nCommands that would be executed:")
                Enum.each(commands, fn cmd -> IO.puts("  #{cmd}") end)
              else
                IO.puts("Restoring session: #{session_name}")
                Pane.Restore.restore_session(session)
              end
              
            {:error, reason} ->
              IO.puts("Error: Could not restore session: #{inspect(reason)}")
              System.halt(1)
          end
        end
        
      true ->
        # Normal session creation/management
        case Pane.Config.load_config(config_path) do
          {:error, reason} ->
            IO.puts("Error: Could not load configuration: #{inspect(reason)}")
            System.halt(1)
    
          config ->
            # config_path is already stored in the config object by load_config
            
            cond do
              opts[:preview] ->
                # Set preview mode for debug output
                Application.put_env(:pane, :preview_mode, true)
                
                # Check for no-attach flag
                if no_attach_requested?(opts) do
                  Application.put_env(:pane, :no_attach, true)
                end
                
                # Check for auto-save flag
                if opts[:auto_save] do
                  interval = if opts[:auto_save_interval], do: String.to_integer(opts[:auto_save_interval]), else: 5
                  IO.puts("Auto-save enabled with #{interval} minute interval")
                end
                
                Pane.Command.preview(config)
    
              opts[:attach] ->
                # Direct attach mode - execute the attach command directly
                session_name = config.session
                
                # We still log interactive terminal detection for debugging purposes
                is_interactive = Pane.is_interactive_terminal?()
                
                # Log detection result if in verbose mode
                if Application.get_env(:pane, :verbose, false) do
                  IO.puts("[INFO] Interactive terminal detection: #{is_interactive}")
                  IO.puts("[INFO] Attempting direct attachment")
                end
                
                # Tell the user what's happening
                IO.puts("\nAttaching to tmux session '#{session_name}'...")
                
                # Prepare the terminal
                IO.write("")
                
                # Use a direct exec approach for attaching to tmux
                exec_cmd = "exec tmux attach-session -t \"#{session_name}\""
                
                # Create a temporary execution script
                temp_script = """
                #!/bin/sh
                # Automatically generated script for tmux attachment
                #{exec_cmd}
                """
                script_path = Path.join(System.tmp_dir(), "pane_attach_#{:os.system_time(:millisecond)}.sh")
                
                # Write and execute the script
                File.write!(script_path, temp_script)
                File.chmod!(script_path, 0o755)
                
                # Execute the script as a process replacement
                Port.open({:spawn_executable, script_path}, [:nouse_stdio])
                :timer.sleep(100) # Small delay to ensure process starts
                
                # In case the exec doesn't work (should be rare), exit gracefully
                System.halt(0)
    
              true ->
                # Run in normal mode without preview
                Application.put_env(:pane, :preview_mode, false)
                
                # Only auto-attach if --no-attach isn't specified
                auto_attach = not no_attach_requested?(opts)
                
                # Log the auto-attach setting in verbose mode
                if Application.get_env(:pane, :verbose, false) do
                  IO.puts("[INFO] Auto-attach enabled: #{auto_attach}")
                end
                
                # Check for auto-save flag
                if opts[:auto_save] do
                  # Set up auto-save
                  interval = if opts[:auto_save_interval], do: String.to_integer(opts[:auto_save_interval]), else: 5
                  
                  # Log auto-save setting
                  IO.puts("[INFO] Auto-save enabled with #{interval} minute interval")
                  
                  # Create initial auto-save
                  case Pane.AutoSave.auto_save(config) do
                    {:ok, save_file} ->
                      if Application.get_env(:pane, :verbose, false) do
                        IO.puts("[INFO] Created initial auto-save: #{save_file}")
                      end
                      
                    {:error, reason} ->
                      IO.puts("[WARNING] Failed to create initial auto-save: #{inspect(reason)}")
                  end
                  
                  # Set up auto-save hook in tmux session
                  session_name = config.session
                  auto_save_cmd = "tmux set-hook -t #{session_name} 'after-resize-pane' 'run-shell \"#{auto_save_hook_script(config, interval)}\"'"
                  
                  # Execute the hook setup command
                  System.cmd("sh", ["-c", auto_save_cmd], stderr_to_stdout: true)
                end
                
                Pane.run(config, auto_attach)
            end
        end
    end
  end
  
  # Create a script for the auto-save hook
  defp auto_save_hook_script(config, interval) do
    # Script to run auto-save only after interval minutes
    """
    #!/bin/sh
    last_save_file="/tmp/pane_last_save_#{config.session}"
    now=$(date +%s)
    
    if [ -f "$last_save_file" ]; then
      last_save=$(cat "$last_save_file")
      elapsed=$((now - last_save))
      min_interval=$((#{interval} * 60))
      
      if [ $elapsed -ge $min_interval ]; then
        # Time to save again
        echo $now > "$last_save_file"
        #{elixir_script_path()} auto-save "#{config.session}"
      fi
    else
      # First save
      echo $now > "$last_save_file"
      #{elixir_script_path()} auto-save "#{config.session}"
    fi
    """
  end
  
  # Get path to the Elixir script for background auto-save
  defp elixir_script_path do
    # Path to script in the installation directory
    Path.join(System.fetch_env!("PWD"), "scripts/auto_save.exs")
  end
  
  defp show_help do
    IO.puts("""
    Pane - A tmux session manager

    Usage:
      pane [options]

    Options:
      -p, --preview               Show commands without executing them
      -a, --attach                Directly attach to the session (run this from terminal)
      -c, --config=CONFIG         Use specific config name (e.g. -c myproject) or file (e.g. -c path/to/config.yaml)
      -v, --verbose               Show detailed information during execution
      --no-attach                 Create the session but don't automatically attach to it
      --print-session             Print the session name from the config and exit
      --elixir                    Use the Elixir implementation instead of Node.js (default)
      --auto-save                 Enable automatic session saving
      --auto-save-interval=MINS   Set auto-save interval in minutes (default: 5)
      -r, --restore[=SESSION]     Restore the most recent session (optionally for a specific session name)
      --restore-file=FILE         Restore a session from a specific session file
      --list-sessions             List all available auto-saved sessions
      -h, --help                  Show this help message

    Configuration:
      Configs are looked for in the following locations:
        1. As specified (if absolute path)
        2. ~/.config/pane/
        3. The project's config/ directory
      
      Default config (when no -c option) is loaded from:
        1. ~/.config/pane/default.yaml
        2. The project's config/default.yaml file

    Auto-Save:
      Auto-saved sessions are stored in ~/.local/share/pane/sessions/
      Each session is saved with a timestamp and can be restored later.

    Examples:
      pane                         Create tmux session using default config and attach to it
      pane -c myproject            Use myproject.yaml config from standard locations
      pane --no-attach             Create session without attaching
      pane --preview               Preview the commands that would be executed
      pane --verbose               Show detailed logging during execution
      pane -v -p                   Preview with verbose output
      pane --config=my.yaml        Use custom configuration file
      pane --elixir                Use the Elixir implementation instead of Node.js
      pane --auto-save             Create session with auto-save enabled
      pane --restore               Restore the most recent auto-saved session
      pane --restore=my-session    Restore the most recent auto-saved session with name "my-session"
      pane --list-sessions         Show all available auto-saved sessions
    """)
  end
end