-- Table functionality
local M = {}

--- Insert a Markdown table at the current cursor position
---@param rows number Number of rows in the table
---@param cols number Number of columns in the table
function M.insert_table(rows, cols)
  rows = rows or 3 -- Default to 3 rows (header, separator, data)
  cols = cols or 3 -- Default to 3 columns

  local lines = {}
  -- Create header row
  local header = "|"
  for i = 1, cols do
    header = header .. " Header " .. i .. " |"
  end
  table.insert(lines, header)
  -- Create separator row
  local separator = "|"
  for _ = 1, cols do
    separator = separator .. " --- |"
  end
  table.insert(lines, separator)
  -- Create data rows
  for i = 1, rows - 2 do
    local row = "|"
    for j = 1, cols do
      row = row .. " Cell " .. i .. "," .. j .. " |"
    end
    table.insert(lines, row)
  end

  -- Insert the table at the current cursor position
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- Convert to 0-indexed

  vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)
  -- Move cursor to the first cell after the header
  vim.api.nvim_win_set_cursor(0, { row + 3, 2 })
end

return M
