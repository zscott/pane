/**
 * Tmux command abstractions
 */

/**
 * Session management commands
 */
class TmuxSession {
  /**
   * Check if a session exists
   * 
   * @param {string} session - The session name
   * @returns {string} Tmux command to check session existence
   */
  static exists(session) {
    return `tmux has-session -t "${session}" 2>/dev/null`;
  }
  
  /**
   * Create a new session
   * 
   * @param {string} session - The session name
   * @param {Object} opts - Session options
   * @returns {string} Tmux command to create a session
   */
  static new(session, opts = {}) {
    const options = [];
    
    // Add window name if provided
    if (opts.windowName) {
      options.push(`-n "${opts.windowName}"`);
    }
    
    // Add working directory if provided
    if (opts.cwd) {
      options.push(`-c "${opts.cwd}"`);
    }
    
    // Use -A flag to attach-or-create in a single command
    if (opts.createOrAttach) {
      options.push('-A');
    }
    
    // Add detached flag to prevent immediate attachment
    options.push('-d');
    
    return `tmux new-session ${options.join(' ')} -s "${session}"`;
  }
  
  /**
   * Attach to a session
   * 
   * @param {Object} opts - Session options
   * @returns {string} Tmux command to attach to a session
   */
  static attach(opts = {}) {
    const options = [];
    
    // Add target session if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    return `tmux attach-session ${options.join(' ')}`;
  }
  
  /**
   * List sessions
   * 
   * @returns {string} Tmux command to list sessions
   */
  static list() {
    return 'tmux list-sessions';
  }
  
  /**
   * Kill a session
   * 
   * @param {string} target - The session to kill
   * @returns {string} Tmux command to kill a session
   */
  static kill(target) {
    return `tmux kill-session -t "${target}"`;
  }
  
  /**
   * Set a session option
   * 
   * @param {string} option - Option name
   * @param {string} value - Option value
   * @param {Object} opts - Additional options
   * @returns {string} Tmux command to set a session option
   */
  static setOption(option, value, opts = {}) {
    const options = [];
    
    // Add target session if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    return `tmux set-option ${options.join(' ')} ${option} ${value}`;
  }
}

/**
 * Window management commands
 */
class TmuxWindow {
  /**
   * Create a new window
   * 
   * @param {string} name - The window name
   * @param {Object} opts - Window options
   * @returns {string} Tmux command to create a window
   */
  static new(name, opts = {}) {
    const options = [];
    
    // Add target session if provided
    if (opts.targetSession) {
      options.push(`-t "${opts.targetSession}"`);
    }
    
    // Add window index if provided
    if (opts.windowIndex !== undefined) {
      // Windows are zero-indexed in tmux
      options.push(`-a -t "${opts.targetSession}:${opts.windowIndex - 1}"`);
    }
    
    // Add working directory if provided
    if (opts.cwd) {
      options.push(`-c "${opts.cwd}"`);
    }
    
    // Add detached flag to prevent switching to this window
    options.push('-d');
    
    return `tmux new-window ${options.join(' ')} -n "${name}"`;
  }
  
  /**
   * Select a window
   * 
   * @param {string} target - The window to select
   * @returns {string} Tmux command to select a window
   */
  static select(target) {
    return `tmux select-window -t "${target}"`;
  }
  
  /**
   * List windows
   * 
   * @param {Object} opts - Window options
   * @returns {string} Tmux command to list windows
   */
  static list(opts = {}) {
    const options = [];
    
    // Add target session if provided
    if (opts.targetSession) {
      options.push(`-t "${opts.targetSession}"`);
    }
    
    return `tmux list-windows ${options.join(' ')}`;
  }
  
  /**
   * Kill a window
   * 
   * @param {string} target - The window to kill
   * @returns {string} Tmux command to kill a window
   */
  static kill(target) {
    return `tmux kill-window -t "${target}"`;
  }
  
  /**
   * Set a window option
   * 
   * @param {string} option - Option name
   * @param {string} value - Option value
   * @param {Object} opts - Additional options
   * @returns {string} Tmux command to set a window option
   */
  static setOption(option, value, opts = {}) {
    const options = [];
    
    // Add target window if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    return `tmux set-window-option ${options.join(' ')} ${option} ${value}`;
  }
}

/**
 * Pane management commands
 */
class TmuxPane {
  /**
   * Split a pane
   * 
   * @param {Object} opts - Split options
   * @returns {string} Tmux command to split a pane
   */
  static split(opts = {}) {
    const options = [];
    
    // Add target if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    // Add horizontal or vertical flag
    if (opts.horizontal) {
      options.push('-h');
    } else if (opts.vertical) {
      options.push('-v');
    }
    
    // Add percentage if provided
    if (opts.percentage) {
      options.push(`-p ${opts.percentage}`);
    }
    
    // Add working directory if provided
    if (opts.cwd) {
      options.push(`-c "${opts.cwd}"`);
    }
    
    return `tmux split-window ${options.join(' ')}`;
  }
  
  /**
   * Select a pane
   * 
   * @param {string} target - The pane to select
   * @returns {string} Tmux command to select a pane
   */
  static select(target) {
    return `tmux select-pane -t "${target}"`;
  }
  
  /**
   * Send keys to a pane
   * 
   * @param {string} keys - The keys to send
   * @param {Object} opts - Additional options
   * @returns {string} Tmux command to send keys
   */
  static sendKeys(keys, opts = {}) {
    const options = [];
    
    // Add target if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    // Create the command with proper shell change if needed
    let command = keys;
    
    // If a cwd is specified and the command doesn't already change directory
    if (opts.cwd && !command.startsWith('cd ')) {
      command = `cd "${opts.cwd}" && ${command}`;
    }
    
    return `tmux send-keys -t "${opts.target}" "${command.replace(/"/g, '\\"')}" C-m`;
  }
  
  /**
   * Kill a pane
   * 
   * @param {string} target - The pane to kill
   * @returns {string} Tmux command to kill a pane
   */
  static kill(target) {
    return `tmux kill-pane -t "${target}"`;
  }
}

/**
 * Layout management commands
 */
class TmuxLayout {
  /**
   * Select a layout
   * 
   * @param {string} layout - The layout name
   * @param {Object} opts - Additional options
   * @returns {string} Tmux command to select a layout
   */
  static select(layout, opts = {}) {
    const options = [];
    
    // Add target if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    return `tmux select-layout ${options.join(' ')} ${layout}`;
  }
  
  /**
   * Select the next layout
   * 
   * @param {Object} opts - Additional options
   * @returns {string} Tmux command to select the next layout
   */
  static next(opts = {}) {
    const options = [];
    
    // Add target if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    return `tmux next-layout ${options.join(' ')}`;
  }
  
  /**
   * Select the previous layout
   * 
   * @param {Object} opts - Additional options
   * @returns {string} Tmux command to select the previous layout
   */
  static previous(opts = {}) {
    const options = [];
    
    // Add target if provided
    if (opts.target) {
      options.push(`-t "${opts.target}"`);
    }
    
    return `tmux previous-layout ${options.join(' ')}`;
  }
}

module.exports = {
  TmuxSession,
  TmuxWindow,
  TmuxPane,
  TmuxLayout
};