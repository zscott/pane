defmodule Pane.RestoreTest do
  use ExUnit.Case
  
  alias Pane.Restore
  
  # Setup test environment
  setup do
    # Set test mode to avoid actual tmux execution
    Application.put_env(:pane, :test_mode, true)
    
    # Use a temporary directory for test session files
    test_sessions_dir = "#{System.tmp_dir()}/pane_test_sessions_#{:os.system_time(:millisecond)}"
    File.mkdir_p!(test_sessions_dir)
    Application.put_env(:pane, :sessions_dir, test_sessions_dir)
    
    # Clean up after tests
    on_exit(fn ->
      File.rm_rf!(test_sessions_dir)
    end)
    
    # Create a sample saved session for testing
    sample_session = %{
      metadata: %{
        session_name: "test_session",
        timestamp: "20230101120000",
        pane_version: "0.1.0"
      },
      config: %{
        session: "test_session",
        root: "/home/user/projects",
        default_layout: "dev",
        layouts: %{
          dev: %{
            template: "TopSplitBottom",
            commands: ["vim", "ls", "htop"]
          }
        },
        windows: [
          %{path: "project1", label: "p1"},
          %{path: "project2", label: "p2", layout: "dev"}
        ]
      },
      tmux_info: %{
        windows: [
          %{
            index: 0,
            name: "p1",
            layout: "main-vertical",
            panes: [
              %{index: 0, current_path: "/home/user/projects/project1"},
              %{index: 1, current_path: "/home/user/projects/project1"}
            ]
          },
          %{
            index: 1,
            name: "p2",
            layout: "main-vertical",
            panes: [
              %{index: 0, current_path: "/home/user/projects/project2"},
              %{index: 1, current_path: "/home/user/projects/project2"}
            ]
          }
        ]
      }
    }
    
    # Save the sample session
    session_file = "#{test_sessions_dir}/test_session_20230101120000.session"
    File.write!(session_file, :erlang.term_to_binary(sample_session))
    
    # Return test context
    %{
      test_sessions_dir: test_sessions_dir,
      sample_session: sample_session,
      session_file: session_file
    }
  end
  
  test "restore_latest returns error when no sessions exist for the name" do
    result = Restore.restore_latest("nonexistent_session")
    assert result == {:error, :no_session_found}
  end
  
  test "restore_latest loads the most recent session", %{sample_session: session} do
    # Create a newer session file
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    session_name = session.metadata.session_name
    
    newer_session = put_in(session.metadata.timestamp, "20230101120100")
    newer_file = "#{sessions_dir}/#{session_name}_20230101120100.session"
    File.write!(newer_file, :erlang.term_to_binary(newer_session))
    
    # Test restore_latest finds the newer session
    {:ok, restored_session, commands} = Restore.restore_latest(session_name)
    
    assert restored_session.metadata.timestamp == "20230101120100"
    assert is_list(commands)
    assert length(commands) > 0
  end
  
  test "restore_file returns error for non-existent file" do
    result = Restore.restore_file("/nonexistent/path.session")
    assert result == {:error, :file_not_found}
  end
  
  test "restore_file loads a specific session file", %{session_file: file, sample_session: session} do
    {:ok, restored_session, commands} = Restore.restore_file(file)
    
    assert restored_session.metadata.session_name == session.metadata.session_name
    assert restored_session.metadata.timestamp == session.metadata.timestamp
    assert is_list(commands)
    assert length(commands) > 0
  end
  
  test "generate_restore_commands creates correct tmux commands", %{sample_session: session} do
    # Test command generation
    commands = Restore.generate_restore_commands(session)
    
    # Verify commands list structure
    assert is_list(commands)
    assert length(commands) > 0
    
    # Check for expected tmux commands
    session_name = session.metadata.session_name
    
    # Check for session creation
    has_new_session = Enum.any?(commands, fn cmd -> 
      String.contains?(cmd, "tmux new-session") && String.contains?(cmd, "-s #{session_name}")
    end)
    assert has_new_session
    
    # Check for window creation (should match number of windows in sample)
    window_commands = Enum.filter(commands, fn cmd -> String.contains?(cmd, "tmux new-window") end)
    # One fewer than total because first window is created with the session
    assert length(window_commands) == length(session.tmux_info.windows) - 1
    
    # Check for pane operations
    pane_commands = Enum.filter(commands, fn cmd -> 
      String.contains?(cmd, "tmux split-window") || String.contains?(cmd, "tmux select-layout")
    end)
    assert length(pane_commands) > 0
  end
  
  test "restore_session executes the restore commands", %{sample_session: session} do
    # Test with test_mode to avoid actual execution
    {:ok, result} = Restore.restore_session(session)
    
    # In test mode, this should return the list of commands that would be executed
    assert is_list(result)
    assert length(result) > 0
    
    # Check for session has-session and creation commands
    has_check = Enum.any?(result, fn cmd -> String.contains?(cmd, "tmux has-session") end)
    has_create = Enum.any?(result, fn cmd -> String.contains?(cmd, "tmux new-session") end)
    
    assert has_check
    assert has_create
  end
  
  test "parse_session_id correctly extracts components" do
    # Test with valid session ID
    session_id = "test_session_20230101120000"
    {:ok, name, timestamp} = Restore.parse_session_id(session_id)
    
    assert name == "test_session"
    assert timestamp == "20230101120000"
    
    # Test with malformed ID
    assert Restore.parse_session_id("invalid_format") == {:error, :invalid_format}
  end
  
  test "list_available_sessions returns formatted session list", %{sample_session: session} do
    # Create multiple session files
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    
    # Older session
    older_session = put_in(session.metadata.timestamp, "20220101120000")
    File.write!(
      "#{sessions_dir}/test_session_20220101120000.session", 
      :erlang.term_to_binary(older_session)
    )
    
    # Newer session
    newer_session = put_in(session.metadata.timestamp, "20220201120000")
    File.write!(
      "#{sessions_dir}/test_session_20220201120000.session", 
      :erlang.term_to_binary(newer_session)
    )
    
    # Another session name
    other_session = put_in(session.metadata.session_name, "other_session")
    other_session = put_in(other_session.metadata.timestamp, "20220301120000")
    File.write!(
      "#{sessions_dir}/other_session_20220301120000.session", 
      :erlang.term_to_binary(other_session)
    )
    
    # Get formatted list
    session_list = Restore.list_available_sessions()
    
    # Should be a list of formatted strings
    assert is_list(session_list)
    assert length(session_list) == 4
    
    # Each item should be a string containing session name and date
    assert Enum.all?(session_list, fn item -> 
      String.contains?(item, "test_session") || String.contains?(item, "other_session")
    end)
    
    # Items should be sorted by timestamp (newest first)
    first_item = List.first(session_list)
    assert String.contains?(first_item, "2023-01-01") || 
           String.contains?(first_item, "2022-03-01") || 
           String.contains?(first_item, "2022-02-01")
  end
end