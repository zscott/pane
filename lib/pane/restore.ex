defmodule Pane.Restore do
  @moduledoc """
  Functionality for restoring tmux sessions from auto-saved session files.
  
  This module provides the ability to restore a tmux session from a previously
  auto-saved state, recreating the window and pane layout as it was when saved.
  """
  
  alias Pane.AutoSave
  alias Pane.Tmux
  
  @doc """
  Restores the most recent auto-saved session for a given session name.
  
  ## Parameters
    * `session_name` - The name of the session to restore
    
  ## Returns
    * `{:ok, session, commands}` on success
    * `{:error, reason}` if restore fails
  """
  def restore_latest(session_name) do
    # Get the latest session data
    case AutoSave.get_latest_session(session_name) do
      nil -> {:error, :no_session_found}
      session_data ->
        # Generate restore commands
        commands = generate_restore_commands(session_data)
        {:ok, session_data, commands}
    end
  end
  
  @doc """
  Restores a session from a specific session file.
  
  ## Parameters
    * `file_path` - Path to the session file
    
  ## Returns
    * `{:ok, session, commands}` on success
    * `{:error, reason}` if restore fails
  """
  def restore_file(file_path) do
    # Check if file exists
    if not File.exists?(file_path) do
      {:error, :file_not_found}
    else
      # Read the session data
      case File.read(file_path) do
        {:ok, data} ->
          try do
            session_data = :erlang.binary_to_term(data)
            commands = generate_restore_commands(session_data)
            {:ok, session_data, commands}
          rescue
            _ -> {:error, :invalid_session_file}
          end
        {:error, reason} -> {:error, reason}
      end
    end
  end
  
  @doc """
  Generates tmux commands to restore a session from saved data.
  
  ## Parameters
    * `session_data` - The saved session data structure
    
  ## Returns
    * A list of tmux commands to restore the session
  """
  def generate_restore_commands(session_data) do
    %{
      metadata: %{session_name: session_name},
      config: _config,
      tmux_info: tmux_info
    } = session_data
    
    # Check if session already exists
    has_session_cmd = Tmux.Session.exists?(session_name)
    
    # Prepare the base commands list with the has-session check
    commands = [has_session_cmd]
    
    # Add command to create the session if it doesn't exist
    first_window = get_first_window(tmux_info)
    
    # Create session with first window
    create_session_cmd = Tmux.Session.new(
      session_name,
      windowName: first_window[:name],
      cwd: first_window[:cwd]
    )
    
    commands = commands ++ [create_session_cmd]
    
    # Add commands for each additional window
    window_commands = create_window_commands(session_name, tmux_info.windows)
    commands = commands ++ window_commands
    
    # Add commands to recreate pane structure in each window
    pane_commands = create_pane_commands(session_name, tmux_info.windows)
    commands = commands ++ pane_commands
    
    commands
  end
  
  @doc """
  Executes the commands to restore a session.
  
  ## Parameters
    * `session_data` - The saved session data structure
    
  ## Returns
    * `{:ok, commands}` on success, where commands is the list of executed commands
    * `{:error, reason}` if restore fails
  """
  def restore_session(session_data) do
    # Generate restore commands
    commands = generate_restore_commands(session_data)
    
    if Application.get_env(:pane, :test_mode, false) do
      # In test mode, just return the commands
      {:ok, commands}
    else
      # Execute commands
      _session_name = session_data.metadata.session_name
      
      Enum.each(commands, fn cmd ->
        System.cmd("sh", ["-c", cmd], stderr_to_stdout: true)
      end)
      
      {:ok, commands}
    end
  end
  
  @doc """
  Returns a list of available sessions in a user-friendly format.
  
  ## Returns
    * A list of strings, each representing an available session
  """
  def list_available_sessions do
    AutoSave.list_sessions()
    |> Enum.sort_by(fn session -> session.metadata.timestamp end, :desc)
    |> Enum.map(fn session ->
      # Format timestamp as a readable date
      timestamp = session.metadata.timestamp
      formatted_date = format_timestamp(timestamp)
      
      # Get window count
      window_count = length(session.tmux_info.windows)
      
      # Format session listing
      "#{session.metadata.session_name} (#{formatted_date}) - #{window_count} windows"
    end)
  end
  
  @doc """
  Parses a session ID (like "session_name_20230101120000") into its components.
  
  ## Parameters
    * `session_id` - The session ID to parse
    
  ## Returns
    * `{:ok, session_name, timestamp}` on success
    * `{:error, :invalid_format}` if the ID format is invalid
  """
  def parse_session_id(session_id) do
    case Regex.run(~r/^(.+)_(\d{14})$/, session_id) do
      [_, session_name, timestamp] -> {:ok, session_name, timestamp}
      _ -> {:error, :invalid_format}
    end
  end
  
  # Private helper functions
  
  # Get the first window from tmux info
  defp get_first_window(tmux_info) do
    window = tmux_info.windows
    |> Enum.sort_by(fn w -> w.index end)
    |> List.first()
    
    # Get the first pane's working directory
    cwd = window.panes
    |> Enum.sort_by(fn p -> p.index end)
    |> List.first()
    |> Map.get(:current_path)
    
    %{
      name: window.name,
      cwd: cwd
    }
  end
  
  # Create commands to set up windows
  defp create_window_commands(session_name, windows) do
    # Skip the first window (index 0) as it's created with the session
    windows
    |> Enum.sort_by(fn w -> w.index end)
    |> Enum.drop(1)
    |> Enum.map(fn window ->
      # Get the first pane's working directory
      cwd = window.panes
      |> Enum.sort_by(fn p -> p.index end)
      |> List.first()
      |> Map.get(:current_path)
      
      # Create window
      Tmux.Window.new(
        window.name,
        targetSession: session_name,
        cwd: cwd
      )
    end)
  end
  
  # Create commands to set up panes in each window
  defp create_pane_commands(session_name, windows) do
    windows
    |> Enum.sort_by(fn w -> w.index end)
    |> Enum.flat_map(fn window ->
      window_target = "#{session_name}:#{window.index}"
      
      # Skip first pane (created with window)
      panes = window.panes
      |> Enum.sort_by(fn p -> p.index end)
      |> Enum.drop(1)
      
      # Create pane splits
      pane_commands = panes
      |> Enum.map(fn pane ->
        # Create split
        Tmux.Pane.split(
          direction: rem(pane.index, 2) == 0 && :horizontal || :vertical,
          target: "#{window_target}.0",
          cwd: pane.current_path
        )
      end)
      
      # Set layout
      layout_command = Tmux.Layout.select(
        window.layout,
        target: window_target
      )
      
      pane_commands ++ [layout_command]
    end)
  end
  
  # Format a timestamp string as a readable date
  defp format_timestamp(timestamp) do
    year = String.slice(timestamp, 0, 4)
    month = String.slice(timestamp, 4, 2)
    day = String.slice(timestamp, 6, 2)
    hour = String.slice(timestamp, 8, 2)
    minute = String.slice(timestamp, 10, 2)
    
    "#{year}-#{month}-#{day} #{hour}:#{minute}"
  end
end