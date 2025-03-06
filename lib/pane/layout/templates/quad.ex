defmodule Pane.Layout.Templates.Quad do
  @moduledoc """
  A layout with four equal-sized panes arranged in a 2x2 grid.

  Pane names:
  - :topLeft
  - :topRight
  - :bottomLeft
  - :bottomRight
  """

  @behaviour Pane.Layout.Template

  @impl true
  def pane_names, do: [:topLeft, :topRight, :bottomLeft, :bottomRight]

  @impl true
  def apply(window_target, cwd, _options) do
    # Generate commands
    commands = []

    # First pane is created by default with the window
    # This will be our topLeft pane
    top_left_target = "#{window_target}.0"
    
    # Split window for bottom section (top/bottom split at 50%)
    bottom_left_cmd = Pane.Tmux.Pane.split(
      direction: :vertical, 
      percent: 50, 
      target: top_left_target,
      cwd: cwd
    )
    commands = commands ++ [bottom_left_cmd]
    bottom_left_target = "#{window_target}.1"
    
    # Split the top pane horizontally (left/right split at 50%)
    top_right_cmd = Pane.Tmux.Pane.split(
      direction: :horizontal, 
      percent: 50, 
      target: top_left_target,
      cwd: cwd
    )
    commands = commands ++ [top_right_cmd]
    top_right_target = "#{window_target}.2"
    
    # Split the bottom pane horizontally (left/right split at 50%)
    bottom_right_cmd = Pane.Tmux.Pane.split(
      direction: :horizontal, 
      percent: 50, 
      target: bottom_left_target,
      cwd: cwd
    )
    commands = commands ++ [bottom_right_cmd]
    bottom_right_target = "#{window_target}.3"
    
    # Select the top left pane again to make it active
    select_top_left_cmd = Pane.Tmux.Pane.select(top_left_target)
    commands = commands ++ [select_top_left_cmd]
    
    # Return commands and a map of pane positions to targets
    {
      commands,
      %{
        topLeft: top_left_target,
        topRight: top_right_target,
        bottomLeft: bottom_left_target,
        bottomRight: bottom_right_target
      }
    }
  end
end