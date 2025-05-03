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

--- Processes template content, replacing placeholders and adding frontmatter if needed.
---@param template_content string[] Content read from the template file.
---@param new_file_path string Full path of the new file to be created.
---@param new_file_id string Unique ID for the new file.
---@param timestamp string Timestamp string used for the ID.
---@param opts table Plugin configuration options.
---@return string[] processed_lines Lines ready to be written to the new file.
local function process_template_content(template_content, new_file_path, new_file_id, timestamp, opts)
	-- Create temporary buffer to process lines
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, template_content)

	-- Use configured aliases and tags
	local default_aliases = opts.alias or {}
	local default_tags = opts.tags or {}

	-- Format aliases and tags for frontmatter
	local formatted_aliases = "alias: []"
	if default_aliases and #default_aliases > 0 then
		local alias_list = {}
		for _, alias in ipairs(default_aliases) do
			table.insert(alias_list, '"' .. alias .. '"')
		end
		formatted_aliases = "alias: [" .. table.concat(alias_list, ", ") .. "]"
	end

	local formatted_tags = "tags: []"
	if default_tags and #default_tags > 0 then
		local tag_list = {}
		for _, tag in ipairs(default_tags) do
			table.insert(tag_list, '"' .. tag .. '"')
		end
		formatted_tags = "tags: [" .. table.concat(tag_list, ", ") .. "]"
	end

	-- Replace template placeholders.
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local title = vim.fn.fnamemodify(new_file_path, ":t:r") -- Remove extension
	local date_str = os.date("%Y-%m-%d")
	local datetime_str = os.date("%Y-%m-%d %H:%M:%S")

	for i, line in ipairs(lines) do
		line = line:gsub("{{id}}", new_file_id, 1) -- Replace only first occurrence potentially
		line = line:gsub("{{title}}", title, 1)
		line = line:gsub("{{date}}", date_str, 1)
		line = line:gsub("{{datetime}}", datetime_str, 1)
		line = line:gsub("{{timestamp}}", timestamp, 1)
		line = line:gsub("{{alias}}", formatted_aliases, 1)
		line = line:gsub("{{tags}}", formatted_tags, 1)
		lines[i] = line
	end

	-- Check if the template already has frontmatter
	local has_frontmatter = #lines > 0 and lines[1] == "---"

	-- If no frontmatter exists, add it
	if not has_frontmatter then
		local frontmatter = {
			"---",
			"id: " .. new_file_id,
			'title: "' .. title .. '"',
			formatted_aliases,
			formatted_tags,
			"date: " .. date_str,
			"---",
			"",
		}
		-- Insert frontmatter at the beginning of the file
		for i = #frontmatter, 1, -1 do
			table.insert(lines, 1, frontmatter[i])
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
	vim.notify("Created new file: " .. new_file_path, vim.log.levels.INFO)
	return true
end

--- Handles the core logic after a template file path has been determined.
--- Prompts for filename, processes template, and creates the file.
---@param template_path string Full path to the selected template file.
---@param opts table Plugin configuration options.
function M.handle_template_selection(template_path, opts)
	-- Prompt for new file name.
	vim.ui.input({ prompt = "Enter new file name: " }, function(new_file_name)
		if not new_file_name or new_file_name == "" then
			vim.notify("No file name provided", vim.log.levels.WARN)
			return
		end

		-- Create unique note id, i.e. Zettelkasten method.
		local timestamp = tostring(os.date("%Y%m%d%H%M"))
		-- Sanitize filename for ID generation (replace spaces, etc.)
		local sanitized_name = new_file_name:gsub("[^%w_.-]", "_")
		local new_file_id = timestamp .. "_" .. sanitized_name

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

		-- Read template content
		local template_content = read_template(template_path)
		if not template_content then
			return -- Error already notified by read_template
		end

		-- Process template content
		local processed_lines = process_template_content(template_content, new_file_path, new_file_id, timestamp, opts)

		-- Write buffer to new file and open it.
		write_and_open_file(new_file_path, processed_lines)
	end)
end

return M
