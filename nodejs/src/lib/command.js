/**
 * Command generator for tmux operations
 */
const { execSync } = require('child_process');
const path = require('path');
const os = require('os');
const { TmuxSession, TmuxWindow, TmuxPane, TmuxLayout } = require('./tmux');
const { PaneLayout } = require('./layout');
const { isInteractiveTerminal } = require('./utils');

class PaneCommand {
  /**
   * Generate all tmux commands needed for the session, but only print them.
   * Shows enhanced diagnostic information in the preview mode.
   * 
   * @param {Object} config - The session configuration
   */
  static preview(config) {
    // Get real command list
    const realCommands = this.generateCommands(config);
    
    // Extract session name for further use (used in messages)
    const sessionName = config.session;
    
    // Run terminal detection tests directly
    let testTty = false;
    let ttyCheck = false;
    let stdinCheck = false;
    let termCheck = false;
    
    try {
      execSync('test -t 0', { stdio: 'pipe' });
      testTty = true;
    } catch (error) {
      testTty = false;
    }
    
    try {
      execSync('sh -c "tty | grep -v \'not a tty\' > /dev/null"', { stdio: 'pipe' });
      ttyCheck = true;
    } catch (error) {
      ttyCheck = false;
    }
    
    try {
      execSync('test -c /dev/stdin', { stdio: 'pipe' });
      stdinCheck = true;
    } catch (error) {
      stdinCheck = false;
    }
    
    termCheck = !!process.env.TERM && process.env.TERM !== '';
    
    // Format terminal detection output
    const terminalDetectionOutput = `# is_tty_0?
test -t 0
# result: ${testTty ? '0 (0=true, 1=false)' : '1 (0=true, 1=false)'}

# has_tty_device?
tty | grep -v "not a tty" > /dev/null
# result: ${ttyCheck ? '0 (0=true, 1=false)' : '1 (0=true, 1=false)'}

# is_stdin_char_device?
test -c /dev/stdin
# result: ${stdinCheck ? '0 (0=true, 1=false)' : '1 (0=true, 1=false)'}

# has_term_env?
[ -n "$TERM" ]
# result: ${termCheck ? '0 (0=true, 1=false)' : '1 (0=true, 1=false)'}`;
    
    // Determine if terminal is interactive based on the tests
    const isTerminalInteractive = isInteractiveTerminal();
    
    // Check if --no-attach flag was specified
    const noAttachSpecified = !!global.noAttach;
    
    // Determine if auto-attach would be attempted
    const wouldAutoAttach = !noAttachSpecified && isTerminalInteractive;
    
    // Check if session exists using first command
    const sessionCheckCmd = realCommands[0];
    
    // Actually check if the session exists
    let sessionExists = false;
    try {
      execSync(`sh -c "${sessionCheckCmd}"`, { stdio: 'pipe' });
      sessionExists = true;
    } catch (error) {
      sessionExists = false;
    }
    
    // Window names for display
    const windowNames = config.windows.map(window => 
      window.label || path.basename(window.path || 'command')
    );
    
    // Configuration section
    console.log('\n# Configuration');
    console.log('# -------------');
    console.log(`# Session: ${config.session}`);
    console.log(`# Config file: ${config.configPath}`);
    console.log(`#   root: ${config.root}`);
    console.log(`#   windows: [${windowNames.join(', ')}]`);
    
    // Terminal detection section
    console.log('\n\n# Terminal detection');
    console.log('# ------------------');
    console.log(terminalDetectionOutput);
    
    // Flag processing section
    console.log('\n# Flag processing');
    console.log('# --------------');
    console.log(`# --no-attach specified?: ${noAttachSpecified}`);
    console.log(`# can_auto_attach?: ${isTerminalInteractive}`);
    console.log(`# auto_attach_enabled?: ${wouldAutoAttach}`);
    
    // Session detection section
    console.log('\n\n# Session detection');
    console.log('# -----------------');
    console.log('# check for running session');
    console.log(sessionCheckCmd);
    console.log(`# session_running?: ${sessionExists}`);
    
    // TMux commands section
    console.log('\n\n# TMux commands that would be executed');
    const existingMsg = sessionExists 
      ? '# Session already exists, only missing windows will be created' 
      : '# Creating new session';
    console.log('# -----------------------------------');
    console.log(existingMsg);
    
    // Skip the session check command (already shown) and attach command (shown separately)
    const cmdsToShow = realCommands.slice(1, realCommands.length - 1);
    cmdsToShow.forEach(cmd => console.log(cmd));
    
    // Auto attach section
    const attachCmd = realCommands[realCommands.length - 1];
    console.log('\n# Auto attach command');
    console.log('# -----------------');
    if (wouldAutoAttach) {
      console.log(attachCmd);
    } else {
      console.log('# Would not auto-attach (--no-attach specified or not in an interactive terminal)');
      console.log('# To manually attach, you would run:');
      console.log(attachCmd);
    }
  }
  
