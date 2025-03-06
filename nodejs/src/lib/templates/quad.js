/**
 * A layout with four equal-sized panes arranged in a 2x2 grid.
 * 
 * Pane names:
 * - topLeft
 * - topRight
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
  return ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'];
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
  // This will be our topLeft pane
  const topLeftTarget = `${windowTarget}.0`;
  
  // Create a bottom pane that's 50% of the window height
  const splitCommand1 = TmuxPane.split({ 
    target: topLeftTarget, 
    vertical: true, 
    percentage: 50,
    cwd
  });
  
  // The new pane becomes pane 1
  const bottomLeftTarget = `${windowTarget}.1`;
  
  // Split the top pane horizontally to create top right pane
  const splitCommand2 = TmuxPane.split({ 
    target: topLeftTarget, 
    horizontal: true, 
    percentage: 50,
    cwd
  });
  
  // The new pane becomes pane 2
  const topRightTarget = `${windowTarget}.2`;
  
  // Split the bottom pane horizontally to create bottom right pane
  const splitCommand3 = TmuxPane.split({ 
    target: bottomLeftTarget, 
    horizontal: true, 
    percentage: 50,
    cwd
  });
  
  // The new pane becomes pane 3
  const bottomRightTarget = `${windowTarget}.3`;
  
  // Select the top left pane to make it active
  const selectCommand = TmuxPane.select(topLeftTarget);
  
  // Return commands and pane targets
  return {
    commands: [splitCommand1, splitCommand2, splitCommand3, selectCommand],
    paneTargets: {
      topLeft: topLeftTarget,
      topRight: topRightTarget,
      bottomLeft: bottomLeftTarget,
      bottomRight: bottomRightTarget
    }
  };
}

module.exports = {
  paneNames,
  apply
};