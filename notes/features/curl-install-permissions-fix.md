# Curl Installation Permissions Fix

## Issue
The combined installation script (`setup-combined.sh`) checks for sudo permissions at the beginning but doesn't handle them gracefully. When users try to install using the curl command from the README, they get:

```
Setting up Pane (Combined Node.js and Elixir versions)...
This script requires sudo privileges to install to /usr/local
Please run: sudo bash
```

But the recommendation to use `sudo bash` doesn't work in the curl pipe context.

## Analysis
I've identified the root causes:

1. The README currently points to `setup-combined.sh`, but this script doesn't handle sudo gracefully
2. The original `setup.sh` script already has proper sudo handling using a `USE_SUDO` variable
3. The `setup.sh` script contains a `setup_permissions()` function that:
   - Determines if sudo is needed
   - Warns the user they'll be prompted for their password
   - Uses the `USE_SUDO` variable before commands that need elevated privileges

## Solution
The simpler solution is to revert the README to use the original `setup.sh` script which already has proper sudo handling:

```bash
# Install using curl
curl -sSL https://raw.githubusercontent.com/zscott/pane/main/scripts/setup.sh | bash
```

This script is:
1. Intent-revealing rather than implementation-revealing (users don't need to know which implementations are being installed)
2. Properly handles sudo permissions when needed
3. Has more features (dependency checking, proper error handling, upgrade support)

By focusing on `setup.sh` instead of `setup-combined.sh`, we maintain a cleaner user interface that's more resilient to implementation changes.