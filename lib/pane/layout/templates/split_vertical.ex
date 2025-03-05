defmodule Pane.Layout.Templates.SplitVertical do
  @moduledoc """
  A layout with two vertical panes (50/50 split by default).

  Pane names:
  - :left
  - :right
  """

  @behaviour Pane.Layout.Template

  @impl true
  def pane_names, do: [:left, :right]

  @impl true
  def apply(window_target, cwd, _options) do
    # First pane is created by default with the window, so we just need to reference it
    left_target = "#{window_target}.0"
    
    # Split window horizontally (side by side)
    # Note: In tmux, -h means horizontal split (left/right)
    right_cmd = Pane.Tmux.Pane.split(
      direction: :horizontal, 
      percent: 50, 
      target: left_target,
      cwd: cwd
    )
    right_target = "#{window_target}.1"
    
    # Select the left pane again to make it active
    select_left_cmd = Pane.Tmux.Pane.select(left_target)
    
    # Build the commands list
    commands = [right_cmd, select_left_cmd]
    
    # Return commands and a map of pane positions to targets
    {
      commands,
      %{
        left: left_target,
        right: right_target
      }
    }
  end
end