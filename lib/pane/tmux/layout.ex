defmodule Pane.Tmux.Layout do
  @moduledoc """
  Functions related to tmux layout management.
  """

  @doc """
  Select a layout.

  ## Options
    * `:target` - Target window (required)
  """
  @spec select(String.t(), Keyword.t()) :: String.t()
  def select(layout, opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    ~s(tmux select-layout -t "#{target}" #{layout})
  end

  @doc """
  Move to the next layout.

  ## Options
    * `:target` - Target window (required)
  """
  @spec next(Keyword.t()) :: String.t()
  def next(opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    ~s(tmux next-layout -t "#{target}")
  end

  @doc """
  Move to the previous layout.

  ## Options
    * `:target` - Target window (required)
  """
  @spec previous(Keyword.t()) :: String.t()
  def previous(opts \\ []) do
    target = Keyword.fetch!(opts, :target)
    ~s(tmux previous-layout -t "#{target}")
  end
end