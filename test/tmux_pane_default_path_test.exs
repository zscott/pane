defmodule Pane.Tmux.PaneDefaultPathTest do
  use ExUnit.Case
  
  test "default_tmp_path is set to System.tmp_dir()" do
    # We can directly check the module attribute by using String.contains?
    # on the source code file
    source_code = File.read!("lib/pane/tmux/pane.ex")
    
    # Verify the module attribute is defined
    assert String.contains?(source_code, "@default_tmp_path System.tmp_dir()")
    
    # Verify we don't use hardcoded /tmp
    refute String.contains?(source_code, "|| \"/tmp\"")
    assert String.contains?(source_code, "|| @default_tmp_path")
  end
end