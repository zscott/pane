defmodule Pane.TemplatesLayoutTest do
  use ExUnit.Case
  doctest Pane.Layout

  alias Pane.Layout
  alias Pane.Layout.Template
  alias Pane.Layout.Templates.TopSplitBottom
  alias Pane.Layout.Templates.SplitVertical
  alias Pane.Layout.Templates.Single

  test "template modules can be found by name" do
    assert Template.get_template_module("TopSplitBottom") == TopSplitBottom
    assert Template.get_template_module("SplitVertical") == SplitVertical
    assert Template.get_template_module("Single") == Single
  end

  test "template module listings work" do
    modules = Template.list_template_modules()
    assert TopSplitBottom in modules
    assert SplitVertical in modules
    assert Single in modules
  end

  test "template names can be listed" do
    names = Template.list_template_names()
    assert "TopSplitBottom" in names
    assert "SplitVertical" in names
    assert "Single" in names
  end

  test "TopSplitBottom template generates correct commands" do
    {commands, pane_targets} = TopSplitBottom.apply("session:0", "/home/user/project", %{})
    
    # Check generated commands
    assert length(commands) == 3
    
    # Vertical split for bottom section
    assert Enum.at(commands, 0) =~ "tmux split-window -v"
    assert Enum.at(commands, 0) =~ "-t \"session:0.0\""
    
    # Horizontal split for bottom right section
    assert Enum.at(commands, 1) =~ "tmux split-window -h"
    assert Enum.at(commands, 1) =~ "-t \"session:0.1\""
    
    # Select top pane at the end
    assert Enum.at(commands, 2) =~ "tmux select-pane -t \"session:0.0\""
    
    # Check pane targets
    assert pane_targets.top == "session:0.0"
    assert pane_targets.bottomLeft == "session:0.1"
    assert pane_targets.bottomRight == "session:0.2"
  end

  test "SplitVertical template generates correct commands" do
    {commands, pane_targets} = SplitVertical.apply("session:0", "/home/user/project", %{})
    
    # Check generated commands
    assert length(commands) == 2
    
    # Horizontal split for right section
    assert Enum.at(commands, 0) =~ "tmux split-window -h"
    assert Enum.at(commands, 0) =~ "-t \"session:0.0\""
    
    # Select left pane at the end
    assert Enum.at(commands, 1) =~ "tmux select-pane -t \"session:0.0\""
    
    # Check pane targets
    assert pane_targets.left == "session:0.0"
    assert pane_targets.right == "session:0.1"
  end

  test "Single template generates correct commands" do
    {commands, pane_targets} = Single.apply("session:0", "/home/user/project", %{})
    
    # Check generated commands - should be empty as single template doesn't need splits
    assert commands == []
    
    # Check pane targets
    assert pane_targets.main == "session:0.0"
  end

  test "Template.apply generates combined commands" do
    window_target = "session:0"
    cwd = "/home/user/project"
    commands = %{
      top: "nvim .",
      bottomLeft: "ls -la",
      bottomRight: "git status"
    }
    
    cmds = Template.apply("TopSplitBottom", window_target, cwd, commands)
    
    # Check for layout creation commands
    assert Enum.any?(cmds, &(&1 =~ "tmux split-window -v"))
    assert Enum.any?(cmds, &(&1 =~ "tmux split-window -h"))
    
    # Check for command execution
    assert Enum.any?(cmds, &(&1 =~ "tmux send-keys" && &1 =~ "nvim ."))
    assert Enum.any?(cmds, &(&1 =~ "tmux send-keys" && &1 =~ "ls -la"))
    assert Enum.any?(cmds, &(&1 =~ "tmux send-keys" && &1 =~ "git status"))
  end

  test "Layout.extract_commands handles different command formats" do
    # Simple string commands
    panes1 = %{top: "nvim", bottom: "bash"}
    assert Layout.extract_commands(panes1) == %{top: "nvim", bottom: "bash"}
    
    # Mixed formats
    panes2 = %{
      top: %{cmd: "nvim", height: 60},
      bottom: "bash"
    }
    assert Layout.extract_commands(panes2) == %{top: "nvim", bottom: "bash"}
    
    # String keys
    panes3 = %{"top" => "nvim", "bottom" => "bash"}
    assert Layout.extract_commands(panes3) == %{top: "nvim", bottom: "bash"}
  end

  test "Layout.extract_options extracts size options" do
    layout_config = %{
      template: "TopSplitBottom",
      panes: %{
        top: %{cmd: "nvim", height: 75},
        bottomLeft: "bash",
        bottomRight: "bash"
      }
    }
    
    options = Layout.extract_options(layout_config)
    assert options.topSize == 75
  end

  test "Layout.apply_layout combines everything correctly" do
    layout_config = %{
      template: "TopSplitBottom",
      panes: %{
        top: "nvim",
        bottomLeft: "zsh",
        bottomRight: "git status"
      }
    }
    
    cmds = Layout.apply_layout("session:0", "/home/user/project", layout_config)
    
    # Check that we get the expected number of commands
    assert length(cmds) == 6  # 3 for layout + 3 for commands
    
    # Check layout commands
    assert Enum.any?(cmds, &(&1 =~ "tmux split-window -v"))
    assert Enum.any?(cmds, &(&1 =~ "tmux split-window -h"))
    
    # Check command execution
    assert Enum.any?(cmds, &(&1 =~ "tmux send-keys" && &1 =~ "nvim"))
    assert Enum.any?(cmds, &(&1 =~ "tmux send-keys" && &1 =~ "zsh"))
    assert Enum.any?(cmds, &(&1 =~ "tmux send-keys" && &1 =~ "git status"))
  end
end