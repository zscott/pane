.PHONY: help release-patch release-minor release-major version-info test test-unit test-scripts test-yaml

# Default target - show help
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Pane - Tmux Session Manager"
	@echo "==========================="
	@echo
	@echo "Usage: make [target]"
	@echo
	@echo "Targets:"
	@echo "  help          Show this help message"
	@echo "  version-info  Show current and next version information"
	@echo "  release-patch Create a new patch release (x.y.z → x.y.z+1)"
	@echo "  release-minor Create a new minor release (x.y.z → x.y+1.0)"
	@echo "  release-major Create a new major release (x.y.z → x+1.0.0)"
	@echo "  test          Run all tests (unit, scripts, yaml)"
	@echo "  test-unit     Run Elixir unit tests with mix test"
	@echo "  test-scripts  Run shell script test suite"
	@echo "  test-yaml     Run YAML parsing tests"
	@echo
	@scripts/version.sh info

# Show version information
version-info:
	@scripts/version.sh info

# Create releases
release-patch:
	@scripts/version.sh release patch

release-minor:
	@scripts/version.sh release minor

release-major:
	@scripts/version.sh release major
	
# Test targets
test: test-unit test-scripts test-yaml
	@echo "All tests passed!"

test-unit:
	@echo "Running Elixir unit tests..."
	@mix test

test-scripts:
	@echo "Running shell script tests..."
	@echo "Testing pane CLI functionality..."
	@./test/scripts/test_pane.sh
	@echo "Testing terminal detection..."
	@./test/scripts/detect_terminal.sh --verbose

test-yaml:
	@echo "Running YAML parsing tests..."
	@mix run test/test_yaml_parsing.exs
