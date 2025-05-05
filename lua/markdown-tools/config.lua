---@mod markdown-tools.config Configuration module

---@class MarkdownToolsKeymapConfig
---@field create_from_template string? Keymap for creating from template
---@field insert_header string? Keymap for inserting header
---@field insert_list_item string? Keymap for inserting list item
---@field insert_code_block string? Keymap for inserting code block
---@field insert_bold string? Keymap for inserting bold text
---@field insert_highlight string? Keymap for inserting highlight text
---@field insert_italic string? Keymap for inserting italic text
---@field insert_link string? Keymap for inserting link
---@field insert_table string? Keymap for inserting table
---@field insert_checkbox string? Keymap for inserting checkbox
---@field toggle_checkbox string? Keymap for toggling checkbox
---@field preview string? Keymap for previewing markdown

---@class MarkdownToolsCommandEnableConfig
---@field create_from_template boolean Enable create from template command
---@field insert_header boolean Enable insert header command
---@field insert_code_block boolean Enable insert code block command
---@field insert_bold boolean Enable insert bold text command
---@field insert_highlight boolean Enable insert highlight text command
---@field insert_italic boolean Enable insert italic text command
---@field insert_link boolean Enable insert link command
---@field insert_table boolean Enable insert table command
---@field insert_checkbox boolean Enable insert checkbox command
---@field toggle_checkbox boolean Enable toggle checkbox command
---@field preview boolean Enable preview command

---@class MarkdownToolsConfig
---@field template_dir string Directory for templates
---@field picker 'fzf' | 'snacks' | 'telescope' Picker to use for file selection
---@field alias string[] Default aliases for new markdown files
---@field tags string[] Default tags for new markdown files
---@field insert_frontmatter boolean Automatically add frontmatter when creating new markdown files with e.g. `MarkdownNewTemplate`.
---@field frontmatter_id fun(opts: {timestamp: string, filename: string, sanitized_name: string, filepath: string}):string | nil Function to generate the 'id' field in the frontmatter. Return nil to omit the id field.
---@field frontmatter_title fun(opts: {timestamp: string, filename: string, sanitized_name: string, filepath: string}):string | nil Function to generate the 'title' field in the frontmatter. Return nil to omit the title field.
---@field frontmatter_alias fun(opts: {timestamp: string, filename: string, sanitized_name: string, filepath: string}):string[] | nil Function to generate the 'alias' field in the frontmatter. Return nil to omit the alias field.
---@field frontmatter_tags fun(opts: {timestamp: string, filename: string, sanitized_name: string, filepath: string}):string[] | nil Function to generate the 'tags' field in the frontmatter. Return nil to omit the tags field.
---@field frontmatter_date fun(opts: {timestamp: string, filename: string, sanitized_name: string, filepath: string}):string | nil Function to generate the 'date' field in the frontmatter. Return nil to omit the date field.
---@field frontmatter_custom table<string, fun(opts: {timestamp: string, filename: string, sanitized_name: string, filepath: string}):string|string[]|nil> Table defining custom frontmatter fields and their generator functions.
---@field keymaps MarkdownToolsKeymapConfig Keymappings for markdown shortcuts
---@field commands MarkdownToolsCommandEnableConfig Configuration for enabling/disabling commands
---@field preview_command string|function|nil Command or function to use for previewing markdown
---@field enable_local_options boolean Whether to enable local options for markdown files
---@field wrap boolean Whether to enable line wrapping for markdown files
---@field conceallevel number Conceallevel for markdown files
---@field concealcursor string Concealcursor for markdown files
---@field spell boolean Whether to enable spell checking for markdown files
---@field spelllang string Language for spell checking
---@field file_types string[] File types where keymaps should be active
---@field continue_lists_on_enter boolean Automatically continue lists on Enter

local M = {}

---@return MarkdownToolsConfig
local function get_defaults()
  return {
    template_dir = vim.g.template_dir or vim.fn.expand("~/.config/nvim/templates"),
    picker = "fzf",
    alias = {},
    tags = {},
    insert_frontmatter = true, -- Add frontmatter by default
    frontmatter_id = function(opts)
      return opts.timestamp .. "_" .. opts.sanitized_name
    end,
    frontmatter_title = function(opts)
      -- Default title is the filename without extension
      return vim.fn.fnamemodify(opts.filename, ":t:r")
    end,
    frontmatter_alias = function(_opts) -- Default: empty list
      return {}
    end,
    frontmatter_tags = function(_opts) -- Default: empty list
      return {}
    end,
    frontmatter_date = function(_opts) -- Default: YYYY-MM-DD
      return os.date("%Y-%m-%d")
    end,
    frontmatter_custom = {}, -- Default: no custom fields
    keymaps = {
      -- Default keymaps (empty means no default keymaps)
      -- Users can configure these in their setup function
      create_from_template = "<leader>mnt", -- New Template
      insert_header = "<leader>mH", -- Header
      insert_list_item = "",
      insert_code_block = "<leader>mc", -- Code block
      insert_bold = "<leader>mb", -- Bold
      insert_highlight = "<leader>mh", -- Highlight
      insert_italic = "<leader>mi", -- Italic
      insert_link = "<leader>ml", -- Link
      insert_table = "<leader>mt", -- Table
      insert_checkbox = "<leader>mk", -- Checkbox
      toggle_checkbox = "<leader>mx", -- Toggle Checkbox
      preview = "<leader>mp", -- Preview
    },
    commands = {
      create_from_template = true,
      insert_header = true,
      insert_code_block = true,
      insert_bold = true,
      insert_highlight = true,
      insert_italic = true,
      insert_link = true,
      insert_table = true,
      insert_checkbox = true,
      toggle_checkbox = true,
      preview = false, -- Disabled by default
    },
    preview_command = nil, -- Will use a default based on available plugins

    -- Markdown file local options
    enable_local_options = true,
    wrap = true,
    conceallevel = 2,
    concealcursor = "nc",
    spell = true,
    spelllang = "en_us",
    file_types = { "markdown" }, -- Default to markdown
    continue_lists_on_enter = true, -- Added new option
  }
end

-- Initialize options with defaults
---@type MarkdownToolsConfig
M.options = get_defaults()

--- Merges user options with defaults and stores them.
---@param opts? MarkdownToolsConfig User configuration options.
---@return boolean success Whether setup was successful
function M.setup(opts)
  -- Merge user options into the existing defaults
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- Validate essential config
  if not M.options.template_dir or M.options.template_dir == "" then
    vim.notify("markdown-tools: template_dir is not configured.", vim.log.levels.ERROR)
    -- Optionally set a default fallback here if desired, but erroring is safer
    -- M.options.template_dir = vim.fn.expand("~/.config/nvim/templates")
    return false -- Indicate setup failure
  end
  return true -- Indicate setup success
end

return M
