-- tests/minimal_init.lua
-- Add the plugin's root directory and the locally cloned plenary.nvim directory to runtimepath
local plugin_root = vim.fn.getcwd()
local plenary_path = plugin_root .. "/plenary.nvim"

vim.opt.runtimepath:prepend(plenary_path)
vim.opt.runtimepath:prepend(plugin_root)

-- Explicitly source plenary's plugin file to register commands
vim.cmd("runtime! plugin/plenary.vim")

-- Load plenary and the plugin
require("plenary")
require("markdown-tools").setup() -- Load with default config for testing

-- NOTE: Tests are triggered by `make test`.
