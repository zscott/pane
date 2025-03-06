/**
 * A layout with a single pane filling the entire window.
 * 
 * Pane names:
 * - main
 */

/**
 * Returns the list of pane position names defined by this template.
 * 
 * @returns {string[]} Array of pane names
 */
function paneNames() {
  return ['main'];
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
  // First pane is created by default with the window, so we just need to reference it
  const mainTarget = `${windowTarget}.0`;
  
  // No additional commands needed for a single pane
  const commands = [];
  
  // Return commands and a map of pane positions to targets
  return {
    commands,
    paneTargets: {
      main: mainTarget
    }
  };
}

module.exports = {
  paneNames,
  apply
};