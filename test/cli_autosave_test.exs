defmodule Pane.CLI.AutoSaveTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  
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
    
    # Return test context
    %{
      test_sessions_dir: test_sessions_dir
    }
  end
  
  test "CLI parses --auto-save flag correctly" do
    {opts, _, _} = Pane.CLI.parse_args(["--auto-save"])
    assert Keyword.get(opts, :auto_save) == true
    
    # Test with other options
    {opts, _, _} = Pane.CLI.parse_args(["--auto-save", "--verbose"])
    assert Keyword.get(opts, :auto_save) == true
    assert Keyword.get(opts, :verbose) == true
    
    # Test default is false
    {opts, _, _} = Pane.CLI.parse_args([])
    assert Keyword.get(opts, :auto_save) == nil
  end
  
  test "CLI parses --auto-save-interval flag correctly" do
    {opts, _, _} = Pane.CLI.parse_args(["--auto-save-interval=10"])
    assert Keyword.get(opts, :auto_save_interval) == "10"
    
    # Test with other options
    {opts, _, _} = Pane.CLI.parse_args(["--auto-save", "--auto-save-interval=5"])
    assert Keyword.get(opts, :auto_save) == true
    assert Keyword.get(opts, :auto_save_interval) == "5"
  end
  
  test "CLI parses --restore flag correctly" do
    {opts, _, _} = Pane.CLI.parse_args(["--restore"])
    assert Keyword.get(opts, :restore) == true
    
    # Test with session name
    {opts, _, _} = Pane.CLI.parse_args(["--restore=test_session"])
    assert Keyword.get(opts, :restore) == "test_session"
    
    # Test default is false
    {opts, _, _} = Pane.CLI.parse_args([])
    assert Keyword.get(opts, :restore) == nil
  end
  
  test "CLI parses --restore-file flag correctly" do
    {opts, _, _} = Pane.CLI.parse_args(["--restore-file=/path/to/session.session"])
    assert Keyword.get(opts, :restore_file) == "/path/to/session.session"
  end
  
  test "CLI parses --list-sessions flag correctly" do
    {opts, _, _} = Pane.CLI.parse_args(["--list-sessions"])
    assert Keyword.get(opts, :list_sessions) == true
  end
  
  test "CLI help text includes auto-save and restore options" do
    # Capture IO output
    output = capture_io(fn ->
      Pane.CLI.main(["--help"])
    end)
    
    # Verify help text includes new options
    assert String.contains?(output, "--auto-save")
    assert String.contains?(output, "--auto-save-interval")
    assert String.contains?(output, "--restore")
    assert String.contains?(output, "--restore-file")
    assert String.contains?(output, "--list-sessions")
  end
  
  test "CLI processes auto-save flag correctly" do
    # Test that auto-save flag is processed
    output = capture_io(fn ->
      Pane.CLI.process([auto_save: true, preview: true])
    end)
    
    # Verify output mentions auto-save
    assert String.contains?(output, "Auto-save enabled")
  end
  
  test "CLI processes restore flag correctly" do
    # Create a test session file
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    
    sample_session = %{
      metadata: %{
        session_name: "test_session",
        timestamp: "20230101120000"
      },
      config: %{session: "test_session"},
      tmux_info: %{
        windows: [
          %{
            index: 0,
            name: "test",
            layout: "main-vertical",
            panes: [
              %{index: 0, current_path: "/tmp"}
            ]
          }
        ]
      }
    }
    
    session_file = "#{sessions_dir}/test_session_20230101120000.session"
    File.write!(session_file, :erlang.term_to_binary(sample_session))
    
    # Test with valid session
    output = capture_io(fn ->
      Pane.CLI.process([restore: "test_session", preview: true])
    end)
    
    # Verify output mentions restore
    assert String.contains?(output, "Restoring session") || 
           String.contains?(output, "restore")
  end
  
  test "CLI processes list-sessions flag correctly" do
    # Create some test session files
    sessions_dir = Application.get_env(:pane, :sessions_dir)
    
    # Sample session 1
    sample_session1 = %{
      metadata: %{
        session_name: "test_session1",
        timestamp: "20230101120000"
      },
      tmux_info: %{
        windows: []
      }
    }
    
    # Sample session 2
    sample_session2 = %{
      metadata: %{
        session_name: "test_session2",
        timestamp: "20230101130000"
      },
      tmux_info: %{
        windows: []
      }
    }
    
    # Save session files
    File.write!(
      "#{sessions_dir}/test_session1_20230101120000.session", 
      :erlang.term_to_binary(sample_session1)
    )
    
    File.write!(
      "#{sessions_dir}/test_session2_20230101130000.session", 
      :erlang.term_to_binary(sample_session2)
    )
    
    # Test list-sessions option
    output = capture_io(fn ->
      Pane.CLI.process([list_sessions: true])
    end)
    
    # Verify output contains session information
    assert String.contains?(output, "Available sessions")
    assert String.contains?(output, "test_session1") || String.contains?(output, "test_session2")
  end
end