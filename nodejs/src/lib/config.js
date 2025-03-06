/**
 * Configuration handling for Pane
 */
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const os = require('os');

class PaneConfig {
  // Configuration constants
  static DEFAULT_CONFIG_DIR = path.join(os.homedir(), '.config', 'pane');
  static DEFAULT_CONFIG_FILE = 'default.yaml';
  static FALLBACK_CONFIG_PATH = path.join(__dirname, '..', '..', 'config', 'default.yaml');
  
  /**
   * Load and return the configuration from the specified YAML file,
   * or from the default location if not specified.
   * 
   * @param {string|null} configFile - The config file name or path
   * @returns {Promise<Object>} The configuration object
   */
  static async loadConfig(configFile = null) {
    const configPath = await this.resolveConfigPath(configFile);
    
    // Log configuration file path if verbose mode
    if (global.verbose) {
      console.log(`[INFO] Loading configuration from: ${configPath}`);
    }
    
    try {
      const config = await this.readYamlConfig(configPath);
      const normalized = this.normalizeConfig(config);
      
      // Store the actual config path that was used in the configuration
      normalized.configPath = configPath;
      
      // Log session and layout info if verbose
      if (global.verbose) {
        console.log(`[INFO] Session name: ${normalized.session}`);
        console.log(`[INFO] Root directory: ${normalized.root}`);
        console.log(`[INFO] Default layout: ${normalized.defaultLayout}`);
        console.log(`[INFO] Available layouts: ${Object.keys(normalized.layouts).join(', ')}`);
        console.log(`[INFO] Windows: ${normalized.windows.length}`);
      }
      
      return normalized;
    } catch (error) {
      console.warn(`Failed to load config from '${configPath}': ${error.message}`);
      throw error;
    }
  }
  
  /**
   * Returns the path to the config directory, ensuring it exists.
   * 
   * @returns {string} Path to the config directory
   */
  static configDir() {
    const dir = this.DEFAULT_CONFIG_DIR;
    
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    return dir;
  }
  
  /**
   * Returns the default config file path.
   * 
   * @returns {string} Path to the default config file
   */
  static defaultConfigPath() {
    return path.join(this.configDir(), this.DEFAULT_CONFIG_FILE);
  }
  
  /**
   * Resolve the config path, checking multiple locations.
   * 
   * @param {string|null} configPath - The config file name or path
   * @returns {Promise<string>} The resolved config path
   */
  static async resolveConfigPath(configPath) {
    if (configPath === null) {
      // Use default.yaml config when no config is specified
      // Check standard locations in order
      if (fs.existsSync(this.defaultConfigPath())) {
        return this.defaultConfigPath();
      } else if (fs.existsSync(this.FALLBACK_CONFIG_PATH)) {
        return this.FALLBACK_CONFIG_PATH;
      } else {
        // Return default path even if it doesn't exist yet
        return this.defaultConfigPath();
      }
    }
    
    // Check if the path is just a name without extension or path
    if (!configPath.includes('/') && !configPath.includes('.')) {
      configPath = `${configPath}.yaml`;
    }
    
    // Check in several locations:
    // 1. As provided (absolute path)
    // 2. In the user's config directory
    // 3. In the project's config directory
    const expandedPath = path.resolve(configPath);
    
    if (fs.existsSync(expandedPath)) {
      return expandedPath;
    }
    
    const userPath = path.join(this.configDir(), configPath);
    if (fs.existsSync(userPath)) {
      return userPath;
    }
    
    const projectPath = path.join(path.dirname(this.FALLBACK_CONFIG_PATH), path.basename(configPath));
    if (fs.existsSync(projectPath)) {
      return projectPath;
    }
    
    // Return the expanded path even if it doesn't exist
    return expandedPath;
  }
  
  /**
   * Read and parse a YAML config file.
   * 
   * @param {string} filePath - Path to the YAML file
   * @returns {Promise<Object>} Parsed YAML content
   */
  static async readYamlConfig(filePath) {
    if (fs.existsSync(filePath)) {
      try {
        const content = fs.readFileSync(filePath, 'utf8');
        return yaml.load(content);
      } catch (error) {
        throw new Error(`Failed to parse YAML file: ${error.message}`);
      }
    } else {
      throw new Error('Config file not found');
    }
  }
  
  /**
   * Normalize configuration to expected format.
   * 
   * @param {Object} config - Raw configuration object
   * @returns {Object} Normalized configuration
   */
  static normalizeConfig(config) {
    // Get values from raw config
    const rawWindows = config.windows || [];
    const rawLayouts = config.layouts || {};
    const defaultLayout = config.defaultLayout || 'dev';
    
    // Extract basic fields, excluding windows and layouts
    const configWithoutSpecial = { ...config };
    delete configWithoutSpecial.windows;
    delete configWithoutSpecial.layouts;
    
    // Process windows preserving original layout values
    const windows = rawWindows.map(window => {
      // Keep the original layout key
      const originalLayout = window.layout;
      
      // Process window without the layout
      const windowWithoutLayout = { ...window };
      delete windowWithoutLayout.layout;
      
      // Create a normalized window object
      const normalizedWindow = {
        ...windowWithoutLayout,
        label: windowWithoutLayout.label || null,
        command: windowWithoutLayout.command || null
      };
      
      // Add original layout or default if not specified
      return {
        ...normalizedWindow,
        layout: originalLayout || defaultLayout
      };
    });
    
    // Process the raw layouts, preserving original keys
    let layouts = {};
    if (Object.keys(rawLayouts).length > 0) {
      // Convert each layout independently
      for (const [name, layoutConfig] of Object.entries(rawLayouts)) {
        const template = layoutConfig.template;
        const panes = layoutConfig.panes || {};
        
        // Create processed layout config
        layouts[name] = {
          template,
          panes: { ...panes }
        };
        
        // Add shell if specified
        if (layoutConfig.shell) {
          layouts[name].shell = layoutConfig.shell;
        }
        
        // Add commands if specified
        if (layoutConfig.commands) {
          layouts[name].commands = layoutConfig.commands;
        }
      }
    } else {
      // Default layouts
      layouts = {
        dev: {
          template: 'TopSplitBottom',
          panes: {
            top: 'nvim .',
            bottomLeft: 'zsh',
            bottomRight: 'zsh'
          }
        },
        single: {
          template: 'Single',
          panes: {
            main: ''
          }
        }
      };
    }
    
    // Add aiCoding layout if it doesn't exist
    if (!layouts.aiCoding) {
      layouts.aiCoding = {
        template: 'SplitVertical',
        panes: {
          left: 'nvim .',
          right: 'claude code'
        }
      };
    }
    
    // Return standardized config map
    return {
      session: configWithoutSpecial.session || 'layr8',
      root: configWithoutSpecial.root || '~/',
      defaultLayout: configWithoutSpecial.defaultLayout || 'dev',
      layouts,
      windows
    };
  }
}

module.exports = {
  PaneConfig
};