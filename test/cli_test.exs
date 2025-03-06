defmodule Pane.CLITest do
  use ExUnit.Case
  
  describe "no_attach_requested?/1" do
    test "returns true when no_attach is true" do
      opts = [no_attach: true]
      assert Pane.CLI.no_attach_requested?(opts)
    end
    
    test "returns true when attach is false" do
      opts = [attach: false]
      assert Pane.CLI.no_attach_requested?(opts)
    end
    
    test "returns true when both no_attach is true and attach is false" do
      opts = [no_attach: true, attach: false]
      assert Pane.CLI.no_attach_requested?(opts)
    end
    
    test "returns false when no_attach is false and attach is not specified" do
      opts = [no_attach: false]
      refute Pane.CLI.no_attach_requested?(opts)
    end
    
    test "returns false when attach is true and no_attach is not specified" do
      opts = [attach: true]
      refute Pane.CLI.no_attach_requested?(opts)
    end
    
    test "returns false when no relevant flags are specified" do
      opts = [preview: true, config: "test"]
      refute Pane.CLI.no_attach_requested?(opts)
    end
  end
end