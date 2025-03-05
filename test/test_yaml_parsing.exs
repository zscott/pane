defmodule YamlTest do
  def run do
    # Test raw YAML parsing
    {:ok, raw_config} = YamlElixir.read_from_file("config/default.yaml")
    IO.puts("Raw YAML config:")
    IO.inspect(raw_config, pretty: true)
    
    # Test processed config
    config = Pane.Config.load_config()
    IO.puts("\nProcessed config:")
    IO.inspect(config, label: "Loaded config", pretty: true)

    # Test getting a specific layout
    IO.puts("\nTesting layout resolution:")
    ["dev", "devLargeEditor", "aiCoding", "single"] 
    |> Enum.each(fn layout_name ->
      layout = Pane.Layout.get_layout_config(config, layout_name)
      template_name = layout.template
      module_name = 
        if is_atom(template_name), 
          do: Atom.to_string(template_name), 
          else: template_name
      template_module = Pane.Layout.Template.get_template_module(module_name)
      IO.puts("Layout '#{layout_name}' -> template '#{template_name}' -> module #{inspect(template_module)}")
    end)

    # Test window layout processing
    IO.puts("\nTesting window layout processing:")
    config.windows
    |> Enum.each(fn window ->
      layout_name = window[:layout] || config.defaultLayout
      layout = Pane.Layout.get_layout_config(config, layout_name)
      template_name = layout.template
      template_module = Pane.Layout.Template.get_template_module(template_name)
      
      # For windows with special layouts
      window_path = window[:path] || "command_window"
      is_special = layout_name == "aiCoding" || layout_name == "single"
      
      IO.puts("Window #{window_path} -> layout '#{layout_name}' -> template '#{template_name}' -> module #{inspect(template_module)} #{if is_special, do: "[SPECIAL]", else: ""}")
      
      # Debug commands generation for special windows
      if is_special do
        cwd = Path.expand("~/projects/#{window_path}")
        window_target = "test_session:0"
        window_opts = 
          if window[:command], 
            do: %{command: window.command}, 
            else: %{}
            
        # Generate and show the actual commands
        layout_cmds = Pane.Layout.apply_layout(window_target, cwd, layout, window_opts)
        IO.puts("  Generated commands for #{window_path}:")
        Enum.each(layout_cmds, fn cmd -> IO.puts("  $ #{cmd}") end)
        IO.puts("")
      end
    end)
    
    # Test the single window specifically
    single_window = Enum.find(config.windows, fn w -> Map.get(w, :command) == "k9s" end)
    if single_window do
      IO.puts("\nSpecial test for single window with k9s command:")
      layout_name = single_window[:layout] || config.defaultLayout
      layout = Pane.Layout.get_layout_config(config, layout_name)
      template_name = layout.template
      
      cwd = Path.expand("~/projects/")
      window_target = "test_session:1"
      window_opts = %{command: single_window.command}
      
      # Generate and show the actual commands
      layout_cmds = Pane.Layout.apply_layout(window_target, cwd, layout, window_opts)
      IO.puts("  Generated commands for k9s window:")
      Enum.each(layout_cmds, fn cmd -> IO.puts("  $ #{cmd}") end)
    end
  end
end

YamlTest.run()