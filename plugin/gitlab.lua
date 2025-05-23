-- Main plugin file for gitlab.nvim

local M = {}

---@class GitlabConfig
local default_config = {
  -- Default configuration options
  -- e.g., default_project = "",
}

M.config = default_config

--- Setup the plugin with user-provided configuration
---@param opts GitlabConfig? User configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {}, M.config, opts or {})
  -- You might want to validate glab installation and auth status here
end

-- Example command to be exposed
local function create_issue_command()
  require('gitlab.issue').create_issue_ui()
end

vim.api.nvim_create_user_command(
  "GitlabCreateIssue",
  create_issue_command,
  { nargs = 0, desc = "Create a GitLab Issue" }
)

-- Add more commands here as features are developed
-- e.g., GitlabCreateIssueBranch

return M