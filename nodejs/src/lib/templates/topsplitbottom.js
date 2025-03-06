/**
 * A layout with a large top pane (60%) and two equal bottom panes (40% total).
 * 
 * Pane names:
 * - top
 * - bottomLeft
 * - bottomRight
 */
const { TmuxPane } = require('../tmux');

/**
 * Returns the list of pane position names defined by this template.
 * 
 * @returns {string[]} Array of pane names
 */
function paneNames() {
  return ['top', 'bottomLeft', 'bottomRight'];
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
  const topTarget = `${windowTarget}.0`;
  
  // Create a bottom pane that's 40% of the window height
  const splitCommand1 = TmuxPane.split({ 
    target: topTarget, 
    vertical: true, 
    percentage: 40,
    cwd
  });
  
  // The new pane becomes pane 1
  const bottomLeftTarget = `${windowTarget}.1`;
  
  // Create a bottom right pane by splitting the bottom left pane horizontally
  const splitCommand2 = TmuxPane.split({ 
    target: bottomLeftTarget, 
    horizontal: true, 
    percentage: 50,
    cwd
  });
  
  // The new pane becomes pane 2
  const bottomRightTarget = `${windowTarget}.2`;
  
  // Select the top pane to make it active
  const selectCommand = TmuxPane.select(topTarget);
  
  // Return commands and pane targets
  return {
    commands: [splitCommand1, splitCommand2, selectCommand],
    paneTargets: {
      top: topTarget,
      bottomLeft: bottomLeftTarget,
      bottomRight: bottomRightTarget
    }
  };
}

module.exports = {
  paneNames,
  apply
};