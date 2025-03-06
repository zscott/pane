defmodule Pane.CommandTemplateTest do
  use ExUnit.Case
  
  describe "process_template_command/3" do
    test "sends command to the first pane regardless of template" do
      # Given different templates
      layouts = [
        %{template: "Single"},
        %{template: "TopSplitBottom"},
        %{template: "SplitVertical"}
      ]
      
      # When applied to a window
      window_target = "session:0"
      command = "echo hello"
      
      results = Enum.map(layouts, fn layout ->
        Pane.Command.process_template_command(command, layout, window_target)
      end)
      
      # All should target the first pane (pane 0)
      Enum.each(results, fn result ->
        assert result =~ "-t \"session:0.0\""
        assert result =~ command
      end)
    end
  end
end