-- Health check module for markdown-shortcuts.nvim
---@diagnostic disable: param-type-mismatch
local M = {}

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
	start("markdown-shortcuts.nvim")

	-- Check Neovim version
	if vim.fn.has("nvim-0.8.0") == 1 then
		ok("Neovim version >= 0.8.0")
	else
		warn("Neovim version < 0.8.0. Some features may not work correctly.")
	end

	-- Check template directory
	local config = require("markdown-shortcuts.config")
	local template_dir = config.options.template_dir

	if template_dir and template_dir ~= "" then
		if vim.fn.isdirectory(template_dir) == 1 then
			ok("Template directory exists: " .. template_dir)

			-- Check if there are template files
			local templates = vim.fn.glob(template_dir .. "/*.md", false, true)
			if #templates > 0 then
				ok("Found " .. #templates .. " template files")
			else
				warn("No .md template files found in " .. template_dir)
			end
		else
			warn("Template directory does not exist: " .. template_dir)
			info("Create the directory or set a different path in your configuration")
		end
	else
		error("Template directory not configured")
		info("Set template_dir in your configuration")
	end

	-- Check picker availability
	local picker = config.options.picker
	if picker == "fzf" then
		if vim.fn.exists("*fzf#run") == 1 then
			ok("FZF picker is available")
		else
			warn("FZF picker is configured but not available")
			info("Install fzf.vim or choose a different picker")
		end
	elseif picker == "telescope" then
		local has_telescope, _ = pcall(require, "telescope")
		if has_telescope then
			ok("Telescope picker is available")
		else
			warn("Telescope picker is configured but not available")
			info("Install telescope.nvim or choose a different picker")
		end
	elseif picker == "snacks" then
		local has_snacks, _ = pcall(require, "snacks")
		if has_snacks then
			ok("Snacks picker is available")
		else
			warn("Snacks picker is configured but not available")
			info("Install snacks.nvim or choose a different picker")
		end
	else
		warn("Unknown picker configured: " .. picker)
		info("Valid options are: 'fzf', 'telescope', 'snacks'")
	end

	-- Check preview command availability
	local preview = require("markdown-shortcuts.preview")
	preview.detect_preview_plugin()

	if config.options.preview_command then
		local cmd_type = type(config.options.preview_command)
		if cmd_type == "function" then
			ok("Custom preview function is configured")
		elseif cmd_type == "string" then
			local preview_cmd = config.options.preview_command
			-- Check if the command has spaces
			if preview_cmd and preview_cmd:match("%s") then
				-- Extract the first part of the command
				local cmd = vim.split(preview_cmd, " ")[1]
				-- Check if the command is executable
				---@diagnostic disable-next-line: param-type-mismatch
				if vim.fn.executable(cmd) == 1 then
					ok("Preview command is available: " .. cmd)
				else
					warn("Preview command is not executable: " .. cmd)
				end
			else
				-- Use the whole string as the command
				---@diagnostic disable-next-line: param-type-mismatch
				if preview_cmd and vim.fn.executable(preview_cmd) == 1 then
					ok("Preview command is available: " .. preview_cmd)
				else
					warn("Preview command is not executable: " .. preview_cmd)
				end
			end
		else
			warn("Invalid preview_command type: " .. cmd_type)
		end
	else
		info("Using auto-detected preview method")
	end
end

return M
