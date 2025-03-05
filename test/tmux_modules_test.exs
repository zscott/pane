defmodule Pane.TmuxModulesTest do
  use ExUnit.Case
  
  alias Pane.Tmux
  alias Pane.Tmux.Session
  alias Pane.Tmux.Window
  alias Pane.Tmux.Pane

  describe "Session module" do
    test "exists? returns correct command" do
      assert Session.exists?("my-session") == ~s(tmux has-session -t "my-session")
    end

    test "new creates correct command" do
      assert Session.new("my-session") == "tmux new-session -d -s my-session"
      assert Session.new("my-session", detached: false) == "tmux new-session -s my-session"
      assert Session.new("my-session", cwd: "/tmp") == ~s(tmux new-session -d -s my-session -c "/tmp")
    end

    test "attach creates correct command" do
      assert Session.attach(target: "my-session") == ~s(tmux attach-session -t "my-session")
    end
  end

  describe "Window module" do
    test "new creates correct command" do
      assert Window.new("my-window") == ~s(tmux new-window -n "my-window")
      assert Window.new("my-window", cwd: "/tmp") == ~s(tmux new-window -n "my-window" -c "/tmp")
    end

    test "set_option creates correct command" do
      assert Window.set_option("option", "value", target: "my-window") == 
        ~s(tmux set-window-option -t "my-window" option value)
    end
  end

  describe "Pane module" do
    test "split creates correct command" do
      assert Pane.split() == "tmux split-window -h"
      assert Pane.split(direction: :vertical) == "tmux split-window -v"
      assert Pane.split(percent: 30) == "tmux split-window -h -p 30"
    end

    test "send_keys creates correct command" do
      assert Pane.send_keys("echo hello", target: "0") == ~s(tmux send-keys -t "0" "echo hello" C-m)
      assert Pane.send_keys("echo hello", target: "0", enter: false) == ~s(tmux send-keys -t "0" "echo hello")
    end
  end


  describe "Facade module" do
    test "delegates to correct implementation" do
      assert Tmux.session_exists?("test") == Session.exists?("test")
      assert Tmux.new_window("test") == Window.new("test")
      assert Tmux.split_window() == Pane.split()
    end
  end
end