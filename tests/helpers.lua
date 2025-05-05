-- tests/helpers.lua
local M = {}

-- Function to reset Neovim state between tests
function M.reset_nvim()
  -- Clear all buffers without saving
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buftype") == "" then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end

  -- Clear user commands (be careful with this, might remove commands from other plugins in test env)
  -- Consider targeting only commands defined by your plugin if possible
  for _, cmd in ipairs(vim.api.nvim_get_commands({})) do
    if cmd.name:match("^Markdown") then -- Example: Only remove commands starting with Markdown
      vim.api.nvim_del_user_command(cmd.name)
    end
  end

  -- Clear keymaps (similarly, be careful and target specific maps)
  -- vim.api.nvim_clear_keymap('n')
  -- vim.api.nvim_clear_keymap('v')
  -- ... etc.

  -- Reset options (if needed)
  -- vim.cmd('set all&')

  -- Unload and clear package cache for the plugin to ensure fresh load
  package.loaded["markdown-tools"] = nil
  package.loaded["markdown-tools.config"] = nil
  package.loaded["markdown-tools.commands"] = nil
  package.loaded["markdown-tools.template"] = nil
  package.loaded["markdown-tools.keymaps"] = nil
  package.loaded["markdown-tools.lists"] = nil
  package.loaded["markdown-tools.picker"] = nil
  package.loaded["markdown-tools.preview"] = nil
  package.loaded["markdown-tools.table"] = nil
  package.loaded["markdown-tools.autocmds"] = nil
  package.loaded["markdown-tools.health"] = nil
  package.loaded["markdown-tools.plugin"] = nil

  -- Wait for event loop to process potential pending events
  vim.wait(10)
end

-- Helper to set visual selection marks
function M.set_visual_selection(start_line, start_col, end_line, end_col)
  vim.fn.setpos("'<", { 0, start_line, start_col, 0 })
  vim.fn.setpos("'>", { 0, end_line, end_col, 0 })
end

-- Helper to get buffer content as a single string
function M.get_buffer_content()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

return M
