local M = {}

--- Reads content from the specified template file.
---@param template_path string Full path to the template file.
---@return string[]? content Lines of the template file or nil on error.
local function read_template(template_path)
  -- Check if template file exists before proceeding.
  if vim.fn.filereadable(template_path) ~= 1 then
    vim.notify("Template file not found: " .. template_path, vim.log.levels.ERROR)
    return nil
  end

  -- Read template content with error handling.
  local template_content
  local read_ok, read_err = pcall(function()
    template_content = vim.fn.readfile(template_path)
  end)

  if not read_ok or not template_content then
    vim.notify("Failed to read template file: " .. (read_err or "unknown error"), vim.log.levels.ERROR)
    return nil
  end

  return template_content
end

--- Formats a list of strings into a YAML list string.
---@param key string The YAML key (e.g., "alias", "tags").
---@param values string[]? List of string values.
---@return string? formatted_yaml The formatted YAML string (e.g., "tags: ["tag1", "tag2"]") or nil if values is nil or empty.
local function format_yaml_list(key, values)
  if not values or #values == 0 then
    return key .. ": []" -- Return empty list representation
  end
  local quoted_values = {}
  for _, v in ipairs(values) do
    table.insert(quoted_values, '"' .. v .. '"')
  end
  return key .. ": [" .. table.concat(quoted_values, ", ") .. "]"
end

--- Processes template content, replacing placeholders and adding frontmatter if needed.
---@param template_content string[] Content read from the template file.
---@param new_file_path string Full path of the new file to be created.
---@param frontmatter_values table Table containing generated frontmatter values (id, title, alias, tags, date, custom = {key=value}).
---@param timestamp string Timestamp string used for the ID.
---@param opts table Plugin configuration options.
---@return string[] processed_lines Lines ready to be written to the new file.
local function process_template_content(template_content, new_file_path, frontmatter_values, timestamp, opts)
  -- Create temporary buffer to process lines
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, template_content)

  -- Format generated alias and tags for placeholders and frontmatter insertion
  local formatted_aliases = format_yaml_list("alias", frontmatter_values.alias)
  local formatted_tags = format_yaml_list("tags", frontmatter_values.tags)

  -- Format custom fields for placeholders
  local custom_placeholders = {}
  if type(frontmatter_values.custom) == "table" then
    for key, value in pairs(frontmatter_values.custom) do
      if type(value) == "table" then
        custom_placeholders[key] = format_yaml_list(key, value) or (key .. ": []")
      elseif type(value) == "string" then
        -- Basic string quoting for safety in YAML
        custom_placeholders[key] = key .. ': "' .. value:gsub('"', '\\"') .. '"'
      else
        -- Handle other simple types like numbers/booleans directly
        custom_placeholders[key] = key .. ": " .. tostring(value)
      end
    end
  end

  -- Helper function to format a list for placeholder replacement
  local function format_placeholder_list(values)
    if not values or #values == 0 then
      return "[]"
    end
    local quoted_values = {}
    for _, v in ipairs(values) do
      table.insert(quoted_values, '"' .. v .. '"') -- Quote values for YAML compatibility
    end
    return "[" .. table.concat(quoted_values, ", ") .. "]"
  end

  -- Replace template placeholders.
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local datetime_str = os.date("%Y-%m-%d %H:%M:%S")

  for i, line in ipairs(lines) do
    -- Replace standard placeholders
    line = line:gsub("{{id}}", frontmatter_values.id or "", 1)
    line = line:gsub("{{title}}", frontmatter_values.title or "", 1)
    line = line:gsub("{{date}}", frontmatter_values.date or "", 1)
    line = line:gsub("{{datetime}}", datetime_str, 1) -- Keep datetime as current time
    line = line:gsub("{{timestamp}}", timestamp, 1) -- Keep timestamp as generation time
    -- Replace list placeholders with bracketed format
    line = line:gsub("{{alias}}", format_placeholder_list(frontmatter_values.alias), 1)
    line = line:gsub("{{tags}}", format_placeholder_list(frontmatter_values.tags), 1)

    -- Replace custom placeholders (e.g., {{my_custom_field}})
    if type(frontmatter_values.custom) == "table" then
      for key, _ in pairs(frontmatter_values.custom) do
        local placeholder = "{{" .. key .. "}}"
        local replacement = ""
        if frontmatter_values.custom[key] ~= nil then
          if type(frontmatter_values.custom[key]) == "table" then
            -- For list placeholders, insert the bracketed list format
            replacement = format_placeholder_list(frontmatter_values.custom[key])
          else
            replacement = tostring(frontmatter_values.custom[key])
          end
        end
        line = line:gsub(placeholder, replacement, 1)
      end
    end

    lines[i] = line
  end

  -- Check if the template already has frontmatter
  local has_frontmatter = #lines > 0 and lines[1] == "---"

  -- If no frontmatter exists and the option is enabled, add it
  if not has_frontmatter and opts.insert_frontmatter then
    local frontmatter = { "---" }
    if frontmatter_values.id then
      table.insert(frontmatter, "id: " .. frontmatter_values.id)
    end
    if frontmatter_values.title then
      table.insert(frontmatter, 'title: "' .. frontmatter_values.title .. '"')
    end
    if formatted_aliases then
      table.insert(frontmatter, formatted_aliases)
    end
    if formatted_tags then
      table.insert(frontmatter, formatted_tags)
    end
    if frontmatter_values.date then
      table.insert(frontmatter, "date: " .. frontmatter_values.date)
    end

    -- Add custom fields to frontmatter
    if type(frontmatter_values.custom) == "table" then
      for key, formatted_value_line in pairs(custom_placeholders) do
        table.insert(frontmatter, formatted_value_line)
      end
    end

    table.insert(frontmatter, "---")
    table.insert(frontmatter, "")

    -- Insert frontmatter at the beginning of the file
    -- Only insert if there are fields other than the --- separators
    if #frontmatter > 3 then
      for i = #frontmatter, 1, -1 do
        table.insert(lines, 1, frontmatter[i])
      end
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local processed_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Clean up temporary buffer.
  vim.api.nvim_buf_delete(buf, { force = true })

  return processed_lines
