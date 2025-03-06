/**
 * Utility functions for Pane
 */
const { execSync } = require('child_process');

/**
 * Check if the current process is running in an interactive terminal.
 * Uses multiple methods to more reliably detect interactive terminals.
 * 
 * @returns {boolean} True if running in an interactive terminal
 */
function isInteractiveTerminal() {
  let testTty = false;
  let ttyCheck = false;
  let stdinCheck = false;
  let termCheck = false;
  
  // First approach: Check using test -t 0
  try {
    execSync('test -t 0', { stdio: 'pipe' });
    testTty = true;
  } catch (error) {
    testTty = false;
  }
  
  // Second approach: Check using tty command
  try {
    execSync('sh -c "tty | grep -v \'not a tty\' > /dev/null"', { stdio: 'pipe' });
    ttyCheck = true;
  } catch (error) {
    ttyCheck = false;
  }
  
  // Third approach: Check standard input as character device
  try {
    execSync('test -c /dev/stdin', { stdio: 'pipe' });
    stdinCheck = true;
  } catch (error) {
    stdinCheck = false;
  }
  
  // Fourth approach: Check TERM environment variable
  termCheck = !!process.env.TERM && process.env.TERM !== '';
  
  // Combine the results - if any method detects a terminal, consider it interactive
  return testTty || ttyCheck || stdinCheck || termCheck;
}

module.exports = {
  isInteractiveTerminal
};