/**
 * A layout with two equal vertical panes side by side.
 * 
 * Pane names:
 * - left
 * - right
 */
const { TmuxPane } = require('../tmux');

/**
 * Returns the list of pane position names defined by this template.
 * 
 * @returns {string[]} Array of pane names
 */
function paneNames() {
  return ['left', 'right'];
}

/**
 * Creates the pane structure within a window.
 * 
 * @param {string} windowTarget - The target identifier for the window
 * @param {string} cwd - The current working directory 
 * @param {Object} options - Additional options
 * @returns {Object} Commands and pane targets
 */
function apply(windowTarget, cwd, options = {}) {
  // First pane is created by default with the window
  const leftTarget = `${windowTarget}.0`;
  
  // Create a right pane that's 50% of the window width
  const splitCommand = TmuxPane.split({ 
    target: leftTarget, 
    horizontal: true, 
    percentage: 50,
    cwd
  });
  
  // The new pane becomes pane 1
  const rightTarget = `${windowTarget}.1`;
  
  // Return commands and pane targets
  return {
    commands: [splitCommand],
    paneTargets: {
      left: leftTarget,
      right: rightTarget
    }
  };
}

module.exports = {
  paneNames,
  apply
};