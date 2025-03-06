# Curl Installation Permissions Bug Fix

## Issue
The curl installation command from the README fails because it requires sudo privileges but doesn't request them properly. The current command is:

```bash
curl -sSL https://raw.githubusercontent.com/zscott/pane/main/scripts/setup-combined.sh | bash
```

This fails with:
```
Setting up Pane (Combined Node.js and Elixir versions)...
This script requires sudo privileges to install to /usr/local
Please run: sudo bash
```

## Analysis
1. The setup-combined.sh script checks for write permissions to /usr/local and exits if they're not available
2. When piping the curl output to bash, there's no way to elevate privileges mid-script
3. The recommended fix "sudo bash" doesn't work in this context because it loses the piped input

## Potential Solutions
1. Update the README to use sudo with the curl command
2. Modify the setup script to use sudo internally for operations that require it
3. Change the installation directory to one that doesn't require sudo
4. Add a wrapper script that can re-execute itself with sudo
5. Use a two-step approach: download the script first, then run it with sudo

## Selected Approach
Initially, I chose to update the README to use `sudo bash` with the curl pipe command, but this has security implications because it runs unread code with elevated privileges.

After reconsideration, the safer approach is to use the two-step installation process:
1. Download the script first (so users can inspect it if desired)
2. Make it executable
3. Run it with sudo
4. Clean up afterward

This is more secure and follows the principle of least privilege, only using sudo when necessary.