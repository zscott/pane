defmodule Pane.AutoSaveTest do
  use ExUnit.Case
  
  alias Pane.AutoSave
  
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
    
    # Provide sample session config for testing
    sample_config = %{
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
    }
    
    # Return test context
    %{
      test_sessions_dir: test_sessions_dir,
      sample_config: sample_config
    }
  end
  
  test "auto_save creates sessions directory if it doesn't exist", %{sample_config: config} do
    # Delete sessions directory to test creation
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    File.rm_rf!(sessions_dir)
    
    # Call auto_save
    {:ok, session_file} = AutoSave.auto_save(config)
    
    # Verify directory was created
    assert File.exists?(sessions_dir)
    assert File.exists?(session_file)
  end
  
  test "auto_save creates a session state file with timestamp", %{sample_config: config} do
    {:ok, session_file} = AutoSave.auto_save(config)
    
    # File name should include session name and timestamp
    assert String.contains?(session_file, "test_session")
    assert String.match?(session_file, ~r/\d{14}/)
    
    # File should exist
    assert File.exists?(session_file)
  end
  
  test "auto_save captures session information correctly", %{sample_config: config} do
    {:ok, session_file} = AutoSave.auto_save(config)
    
    # Read the saved file
    {:ok, content} = File.read(session_file)
    saved_session = :erlang.binary_to_term(content)
    
    # Verify content
    assert saved_session.metadata.session_name == "test_session"
    assert saved_session.metadata.timestamp != nil
    assert saved_session.config.session == "test_session"
    assert saved_session.config.root == "/home/user/projects"
    assert length(saved_session.config.windows) == 2
    
    # Verify tmux session query commands
    assert saved_session.tmux_info != nil
  end
  
  test "get_latest_session returns nil when no sessions exist" do
    # Use empty directory
    empty_dir = "#{System.tmp_dir()}/pane_empty_#{:os.system_time(:millisecond)}"
    File.mkdir_p!(empty_dir)
    Application.put_env(:pane, :sessions_dir, empty_dir)
    
    assert AutoSave.get_latest_session("any_session") == nil
    
    # Clean up
    File.rm_rf!(empty_dir)
  end
  
  test "get_latest_session finds the most recent session file", %{sample_config: config} do
    # Create multiple session files with different timestamps
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    session_name = config.session
    
    # Create older file
    older_timestamp = "20230101120000"
    older_file = "#{sessions_dir}/#{session_name}_#{older_timestamp}.session"
    File.write!(older_file, :erlang.term_to_binary(%{metadata: %{timestamp: older_timestamp, session_name: session_name}}))
    
    # Create newer file
    newer_timestamp = "20230101120100"
    newer_file = "#{sessions_dir}/#{session_name}_#{newer_timestamp}.session"
    File.write!(newer_file, :erlang.term_to_binary(%{metadata: %{timestamp: newer_timestamp, session_name: session_name}}))
    
    # Test that get_latest_session returns the newest file
    latest_session = AutoSave.get_latest_session(session_name)
    assert latest_session != nil
    assert latest_session.metadata.timestamp == newer_timestamp
  end
  
  test "list_sessions returns empty list when no sessions exist" do
    # Use empty directory
    empty_dir = "#{System.tmp_dir()}/pane_empty_#{:os.system_time(:millisecond)}"
    File.mkdir_p!(empty_dir)
    Application.put_env(:pane, :sessions_dir, empty_dir)
    
    assert AutoSave.list_sessions() == []
    
    # Clean up
    File.rm_rf!(empty_dir)
  end
  
  test "list_sessions returns all available session files", %{} do
    # Create multiple session files for different sessions
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    
    # Create session 1
    File.write!(
      "#{sessions_dir}/session1_20230101120000.session", 
      :erlang.term_to_binary(%{metadata: %{session_name: "session1", timestamp: "20230101120000"}, tmux_info: %{windows: []}})
    )
    
    # Create session 2
    File.write!(
      "#{sessions_dir}/session2_20230101120100.session", 
      :erlang.term_to_binary(%{metadata: %{session_name: "session2", timestamp: "20230101120100"}, tmux_info: %{windows: []}})
    )
    
    # Test that list_sessions returns all sessions
    sessions = AutoSave.list_sessions()
    assert length(sessions) == 2
    assert Enum.any?(sessions, fn s -> s.metadata.session_name == "session1" end)
    assert Enum.any?(sessions, fn s -> s.metadata.session_name == "session2" end)
  end
  
  test "clean_old_sessions removes sessions older than retention period", %{sample_config: config} do
    # Create multiple session files with different timestamps
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    session_name = config.session
    
    # Use fixed dates for consistency
    past_date = "20220101120000"  # Jan 1, 2022
    recent_date = "20250101120000"  # Jan 1, 2025
    
    # Create old file (from 2022)
    old_file = "#{sessions_dir}/#{session_name}_#{past_date}.session"
    File.write!(old_file, :erlang.term_to_binary(%{
      metadata: %{
        timestamp: past_date, 
        session_name: session_name
      }
    }))
    
    # Create recent file (from 2025)
    recent_file = "#{sessions_dir}/#{session_name}_#{recent_date}.session"
    File.write!(recent_file, :erlang.term_to_binary(%{
      metadata: %{
        timestamp: recent_date, 
        session_name: session_name
      }
    }))
    
    # Test clean_old_sessions with 7-day retention
    AutoSave.clean_old_sessions(7)
    
    # Old file should be removed, recent file should remain
    refute File.exists?(old_file)
    assert File.exists?(recent_file)
  end
end