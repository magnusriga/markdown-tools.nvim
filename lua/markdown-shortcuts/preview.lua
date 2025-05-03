local config = require("markdown-shortcuts.config")

local M = {}

-- Detect available preview plugins
function M.detect_preview_plugin()
	local plugins = {
		{ name = "markdown-preview.nvim", module = "markdown-preview" },
		{ name = "peek.nvim", module = "peek" },
		{ name = "glow.nvim", module = "glow" },
		{ name = "nvim-markdown-preview", command = "MarkdownPreview" },
	}

	for _, plugin in ipairs(plugins) do
		if plugin.module then
			local ok = pcall(require, plugin.module)
			if ok then
				return plugin.name
			end
		elseif plugin.command then
			local ok = pcall(vim.api.nvim_command, "command " .. plugin.command)
			if ok then
				return plugin.name
			end
		end
	end

	return nil
end

-- Preview with markdown-preview.nvim
local function preview_with_markdown_preview()
	vim.cmd("MarkdownPreview")
end

-- Preview with peek.nvim
local function preview_with_peek()
	local peek = require("peek")
	if not peek.is_open() then
		peek.open()
	end
end

-- Preview with glow.nvim
local function preview_with_glow()
	vim.cmd("Glow")
end

-- Preview with nvim-markdown-preview
local function preview_with_nvim_markdown_preview()
	vim.cmd("MarkdownPreview")
end

-- Preview with system default application
local function preview_with_system()
	local file = vim.fn.expand("%:p")
	local os_name = vim.loop.os_uname().sysname

	if os_name == "Darwin" then
		-- macOS
		vim.fn.jobstart({ "open", file })
	elseif os_name == "Linux" then
		-- Linux
		vim.fn.jobstart({ "xdg-open", file })
	elseif os_name:match("Windows") then
		-- Windows
		vim.fn.jobstart({ "cmd.exe", "/c", "start", file })
	else
		vim.notify("Unsupported operating system for preview", vim.log.levels.ERROR)
	end
end

-- Main preview function
function M.preview()
	-- Save the current buffer if it's modified
	if vim.bo.modified then
		vim.cmd("write")
	end

	-- Use configured preview command if available
	if config.options.preview_command then
		if type(config.options.preview_command) == "function" then
			config.options.preview_command()
		else
			vim.cmd(config.options.preview_command)
		end
		return
	end

	-- Otherwise, detect and use available preview plugin
	local plugin = M.detect_preview_plugin()

	if plugin == "markdown-preview.nvim" then
		preview_with_markdown_preview()
	elseif plugin == "peek.nvim" then
		preview_with_peek()
	elseif plugin == "glow.nvim" then
		preview_with_glow()
	elseif plugin == "nvim-markdown-preview" then
		preview_with_nvim_markdown_preview()
	else
		-- Fallback to system default application
		preview_with_system()
	end
end

return M
