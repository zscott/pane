# YAML Configuration Naming Conventions

## Current State
The YAML configuration files in this project already follow Kubernetes-like naming conventions:

1. Field names use camelCase for compound words (e.g., `defaultLayout`, `bottomLeft`, `bottomRight`)
2. Simple field names use lowercase (e.g., `session`, `root`, `windows`, `template`, `panes`)
3. Template names use PascalCase (e.g., `TopSplitBottom`, `SplitVertical`, `Single`)

## Code Coupling
The Elixir codebase has tight coupling to these naming conventions:

1. The type definitions in `config.ex` use camelCase field names in the type specs
2. Functions reference these fields directly using the same casing (e.g., `config.defaultLayout`, `layout.panes.bottomLeft`)
3. The YAML parsing logic directly extracts these keys and converts them to atoms with the same casing

## Verification
A test has been added to verify the YAML naming conventions:

```elixir
test "extracts camelCase keys from config following Kubernetes conventions" do
  config = Config.load_config("test/fixtures/test-config.yaml")
  
  # Test for camelCase keys
  assert Map.has_key?(config, :defaultLayout)
  
  # Check template pane keys
  dev_layout = Map.get(config.layouts, :dev)
  assert Map.has_key?(dev_layout.panes, :bottomLeft) 
  assert Map.has_key?(dev_layout.panes, :bottomRight)
end
```