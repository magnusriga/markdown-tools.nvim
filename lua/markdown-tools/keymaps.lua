---@mod markdown-tools.keymaps Keymap setup functionality
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
						require("markdown-tools.commands").insert_header(opts)
					end,
					desc = "Header",
				},
				{
					command_key = "insert_code_block",
					mode = "n", -- Normal mode only
					key = keymaps.insert_code_block,
					cmd = function()
						require("markdown-tools.commands").insert_code_block({ range = 0 })
					end,
					desc = "Code block (Normal)",
				},
				{
					command_key = "insert_code_block",
					mode = "v", -- Visual mode only
					key = keymaps.insert_code_block,
					cmd = function()
						-- Still need Lua for prompt, exit visual first
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						require("markdown-tools.commands").insert_code_block({ range = 2 })
					end,
					desc = "Code block (Visual)",
				},
				{
					command_key = "insert_bold",
					mode = "n", -- Normal mode only
					key = keymaps.insert_bold,
					cmd = function()
						-- Call command function (prompts for input in normal mode)
						require("markdown-tools.commands").insert_bold({ range = 0 }) -- Explicitly pass range 0
					end,
					desc = "Bold text (Normal)",
				},
				{
					command_key = "insert_bold",
					mode = "v", -- Visual mode only
					key = keymaps.insert_bold,
					-- Use Vim command sequence for visual wrapping
					cmd = 's**<C-r>"**<Esc>',
					desc = "Bold text (Visual)",
					opts = { remap = true } -- Allow remapping <C-r>
				},
				{
					command_key = "insert_highlight",
					mode = "n", -- Normal mode only
					key = keymaps.insert_highlight,
					cmd = function()
						-- Call command function (prompts for input in normal mode)
						require("markdown-tools.commands").insert_highlight({ range = 0 }) -- Explicitly pass range 0
					end,
					desc = "Highlight text (Normal)",
				},
				{
					command_key = "insert_highlight",
					mode = "v", -- Visual mode only
					key = keymaps.insert_highlight,
					-- Use Vim command sequence for visual wrapping
					cmd = 's==<C-r>"==<Esc>',
					desc = "Highlight text (Visual)",
					opts = { remap = true } -- Allow remapping <C-r>
				},
				{
					command_key = "insert_italic",
					mode = "n", -- Normal mode only
					key = keymaps.insert_italic,
					cmd = function()
						-- Call command function (prompts for input in normal mode)
						require("markdown-tools.commands").insert_italic({ range = 0 }) -- Explicitly pass range 0
					end,
					desc = "Italic text (Normal)",
				},
				{
					command_key = "insert_italic",
					mode = "v", -- Visual mode only
					key = keymaps.insert_italic,
					-- Use Vim command sequence for visual wrapping
					cmd = 's*<C-r>"*<Esc>',
					desc = "Italic text (Visual)",
					opts = { remap = true } -- Allow remapping <C-r>
				},
				{
					command_key = "insert_link",
					mode = "n", -- Normal mode only
					key = keymaps.insert_link,
					cmd = function()
						require("markdown-tools.commands").insert_link({ range = 0 })
					end,
					desc = "Link (Normal)",
				},
				{
					command_key = "insert_link",
					mode = "v", -- Visual mode only
					key = keymaps.insert_link,
					-- Use Vim command sequence + Lua helper for prompt
					-- 1. Substitute selection: `s[<C-r>"]()`
					-- 2. Exit substitute mode: `<Esc>`
					-- 3. Move cursor left: `<Cmd>normal! h<CR>`
					-- 4. Enter insert mode (before cursor): `<Cmd>startinsert<CR>`
					-- 5. Call Lua helper to prompt and insert URL
					cmd = 's[<C-r>"]()<Esc><Cmd>normal! h<CR><Cmd>startinsert<CR><Cmd>lua require("markdown-tools.commands").prompt_and_insert_url()<CR>',
					desc = "Link (Visual)",
					opts = { remap = true } -- Allow remapping <C-r>, <Esc>, <Cmd>, <CR>
				},
				{
					command_key = "insert_table",
					mode = "n",
					key = keymaps.insert_table,
					cmd = "<cmd>MarkdownInsertTable<CR>",
					desc = "Insert table",
				},
				{
					command_key = "insert_checkbox",
					mode = "n", -- Normal mode only
					key = keymaps.insert_checkbox,
					cmd = function()
						require("markdown-tools.commands").insert_checkbox({ range = 0 })
					end,
					desc = "Checkbox (Normal)",
				},
				{
					command_key = "insert_checkbox",
					mode = "v", -- Visual mode only
					key = keymaps.insert_checkbox,
						-- Call the Lua function directly, which handles line insertion
					cmd = function()
						-- Exit visual mode before calling the command
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
						require("markdown-tools.commands").insert_checkbox()
					end,
					desc = "Checkbox (Visual - Start of Line)", -- Updated description
					opts = nil -- Remove remap = true, no longer needed
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
					-- Combine base opts with config-specific opts
					local base_opts = { desc = config.desc, buffer = true }
					local final_opts = vim.tbl_extend("force", base_opts, config.opts or {})

					-- Use setup_keymap helper
					setup_keymap(config.mode, config.key, config.cmd, config.desc, final_opts)
				end
			end

			-- Add keymap for continuing lists on Enter if enabled
			if require("markdown-tools.config").options.continue_lists_on_enter then
				vim.keymap.set("i", "<CR>", function()
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
						-- If it is, call the list continuation function directly
						require('markdown-tools.lists').continue_list_on_enter()
					else
						-- Otherwise, feed a normal <CR> keypress
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
					end
				end, { buffer = true, desc = "Continue Markdown List" })
			end
		end,
	})
end

return M
