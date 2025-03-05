defmodule Pane.Layout.Templates.Single do
  @moduledoc """
  A layout with a single pane filling the entire window.

  Pane names:
  - :main
  """

  @behaviour Pane.Layout.Template

  @impl true
  def pane_names, do: [:main]

  @impl true
  def apply(window_target, _cwd, _options) do
    # First pane is created by default with the window, so we just need to reference it
    main_target = "#{window_target}.0"
    
    # No additional commands needed for a single pane
    commands = []
    
    # Return commands and a map of pane positions to targets
    {
      commands,
      %{
        main: main_target
      }
    }
  end
end