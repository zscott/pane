/**
 * Tests for the layout templates
 */
const assert = require('assert').strict;
const path = require('path');

// Import templates
const single = require('../src/lib/templates/single');
const splitVertical = require('../src/lib/templates/splitvertical');
const topSplitBottom = require('../src/lib/templates/topsplitbottom');
const quad = require('../src/lib/templates/quad');

// Run tests
function runTemplateTests() {
  console.log('Running Template test suite...');
  
  try {
    // Test single template
    console.log('Testing Single template...');
    const singleResult = single.apply('session:0', '/home/user/project');
    assert.deepStrictEqual(singleResult.commands, [], 'Single template should have no commands');
    assert.deepStrictEqual(singleResult.paneTargets, { main: 'session:0.0' }, 'Single template should have one pane target');
    
    // Test SplitVertical template
    console.log('Testing SplitVertical template...');
    const verticalResult = splitVertical.apply('session:0', '/home/user/project');
    assert.strictEqual(verticalResult.commands.length, 1, 'SplitVertical should have 1 command');
    assert(verticalResult.commands[0].includes('split-window') && verticalResult.commands[0].includes('-h'), 'Should have horizontal split');
    assert.deepStrictEqual(
      verticalResult.paneTargets, 
      { left: 'session:0.0', right: 'session:0.1' },
      'SplitVertical should have correct pane targets'
    );
    
    // Test TopSplitBottom template
    console.log('Testing TopSplitBottom template...');
    const topSplitResult = topSplitBottom.apply('session:0', '/home/user/project');
    assert.strictEqual(topSplitResult.commands.length, 3, 'TopSplitBottom should have 3 commands');
    assert(topSplitResult.commands[0].includes('split-window') && topSplitResult.commands[0].includes('-v'), 'Should have vertical split');
    assert(topSplitResult.commands[1].includes('split-window') && topSplitResult.commands[1].includes('-h'), 'Should have horizontal split');
    assert.deepStrictEqual(
      topSplitResult.paneTargets,
      { top: 'session:0.0', bottomLeft: 'session:0.1', bottomRight: 'session:0.2' },
      'TopSplitBottom should have correct pane targets'
    );
    
    // Test Quad template
    console.log('Testing Quad template...');
    const quadResult = quad.apply('session:0', '/home/user/project');
    assert.strictEqual(quadResult.commands.length, 4, 'Quad should have 4 commands');
    assert(quadResult.commands[0].includes('split-window') && quadResult.commands[0].includes('-v'), 'Should have vertical split');
    assert(quadResult.commands[1].includes('split-window') && quadResult.commands[1].includes('-h'), 'Should have horizontal split for top section');
    assert(quadResult.commands[2].includes('split-window') && quadResult.commands[2].includes('-h'), 'Should have horizontal split for bottom section');
    assert.deepStrictEqual(
      quadResult.paneTargets,
      { 
        topLeft: 'session:0.0', 
        topRight: 'session:0.2', 
        bottomLeft: 'session:0.1', 
        bottomRight: 'session:0.3' 
      },
      'Quad should have correct pane targets'
    );
    
    console.log('All template tests passed successfully!');
  } catch (error) {
    console.error('Test failed:', error.message);
    process.exit(1);
  }
}

// Run tests
runTemplateTests();