  /**
   * Generate all tmux commands for the given configuration.
   * 
   * @param {Object} config - The session configuration
   * @returns {string[]} List of tmux commands
   */
  static generateCommands(config) {
    const { session, root, windows } = config;
    
    // Check if session exists command
    const sessionCheck = TmuxSession.exists(session);
    
    // Generate window creation commands
    const windowCommands = [];
    
    windows.forEach((window, index) => {
      // Determine if this is a path-based or command-only window
      let fullPath, windowLabel;
      
      if (window.path) {
        fullPath = path.resolve(root.replace(/^~/, os.homedir()), window.path);
        windowLabel = this.getWindowLabel(window);
      } else {
        // For command-only windows, use root dir and derive label from command
        const label = window.label || 
          (window.command && window.command.split(' ')[0]) || 'cmd';
        
        fullPath = path.resolve(root.replace(/^~/, os.homedir()));
        windowLabel = label;
      }
      
      // Get layout name for this window
      const layoutName = window.layout || config.defaultLayout || 'dev';
      
      // Log window creation if verbose mode
      if (global.verbose) {
        const windowType = index === 0 ? 'first window' : 'window';
        console.log(`[INFO] Creating ${windowType}: ${windowLabel} (layout: ${layoutName})`);
      }
      
      // Get the layout configuration
      const layoutConfig = PaneLayout.getLayoutConfig(config, layoutName);
      
      if (index === 0) {
        // First window - create session with a window
        const sessionCmd = TmuxSession.new(session, {
          cwd: fullPath,
          windowName: windowLabel,
          createOrAttach: true
        });
        
        windowCommands.push(sessionCmd);
        
        // Apply layout to the first window
        const windowTarget = `${session}:0`;
        
        // Pass window command to layout if available
        const windowOpts = window.command ? { command: window.command } : {};
        
        // Use the layout system for all layouts
        const layoutCmds = PaneLayout.applyLayout(windowTarget, fullPath, layoutConfig, windowOpts);
        windowCommands.push(...layoutCmds);
      } else {
        // Other windows - create a new window using index
        const windowCmd = TmuxWindow.new(windowLabel, {
          targetSession: session,
          cwd: fullPath,
          windowIndex: index
        });
        
        windowCommands.push(windowCmd);
        
        // Apply layout to this window
        const windowTarget = `${session}:${index}`;
        
        // Pass window command to layout if available
        const windowOpts = window.command ? { command: window.command } : {};
        
        // Use the layout system for all layouts
        const layoutCmds = PaneLayout.applyLayout(windowTarget, fullPath, layoutConfig, windowOpts);
        windowCommands.push(...layoutCmds);
      }
    });
    
    // Select first window and attach
    const finalCommands = [
      TmuxWindow.select(`${session}:0`),
      TmuxSession.attach({ target: session })
    ];
    
    // Full command set
    return [sessionCheck, ...windowCommands, ...finalCommands];
  }
  
  /**
   * Process a template command for command-only windows.
   * 
   * @param {string} command - The command to run
   * @param {Object} layoutConfig - The layout configuration
   * @param {string} windowTarget - The target window
   * @returns {string} The tmux command
   */
  static processTemplateCommand(command, layoutConfig, windowTarget) {
    // For command-only windows with the single layout,
    // we need to send the command to the main pane
    const template = layoutConfig.template;
    
    if (template === 'Single') {
      return TmuxPane.sendKeys(command, { target: `${windowTarget}.0` });
    } else {
      // For other layouts, we'd need to determine where to send the command
      // based on the layout configuration
      return TmuxPane.sendKeys(command, { target: `${windowTarget}.0` });
    }
  }
  
  /**
   * Get the window label, either from the config or derived from the path.
   * 
   * @param {Object} window - The window configuration
   * @returns {string} The window label
   */
  static getWindowLabel(window) {
    if (window.label) {
      return window.label;
    } else if (window.path) {
      // Use the last part of the path as the label
      return window.path.split('/').pop();
    } else if (window.command) {
      // Use the first word of the command as the label
      return window.command.split(' ')[0];
    } else {
      return 'window';
    }
  }
}

module.exports = {
  PaneCommand
};