#!/usr/bin/env elixir

# Determine project root
project_root = 
  case Path.basename(__DIR__) do
    "scripts" -> Path.join(__DIR__, "..")
    _ -> __DIR__
  end

# Add the lib directory to the code path
Code.prepend_path(Path.expand("_build/dev/lib/pane/ebin", project_root))
Code.prepend_path(Path.expand("lib", project_root))

# Check if deps are compiled, otherwise add _build/dev/lib/* to path
deps_path = Path.expand("_build/dev/lib", project_root)
if File.exists?(deps_path) do
  deps_paths = 
    deps_path
    |> File.ls!()
    |> Enum.map(fn dir -> Path.join([deps_path, dir, "ebin"]) end)
    |> Enum.filter(&File.exists?/1)
  
  Enum.each(deps_paths, &Code.prepend_path/1)
else
  # If no _build found, try to compile
  IO.puts("Initial compilation required...")
  
  if not File.exists?(Path.join(project_root, "mix.exs")) do
    IO.puts("Error: Could not find mix.exs in #{project_root}")
    System.halt(1)
  end
  
  try do
    {_, 0} = System.cmd("mix", ["deps.get"], cd: project_root, into: IO.stream(:stdio, :line))
    {_, 0} = System.cmd("mix", ["compile"], cd: project_root, into: IO.stream(:stdio, :line))
  rescue
    _ -> 
      IO.puts("Error compiling project")
      System.halt(1)
  end
  
  # Add the compiled paths again
  Code.prepend_path(Path.expand("_build/dev/lib/pane/ebin", project_root))
  
  if File.exists?(deps_path) do
    deps_paths = 
      deps_path
      |> File.ls!()
      |> Enum.map(fn dir -> Path.join([deps_path, dir, "ebin"]) end)
      |> Enum.filter(&File.exists?/1)
    
    Enum.each(deps_paths, &Code.prepend_path/1)
  end
end

# Execute the CLI
Pane.CLI.main(System.argv())