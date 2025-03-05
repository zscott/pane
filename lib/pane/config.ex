defmodule Pane.Config do
  @moduledoc """
  Configuration for Pane tmux sessions.
  """
  require Logger

  @type pane_config :: String.t() | %{
          cmd: String.t(),
          height: integer() | nil,
          width: integer() | nil
        }
        
  @type layout_config :: %{
          template: String.t(),
          panes: %{atom() => pane_config()}
        }

  @type window_config :: %{
          path: String.t() | nil,
          label: String.t() | nil,
          command: String.t() | nil,
          layout: String.t() | nil
        }

  @type t :: %{
          session: String.t(),
          root: String.t(),
          defaultLayout: String.t() | nil,
          layouts: %{atom() => layout_config()},
          windows: [window_config()]
        }

  @default_config_dir "~/.config/pane"
  @default_config_file "default.yaml"
  @fallback_config_path Path.join([
                          Path.dirname(__ENV__.file),
                          "..",
                          "..",
                          "config",
                          "default.yaml"
                        ])

  @doc """
  Load and return the configuration from the specified YAML file,
  or from the default location if not specified.

  Returns the configuration or {:error, reason} on failure.
  """
  @spec load_config(String.t() | nil) :: t() | {:error, term()}
  def load_config(config_file \\ nil) do
    config_path = resolve_config_path(config_file)

    # Log configuration file path if verbose mode
    if Application.get_env(:pane, :verbose, false) do
      IO.puts("[INFO] Loading configuration from: #{config_path}")
    end

    case read_yaml_config(config_path) do
      {:ok, config} ->
        normalized = normalize_config(config)
        
        # Store the actual config path that was used in the configuration
        normalized = Map.put(normalized, :config_path, config_path)
        
        # Log session and layout info if verbose
        if Application.get_env(:pane, :verbose, false) do
          IO.puts("[INFO] Session name: #{normalized.session}")
          IO.puts("[INFO] Root directory: #{normalized.root}")
          IO.puts("[INFO] Default layout: #{normalized.defaultLayout}")
          IO.puts("[INFO] Available layouts: #{Map.keys(normalized.layouts) |> Enum.join(", ")}")
          IO.puts("[INFO] Windows: #{length(normalized.windows)}")
        end
        
        normalized

      {:error, reason} ->
        Logger.warning("Failed to load config from '#{config_path}': #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Returns the path to the config directory, ensuring it exists.
  """
  @spec config_dir() :: String.t()
  def config_dir do
    dir = Path.expand(@default_config_dir)

    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    dir
  end

  @doc """
  Returns the default config file path.
  """
  @spec default_config_path() :: String.t()
  def default_config_path do
    Path.join(config_dir(), @default_config_file)
  end

  # Resolve the config path, checking multiple locations
  defp resolve_config_path(nil) do
    # Use default.yaml config when no config is specified
    # Check standard locations in order
    cond do
      File.exists?(path = default_config_path()) -> path
      File.exists?(path = @fallback_config_path) -> path
      # Return default path even if it doesn't exist yet
      true -> default_config_path()
    end
  end

  defp resolve_config_path(path) do
    # Check if the path is just a name without extension or path
    path =
      if !String.contains?(path, "/") && !String.contains?(path, ".") do
        "#{path}.yaml"
      else
        path
      end

    # Check in several locations:
    # 1. As provided (absolute path)
    # 2. In the user's config directory
    # 3. In the project's config directory
    expanded_path = Path.expand(path)

    cond do
      File.exists?(expanded_path) ->
        expanded_path

      File.exists?(user_path = Path.join(config_dir(), path)) ->
        user_path

      File.exists?(
        project_path = Path.join(Path.dirname(@fallback_config_path), Path.basename(path))
      ) ->
        project_path

      true ->
        # Return the expanded path even if it doesn't exist
        expanded_path
    end
  end

  # Read and parse YAML config file
  defp read_yaml_config(path) do
    if File.exists?(path) do
      YamlElixir.read_from_file(path)
    else
      {:error, :enoent}
    end
  end

  # Normalize configuration to expected format
  defp normalize_config(config) do
    # Get values from raw config
    raw_windows = config["windows"] || []
    raw_layouts = config["layouts"] || %{}
    default_layout = config["defaultLayout"] || "dev"
    
    # Convert the raw config to a map with atom keys (except for windows and layouts)
    config_without_special = 
      config
      |> Map.delete("windows")
      |> Map.delete("layouts")
      |> atomize_keys(true)
    
    # Now process windows preserving original layout values
    windows =
      Enum.map(raw_windows, fn window ->
        # Keep the original layout key
        original_layout = window["layout"]
        
        # Convert to atoms but without the layout key
        window_without_layout = Map.delete(window, "layout")
        window_with_atoms = atomize_keys(window_without_layout, true)
        
        # Then add default values 
        window_with_defaults =
          window_with_atoms
          |> Map.put_new(:label, nil)
          |> Map.put_new(:command, nil)
        
        # Add original layout or default if not specified
        window_with_layout =
          if original_layout do
            # Use the original layout value
            Map.put(window_with_defaults, :layout, original_layout)
          else
            Map.put(window_with_defaults, :layout, default_layout)
          end
          
        window_with_layout
      end)

    # Process the raw layouts, preserving original keys
    layouts = 
      if map_size(raw_layouts) > 0 do
        # Convert each layout independently
        Enum.map(raw_layouts, fn {name, config} ->
          # Convert layout config but preserve template string
          template = config["template"]
          panes = config["panes"] || %{}
          
          # Convert panes map
          processed_panes = 
            Enum.map(panes, fn {pane_name, pane_config} ->
              {String.to_atom(pane_name), pane_config}
            end)
            |> Enum.into(%{})
            
          # Create layout config with atom keys but string template
          {
            String.to_atom(name),
            %{
              template: template,
              panes: processed_panes
            }
          }
        end)
        |> Enum.into(%{})
      else
        # Default layouts
        %{
          dev: %{
            template: "TopSplitBottom",
            panes: %{
              top: "nvim .",
              bottomLeft: "zsh",
              bottomRight: "zsh"
            }
          },
          single: %{
            template: "Single",
            panes: %{
              main: ""
            }
          }
        }
      end

    # Create layouts atom map merged with aiCoding
    # Manually ensure aiCoding is available
    layouts_with_extras = 
      Map.merge(layouts, %{
        aiCoding: %{
          template: "SplitVertical",
          panes: %{
            left: "nvim .",
            right: "claude code"
          }
        }
      })
    
    # Return standardized config map
    %{
      session: config_without_special[:session] || "layr8",
      root: config_without_special[:root] || "~/",
      defaultLayout: config_without_special[:defaultLayout] || "dev",
      layouts: layouts_with_extras,
      windows: windows
    }
  end


  @doc """
  Convert string keys to atoms in maps, recursively if requested.
  
  ## Parameters
    * `map` - The map to convert
    * `recursive` - Whether to convert nested maps and lists
  """
  def atomize_keys(map, recursive \\ false)
  
  def atomize_keys(map, recursive) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      # Convert string keys to atoms or keep atom keys
      key = if is_binary(key), do: String.to_atom(key), else: key
      
      # Recurse into nested maps if requested
      value = 
        cond do
          recursive && is_map(value) ->
            atomize_keys(value, recursive)
          recursive && is_list(value) ->
            Enum.map(value, &atomize_keys(&1, recursive))
          true ->
            value
        end
      
      Map.put(acc, key, value)
    end)
  end

  # Handle list items if recursive
  def atomize_keys(list, true) when is_list(list) do
    Enum.map(list, &atomize_keys(&1, true))
  end

  # Handle non-maps
  def atomize_keys(value, _), do: value
end
