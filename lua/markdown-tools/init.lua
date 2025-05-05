local config = require("markdown-tools.config")
local autocmds = require("markdown-tools.autocmds")
local keymaps = require("markdown-tools.keymaps")
local commands = require("markdown-tools.commands")

-- Module definition
local M = {}

--- Helper function to register a command only if it's enabled
local function register_command(name, func, opts)
	local command_key
	-- Map command name to config key
	if name == "MarkdownNewTemplate" then
		command_key = "create_from_template"
	elseif name == "MarkdownHeader" then
		command_key = "insert_header"
	elseif name == "MarkdownCodeBlock" then
		command_key = "insert_code_block"
	elseif name == "MarkdownBold" then
		command_key = "insert_bold"
	elseif name == "MarkdownHighlight" then
		command_key = "insert_highlight"
	elseif name == "MarkdownItalic" then
		command_key = "insert_italic"
	elseif name == "MarkdownLink" then
		command_key = "insert_link"
	elseif name == "MarkdownInsertTable" then -- Kept original name
		command_key = "insert_table"
	elseif name == "MarkdownCheckbox" then -- Renamed command
		command_key = "insert_checkbox" -- Renamed key
	elseif name == "MarkdownToggleCheckbox" then -- Renamed command
		command_key = "toggle_checkbox" -- Renamed key
	elseif name == "MarkdownPreview" then
		command_key = "preview"
	else
		-- Fallback or error handling if needed
		command_key = name:gsub("^Markdown", "")
		command_key = command_key:sub(1, 1):lower() .. command_key:sub(2)
	end

	if config.options.commands[command_key] then
		vim.api.nvim_create_user_command(name, func, opts)
	end
end

--- Setup function for the plugin. Merges user options with defaults and registers commands.
---@param opts? Config User configuration options.
function M.setup(opts)
	if not config.setup(opts) then
		return
	end

	-- Register commands only if enabled
	register_command("MarkdownNewTemplate", commands.create_from_template, { desc = "Create Markdown file from template." })
	register_command("MarkdownHeader", function(args)
		-- Pass the whole args table, which includes range info
		commands.insert_header(args)
	end, { nargs = "*", desc = "Insert Markdown header.", range = true }) -- Add range = true
	register_command("MarkdownCodeBlock", function(args)
		-- Pass the whole args table, which includes range info
		commands.insert_code_block(args)
	end, { nargs = "*", desc = "Insert Markdown code block.", range = true }) -- Added range = true
	register_command("MarkdownBold", function(args)
		commands.insert_bold(args)
	end, { nargs = "*", desc = "Insert bold text.", range = true })
	register_command("MarkdownHighlight", function(args)
		commands.insert_highlight(args)
	end, { nargs = "*", desc = "Insert highlight text.", range = true })
	register_command("MarkdownItalic", function(args)
		commands.insert_italic(args)
	end, { nargs = "*", desc = "Insert italic text.", range = true })
	register_command("MarkdownLink", function(args)
		commands.insert_link(args)
	end, { nargs = "*", desc = "Insert Markdown link.", range = true })
	register_command("MarkdownInsertTable", function(args)
		commands.insert_table(args.fargs)
	end, { nargs = "*", desc = "Insert Markdown table." })
	register_command("MarkdownCheckbox", function(args) -- Renamed command
		commands.insert_checkbox(args) -- Renamed function call
	end, { nargs = "*", desc = "Insert Markdown checkbox list item.", range = true }) -- Updated description
	register_command("MarkdownToggleCheckbox", commands.toggle_checkbox, { desc = "Toggle Markdown checkbox completion." }) -- Renamed command, function call, updated description
	register_command("MarkdownPreview", commands.preview, { desc = "Preview Markdown file." })

	autocmds.setup_autocmds(config.options)
	keymaps.setup_keymaps(config.options.keymaps, config.options.commands, config.options.file_types) -- Pass file_types
end

return M
