defmodule Pane.Tmux.Window do
  @moduledoc """
  Functions related to tmux window management.
  """

  @doc """
  Create a new window.

  ## Options
    * `:cwd` - Set the working directory for the window
    * `:target_session` - Target session (default: nil)
    * `:window_index` - Index to create window at (default: nil - next available)
  """
  @spec new(String.t(), Keyword.t()) :: String.t()
  def new(name, opts \\ []) do
    cwd = Keyword.get(opts, :cwd)
    target_session = Keyword.get(opts, :target_session)
    window_index = Keyword.get(opts, :window_index)
    
    # If window index is provided, generate a specific target
    target = 
      cond do
        window_index && target_session ->
          "#{target_session}:#{window_index}"
        true ->
          target_session
      end

    cmd = ["tmux new-window"]
    cmd = if target, do: cmd ++ [~s(-t "#{target}")], else: cmd
    cmd = cmd ++ [~s(-n "#{name}")]
    cmd = if cwd, do: cmd ++ [~s(-c "#{cwd}")], else: cmd

    Enum.join(cmd, " ")
  end

  @doc """
  Select a window.
  """
  @spec select(String.t()) :: String.t()
  def select(target) do
    ~s(tmux select-window -t "#{target}")
  end

  @doc """
  List windows.

  ## Options
    * `:target` - Target session (optional)
  """
  @spec list(Keyword.t()) :: String.t()
  def list(opts \\ []) do
    target = Keyword.get(opts, :target)

    if target do
      ~s(tmux list-windows -t "#{target}")
    else
      "tmux list-windows"
    end
  end

  @doc """
  Kill a window.
  """
  @spec kill(String.t()) :: String.t()
  def kill(target) do
    ~s(tmux kill-window -t "#{target}")
  end

  @doc """
  Set a window option.
  """
  @spec set_option(String.t(), String.t(), Keyword.t()) :: String.t()
  def set_option(option, value, opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    ~s(tmux set-window-option -t "#{target}" #{option} #{value})
  end
end