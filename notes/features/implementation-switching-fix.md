# Implementation Switching Bug Fix Notes

## Overview
This feature fixes a bug where the Elixir implementation is used by default in development mode instead of the Node.js implementation. The problem is that the `./pane.sh` script always uses the Elixir implementation, but it should be using wrapper.sh to select the correct implementation.

## Requirement Analysis
Based on examining the code:

1. The `pane` script in the project root correctly calls `scripts/wrapper.sh` which handles implementation selection
2. However, when using `./pane.sh` directly, it bypasses `wrapper.sh` and always uses the Elixir implementation
3. The implementation flag (`--elixir`) is not documented in the CLI help text

## Implementation Plan
1. Modify `pane.sh` to delegate to `wrapper.sh` like the `pane` script does
2. Update the CLI help text in both implementations to document the `--elixir` flag
3. Add a test that verifies the implementation switching works correctly

## Testing Approach
We'll test by:
1. Ensuring that `./pane.sh --help` shows the `--elixir` flag
2. Verifying that `./pane.sh --preview` shows the Node.js implementation by default
3. Checking that `./pane.sh --elixir --preview` correctly switches to the Elixir implementation