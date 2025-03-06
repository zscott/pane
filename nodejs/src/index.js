/**
 * Main entry point for the Pane application
 */
const { PaneConfig } = require('./lib/config');
const { PaneCommand } = require('./lib/command');
const { isInteractiveTerminal } = require('./lib/utils');

/**
 * Run the tmux session setup with the given configuration
 * 
 * @param {Object} config - The session configuration
 * @param {boolean} autoAttach - Whether to automatically attach to the session
 */
function run(config, autoAttach = false) {
  // Generate all tmux commands
  const commands = PaneCommand.generateCommands(config);
  
  // Check if session exists
  const [sessionCheckCmd, ...remainingCommands] = commands;
  
  // Last command is the attach command (used for reference only)
  const attachCmd = commands[commands.length - 1];
  
  // Execute session check command to determine if session exists
  const { execSync } = require('child_process');
  let sessionExists = false;
  
  try {
    execSync(`sh -c "${sessionCheckCmd}"`, { stdio: 'pipe' });
    sessionExists = true;
  } catch (error) {
    sessionExists = false;
  }
  
  // Only create windows if session doesn't exist
  if (!sessionExists) {
    // Execute each command except the session check and the attach command
    const commandsToRun = remainingCommands.slice(0, remainingCommands.length - 1);
    
    for (const cmd of commandsToRun) {
      try {
        execSync(`sh -c "${cmd}"`, { stdio: 'pipe' });
      } catch (error) {
        console.warn(`Warning: Command failed: ${cmd}`);
        console.warn(`Error: ${error.message}`);
      }
    }
  }
  
  // Extract session name from config
  const { session: sessionName } = config;
  
  // Check if we should auto-attach (based on the autoAttach parameter)
  if (autoAttach) {
    // Check if we're in a terminal environment
    const interactive = isInteractiveTerminal();
    
    // Log the detection result in verbose mode
    if (global.verbose) {
      console.log(`[INFO] Interactive terminal detection: ${interactive}`);
    }
    
    if (interactive) {
      // Tell the user what's happening
      console.log(`\nAttaching to tmux session '${sessionName}'...`);
      
      // Use a direct exec approach for attaching to tmux
      const execCmd = `exec tmux attach-session -t "${sessionName}"`;
      
      // Create a temporary execution script
      const fs = require('fs');
      const path = require('path');
      const tmp = require('tmp');
      
      const tempScript = `#!/bin/sh
# Automatically generated script for tmux attachment
${execCmd}
`;
      
      const scriptPath = tmp.tmpNameSync({ prefix: 'pane_attach_', postfix: '.sh' });
      fs.writeFileSync(scriptPath, tempScript);
      fs.chmodSync(scriptPath, 0o755);
      
      // Execute the script as a process replacement
      const { spawn } = require('child_process');
      spawn(scriptPath, [], {
        stdio: 'inherit',
        detached: true
      });
      
      // Small delay to ensure process starts
      setTimeout(() => {
        process.exit(0);
      }, 100);
    } else {
      // If we're not in an interactive terminal, just print instructions
      console.log(`\nTmux session '${sessionName}' is ready.`);
      console.log(`Cannot attach automatically - not running in an interactive terminal.`);
      console.log(`To attach to this session, run the following command in your terminal:`);
      console.log(`  tmux attach -t ${sessionName}`);
    }
  } else {
    // If autoAttach is false (--no-attach was specified), just print instructions
    console.log(`\nTmux session '${sessionName}' is ready.`);
    console.log(`To attach to this session, run the following command in your terminal:`);
    console.log(`  tmux attach -t ${sessionName}`);
    console.log(`\nRun this script with --preview to see the full list of commands executed.`);
  }
}

module.exports = {
  run
};