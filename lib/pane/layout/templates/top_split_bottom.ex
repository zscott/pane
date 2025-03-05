defmodule Pane.Layout.Templates.TopSplitBottom do
  @moduledoc """
  A layout with a large top pane (60% by default) and two equal bottom panes (40% total).

  Pane names:
  - :top
  - :bottomLeft
  - :bottomRight
  """

  @behaviour Pane.Layout.Template

  @impl true
  def pane_names, do: [:top, :bottomLeft, :bottomRight]

  @impl true
  def apply(window_target, cwd, options) do
    # Extract options with defaults
    top_size = Map.get(options, :topSize, 60)
    bottom_size = 100 - top_size

    # Generate commands
    commands = []

    # First pane is created by default with the window, so we just need to reference it
    top_target = "#{window_target}.0"
    
    # Split window for bottom section (top/bottom split)
    # Note: In tmux, -v means vertical split, which divides top/bottom
    bottom_left_cmd = Pane.Tmux.Pane.split(
      direction: :vertical, 
      percent: bottom_size, 
      target: top_target,
      cwd: cwd
    )
    commands = commands ++ [bottom_left_cmd]
    bottom_left_target = "#{window_target}.1"
    
    # Split the bottom pane horizontally (left/right split)
    # Note: In tmux, -h means horizontal split, which divides left/right
    bottom_right_cmd = Pane.Tmux.Pane.split(
      direction: :horizontal, 
      percent: 50, 
      target: bottom_left_target,
      cwd: cwd
    )
    commands = commands ++ [bottom_right_cmd]
    bottom_right_target = "#{window_target}.2"
    
    # Select the top pane again to make it active
    select_top_cmd = Pane.Tmux.Pane.select(top_target)
    commands = commands ++ [select_top_cmd]
    
    # Return commands and a map of pane positions to targets
    {
      commands,
      %{
        top: top_target,
        bottomLeft: bottom_left_target,
        bottomRight: bottom_right_target
      }
    }
  end
end