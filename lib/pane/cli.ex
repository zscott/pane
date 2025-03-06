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

  def main(args) do
    # Print a small indicator this is the Elixir version
    IO.puts("[pane] Elixir implementation")
    
    # Fall back to native OptionParser for robustness with strict validation
    {opts, invalid, unknown} =
      OptionParser.parse(args,
        strict: [
          preview: :boolean,
          help: :boolean,
          attach: :boolean,
          config: :string,
          verbose: :boolean,
          print_session: :boolean,
          no_attach: :boolean
        ],
        aliases: [
          p: :preview,
          h: :help,
          a: :attach,
          c: :config,
          v: :verbose
        ]
      )
    
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

  defp process(opts) do
    # Get config file name from command line options
    config_path = opts[:config]

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
            
            Pane.run(config, auto_attach)
        end
    end
  end
  
  defp show_help do
    IO.puts("""
    Pane - A tmux session manager

    Usage:
      pane [options]

    Options:
      -p, --preview          Show commands without executing them
      -a, --attach           Directly attach to the session (run this from terminal)
      -c, --config=CONFIG    Use specific config name (e.g. -c myproject) or file (e.g. -c path/to/config.yaml)
      -v, --verbose          Show detailed information during execution
      --no-attach            Create the session but don't automatically attach to it
      --print-session        Print the session name from the config and exit
      -h, --help             Show this help message

    Configuration:
      Configs are looked for in the following locations:
        1. As specified (if absolute path)
        2. ~/.config/pane/
        3. The project's config/ directory
      
      Default config (when no -c option) is loaded from:
        1. ~/.config/pane/default.yaml
        2. The project's config/default.yaml file

    Examples:
      pane                   Create tmux session using default config and attach to it
      pane -c myproject      Use myproject.yaml config from standard locations
      pane --no-attach       Create session without attaching
      pane --preview         Preview the commands that would be executed
      pane --verbose         Show detailed logging during execution
      pane -v -p             Preview with verbose output
      pane --config=my.yaml  Use custom configuration file
    """)
  end
end