---@mod markdown-tools.lists List handling utilities
local M = {}

function M.keymap_init()
  local line = vim.api.nvim_get_current_line()
  local _, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Define separate patterns for each list type
  local pattern_bullet = "^%s*[-*+]%s+"
  local pattern_numbered = "^%s*%d+%.%s+"
  local pattern_checkbox = "^%s*[-*+] %[[ x]%]%s+"

  -- Check if cursor is at end and any pattern matched
  local is_list_end = cursor_col == #line
    and (line:match(pattern_bullet) or line:match(pattern_numbered) or line:match(pattern_checkbox))

  if is_list_end then
    -- If it is, schedule the list continuation function to run soon
    vim.schedule(function()
      require("markdown-tools.lists").continue_list_on_enter()
    end)
    return "" -- Handled: tell Neovim to do nothing further for this <CR>
  else
    -- Otherwise, let Neovim handle <CR> as default
    -- return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
    return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "nt", false)
  end
end

--- Handles the <CR> key press in insert mode for markdown files.
-- Continues lists (bullet, numbered, checkbox) automatically.
-- If the current list item is empty, hitting Enter removes the list marker and inserts a blank line.
-- Otherwise, inserts a new list item with the appropriate marker and indentation.
-- NOTE: This function now modifies the buffer directly and does not return keys.
function M.continue_list_on_enter()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local line = vim.api.nvim_get_current_line()
  local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(winid)) -- 1-based row

  -- Try to match different list types
  local indent, marker, content
  local marker_type = nil

  -- Match numbered lists (e.g., "  1. content")
  indent, marker, content = line:match("^(%s*)(%d+%.%s+)(.*)$")
  if indent then
    marker_type = "number"
  else
    -- Match checkbox lists (e.g., "- [ ] content", "* [x] content")
    indent, marker, content = line:match("^(%s*)([-*+] %[[ x]%]%s+)(.*)$") -- Allow -, *, +
    if indent then
      marker_type = "checkbox"
    else
      -- Match bullet lists (e.g., " * content")
      indent, marker, content = line:match("^(%s*)([-*+]%s+)(.*)$")
      if indent then
        marker_type = "bullet"
      end
    end
  end

  -- This function should only be called via the keymap, which already checks
  -- if it's a list line and cursor is at the end. So, marker_type should exist.
  if not marker_type then
    -- Fallback just in case: insert a normal newline
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "i", false)
    return
  end

  -- If the list item content is empty or only whitespace
  if content:match("^%s*$") then
    -- Replace the current line (marker + indent) with an empty line
    vim.api.nvim_buf_set_lines(bufnr, cursor_row - 1, cursor_row, false, { "" })
    -- Move cursor to the beginning of the (now empty) current line
    vim.api.nvim_win_set_cursor(winid, { cursor_row, 0 }) -- Set cursor (1-based row, 0-based byte col)
  else
    -- Calculate the next marker
    local next_marker = marker
    if marker_type == "number" then
      local num_match = marker:match("(%d+)%.%s+$")
      if num_match then
        local next_num = tonumber(num_match) + 1
        -- Correctly capture the suffix (e.g., ". ")
        local marker_suffix = marker:match("^%d+(%.%s+)")
        next_marker = string.format("%d%s", next_num, marker_suffix or ". ")
      end
    elseif marker_type == "checkbox" then
      -- Preserve the original bullet type (-, *, +)
      local bullet = marker:match("^([*-+])")
      next_marker = (bullet or "-") .. " [ ] " -- Default to unchecked
    end
    -- For bullet lists, next_marker is already correct (same as current marker)

    -- Insert the new list item line below the current one
    local new_line = indent .. next_marker
    vim.api.nvim_buf_set_lines(bufnr, cursor_row, cursor_row, false, { new_line })
    -- Move cursor to the end of the new marker
    -- Use the byte length of the inserted line content as the 0-based column index
    vim.api.nvim_win_set_cursor(winid, { cursor_row + 1, #new_line }) -- Set cursor (1-based row, 0-based byte col)
  end
end

return M
