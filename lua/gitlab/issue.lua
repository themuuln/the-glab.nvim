-- lua/gitlab/issue.lua
local NuiPopup = require('nui.popup')
local NuiInput = require('nui.input')
local NuiLine = require('nui.line')
local NuiText = require('nui.text')
local NuiLayout = require('nui.layout')
local NuiSplit = require('nui.split')
local event = require('nui.utils.autocmd').event

local M = {}

local function get_current_project_name()
  -- Try to get project name from git remote
  local remote_output = vim.fn.system('git remote get-url origin')
  if vim.v.shell_error ~= 0 then
    vim.notify("Could not get git remote 'origin'. Make sure you are in a git repository.", vim.log.levels.WARN)
    return nil
  end

  local project_name = remote_output:match(".*[:/]([^/]+/[^/]+)%.git$")
                      or remote_output:match(".*[:/]([^/]+/[^/]+)$") -- for HTTPS URLs without .git

  if not project_name then
    vim.notify("Could not parse project name from git remote 'origin'.", vim.log.levels.WARN)
    return nil
  end
  return project_name:gsub("^gitlab%.com/", "") -- Remove gitlab.com/ prefix if present
end

function M.create_issue_ui()
  local project_name = get_current_project_name()
  if not project_name then
    vim.notify("Failed to determine GitLab project. Cannot create issue.", vim.log.levels.ERROR)
    return
  end

  local title_input = NuiInput({
    position = "50%",
    size = {
      width = "80%",
      height = 1,
    },
    border = {
      style = "single",
      text = {
        top = "Issue Title",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    prompt = "> ",
    default_value = "",
    on_submit = function(value)
      -- Store title and open description input
      M.create_issue_description_ui(project_name, value)
    end,
  })

  -- Mount the component
  title_input:mount()

  -- Unmount component when cursor leaves buffer
  title_input:on(event.BufLeave, function()
    title_input:unmount()
  end)
end

function M.create_issue_description_ui(project_name, issue_title)
  local description_input = NuiInput({
    position = "50%",
    size = {
      width = "80%",
      height = 10, -- Allow for multi-line description
    },
    border = {
      style = "single",
      text = {
        top = "Issue Description (Ctrl-D to submit, Ctrl-C to cancel)",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
      wrap = true,
    },
  }, {
    prompt = "> ",
    default_value = "",
    on_submit = function(value)
      M.create_gitlab_issue(project_name, issue_title, value)
    end,
  })

  description_input:mount()

  description_input:on(event.BufLeave, function()
    description_input:unmount()
  end)

  -- Custom keymap for submitting with Ctrl-D
  vim.api.nvim_buf_set_keymap(description_input.bufnr, 'i', '<C-d>', '<Esc><Cmd>lua require("nui.input").submit()<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(description_input.bufnr, 'n', '<C-d>', '<Cmd>lua require("nui.input").submit()<CR>', { noremap = true, silent = true })
  -- Custom keymap for cancelling with Ctrl-C
  vim.api.nvim_buf_set_keymap(description_input.bufnr, 'i', '<C-c>', '<Esc><Cmd>lua require("nui.input").close()<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(description_input.bufnr, 'n', '<C-c>', '<Cmd>lua require("nui.input").close()<CR>', { noremap = true, silent = true })
end

function M.create_gitlab_issue(project_name, title, description)
  if not title or title == "" then
    vim.notify("Issue title cannot be empty.", vim.log.levels.ERROR)
    return
  end

  local cmd = string.format("glab issue create -t %s -d %s -R %s",
    vim.fn.shellescape(title),
    vim.fn.shellescape(description),
    vim.fn.shellescape(project_name)
  )

  vim.notify(string.format("Creating issue: %s", title))
  local output = vim.fn.system(cmd)

  if vim.v.shell_error == 0 then
    vim.notify(string.format("Issue created successfully!\n%s", output), vim.log.levels.INFO)
    -- Ask to create a branch for this issue
    M.ask_create_branch_for_issue(output)
  else
    vim.notify(string.format("Failed to create issue.\nError: %s", output), vim.log.levels.ERROR)
  end
end

function M.ask_create_branch_for_issue(issue_creation_output)
  local issue_url = issue_creation_output:match("(https://[%w%p%-]+)")
  if not issue_url then
    vim.notify("Could not parse issue URL from glab output.", vim.log.levels.WARN)
    return
  end

  local issue_iid = issue_url:match("/issues/(%d+)$")
  if not issue_iid then
    vim.notify("Could not parse issue IID from URL: " .. issue_url, vim.log.levels.WARN)
    return
  end

  local project_name = get_current_project_name()
  if not project_name then return end

  local popup = NuiPopup({
    enter = true,
    focusable = true,
    border = {
      style = "single",
      text = {
        top = "Create branch for issue #" .. issue_iid .. "?",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = "40%",
      height = 3,
    },
  })

  local yes_button = NuiText(" Yes ")
  local no_button = NuiText(" No ")

  local line = NuiLine()
  line:append(yes_button, { "FloatButtonActive", "FloatButton" })
  line:append(NuiText("  ")) -- Spacer
  line:append(no_button, { "FloatButtonActive", "FloatButton" })

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)

  popup:map("n", "q", function()
    popup:unmount()
  end, { noremap = true, silent = true })

  popup:map("n", "<CR>", function()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local selected_text = vim.api.nvim_buf_get_lines(popup.bufnr, current_line - 1, current_line, false)[1]
    if selected_text:match("Yes") then
      M.create_branch_for_issue(project_name, issue_iid)
    end
    popup:unmount()
  end, { noremap = true, silent = true })

  popup:map("n", "Y", function() M.create_branch_for_issue(project_name, issue_iid) popup:unmount() end, { noremap = true, silent = true, desc = "Create branch" })
  popup:map("n", "y", function() M.create_branch_for_issue(project_name, issue_iid) popup:unmount() end, { noremap = true, silent = true, desc = "Create branch" })
  popup:map("n", "N", function() popup:unmount() end, { noremap = true, silent = true, desc = "Do not create branch" })
  popup:map("n", "n", function() popup:unmount() end, { noremap = true, silent = true, desc = "Do not create branch" })

  popup:mount(NuiLayout(
    { position = "50%", relative = "editor" },
    NuiSplit({ direction = "col" }, NuiText("")), -- Dummy to center the line
    NuiSplit({ direction = "col" }, line)
  ))
end

function M.create_branch_for_issue(project_name, issue_iid)
  -- Generate a branch name from the issue title (simplified)
  -- You might want a more sophisticated way to get the issue title here
  -- For now, we'll use a generic name
  local branch_name = string.format("issue/%s", issue_iid)

  local cmd = string.format("glab issue view %s -R %s --json title", issue_iid, vim.fn.shellescape(project_name))
  local issue_json_str = vim.fn.system(cmd)
  local issue_title = ""
  if vim.v.shell_error == 0 and issue_json_str ~= "" then
    local ok, issue_data = pcall(vim.fn.json_decode, issue_json_str)
    if ok and issue_data and issue_data.title then
      issue_title = issue_data.title
      -- Sanitize title for branch name
      branch_name = string.format("issue/%s-%s", issue_iid, issue_title:lower():gsub("[^%w%-]", "-"):gsub("%-%-+%", "-"):gsub("^%-*", ""):gsub("%-*$", ""))
      -- Truncate if too long
      if #branch_name > 50 then branch_name = branch_name:sub(1, 50) end
    else
      vim.notify("Could not parse issue title from glab output to create a better branch name.", vim.log.levels.WARN)
    end
  else
    vim.notify("Could not fetch issue title to create a better branch name. Using generic name.", vim.log.levels.WARN)
  end

  local create_branch_cmd = string.format("glab mr create --create-source-branch -t %s -d %s --source-branch %s -R %s",
    vim.fn.shellescape("Draft: MR for issue #" .. issue_iid .. (": " .. issue_title):gsub("'", "\\'")),
    vim.fn.shellescape("Resolves issue #" .. issue_iid),
    vim.fn.shellescape(branch_name),
    vim.fn.shellescape(project_name)
  )
  -- The above command creates an MR and the branch if it doesn't exist.
  -- A simpler alternative if you only want the branch:
  -- local create_branch_cmd = string.format("git checkout -b %s", vim.fn.shellescape(branch_name))
  -- followed by git push -u origin branch_name
  -- and then potentially `glab mr create --autofill ...`
  -- For now, `glab mr create --create-source-branch` is more direct for the user's request.

  vim.notify(string.format("Creating branch '%s' and MR for issue #%s...", branch_name, issue_iid))
  local output = vim.fn.system(create_branch_cmd)

  if vim.v.shell_error == 0 then
    vim.notify(string.format("Branch '%s' and MR created successfully!\n%s", branch_name, output), vim.log.levels.INFO)
    -- Attempt to checkout the new branch
    local checkout_cmd = string.format("git checkout %s", vim.fn.shellescape(branch_name))
    vim.fn.system(checkout_cmd)
    if vim.v.shell_error == 0 then
      vim.notify(string.format("Switched to branch '%s'", branch_name), vim.log.levels.INFO)
    else
      vim.notify(string.format("Failed to switch to branch '%s'. You may need to do it manually.", branch_name), vim.log.levels.WARN)
    end
  else
    vim.notify(string.format("Failed to create branch '%s' and MR.\nError: %s", branch_name, output), vim.log.levels.ERROR)
  end
end

return M