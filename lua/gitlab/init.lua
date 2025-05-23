-- /Users/ict/coding/the-glab.nvim/lua/gitlab/init.lua
local M = {}

---@class GitlabConfig
local default_config = {
  -- Default configuration options
  -- e.g., default_project = "",
}

-- Initialize M.config with a deepcopy of default_config.
-- This ensures that default_config itself is not modified and 
-- provides a clean base if setup is called multiple times.
M.config = vim.deepcopy(default_config)

--- Setup the plugin with user-provided configuration
---@param opts GitlabConfig? User configuration options
function M.setup(opts)
  -- This line re-calculates M.config based on the original default_config and new opts.
  -- vim.tbl_deep_extend with an empty table as the first target ensures a new table is created
  -- or that it correctly merges into a fresh version of defaults.
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
  -- You might want to validate glab installation and auth status here

  -- Commands should be defined once. If setup is called multiple times,
  -- avoid redefining commands. Check if they exist first or use a flag.
  if not M._commands_created then
    local function create_issue_command()
      -- 'gitlab.issue' should be requireable as 'lua/gitlab/issue.lua' exists.
      require('gitlab.issue').create_issue_ui()
    end

    vim.api.nvim_create_user_command(
      "GitlabCreateIssue",
      create_issue_command,
      { nargs = 0, desc = "Create a GitLab Issue" }
    )
    -- Add more commands here as features are developed
    M._commands_created = true
  end
end

return M