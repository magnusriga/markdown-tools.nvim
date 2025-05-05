local template = require("markdown-tools.template")

local M = {}

--- Processes the selected item from the picker.
--- Tries to match the selected item (which might have icons) to an actual file.
---@param selected table List containing the selected item string from the picker.
---@param template_dir string Directory where templates are stored.
---@param opts MarkdownToolsConfig Plugin configuration options.
local function process_selected_picker_item(selected, template_dir, opts)
	if not selected or #selected == 0 then
		vim.notify("No template selected.", vim.log.levels.WARN)
		return
	end

	local selected_item_name = selected[1] -- This might be just the filename, potentially with icons
	vim.notify("Picker selected: " .. selected_item_name, vim.log.levels.DEBUG)

	-- Attempt to find the actual file corresponding to the selected item name.
	-- This is necessary because some pickers might add icons or modify the display name.
	-- NOTE: This matching logic might be fragile if filenames contain parts of other filenames.
	local available_files = vim.fn.readdir(template_dir)
	local matched_file = nil
	local lower_selected_item = selected_item_name:lower()

	for _, file in ipairs(available_files) do
		local lower_file = file:lower()
		-- Check if the actual filename is contained within the selected item string
		-- or if the selected item string is contained within the actual filename.
		-- This handles cases where icons are prepended/appended.
		if lower_selected_item:find(lower_file, 1, true) or lower_file:find(lower_selected_item, 1, true) then
			-- Basic sanity check: ensure it's likely the intended file (e.g., ends with .md if selected item does)
			if selected_item_name:match("%.md$") == file:match("%.md$") then
				matched_file = file
				break
			end
			-- Fallback if extension check fails but it's the only potential match
			if not matched_file then
				matched_file = file
			end
		end
	end

	if matched_file then
		local full_template_path = vim.fn.fnamemodify(template_dir .. "/" .. matched_file, ":p")
		vim.notify("Matched template file: " .. full_template_path, vim.log.levels.DEBUG)
		-- Call the handler function from the template module
		template.handle_template_selection(full_template_path, opts)
	else
		vim.notify(
			"Could not match selected template '" .. selected_item_name .. "' to any file in " .. template_dir,
			vim.log.levels.ERROR
		)
		vim.notify("Available files: " .. vim.inspect(available_files), vim.log.levels.DEBUG)
	end
end

--- Select template using fzf-lua
---@param template_dir string Directory for templates
---@param callback fun(selected: table, template_dir: string, opts: MarkdownToolsConfig) Callback function
---@param opts MarkdownToolsConfig Plugin configuration options.
local function select_with_fzf(template_dir, callback, opts)
	local ok, fzf_lua = pcall(require, "fzf-lua")
	if not ok then
		vim.notify("fzf-lua is not installed or loadable", vim.log.levels.ERROR)
		return
	end
	fzf_lua.files({
		prompt = "Select Template> ",
		cwd = template_dir,
		actions = {
			["default"] = function(selected)
				callback(selected, template_dir, opts)
			end,
		},
	})
end

--- Select template using telescope
---@param template_dir string Directory for templates
---@param callback fun(selected: table, template_dir: string, opts: MarkdownToolsConfig) Callback function
---@param opts MarkdownToolsConfig Plugin configuration options.
local function select_with_telescope(template_dir, callback, opts)
	local ok, telescope = pcall(require, "telescope.builtin")
	if not ok then
		vim.notify("telescope is not installed or loadable", vim.log.levels.ERROR)
		return
	end
	telescope.find_files({
		prompt_title = "Select Template",
		cwd = template_dir,
		attach_mappings = function(_, map)
			map("i", "<CR>", function(bufnr)
				local selection = require("telescope.actions.state").get_selected_entry(bufnr)
				require("telescope.actions").close(bufnr)
				if selection then
					-- selection.value is usually the filename relative to cwd
					callback({ selection.value }, template_dir, opts)
				end
			end)
			return true
		end,
	})
end

--- Select template using snacks
---@param template_dir string Directory for templates
---@param callback fun(selected: table, template_dir: string, opts: MarkdownToolsConfig) Callback function
---@param opts MarkdownToolsConfig Plugin configuration options.
local function select_with_snacks(template_dir, callback, opts)
	local ok, Snacks = pcall(require, "snacks")
	if not ok then
		vim.notify("snacks is not installed or loadable", vim.log.levels.ERROR)
		return
	end
	Snacks.picker.files({
		prompt = "Select Template",
		cwd = template_dir,
		confirm = function(picker, item)
			picker:close()
			if item then
				-- item.file is usually the filename relative to cwd
				callback({ item.file }, template_dir, opts)
			end
		end,
	})
end

--- Dispatches template selection to the configured picker.
---@param opts MarkdownToolsConfig Plugin configuration options.
function M.select_template(opts)
	local picker_type = opts.picker
	local template_dir = opts.template_dir

	-- Ensure template directory exists
	if vim.fn.isdirectory(template_dir) == 0 then
		vim.notify("Template directory not found: " .. template_dir, vim.log.levels.ERROR)
		return
	end

	local callback = process_selected_picker_item

	if picker_type == "fzf" then
		select_with_fzf(template_dir, callback, opts)
	elseif picker_type == "telescope" then
		select_with_telescope(template_dir, callback, opts)
	elseif picker_type == "snacks" then
		select_with_snacks(template_dir, callback, opts)
	else
		vim.notify(
			"Unsupported picker: " .. tostring(picker_type) .. ". Please use 'fzf', 'telescope', or 'snacks'.",
			vim.log.levels.ERROR
		)
	end
end

return M
