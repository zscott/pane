/**
 * Basic test for Pane functionality
 */
const { spawn } = require('child_process');
const path = require('path');
const assert = require('assert').strict;

// Path to pane script
const panePath = path.resolve(__dirname, '../bin/pane.js');

// Set test environment
process.env.NODE_ENV = 'test';
global.testMode = true;

// Helper function to run pane with arguments
function runPane(args = []) {
  return new Promise((resolve, reject) => {
    const output = [];
    const errors = [];
    
    const proc = spawn('node', [panePath, ...args], {
      env: { ...process.env, NODE_ENV: 'test' }
    });
    
    proc.stdout.on('data', (data) => {
      output.push(data.toString());
    });
    
    proc.stderr.on('data', (data) => {
      errors.push(data.toString());
    });
    
    proc.on('close', (code) => {
      if (code === 0) {
        resolve({
          output: output.join(''),
          errors: errors.join('')
        });
      } else {
        reject(new Error(`Process exited with code ${code}: ${errors.join('')}`));
      }
    });
  });
}

// Test cases
async function runTests() {
  console.log('Running Pane test suite...');
  
  try {
    // Test help option - Commander displays help output on stdout
    console.log('Testing --help option...');
    const helpResult = await runPane(['--help']);
    assert(helpResult.output.includes('A tmux session manager'), 'Help output should include description');
    
    // Test preview with configuration option
    console.log('Testing --preview option with config...');
    const previewResult = await runPane(['--preview', '--config', '../config/default.yaml']);
    assert(previewResult.output.includes('# Configuration'), 'Preview should show Configuration section');
    assert(previewResult.output.includes('# TMux commands that would be executed'), 'Preview should show commands');
    
    // Test version option
    console.log('Testing --version option...');
    const versionResult = await runPane(['--version']);
    assert(versionResult.output.includes('0.1.0'), 'Version should be displayed');
    
    console.log('All tests passed successfully!');
  } catch (error) {
    console.error('Test failed:', error.message);
    process.exit(1);
  }
}

// Run tests
runTests();