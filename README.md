# markdown-shortcuts.nvim

<!-- Badges (replace with actual badges) -->

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License](https://img.shields.io/github/license/magnusriga/markdown-shortcuts.nvim?style=flat-square)](LICENSE)

> Enhancing your Markdown editing experience in Neovim with intuitive shortcuts and commands.

`markdown-shortcuts.nvim` provides a set of commands and configurable keymaps to streamline common Markdown editing tasks, from inserting elements like headers and code blocks to managing checkbox lists and creating files from templates.

## ✨ Features

- **Insert Markdown Elements:** Quickly add headers, code blocks (with language prompt), bold/italic text, links, tables, and checkbox list items.
- **Visual Mode Integration:** Wrap selected text with bold, italic, links, or code blocks.
- **Checkbox Management:** Insert new checkboxes (`- [ ]`) and toggle their state (`- [x]`).
- **Template Creation:** Create new Markdown files from predefined templates using your choice of picker (`fzf`, `telescope`, `mini.pick`).
- **List Continuation:** Automatically continue Markdown lists (bulleted, numbered, checkbox) when pressing Enter.
- **Configurable:** Customize keymaps, enable/disable commands, set template directory, choose picker, and configure Markdown-specific buffer options.
- **Preview:** Basic preview command (requires external tool configuration).

## ⚡️ Requirements

- Neovim >= 0.8.0
- Optional: A picker plugin (`fzf`/`fzf.vim`, `telescope.nvim`, or `mini.pick`) for the template creation feature.
- Optional: An external Markdown preview tool (like `glow`, `pandoc`, etc.) if using the `MarkdownPreview` command.

## 📦 Installation

Use your favorite plugin manager.

**lazy.nvim**

```lua
{
  'magnusriga/markdown-shortcuts.nvim',
  -- Optional dependencies for picker:
  -- dependencies = { 'nvim-telescope/telescope.nvim' },
  -- dependencies = { 'junegunn/fzf', 'junegunn/fzf.vim' },
  -- dependencies = { 'echasnovski/mini.nvim' }, -- If using mini.pick
  event = "FileType markdown", -- Load when a markdown file is opened
  config = function()
    require('markdown-shortcuts').setup({
      -- Your custom configuration here
      -- Example: Use Telescope for template picking
      -- picker = 'telescope',
    })
  end,
}
```

**packer.nvim**

```lua
use {
  'magnusriga/markdown-shortcuts.nvim',
  -- Optional dependencies:
  -- requires = { 'nvim-telescope/telescope.nvim' },
  -- requires = { 'junegunn/fzf', run = ':call fzf#install()' },
  -- requires = { 'echasnovski/mini.nvim' },
  ft = { "markdown" },
  config = function()
    require('markdown-shortcuts').setup({
      -- Configuration goes here
    })
  end,
}
```

## ⚙️ Configuration

Call the `setup` function to configure the plugin. Here are the default settings:

```lua
-- Default configuration
require('markdown-shortcuts').setup({
  -- Directory containing your Markdown templates
  template_dir = vim.fn.expand("~/.config/nvim/templates"),

  -- Picker to use for selecting templates ('fzf', 'telescope', 'snacks'/'mini.pick')
  picker = "fzf",

  -- Default frontmatter fields for new files created from templates
  alias = {},
  tags = {},

  -- Keymappings for shortcuts. Set to `false` or `""` to disable.
  keymaps = {
    create_from_template = "<leader>mnt", -- New Template
    insert_header = "<leader>mh",        -- Header (use count for level)
    insert_list_item = "",              -- (No default, handled by list continuation)
    insert_code_block = "<leader>mc",    -- Code block
    insert_bold = "<leader>mb",        -- Bold
    insert_italic = "<leader>mi",      -- Italic
    insert_link = "<leader>ml",        -- Link
    insert_table = "<leader>mt",        -- Table
    insert_checkbox = "<leader>mk",    -- Checkbox
    toggle_checkbox = "<leader>mx",    -- Toggle Checkbox
    preview = "<leader>mp",          -- Preview
  },

  -- Enable/disable specific commands
  commands = {
    create_from_template = true,
    insert_header = true,
    insert_code_block = true,
    insert_bold = true,
    insert_italic = true,
    insert_link = true,
    insert_table = true,
    insert_checkbox = true,
    toggle_checkbox = true,
    preview = false, -- Requires `preview_command` to be set
  },

  -- Command or Lua function to execute for Markdown preview.
  -- Example: 'glow %' (requires glow) or `function() ... end`
  preview_command = nil,

  -- Apply local buffer settings for Markdown files
  enable_local_options = true,
  wrap = true,
  conceallevel = 2,
  concealcursor = "nc",
  spell = true,
  spelllang = "en_us",

  -- File types where keymaps should be active
  file_types = { "markdown" },

  -- Automatically continue lists (bullet, numbered, checkbox) on Enter
  continue_lists_on_enter = true,
})
```

## 🚀 Usage

### Commands

The following commands are available (if enabled in `config.commands`):

- `:MarkdownNewTemplate`: Select a template from `template_dir` using the configured picker and create a new file.
- `:MarkdownHeader`: Insert a header. Prompts for level (1-6) or uses `[count]` (e.g., `:3MarkdownHeader`). In Visual mode, wraps selection.
- `:MarkdownCodeBlock`: Insert a code block. Prompts for language. In Visual mode, wraps selection.
- `:MarkdownBold`: Insert `**bold text**`. In Visual mode, wraps selection.
- `:MarkdownItalic`: Insert `*italic text*`. In Visual mode, wraps selection.
- `:MarkdownLink`: Insert `[link text](url)`. Prompts for text and URL. In Visual mode, uses selection as text and prompts for URL.
- `:MarkdownInsertTable`: Insert a table. Prompts for rows and columns.
- `:MarkdownCheckbox`: Insert a checkbox list item (`- [ ]`). In Visual mode, uses selection as text.
- `:MarkdownToggleCheckbox`: Toggles the checkbox state (`[ ]` <=> `[x]`) on the current line.
- `:MarkdownPreview`: Executes the configured `preview_command`.

### Keymaps

Default keymaps are provided (see Configuration). Use them in Normal or Visual mode within Markdown files.

- `<leader>mh`: Insert header (prompts or use count).
- `<leader>mc`: Insert code block.
- `<leader>mb`: Insert bold.
- `<leader>mi`: Insert italic.
- `<leader>ml`: Insert link.
- `<leader>mt`: Insert table.
- `<leader>mk`: Insert checkbox.
- `<leader>mx`: Toggle checkbox.
- `<leader>mp`: Preview (if configured).
- `<leader>mnt`: Create new file from template.

### List Continuation

When `continue_lists_on_enter` is `true`, pressing `Enter` in a Markdown list item (bullet `*`, `-`, `+`; numbered `1.`; checkbox `- [ ]`, `- [x]`) will automatically insert the next list marker on the new line.

## Status

Stable. Contributions and suggestions are welcome.

## Contributing

Please see CONTRIBUTING.md (if available) or open an issue/pull request.

## License

Distributed under the MIT License. See `LICENSE` file for more information.
