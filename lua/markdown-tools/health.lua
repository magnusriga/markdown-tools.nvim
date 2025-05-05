-- Health check module for markdown-tools.nvim
---@diagnostic disable: param-type-mismatch
local M = {}

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

-- Helper to check if a Lua module is available
local function check_lua_module(name)
  local success, _ = pcall(require, name)
  return success
end

function M.check()
  start("markdown-tools.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.8.0") == 1 then
    ok("Neovim version >= 0.8.0")
  else
    warn("Neovim version < 0.8.0. This plugin requires Neovim 0.8.0 or later.")
  end

  -- Check core modules load correctly
  local core_modules = {
    "markdown-tools.config",
    "markdown-tools.commands",
    "markdown-tools.keymaps",
    "markdown-tools.lists",
    "markdown-tools.picker",
    "markdown-tools.preview",
    "markdown-tools.template",
  }
  local all_core_ok = true
  for _, mod_name in ipairs(core_modules) do
    if not check_lua_module(mod_name) then
      error("Failed to load core module: " .. mod_name)
      all_core_ok = false
    end
  end
  if all_core_ok then
    ok("Core modules loaded successfully.")
  end

  -- Check configuration and template directory
  local config_ok, config = pcall(require, "markdown-tools.config")
  if not config_ok or not config.options then
    error("Failed to load configuration.")
    info("Ensure require('markdown-tools').setup({...}) is called correctly.")
    return -- Stop checks if config fails
  end

  local template_dir = config.options.template_dir
  if template_dir and template_dir ~= "" then
    if vim.fn.isdirectory(template_dir) == 1 then
      ok("Template directory exists: " .. template_dir)
      -- Check if there are template files
      local templates = vim.fn.glob(template_dir .. "/*.md", false, true)
      if #templates > 0 then
        ok("Found " .. #templates .. " template file(s) in " .. template_dir)
      else
        warn("No *.md template files found in " .. template_dir)
        info("Add some template files (e.g., note.md) to use the :MarkdownNewTemplate command.")
      end
    else
      warn("Template directory does not exist: " .. template_dir)
      info("Create this directory or update the 'template_dir' option in your setup.")
    end
  else
    warn("Template directory ('template_dir') is not configured.")
    info("Set 'template_dir' in your setup to use the template creation feature.")
  end

  -- Check picker availability if template creation is enabled
  if config.options.commands and config.options.commands.create_from_template then
    local picker = config.options.picker
    local picker_ok = false
    if picker == "fzf" then
      if vim.fn.executable("fzf") == 1 and check_lua_module("fzf-lua") then
        ok("Picker 'fzf' (fzf-lua) is available.")
        picker_ok = true
      else
        warn("Picker 'fzf' (fzf-lua) is configured but not fully available.")
        info("Ensure 'fzf' executable is in PATH and 'ibhagwan/fzf-lua' is installed.")
      end
    elseif picker == "telescope" then
      if check_lua_module("telescope") then
        ok("Picker 'telescope' is available.")
        picker_ok = true
      else
        warn("Picker 'telescope' is configured but 'telescope.nvim' is not available.")
        info("Install 'nvim-telescope/telescope.nvim'.")
      end
    elseif picker == "snacks" then
      if check_lua_module("snacks") then
        ok("Picker 'snacks' is available.")
        picker_ok = true
      else
        warn("Picker 'snacks' is configured but 'snacks.nvim' is not available.")
        info("Install 'folke/snacks.nvim'.")
      end
    else
      error("Unknown picker configured: '" .. tostring(picker) .. "'")
      info("Valid options are: 'fzf', 'telescope', 'snacks'.")
    end
    if not picker_ok then
      info("Template creation (:MarkdownNewTemplate) might not work without a valid picker.")
    end
  else
    info("Template creation command is disabled, skipping picker check.")
  end

  -- Check preview command availability if enabled
  if config.options.commands and config.options.commands.preview then
    local preview_ok, preview = pcall(require, "markdown-tools.preview")
    if not preview_ok then
      error("Failed to load preview module.")
    else
      local detected_plugin = preview.detect_preview_plugin() -- Attempt detection

      if config.options.preview_command then
        local cmd_type = type(config.options.preview_command)
        if cmd_type == "function" then
          ok("Custom preview function is configured.")
        elseif cmd_type == "string" then
          local preview_cmd_str = config.options.preview_command
          local cmd_base = vim.split(preview_cmd_str, " ", { plain = true, trimempty = true })[1]
          if cmd_base and vim.fn.executable(cmd_base) == 1 then
            ok("Preview command executable found: " .. cmd_base)
          else
            warn("Configured preview command might not be executable: " .. preview_cmd_str)
            info("Ensure the command '" .. (cmd_base or preview_cmd_str) .. "' is in your PATH.")
          end
        else
          warn("Invalid 'preview_command' type: " .. cmd_type .. ". Expected string or function.")
        end
      elseif detected_plugin then
        ok("Using auto-detected preview plugin: " .. detected_plugin)
      else
        warn(
          "Preview command is enabled but no 'preview_command' is set and no supported preview plugin (glow.nvim, markdown-preview.nvim) was detected."
        )
        info("Set 'preview_command' in your setup or install a supported preview plugin.")
      end
    end
  else
    info("Preview command is disabled.")
  end

  -- Check if keymaps are set (basic check)
  if config.options.keymaps and next(config.options.keymaps) then
    local keymap_count = 0
    for _, v in pairs(config.options.keymaps) do
      if v and v ~= "" and v ~= false then
        keymap_count = keymap_count + 1
      end
    end
    if keymap_count > 0 then
      ok("Found " .. keymap_count .. " active keymap(s) configured.")
    else
      info("No active keymaps seem to be configured in the 'keymaps' table.")
    end
  else
    info("Keymaps table is empty or missing in configuration.")
  end
end

return M
