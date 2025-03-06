#!/usr/bin/env node

/**
 * Command-line interface for Pane
 */
const { program } = require('commander');
const { PaneConfig } = require('../src/lib/config');
const { PaneCommand } = require('../src/lib/command');
const { run } = require('../src/index');
const { isInteractiveTerminal } = require('../src/lib/utils');
const { spawn } = require('child_process');
const fs = require('fs');
const tmp = require('tmp');

// Define CLI options
program
  .name('pane')
  .description('A tmux session manager for creating consistent development environments')
  .option('-p, --preview', 'Show commands without executing them')
  .option('-c, --config <config>', 'Use specific config name or file')
  .option('-v, --verbose', 'Show detailed information during execution')
  .option('-a, --attach', 'Directly attach to the session (run this from terminal)')
  .option('--no-attach', 'Create the session but don\'t automatically attach to it')
  .option('--print-session', 'Print the session name from the config and exit')
  .version('0.1.0');

// Parse command line arguments
program.parse(process.argv);

// Get the options
const opts = program.opts();

// Set global flags
if (opts.verbose) {
  global.verbose = true;
}

// Store the no-attach flag for preview mode
global.noAttach = !!opts.noAttach;

// Show help message
function showHelp() {
  console.log(`
Pane - A tmux session manager

Usage:
  pane [options]

Options:
  -p, --preview          Show commands without executing them
  -a, --attach           Directly attach to the session (run this from terminal)
  -c, --config=CONFIG    Use specific config name (e.g. -c myproject) or file (e.g. -c path/to/config.yaml)
  -v, --verbose          Show detailed information during execution
  --no-attach            Create the session but don't automatically attach to it
  --print-session        Print the session name from the config and exit
  -h, --help             Show this help message

Configuration:
  Configs are looked for in the following locations:
    1. As specified (if absolute path)
    2. ~/.config/pane/
    3. The project's config/ directory
  
  Default config (when no -c option) is loaded from:
    1. ~/.config/pane/default.yaml
    2. The project's config/default.yaml file

Examples:
  pane                   Create tmux session using default config and attach to it
  pane -c myproject      Use myproject.yaml config from standard locations
  pane --no-attach       Create session without attaching
  pane --preview         Preview the commands that would be executed
  pane --verbose         Show detailed logging during execution
  pane -v -p             Preview with verbose output
  pane --config=my.yaml  Use custom configuration file
`);
}

// Main process handler
async function process() {
  // Get config file name from command line options
  const configPath = opts.config;
  
  try {
    const config = await PaneConfig.loadConfig(configPath);
    
    if (opts.printSession) {
      console.log(config.session);
      return;
    }
    
    if (opts.preview) {
      // Set preview mode for debug output
      global.previewMode = true;
      
      // Check for no-attach flag
      const noAttach = opts.noAttach === true || opts.attach === false;
      if (noAttach) {
        global.noAttach = true;
      }
      
      PaneCommand.preview(config);
    } else if (opts.attach) {
      // Direct attach mode - execute the attach command directly
      const sessionName = config.session;
      
      // We still log interactive terminal detection for debugging purposes
      const isInteractive = isInteractiveTerminal();
      
      // Log detection result if in verbose mode
      if (global.verbose) {
        console.log('[INFO] Interactive terminal detection: ' + isInteractive);
        console.log('[INFO] Attempting direct attachment');
      }
      
      // Tell the user what's happening
      console.log(`\nAttaching to tmux session '${sessionName}'...`);
      
      // Use a direct exec approach for attaching to tmux
      const execCmd = `exec tmux attach-session -t "${sessionName}"`;
      
      // Create a temporary execution script
      const tempScript = `#!/bin/sh
# Automatically generated script for tmux attachment
${execCmd}
`;
      
      const scriptPath = tmp.tmpNameSync({ prefix: 'pane_attach_', postfix: '.sh' });
      fs.writeFileSync(scriptPath, tempScript);
      fs.chmodSync(scriptPath, 0o755);
      
      // Execute the script as a process replacement
      spawn(scriptPath, [], {
        stdio: 'inherit',
        detached: true
      });
      
      // Small delay to ensure process starts
      setTimeout(() => {
        process.exit(0);
      }, 100);
    } else {
      // Run in normal mode without preview
      global.previewMode = false;
      
      // Only auto-attach if --no-attach isn't specified
      const noAttach = opts.noAttach === true || opts.attach === false;
      const autoAttach = !noAttach;
      
      // Log the auto-attach setting in verbose mode
      if (global.verbose) {
        console.log(`[INFO] Auto-attach enabled: ${autoAttach}`);
      }
      
      run(config, autoAttach);
    }
  } catch (error) {
    console.error(`Error: Could not load configuration: ${error.message}`);
    process.exit(1);
  }
}

// Handle program options
if (program.args.length === 0 && Object.keys(opts).length === 0) {
  // No arguments or options - show help
  showHelp();
} else if (opts.help) {
  // Help option - show help
  showHelp();
} else {
  // Process other options
  process();
}