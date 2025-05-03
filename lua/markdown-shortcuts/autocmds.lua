-- Autocommands setup functionality
local M = {}

--- Setup autocommands for markdown files
---@param options table Plugin configuration options
function M.setup_autocmds(options)
	-- Create autocommand group
	local augroup = vim.api.nvim_create_augroup("MarkdownShortcuts", { clear = true })

	-- Set up autocommands for markdown files
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = "markdown",
		callback = function()
			-- Set up local options for markdown files
			if options.enable_local_options then
				vim.opt_local.wrap = options.wrap
				vim.opt_local.conceallevel = options.conceallevel
				vim.opt_local.concealcursor = options.concealcursor
				vim.opt_local.spell = options.spell
				vim.opt_local.spelllang = options.spelllang
			end
		end,
	})
end

return M
