defmodule Pane do
  @moduledoc """
  Pane is a tmux session manager that creates a standardized
  development environment across multiple project directories.
  """
  
  @doc """
  Check if the current process is running in an interactive terminal.
  Uses multiple methods to more reliably detect interactive terminals.
  """
  def is_interactive_terminal? do
    # First approach: Check using test -t 0
    test_tty = 
      case System.cmd("test", ["-t", "0"], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end
    
    # Second approach: Check using tty command
    tty_check = 
      case System.cmd("sh", ["-c", "tty | grep -v 'not a tty' > /dev/null"], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end
      
    # Third approach: Check standard input as character device
    stdin_check =
      case System.cmd("test", ["-c", "/dev/stdin"], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end
    
    # Fourth approach: Check TERM environment variable
    term_check = System.get_env("TERM") && System.get_env("TERM") != ""
    
    # Combine the results - if any method detects a terminal, consider it interactive
    test_tty or tty_check or stdin_check or term_check
  end
  
  @doc """
  Run the tmux session setup with the given configuration.
  
  ## Parameters
    * `config` - The session configuration
    * `auto_attach` - Whether to automatically attach to the session (default: false)
  """
  def run(config, auto_attach \\ false) do
    # Generate all tmux commands
    commands = Pane.Command.generate_commands(config)

    # Check if session exists
    [session_check_cmd | remaining_commands] = commands

    # Last command is the attach command (used for reference only)
    _attach_cmd = List.last(commands)

    session_exists? =
      case System.cmd("sh", ["-c", session_check_cmd], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end

    # Only create windows if session doesn't exist
    unless session_exists? do
      # Execute each command except the session check and the attach command
      commands_to_run = Enum.take(remaining_commands, length(remaining_commands) - 1)

      Enum.each(commands_to_run, fn cmd ->
        case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
          {_, 0} ->
            :ok

          {error, _} ->
            IO.puts("Warning: Command failed: #{cmd}")
            IO.puts("Error: #{error}")
        end
      end)
    end

    # Extract the session name from the config
    %{session: session_name} = config

    # Check if we should auto-attach (based on the auto_attach parameter)
    if auto_attach do
      # Check if we're in a terminal environment
      is_interactive = is_interactive_terminal?()
      
      # Log the detection result in verbose mode
      if Application.get_env(:pane, :verbose, false) do
        IO.puts("[INFO] Interactive terminal detection: #{is_interactive}")
      end
      
      if is_interactive do
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
      else
        # If we're not in an interactive terminal, just print instructions
        IO.puts("\nTmux session '#{session_name}' is ready.")
        IO.puts("Cannot attach automatically - not running in an interactive terminal.")
        IO.puts("To attach to this session, run the following command in your terminal:")
        IO.puts("  tmux attach -t #{session_name}")
      end
    else
      # If auto_attach is false (--no-attach was specified), just print instructions
      IO.puts("\nTmux session '#{session_name}' is ready.")
      IO.puts("To attach to this session, run the following command in your terminal:")
      IO.puts("  tmux attach -t #{session_name}")
      IO.puts("\nRun this script with --preview to see the full list of commands executed.")
    end
  end
end