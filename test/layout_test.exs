defmodule Pane.Tmux.LayoutTest do
  use ExUnit.Case
  
  test "select creates correct command" do
    assert Pane.Tmux.Layout.select("main-vertical", target: "my-window") == 
      ~s(tmux select-layout -t "my-window" main-vertical)
  end

  test "next creates correct command" do
    assert Pane.Tmux.Layout.next(target: "my-window") == 
      ~s(tmux next-layout -t "my-window")
  end

  test "previous creates correct command" do
    assert Pane.Tmux.Layout.previous(target: "my-window") == 
      ~s(tmux previous-layout -t "my-window")
  end

  test "facade delegates correctly" do
    assert Pane.Tmux.select_layout("main-vertical", target: "win") == 
      Pane.Tmux.Layout.select("main-vertical", target: "win")
      
    assert Pane.Tmux.next_layout(target: "win") ==
      Pane.Tmux.Layout.next(target: "win")
      
    assert Pane.Tmux.previous_layout(target: "win") ==
      Pane.Tmux.Layout.previous(target: "win")
  end
end