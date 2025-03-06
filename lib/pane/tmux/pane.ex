defmodule Pane.Tmux.Pane do
  @moduledoc """
  Functions related to tmux pane management.
  """
  
  # Default temporary path as fallback when no working directory is specified
  @default_tmp_path System.tmp_dir()

  @doc """
  Split the window.

  ## Options
    * `:direction` - either `:horizontal` or `:vertical` (default: `:horizontal`)
    * `:cwd` - Set the working directory for the new pane
    * `:percent` - Size of the new pane as a percentage
    * `:target` - Target window (default: nil)
    * `:shell` - Command to run in the new pane (default: nil)
  """
  @spec split(Keyword.t()) :: String.t()
  def split(opts \\ []) do
    direction = Keyword.get(opts, :direction, :horizontal)
    cwd = Keyword.get(opts, :cwd)
    percent = Keyword.get(opts, :percent)
    target = Keyword.get(opts, :target)
    shell = Keyword.get(opts, :shell)

    dir_flag = if direction == :horizontal, do: "-h", else: "-v"

    cmd = ["tmux split-window", dir_flag]
    cmd = if target, do: cmd ++ [~s(-t "#{target}")], else: cmd
    cmd = if percent, do: cmd ++ [~s(-p #{percent})], else: cmd
    cmd = if cwd, do: cmd ++ [~s(-c "#{cwd}")], else: cmd
    cmd = if shell, do: cmd ++ [~s('#{shell}')], else: cmd

    Enum.join(cmd, " ")
  end

  @doc """
  Select a pane.
  """
  @spec select(String.t()) :: String.t()
  def select(target) do
    ~s(tmux select-pane -t "#{target}")
  end

  @doc """
  Send keys to a tmux pane.

  ## Options
    * `:literal` - Send keys literally (default: false)
    * `:target` - Target pane or window (required)
    * `:enter` - Send enter key after command (default: true)
  """
  @spec send_keys(String.t(), Keyword.t()) :: String.t()
  def send_keys(keys, opts \\ []) do
    literal = Keyword.get(opts, :literal, false)
    target = Keyword.fetch!(opts, :target)
    enter = Keyword.get(opts, :enter, true)
    test_mode = Keyword.get(opts, :test_mode, false) || Application.get_env(:pane, :test_mode, false)
    cwd = Keyword.get(opts, :cwd)

    cmd = ["tmux send-keys"]
    cmd = if literal, do: cmd ++ ["-l"], else: cmd
    cmd = cmd ++ [~s(-t "#{target}")]
    
    # Note: Using @default_tmp_path instead of hardcoded "/tmp"
    
    # If keys include a shell command with arguments, we need to properly format it
    # for tmux send-keys by using multiple arguments
    cmd = 
      cond do
        # Special case for nvim . or similar commands with period
        # to ensure the period is sent as a separate key press
        keys =~ ~r/nvim\s+\./ && !test_mode ->
          default_cwd = System.get_env("PWD") || @default_tmp_path
          cmd_cwd = cwd || default_cwd
          cmd ++ [~s("cd #{cmd_cwd} && nvim")]
        
        # Replace "bash" with "zsh" for default command strings 
        # (explicit bash commands from config will use the full path)
        keys == "bash" ->
          cmd ++ [~s("zsh")]
        
        # Normal command with spaces
        keys =~ " " && !String.starts_with?(keys, "cd ") && !test_mode ->
          # For commands with spaces, we need special handling
          default_cwd = System.get_env("PWD") || @default_tmp_path
          cmd_cwd = cwd || default_cwd
          
          # For multi-word commands like "claude code", keep them intact
          # Don't split them into parts
          cmd ++ [~s("cd #{cmd_cwd} && #{keys}")]
        
        # Simple command or test mode
        true ->
          cmd ++ [~s("#{keys}")]
      end
      
    cmd = if enter, do: cmd ++ ["C-m"], else: cmd

    Enum.join(cmd, " ")
  end

  @doc """
  Kill a pane.
  """
  @spec kill(String.t()) :: String.t()
  def kill(target) do
    ~s(tmux kill-pane -t "#{target}")
  end
end