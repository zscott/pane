defmodule PaneTest do
  use ExUnit.Case
  doctest Pane

  test "commands are generated correctly" do
    config = %{
      session: "test_session",
      root: "/test/root",
      defaultLayout: "dev",
      layouts: %{
        dev: %{
          template: "TopSplitBottom",
          panes: %{
            top: "nvim",
            bottomLeft: "zsh",
            bottomRight: "zsh"
          }
        }
      },
      windows: [
        %{path: "window1", label: "test1", layout: "dev"},
        %{path: "window2/subdir", command: "echo hello", layout: "dev"}
      ]
    }

    commands = Pane.Command.generate_commands(config)

    # Check expected commands are present
    assert Enum.any?(commands, &String.match?(&1, ~r/tmux has-session/))
    assert Enum.any?(commands, &String.match?(&1, ~r/tmux new-session.*test_session/))
    assert Enum.any?(commands, &String.match?(&1, ~r/tmux new-window.*subdir/))
    assert Enum.any?(commands, &String.match?(&1, ~r/tmux split-window/))
    assert Enum.any?(commands, &String.match?(&1, ~r/tmux send-keys/))
    assert Enum.any?(commands, &String.match?(&1, ~r/tmux attach-session/))
  end

  test "preview shows all commands" do
    config = %{
      session: "preview_test",
      root: "/test/root",
      config_path: "/test/config.yaml",  # Add this line to fix the test
      defaultLayout: "dev",
      layouts: %{
        dev: %{
          template: "Single",
          panes: %{
            main: "nvim"
          }
        }
      },
      windows: [
        %{path: "window1", layout: "dev"}
      ]
    }

    # Capture the output of preview
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        Pane.Command.preview(config)
      end)

    # Verify output contains expected commands
    assert String.match?(output, ~r/tmux new-session.*preview_test/)
    assert String.match?(output, ~r/tmux send-keys/)
    assert String.match?(output, ~r/tmux attach-session/)
  end

  test "window label is derived from path if not specified" do
    # Test with explicit label
    window_with_label = %{path: "some/deep/path", label: "custom"}
    assert Pane.Command.get_window_label(window_with_label) == "custom"

    # Test with derived label from path
    window_without_label = %{path: "some/deep/path"}
    assert Pane.Command.get_window_label(window_without_label) == "path"
  end
end
