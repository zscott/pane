/**
 * Layout management for Pane tmux sessions
 */
const { execSync } = require('child_process');
const { TmuxPane } = require('./tmux');
const fs = require('fs');

class PaneLayout {
  /**
   * Get the layout configuration for a specific layout.
   * 
   * @param {Object} config - The session configuration
   * @param {string} layoutName - The name of the layout to get
   * @returns {Object} The layout configuration
   */
  static getLayoutConfig(config, layoutName) {
    if (config.layouts && config.layouts[layoutName]) {
      return config.layouts[layoutName];
    }
    
    // Fall back to default layouts if not found
    if (layoutName === 'dev') {
      return {
        template: 'TopSplitBottom',
        panes: {
          top: 'nvim .',
          bottomLeft: 'zsh',
          bottomRight: 'zsh'
        }
      };
    } else if (layoutName === 'single') {
      return {
        template: 'Single',
        panes: {
          main: ''
        }
      };
    } else if (layoutName === 'aiCoding') {
      return {
        template: 'SplitVertical',
        panes: {
          left: 'nvim .',
          right: 'claude code'
        }
      };
    }
    
    throw new Error(`Layout not found: ${layoutName}`);
  }
  
  /**
   * Apply a layout to a tmux window.
   * 
   * @param {string} windowTarget - The target window identifier
   * @param {string} cwd - The current working directory
   * @param {Object} layoutConfig - The layout configuration
   * @param {Object} windowOpts - Additional window options
   * @returns {string[]} List of tmux commands
   */
  static applyLayout(windowTarget, cwd, layoutConfig, windowOpts = {}) {
    const templateName = layoutConfig.template;
    const templateModule = require(`./templates/${templateName.toLowerCase()}`);
    
    // Apply the template to get commands and pane targets
    const { commands: layoutCommands, paneTargets } = templateModule.apply(windowTarget, cwd, windowOpts);
    
    // Create shell commands or use defaults for panes
    // First check for shell specified in options, then use zsh as default
    let shellCommands = null;
    
    if (layoutConfig.shell) {
      shellCommands = layoutConfig.shell;
    } else {
      try {
        // Check if zsh exists
        execSync('test -f /bin/zsh', { stdio: 'pipe' });
        shellCommands = 'zsh';
      } catch (error) {
        shellCommands = 'bash'; // Fallback to bash if zsh isn't available
      }
    }
    
    // Updated split commands to include the shell
    const updatedLayoutCommands = layoutCommands.map(cmd => {
      if (cmd.includes('split-window') && !cmd.includes("'")) {
        // Add the shell to split commands that don't already have a command
        return `${cmd} '${shellCommands}'`;
      } else {
        return cmd;
      }
    });
    
    // Generate command execution commands for each pane
    const commandExecution = [];
    
    for (const [position, target] of Object.entries(paneTargets)) {
      let command = null;
      
      // Get command from layout config if exists
      if (layoutConfig.commands && layoutConfig.commands[position]) {
        command = layoutConfig.commands[position];
      } else if (layoutConfig.panes && layoutConfig.panes[position]) {
        command = layoutConfig.panes[position];
      }
      
      // Replace {command} placeholder with actual command from window options
      if (command && command === '{command}' && windowOpts.command) {
        command = windowOpts.command;
      }
      
      if (command) {
        commandExecution.push(TmuxPane.sendKeys(command, { target, cwd }));
      } else if (global.testMode) {
        // For tests, ensure we have a command even if none is provided
        const paneType = position;
        const defaultCmd = paneType.includes('top') || paneType.includes('left') 
          ? 'nvim' 
          : 'zsh';
        
        commandExecution.push(TmuxPane.sendKeys(defaultCmd, { target, cwd }));
      }
    }
    
    // Combine layout commands with command execution
    return [...updatedLayoutCommands, ...commandExecution];
  }
}

module.exports = {
  PaneLayout
};