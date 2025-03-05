defmodule Pane.Layout do
  @moduledoc """
  Functions for managing window layouts using templates.

  This module provides a high-level API for applying layout templates to windows
  and managing the configuration of layouts.
  """

  @doc """
  Applies a layout to a window based on the layout configuration.

  ## Parameters
    * `window_target` - The target identifier for the window
    * `cwd` - The current working directory for the window
    * `layout_config` - The layout configuration from the config file
  
  ## Returns
    * A list of shell commands to execute
  """
  @spec apply_layout(String.t(), String.t(), map(), map()) :: [String.t()]
  def apply_layout(window_target, cwd, layout_config, window_opts \\ %{}) do
    template_name = layout_config.template
    
    # Extract commands from the layout config
    # Convert string keys to atoms if necessary
    commands = extract_commands(layout_config.panes)
    
    # Extract any options from the layout config
    options = extract_options(layout_config)
    
    # Merge window-specific options (like command)
    merged_options = Map.merge(options, window_opts)

    # Apply the template
    # Ensure template name is a string for consistent handling
    template_name_str = if is_atom(template_name), do: Atom.to_string(template_name), else: template_name
    Pane.Layout.Template.apply(template_name_str, window_target, cwd, commands, merged_options)
  end

  @doc """
  Extracts command configuration from the layout config.
  
  Handles both simple string commands and map configurations.

  ## Parameters
    * `panes_config` - The panes section of the layout configuration
  
  ## Returns
    * A map of pane position atoms to command strings
  """
  @spec extract_commands(map()) :: %{atom() => String.t()}
  def extract_commands(panes_config) do
    Enum.reduce(panes_config, %{}, fn {pane_name, config}, acc ->
      # Convert string keys to atoms
      pane_name = if is_binary(pane_name), do: String.to_atom(pane_name), else: pane_name
      
      # Extract command value based on type
      command = cond do
        is_binary(config) -> 
          config
        is_map(config) && Map.has_key?(config, :cmd) -> 
          config.cmd
        is_map(config) && Map.has_key?(config, "cmd") -> 
          config["cmd"]
        true -> 
          # Default to empty string for nil commands
          ""
      end
      
      Map.put(acc, pane_name, command)
    end)
  end

  @doc """
  Extracts layout options from the layout config.

  ## Parameters
    * `layout_config` - The layout configuration
  
  ## Returns
    * A map of options for the template
  """
  @spec extract_options(map()) :: map()
  def extract_options(layout_config) do
    # Extract size options from panes
    pane_options =
      if Map.has_key?(layout_config, :panes) do
        Enum.reduce(layout_config.panes, %{}, fn {pane_name, config}, acc ->
          case config do
            config when is_map(config) ->
              pane_name = if is_binary(pane_name), do: String.to_atom(pane_name), else: pane_name
              
              # Look for size options
              acc = if Map.has_key?(config, :height) do
                size_key = String.to_atom("#{pane_name}Size")
                Map.put(acc, size_key, config.height)
              else
                acc
              end
              
              acc = if Map.has_key?(config, "height") do
                size_key = String.to_atom("#{pane_name}Size")
                Map.put(acc, size_key, config["height"])
              else
                acc
              end
              
              acc
            _ -> acc
          end
        end)
      else
        %{}
      end
    
    # Add other options from the layout config
    Map.drop(layout_config, [:template, :panes])
    |> Map.merge(pane_options)
  end

  @doc """
  Gets a layout configuration by name from the global config.

  ## Parameters
    * `config` - The global configuration
    * `layout_name` - The name of the layout to retrieve
  
  ## Returns
    * The layout configuration map
  """
  @spec get_layout_config(map(), String.t() | atom()) :: map()
  def get_layout_config(config, layout_name) do
    # Try to get atom key first
    atom_key = if is_binary(layout_name), do: String.to_atom(layout_name), else: layout_name
    
    case get_in(config, [:layouts, atom_key]) do
      nil -> 
        # Try string key as fallback
        case get_in(config, [:layouts, layout_name]) do
          nil -> 
            raise "Layout '#{layout_name}' not found in configuration"
          layout_config -> 
            layout_config
        end
      layout_config -> 
        layout_config
    end
  end
end