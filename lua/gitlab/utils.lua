-- lua/gitlab/utils.lua
local M = {}

-- Utility functions will go here
-- For example, functions to run shell commands, parse output, etc.

--- Runs a shell command and returns its output and exit code.
---@param cmd string The command to run.
---@param args table? A list of arguments for the command.
---@return string output, integer exit_code
function M.run_shell_command(cmd, args)
  args = args or {}
  local cmd_str = cmd .. " " .. table.concat(args, " ")
  local output = vim.fn.system(cmd_str)
  local exit_code = vim.v.shell_error
  return output, exit_code
end

return M