end

--- Writes content to a new file and opens it.
---@param new_file_path string Full path of the new file to be created.
---@param lines string[] Content to write to the file.
---@return boolean success True if file was written and opened successfully, false otherwise.
local function write_and_open_file(new_file_path, lines)
  -- Create a temporary buffer to write from
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Write buffer to new file.
  local success, write_err = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      -- Ensure directory exists (create if necessary) - requires mkdir command support
      local dir = vim.fn.fnamemodify(new_file_path, ":h")
      if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
      end
      vim.cmd("write " .. vim.fn.fnameescape(new_file_path))
    end)
  end)

  -- Clean up temporary buffer regardless of write success.
  vim.api.nvim_buf_delete(buf, { force = true })

  if not success then
    vim.notify(
      "Failed to write file: " .. new_file_path .. " Error: " .. (write_err or "unknown"),
      vim.log.levels.ERROR
    )
    return false
  end

  -- Open newly created file.
  vim.cmd("edit " .. vim.fn.fnameescape(new_file_path))
  vim.cmd("stopinsert") -- Explicitly exit insert mode
  vim.notify("Created new file: " .. new_file_path, vim.log.levels.INFO)
  return true
end

--- Helper function to safely call a frontmatter generation function.
---@param fn function|nil The function to call.
---@param opts table The options table to pass to the function.
---@param field_name string The name of the field being generated (for error messages).
---@param expected_type string The expected return type ("string", "table", or "any").
---@return any|nil The result of the function call, or nil on error or if fn is nil.
local function safe_call_frontmatter_fn(fn, opts, field_name, expected_type)
  if type(fn) ~= "function" then
    return nil -- Or handle default logic if fn is not a function
  end

  local ok, result = pcall(fn, opts)
  if not ok then
    vim.notify(string.format("Error calling %s function: %s", field_name, tostring(result)), vim.log.levels.ERROR)
    return nil
  end

  -- Allow nil return
  if result == nil then
    return nil
  end

  -- Type check if expected_type is specified and not 'any'
  if expected_type ~= "any" then
    if expected_type == "string" and type(result) ~= "string" then
      vim.notify(
        string.format("%s function must return a string or nil, got %s", field_name, type(result)),
        vim.log.levels.WARN
      )
      return nil
    elseif expected_type == "table" and type(result) ~= "table" then
      vim.notify(
        string.format("%s function must return a table or nil, got %s", field_name, type(result)),
        vim.log.levels.WARN
      )
      return nil
    end
  end

  return result
