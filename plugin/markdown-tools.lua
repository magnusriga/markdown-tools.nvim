-- Entry point for the plugin when loaded via packer/lazy legacy `plugin/` directory
-- This just calls the setup function from the main module.

-- Check if the main module is already loaded (e.g., by lazy.nvim `opts` or `config`)
-- Avoid running setup twice.
if not package.loaded["markdown-tools"] then
  pcall(require, "markdown-tools")
end
