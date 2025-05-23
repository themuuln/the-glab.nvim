-- lua/gitlab/ui.lua
local NuiPopup = require('nui.popup')
local NuiInput = require('nui.input')
-- Add other Nui components as needed

local M = {}

-- This module will contain reusable UI components or UI helper functions.
-- For example, a generic input prompt or a selection list.

--- Creates a generic input prompt.
---@param opts table NuiInput options (border, size, position, etc.)
---@param input_opts table NuiInput constructor options (prompt, default_value, on_submit, etc.)
function M.create_input_prompt(opts, input_opts)
  local input_component = NuiInput(opts, input_opts)
  input_component:mount()

  input_component:on(require('nui.utils.autocmd').event.BufLeave, function()
    input_component:unmount()
  end)

  return input_component
end

return M