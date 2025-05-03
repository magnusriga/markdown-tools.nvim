---@mod markdown-shortcuts.keymaps Keymap setup functionality
local M = {}

--- Set up a keymap if the key is defined
---@param mode string|string[] The mode(s) for the keymap
---@param key string|nil The key to map
---@param cmd string|function The command to execute or function to call
---@param desc string Description of the keymap
---@param opts? table Additional options for the keymap
local function setup_keymap(mode, key, cmd, desc, opts)
	if key and key ~= "" then
		opts = opts or {}
		opts.desc = desc
		opts.buffer = true
		vim.keymap.set(mode, key, cmd, opts)
	end
end

--- Setup keymaps for markdown files
---@param keymaps table Keymap configuration
---@param commands_enabled table Command enable configuration
---@param file_types string[] List of file types to apply keymaps to
function M.setup_keymaps(keymaps, commands_enabled, file_types)
	-- Create a dedicated augroup for keymaps
	local augroup = vim.api.nvim_create_augroup("MarkdownShortcutsKeymaps", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = file_types, -- Use the configured file types
		callback = function()
			-- Define keymap configurations
			local keymap_configs = {
				{
					command_key = "create_from_template",
					mode = "n",
					key = keymaps.create_from_template,
					cmd = "<cmd>MarkdownNewTemplate<CR>",
					desc = "Create from template",
				},
				{
					command_key = "insert_header",
					mode = { "n", "v" },
					key = keymaps.insert_header,
					cmd = function()
						local count = vim.v.count > 0 and vim.v.count or nil
						local mode = vim.fn.mode(1) -- Get mode, 1 = include selection type
						local opts = { level = count }
						-- Check if the mode indicates visual selection ('v', 'V', or '\022' for visual block)
						if mode:match("^[vV\022]") then
							-- Simulate the range being passed when called from visual mode
							opts.range = 2
							-- Exit visual mode *before* calling the command
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						end
						-- Call the command function directly
						require("markdown-shortcuts.commands").insert_header(opts)
					end,
					desc = "Header",
				},
				-- Removed insert_list_item keymap
				{
					command_key = "insert_code_block",
					mode = { "n", "v" },
					key = keymaps.insert_code_block,
					cmd = function()
						local mode = vim.fn.mode(1)
						local opts = {}
						if mode:match("^[vV\022]") then
							opts.range = 2
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						end
						require("markdown-shortcuts.commands").insert_code_block(opts)
					end,
					desc = "Code block",
				},
				{
					command_key = "insert_bold",
					mode = { "n", "v" },
					key = keymaps.insert_bold,
					cmd = function()
						local mode = vim.fn.mode(1)
						local opts = {}
						if mode:match("^[vV\022]") then
							opts.range = 2
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						end
						require("markdown-shortcuts.commands").insert_bold(opts)
					end,
					desc = "Bold text",
				},
				{
					command_key = "insert_italic",
					mode = { "n", "v" },
					key = keymaps.insert_italic,
					cmd = function()
						local mode = vim.fn.mode(1)
						local opts = {}
						if mode:match("^[vV\022]") then
							opts.range = 2
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						end
						require("markdown-shortcuts.commands").insert_italic(opts)
					end,
					desc = "Italic text",
				},
				{
					command_key = "insert_link",
					mode = { "n", "v" },
					key = keymaps.insert_link,
					cmd = function()
						local mode = vim.fn.mode(1)
						local opts = {}
						if mode:match("^[vV\022]") then
							opts.range = 2
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						end
						require("markdown-shortcuts.commands").insert_link(opts)
					end,
					desc = "Link",
				},
				{
					command_key = "insert_table",
					mode = "n",
					key = keymaps.insert_table,
					cmd = "<cmd>MarkdownInsertTable<CR>",
					desc = "Insert table",
				},
				{
					command_key = "insert_checkbox", -- Renamed key
					mode = { "n", "v" },
					key = keymaps.insert_checkbox, -- Renamed key
					cmd = function()
						local mode = vim.fn.mode(1)
						local opts = {}
						if mode:match("^[vV\022]") then
							opts.range = 2
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						end
						require("markdown-shortcuts.commands").insert_checkbox(opts)
					end,
					desc = "Checkbox", -- Updated description
				},
				{
					command_key = "toggle_checkbox", -- Renamed key
					mode = "n",
					key = keymaps.toggle_checkbox, -- Renamed key
					cmd = "<cmd>MarkdownToggleCheckbox<CR>", -- Renamed command
					desc = "Toggle checkbox", -- Updated description
				},
				{
					command_key = "preview",
					mode = "n",
					key = keymaps.preview,
					cmd = "<cmd>MarkdownPreview<CR>",
					desc = "Preview markdown",
				},
			}

			-- Apply all keymap configurations
			for _, config in ipairs(keymap_configs) do
				-- Only set keymap if the command is enabled
				if commands_enabled[config.command_key] then
					local opts = config.expr and { expr = config.expr } or {}

					local modes = config.mode
					if type(modes) == "string" then
						setup_keymap(modes, config.key, config.cmd, config.desc, opts)
					else
						for _, mode in ipairs(modes) do
							setup_keymap(mode, config.key, config.cmd, config.desc, opts)
						end
					end
				end
			end

			-- Add keymap for continuing lists on Enter if enabled
			if require("markdown-shortcuts.config").options.continue_lists_on_enter then
				vim.keymap.set("i", "<CR>", function()
					require('markdown-shortcuts.lists').continue_list_on_enter()
					-- Return empty string as the function now handles buffer changes
					return ""
				end, { buffer = true, silent = true, desc = "Continue markdown list" })
			end
		end,
	})
end

return M
