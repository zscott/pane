defmodule Pane.ConfigLayoutTest do
  use ExUnit.Case
  doctest Pane.Config

  alias Pane.Config

  test "normalize_config correctly processes layouts" do
    # Create a simple test config
    config_yaml = """
    session: test
    root: ~/projects
    defaultLayout: dev
    layouts:
      dev:
        template: TopSplitBottom
        panes:
          top: nvim
          bottomLeft: bash
          bottomRight: bash
      single:
        template: Single
        panes:
          main: "{command}"
    windows:
      - path: website
        layout: dev
      - command: k9s
        layout: single
    """

    # Write to a temporary file
    path = Path.join(System.tmp_dir!(), "pane_config_test.yaml")
    File.write!(path, config_yaml)

    # Load and normalize the config
    {:ok, raw_config} = YamlElixir.read_from_file(path)
    config = Config.atomize_keys(raw_config, true)
    |> Map.put_new(:defaultLayout, "dev")
    |> Map.put_new(:layouts, %{})
    |> Map.put_new(:windows, [])

    # Check the normalized layouts
    assert Map.has_key?(config, :layouts)
    assert Map.has_key?(config.layouts, :dev)
    assert Map.has_key?(config.layouts, :single)
    
    # Check layout templates
    assert config.layouts.dev.template == "TopSplitBottom"
    assert config.layouts.single.template == "Single"
    
    # Check panes
    assert config.layouts.dev.panes.top == "nvim"
    assert config.layouts.dev.panes.bottomLeft == "bash"
    assert config.layouts.dev.panes.bottomRight == "bash"
    assert config.layouts.single.panes.main == "{command}"

    # Clean up
    File.rm!(path)
  end

  test "atomize_keys correctly processes nested maps" do
    # Create a nested map
    map = %{
      "session" => "test",
      "layouts" => %{
        "dev" => %{
          "template" => "TopSplitBottom",
          "panes" => %{
            "top" => %{"cmd" => "nvim", "height" => 60},
            "bottomLeft" => "bash"
          }
        }
      }
    }

    # Convert keys to atoms
    result = Config.atomize_keys(map, true)
    
    # Check top level
    assert Map.has_key?(result, :session)
    assert Map.has_key?(result, :layouts)
    
    # Check nested levels
    assert Map.has_key?(result.layouts, :dev)
    assert Map.has_key?(result.layouts.dev, :template)
    assert Map.has_key?(result.layouts.dev, :panes)
    
    # Check deeply nested
    assert Map.has_key?(result.layouts.dev.panes, :top)
    assert Map.has_key?(result.layouts.dev.panes, :bottomLeft)
    
    # Check values
    assert result.layouts.dev.panes.top.cmd == "nvim"
    assert result.layouts.dev.panes.top.height == 60
    assert result.layouts.dev.panes.bottomLeft == "bash"
  end

  test "get_layout_config retrieves the correct layout" do
    # Create a test config
    config = %{
      session: "test",
      defaultLayout: "dev",
      layouts: %{
        dev: %{
          template: "TopSplitBottom",
          panes: %{
            top: "nvim",
            bottomLeft: "bash",
            bottomRight: "bash"
          }
        },
        single: %{
          template: "Single",
          panes: %{
            main: "{command}"
          }
        }
      }
    }

    # Get layout config
    layout = Pane.Layout.get_layout_config(config, "dev")
    
    # Check layout
    assert layout.template == "TopSplitBottom"
    assert layout.panes.top == "nvim"
    assert layout.panes.bottomLeft == "bash"
    assert layout.panes.bottomRight == "bash"
  end

  test "layouts are correctly included in command generation" do
    # Create a test config
    config = %{
      session: "test",
      root: "~/projects",
      defaultLayout: "dev",
      layouts: %{
        dev: %{
          template: "TopSplitBottom",
          panes: %{
            top: "nvim",
            bottomLeft: "bash",
            bottomRight: "bash"
          }
        },
        single: %{
          template: "Single",
          panes: %{
            main: "{command}"
          }
        }
      },
      windows: [
        %{
          path: "website",
          layout: "dev"
        },
        %{
          command: "k9s",
          layout: "single"
        }
      ]
    }

    # Generate commands
    commands = Pane.Command.generate_commands(config)
    
    # Check that we have commands for both windows
    assert length(commands) > 5  # Session check + windows + attach
    
    # Check layout commands are included
    assert Enum.any?(commands, &(&1 =~ "tmux split-window -v"))
    assert Enum.any?(commands, &(&1 =~ "tmux split-window -h"))
    assert Enum.any?(commands, &(&1 =~ "tmux send-keys"))
  end

  test "extracts camelCase keys from config following Kubernetes conventions" do
    config = Config.load_config("test/fixtures/test-config.yaml")
    
    # Test for camelCase keys
    assert Map.has_key?(config, :defaultLayout)
    
    # Check template pane keys
    dev_layout = Map.get(config.layouts, :dev)
    assert Map.has_key?(dev_layout.panes, :bottomLeft) 
    assert Map.has_key?(dev_layout.panes, :bottomRight)
  end
end