end

--- Handles the core logic after a template file path has been determined.
--- Prompts for filename, processes template, and creates the file.
---@param template_path string Full path to the selected template file.
---@param opts table Plugin configuration options.
function M.handle_template_selection(template_path, opts)
  -- Schedule the input prompt
  vim.schedule(function()
    -- Prompt for new file name. vim.ui.input should handle mode.
    vim.ui.input({ prompt = "Enter new file name: " }, function(input_file_name)
      if not input_file_name or input_file_name == "" then
        vim.notify("No file name provided", vim.log.levels.WARN)
        return
      end

      local new_file_name = input_file_name -- Keep original input separate

      -- Add `.md` extension, if not already present.
      if not new_file_name:match("%.md$") then
        new_file_name = new_file_name .. ".md"
      end

      -- Expand path for new file (relative to current working directory).
      local new_file_path = vim.fn.expand("%:p:h") .. "/" .. new_file_name -- Create in current dir
      new_file_path = vim.fn.fnamemodify(new_file_path, ":p") -- Ensure absolute path

      -- Check if file already exists.
      if vim.fn.filereadable(new_file_path) == 1 then
        vim.notify("File already exists: " .. new_file_path, vim.log.levels.WARN)
        return
      end

      -- Generate timestamp and sanitized name for ID generation
      local timestamp = tostring(os.date("%Y%m%d%H%M"))
      local sanitized_name = new_file_name:gsub("[^%w_.-]", "_")

      -- Prepare options table for frontmatter functions
      local frontmatter_opts = {
        timestamp = timestamp,
        filename = new_file_name, -- Pass the name with .md extension
        sanitized_name = sanitized_name,
        filepath = new_file_path,
      }

      -- Generate frontmatter values using configured functions
      local frontmatter_values = {
        id = safe_call_frontmatter_fn(opts.frontmatter_id, frontmatter_opts, "frontmatter_id", "string"),
        title = safe_call_frontmatter_fn(opts.frontmatter_title, frontmatter_opts, "frontmatter_title", "string"),
        alias = safe_call_frontmatter_fn(opts.frontmatter_alias, frontmatter_opts, "frontmatter_alias", "table"),
        tags = safe_call_frontmatter_fn(opts.frontmatter_tags, frontmatter_opts, "frontmatter_tags", "table"),
        date = safe_call_frontmatter_fn(opts.frontmatter_date, frontmatter_opts, "frontmatter_date", "string"),
        custom = {}, -- Table to store custom field values
      }

      -- Generate custom frontmatter fields
      if type(opts.frontmatter_custom) == "table" then
        for key, fn in pairs(opts.frontmatter_custom) do
          -- Use 'any' as expected type, formatting handled later
          local value = safe_call_frontmatter_fn(fn, frontmatter_opts, "frontmatter_custom['" .. key .. "']", "any")
          if value ~= nil then
            frontmatter_values.custom[key] = value
          end
        end
      end

      -- Read template content
      local template_content = read_template(template_path)
      if not template_content then
        return -- Error already notified by read_template
      end

      -- Process template content, passing the generated frontmatter values
      local processed_lines =
        process_template_content(template_content, new_file_path, frontmatter_values, timestamp, opts)

      -- Write buffer to new file and open it.
      write_and_open_file(new_file_path, processed_lines)
    end)
    -- Try feeding keys to start insert mode immediately after calling vim.ui.input
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Cmd>startinsert<CR>", true, false, true), "n", false)
  end)
end

return M
