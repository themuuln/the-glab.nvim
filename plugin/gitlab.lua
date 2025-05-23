-- plugin/gitlab.lua
-- This file is sourced by Neovim at startup.
-- It should delegate to the main module in the lua/ directory.

-- Ensure the plugin's lua directory is on the runtime path if it's not already.
-- This is usually handled by the plugin manager, but can be added for robustness if needed.
-- package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

-- Require the main module. This will look for lua/gitlab.lua or lua/gitlab/init.lua.
local gitlab = require('gitlab')

-- If your plugin has a setup function that needs to be called automatically,
-- you can do it here, or instruct users to call it in their config.
-- For example, if you want to call setup with default options:
-- gitlab.setup({})

-- Or, more commonly, users will call setup from their Neovim configuration:
-- require('gitlab').setup({
--   -- user options
-- })

-- This file doesn't need to return anything specific unless other parts of
-- Neovim's startup process expect it for this specific plugin structure.
-- Often, plugin/ files don't return anything or return a minimal table if needed.