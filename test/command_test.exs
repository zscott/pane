defmodule Pane.CommandTest do
  use ExUnit.Case
  
  describe "get_window_opts/1" do
    test "returns map with command when window has command" do
      window = %{command: "echo hello"}
      assert Pane.Command.get_window_opts(window) == %{command: "echo hello"}
    end
    
    test "returns empty map when window has no command" do
      window = %{path: "/some/path"}
      assert Pane.Command.get_window_opts(window) == %{}
    end
    
    test "returns empty map when window is empty" do
      window = %{}
      assert Pane.Command.get_window_opts(window) == %{}
    end
  end
end