defmodule Pane.Tmux.Session do
  @moduledoc """
  Functions related to tmux session management.
  """

  @doc """
  Check if a session exists.
  """
  @spec exists?(String.t()) :: String.t()
  def exists?(session) do
    ~s(tmux has-session -t "#{session}")
  end

  @doc """
  Create a new session.

  ## Options
    * `:detached` - Create the session in detached mode (default: true)
    * `:cwd` - Set the working directory for the session
    * `:window_name` - Set the name of the initial window
    * `:create_or_attach` - Use -A flag to attach-or-create (default: false)
  """
  @spec new(String.t(), Keyword.t()) :: String.t()
  def new(session, opts \\ []) do
    detached = Keyword.get(opts, :detached, true)
    cwd = Keyword.get(opts, :cwd)
    window_name = Keyword.get(opts, :window_name)
    create_or_attach = Keyword.get(opts, :create_or_attach, false)

    cmd = ["tmux new-session"]
    cmd = if detached, do: cmd ++ ["-d"], else: cmd
    cmd = if create_or_attach, do: cmd ++ ["-A"], else: cmd
    cmd = cmd ++ ["-s #{session}"]
    cmd = if cwd, do: cmd ++ [~s(-c "#{cwd}")], else: cmd
    cmd = if window_name, do: cmd ++ [~s(-n "#{window_name}")], else: cmd

    Enum.join(cmd, " ")
  end

  @doc """
  Attach to a session.

  ## Options
    * `:target` - Target session (required)
  """
  @spec attach(Keyword.t()) :: String.t()
  def attach(opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    ~s(tmux attach-session -t "#{target}")
  end

  @doc """
  List sessions.
  """
  @spec list() :: String.t()
  def list do
    "tmux list-sessions"
  end

  @doc """
  Kill a session.
  """
  @spec kill(String.t()) :: String.t()
  def kill(target) do
    ~s(tmux kill-session -t "#{target}")
  end

  @doc """
  Set a session option.
  """
  @spec set_option(String.t(), String.t(), Keyword.t()) :: String.t()
  def set_option(option, value, opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    ~s(tmux set-option -t "#{target}" #{option} #{value})
  end
end