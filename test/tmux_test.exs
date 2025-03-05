defmodule Pane.TmuxTest do
  use ExUnit.Case

  alias Pane.Tmux

  test "session_exists? generates correct command" do
    assert Tmux.session_exists?("test_session") == ~s(tmux has-session -t "test_session")
  end

  test "new_session generates correct command" do
    # Basic usage
    assert Tmux.new_session("test_session") == "tmux new-session -d -s test_session"

    # With options
    cmd = Tmux.new_session("test_session", cwd: "/home/user/code", window_name: "editor")
    assert cmd == ~s(tmux new-session -d -s test_session -c "/home/user/code" -n "editor")

    # Without detached mode
    cmd = Tmux.new_session("test_session", detached: false)
    assert cmd == "tmux new-session -s test_session"
  end

  test "new_window generates correct command" do
    # Basic usage
    assert Tmux.new_window("editor") == ~s(tmux new-window -n "editor")

    # With options
    cmd = Tmux.new_window("editor", cwd: "/home/user/code", target_session: "my_session")
    assert cmd == ~s(tmux new-window -t "my_session" -n "editor" -c "/home/user/code")
  end

  test "send_keys generates correct command" do
    # Basic usage with required target
    assert Tmux.send_keys("ls -la", target: "editor") ==
             ~s(tmux send-keys -t "editor" "ls -la" C-m)

    # With literal option
    cmd = Tmux.send_keys("echo 'Hello'", target: "editor", literal: true)
    assert cmd == ~s(tmux send-keys -l -t "editor" "echo 'Hello'" C-m)

    # Without enter
    cmd = Tmux.send_keys("cd /home", target: "editor", enter: false)
    assert cmd == ~s(tmux send-keys -t "editor" "cd /home")
  end

  test "split_window generates correct command" do
    # Default horizontal split
    assert Tmux.split_window() == "tmux split-window -h"

    # Vertical split
    assert Tmux.split_window(direction: :vertical) == "tmux split-window -v"

    # With all options
    cmd =
      Tmux.split_window(
        direction: :vertical,
        percent: 40,
        cwd: "/home/user/code",
        target: "editor",
        shell: "zsh"
      )

    assert cmd == ~s(tmux split-window -v -t "editor" -p 40 -c "/home/user/code" 'zsh')
  end

  test "select_pane generates correct command" do
    assert Tmux.select_pane("0") == ~s(tmux select-pane -t "0")
  end

  test "select_window generates correct command" do
    assert Tmux.select_window("my_session:0") == ~s(tmux select-window -t "my_session:0")
  end

  test "attach_session generates correct command" do
    assert Tmux.attach_session(target: "my_session") == ~s(tmux attach-session -t "my_session")
  end

  test "set_window_option generates correct command" do
    cmd = Tmux.set_window_option("main-pane-width", "120", target: "my_session:0")
    assert cmd == ~s(tmux set-window-option -t "my_session:0" main-pane-width 120)
  end

  test "set_option generates correct command" do
    cmd = Tmux.set_option("mouse", "on", target: "my_session")
    assert cmd == ~s(tmux set-option -t "my_session" mouse on)
  end

  test "list_sessions generates correct command" do
    assert Tmux.list_sessions() == "tmux list-sessions"
  end

  test "list_windows generates correct command" do
    assert Tmux.list_windows() == "tmux list-windows"
    assert Tmux.list_windows(target: "my_session") == ~s(tmux list-windows -t "my_session")
  end

  test "kill_session generates correct command" do
    assert Tmux.kill_session("my_session") == ~s(tmux kill-session -t "my_session")
  end

  test "kill_window generates correct command" do
    assert Tmux.kill_window("my_session:1") == ~s(tmux kill-window -t "my_session:1")
  end

  test "kill_pane generates correct command" do
    assert Tmux.kill_pane("my_session:1.2") == ~s(tmux kill-pane -t "my_session:1.2")
  end
end
