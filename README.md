# markdown-tools.nvim 🪄

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License](https://img.shields.io/github/license/magnusriga/markdown-tools.nvim?style=flat-square)](LICENSE)
[![Neovim >= 0.8.0](https://img.shields.io/badge/Neovim-%3E%3D%200.8.0-blueviolet.svg?style=flat-square)](https://neovim.io/)
[![CI Status](https://img.shields.io/github/actions/workflow/status/magnusriga/markdown-tools.nvim/ci.yml?branch=main&style=flat-square)](https://github.com/magnusriga/markdown-tools.nvim/actions/workflows/ci.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/magnusriga/markdown-tools.nvim?style=flat-square)](https://github.com/magnusriga/markdown-tools.nvim/releases/latest)

> Enhancing your Markdown editing experience in Neovim with intuitive shortcuts and commands.

`markdown-tools.nvim` provides a set of commands and configurable keymaps to streamline common Markdown editing tasks, from inserting elements like headers and code blocks to managing checkbox lists and creating files from templates.

For users migrating from plugins like [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim), `markdown-tools.nvim` aims to fill some gaps by offering features such as creating new notes based on templates with predefined frontmatter, helping maintain a familiar workflow.

The markdown created, including the frontmatter, is compatible with [obsidian](https://obsidian.md/) and other Markdown editors.

## ✨ Features

- **📝 Template Creation:** Create new Markdown files from predefined templates, using picker `snacks`, `fzf-lua`, or `telescope`. Automatically adds configurable frontmatter with placeholders (e.g., `alias`, `tags`).
- **🧱 Insert Markdown Elements:** Quickly add links, checkboxes, tables, headers, bold/italic/highlight text, code blocks, ++.
- **🎨 Visual Mode Integration:** Wrap selected text with bold, italic, links, or highlights.
- **✅ Checkbox Management:** Insert new checkboxes and toggle their state.
- **➡️ List Continuation:** Automatically continue lists (bullets, numbers, checkboxes) on Enter.
- **🔧 Configurable:** Customize keymaps, enable/disable commands, set template directory, choose picker, configure buffer options, ++.
- **👁️ Preview:** Preview command, using other auto-detected nvim plugins (see below) or default system application.

## ⚡️ Requirements

- Neovim >= 0.8.0
- Optional: A picker plugin (`snacks.nvim`, `fzf-lua`, or `telescope.nvim`) for the template creation feature.

## 📦 Installation

Use your favorite plugin manager.

### lazy.nvim

```lua
{
  'magnusriga/markdown-tools.nvim',
  -- Optional dependencies for picker:
  -- dependencies = { 'folke/snacks.nvim' },
  -- dependencies = { 'ibhagwan/fzf-lua' },
  -- dependencies = { 'nvim-telescope/telescope.nvim' },
  opts = {
      -- Your custom configuration here
      -- Example: Use fzf-lua for template picking
      -- picker = 'fzf',
  },
}
```

### packer.nvim

```lua
use {
  'magnusriga/markdown-tools.nvim',
  -- Optional dependencies:
  -- requires = { 'folke/snacks.nvim' },
  -- requires = { 'ibhagwan/fzf-lua' },
  -- requires = { 'nvim-telescope/telescope.nvim' },
  ft = { "markdown" },
  config = function()
    require('markdown-tools').setup({
      -- Configuration goes here
    })
  end,
}
```

## ⚙️ Configuration

Call the `setup` function to configure the plugin. Here are the default settings:

```lua
-- Default configuration
require('markdown-tools').setup({
  -- Directory containing your Markdown templates
  template_dir = vim.fn.expand("~/.config/nvim/templates"),

  -- Picker to use for selecting templates ('fzf', 'telescope', 'snacks')
  picker = "fzf",

  -- Whether to automatically insert frontmatter if the template doesn't have it
  insert_frontmatter = true,

  -- Functions to generate frontmatter fields.
  -- These functions determine the values used when automatically inserting frontmatter
  -- AND when replacing placeholders in templates.
  -- Each function receives a table `opts` with:
  --   opts.timestamp (string): YYYYMMDDHHMM
  --   opts.filename (string): Full filename including .md extension.
  --   opts.sanitized_name (string): Filename sanitized for use in IDs.
  --   opts.filepath (string): Absolute path to the new file.
  -- Return nil from a function to omit that field from automatically generated frontmatter
  -- and replace its corresponding placeholder with an empty string.

  -- Corresponds to {{id}} placeholder
  frontmatter_id = function(opts)
    -- Default: YYYYMMDDHHMM_sanitized-filename
    return opts.timestamp .. "_" .. opts.sanitized_name
  end,

  -- Corresponds to {{title}} placeholder
  frontmatter_title = function(opts)
    -- Default: Filename without extension
    return vim.fn.fnamemodify(opts.filename, ":t:r")
  end,

  -- Corresponds to {{alias}} placeholder (expects a list/table of strings)
  frontmatter_alias = function(_opts)
    -- Default: Empty list
    return {}
  end,

  -- Corresponds to {{tags}} placeholder (expects a list/table of strings)
  frontmatter_tags = function(_opts)
    -- Default: Empty list
    return {}
  end,

  -- Corresponds to {{date}} placeholder
  frontmatter_date = function(_opts)
    -- Default: Current date YYYY-MM-DD
    return os.date("%Y-%m-%d")
  end,

  -- Define custom frontmatter fields and their generator functions.
  -- The key is the field name (used in frontmatter and as the placeholder {{key}}).
  -- The value is a function receiving the `opts` table.
  -- It can return a string, a table (list) of strings, or nil.
  frontmatter_custom = {},
  -- Example of how to define custom fields:
  -- frontmatter_custom = {
  --   status = function(_opts) return "draft" end,
  --   related = function(_opts) return {} end,
  -- },

  -- Keymappings for shortcuts. Set to `false` or `""` to disable.
  keymaps = {
    create_from_template = "<leader>mnt", -- New Template
    insert_header = "<leader>mH",        -- Header
    insert_code_block = "<leader>mc",    -- Code block
    insert_bold = "<leader>mb",        -- Bold
    insert_highlight = "<leader>mh",    -- Highlight
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

### Types

Here are the type definitions for the configuration options:

```lua
---@class KeymapConfig
---@field create_from_template string? Keymap for creating from template
---@field insert_header string? Keymap for inserting header
---@field insert_list_item string? Keymap for inserting list item
---@field insert_code_block string? Keymap for inserting code block
---@field insert_bold string? Keymap for inserting bold text
---@field insert_italic string? Keymap for inserting italic text
---@field insert_link string? Keymap for inserting link
---@field insert_table string? Keymap for inserting table
---@field insert_checkbox string? Keymap for inserting checkbox
---@field toggle_checkbox string? Keymap for toggling checkbox
---@field preview string? Keymap for previewing markdown

---@class CommandEnableConfig
---@field create_from_template boolean Enable create from template command
---@field insert_header boolean Enable insert header command
---@field insert_code_block boolean Enable insert code block command
---@field insert_bold boolean Enable insert bold text command
---@field insert_italic boolean Enable insert italic text command
---@field insert_link boolean Enable insert link command
---@field insert_table boolean Enable insert table command
---@field insert_checkbox boolean Enable insert checkbox command
---@field toggle_checkbox boolean Enable toggle checkbox command
---@field preview boolean Enable preview command

---@class Config
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
---@field keymaps KeymapConfig Keymappings for markdown shortcuts
---@field commands CommandEnableConfig Configuration for enabling/disabling commands
---@field preview_command string|function|nil Command or function to use for previewing markdown
---@field enable_local_options boolean Whether to enable local options for markdown files
---@field wrap boolean Whether to enable line wrapping for markdown files
---@field conceallevel number Conceallevel for markdown files
---@field concealcursor string Concealcursor for markdown files
---@field spell boolean Whether to enable spell checking for markdown files
---@field spelllang string Language for spell checking
---@field file_types string[] File types where keymaps should be active
---@field continue_lists_on_enter boolean Automatically continue lists on Enter
```

## 🚀 Usage

### 💻 Commands

The following commands are available, most work in both visual and normal mode:

- `:MarkdownNewTemplate`: Select a template from `template_dir` using the configured picker and create a new file.
- `:MarkdownHeader`: Insert a header. Prompts for level (1-6) or uses `[count]` (e.g., `:3MarkdownHeader`). In Visual mode, wraps selection.
- `:MarkdownCodeBlock`: Insert a code block. Prompts for language. In Visual mode, wraps selection.
- `:MarkdownBold`: Insert `**bold text**`. In Visual mode, wraps selection.
- `:MarkdownHighlight`: Insert `==highlight text==`. In Visual mode, wraps selection.
- `:MarkdownItalic`: Insert `*italic text*`. In Visual mode, wraps selection.
- `:MarkdownLink`: Insert `[link text](url)`. Prompts for text and URL. In Visual mode, uses selection as text and prompts for URL.
- `:MarkdownInsertTable`: Insert a table. Prompts for rows and columns.
- `:MarkdownCheckbox`: Insert a checkbox list item (`- [ ]`). In Visual mode, uses selection as text.
- `:MarkdownToggleCheckbox`: Toggles the checkbox state (`[ ]` <=> `[x]`) on the current line.
- `:MarkdownPreview`: Preview markdown. Saves the current file, then attempts to preview using: 1) the configured `preview_command`, 2) an auto-detected plugin (`markdown-preview.nvim`, `peek.nvim`, `glow.nvim`, `nvim-markdown-preview`), or 3) the system's default application as a fallback.

### ⌨️ Keymaps

Default keymaps are provided (see Configuration). Use them in Normal or Visual mode within Markdown files.

- `<leader>mH`: Insert header.
- `<leader>mc`: Insert code block.
- `<leader>mb`: Insert bold.
- `<leader>mh`: Insert highlight.
- `<leader>mi`: Insert italic.
- `<leader>ml`: Insert link.
- `<leader>mt`: Insert table.
- `<leader>mk`: Insert checkbox.
- `<leader>mx`: Toggle checkbox.
- `<leader>mp`: Preview (if configured).
- `<leader>mnt`: Create new file from template.

### 📝 Creating Markdown Files from Templates

The `:MarkdownNewTemplate` command (default keymap `<leader>mnt`) allows you to create new Markdown files based on templates stored in your configured `template_dir`.

> [!NOTE]
> Placeholders in the template, including in any frontmatter, are replaced using the `frontmatter_*` functions in the config (more info below).

#### Frontmatter Handling

When creating a file from a template, the configured frontmatter generator functions (`frontmatter_id`, `frontmatter_title`, `frontmatter_custom`, etc.) are always executed first to produce values for the standard and custom fields.

These generated values are then used in two ways:

1. **Placeholder Replacement:** The content of the selected template file is processed. The following placeholders are supported and replaced with their corresponding generated values:

   - `{{id}}`: Value from `frontmatter_id` function.
   - `{{title}}`: Value from `frontmatter_title` function.
   - `{{date}}`: Value from `frontmatter_date` function.
   - `{{alias}}`: YAML list format of values from `frontmatter_alias` function (e.g., `["alias1", "alias2"]`).
   - `{{tags}}`: YAML list format of values from `frontmatter_tags` function (e.g., `["tag1", "tag2"]`).
   - `{{datetime}}`: Current date and time (YYYY-MM-DD HH:MM:SS). Generated internally.
   - `{{timestamp}}`: Timestamp used during generation (YYYYMMDDHHMM). Generated internally.
   - `{{key}}`: For each key in `frontmatter_custom`, the corresponding placeholder `{{key}}` is replaced by the value returned by its function. If the function returns a list, it's inserted in YAML list format (e.g., `["item1", "item2"]`).

> [!NOTE]
> If a generator function returns `nil`, the corresponding placeholder is replaced with an empty string. **Any other text within double curly braces (e.g., `{{unsupported}}`) that does not match a supported placeholder will be left unchanged in the template content.**

2. **Automatic Frontmatter Insertion:** After placeholder replacement, the plugin checks if the template content starts with `---`.
   - If it **does not** start with `---` AND the `insert_frontmatter` configuration option is `true` (the default), a new frontmatter block is automatically added to the beginning of the file. This block includes all fields (standard and custom) for which the generator function returned a non-nil value, formatted correctly in YAML. List values will be formatted like `tags: [tag1, tag2]`.
   - If it **does** start with `---`, or if `insert_frontmatter` is `false`, no new frontmatter block is inserted. The template's existing frontmatter (with placeholders already replaced) is kept as is.

### ✅ List Continuation

When `continue_lists_on_enter` is `true`, pressing `Enter` in a Markdown list item (bullet `*`, `-`, `+`; numbered `1.`; checkbox `- [ ]`, `- [x]`) will automatically insert the next list marker on the new line.

## 📈 Status

Stable. Contributions and suggestions are welcome.

## 🛠️ Development

Contributions are welcome! Please follow the guidelines below for setting up your development environment and submitting changes.

### Setup

1. **Fork and Clone:** Fork the repository on GitHub and clone your fork locally.
2. **Dependencies:**
    - **Neovim:** >= 0.8.0
    - **Plenary.nvim:** Required for testing. Included as a submodule or managed by your plugin manager during development.
    - **Node.js & npm:** Required for commit linting (`commitlint`, `husky`) and release automation (`semantic-release`). Install via your system package manager or [nvm](https://github.com/nvm-sh/nvm).
3. **Install Node Modules:** Run `npm install` in the project root to install development dependencies listed in `package.json`, including `husky` for Git hooks.

### Testing

- Run the test suite using the provided script:

  ```bash
  make test
  # or directly:
  # ./scripts/test
  ```

- Ensure all tests pass before submitting a pull request. Add new tests for new features or bug fixes.

### Linting and Formatting

- This project uses `stylua` for Lua code formatting.
- Check formatting:

  ```bash
  make lint
  # or directly:
  # stylua --check .
  ```

- Apply formatting:

  ```bash
  make format
  # or directly:
  # stylua .
  ```

### Commit Conventions

- This project follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.
- Commit messages must adhere to this format (e.g., `feat: ...`, `fix: ...`, `chore: ...`).
- The `commit-msg` Git hook (managed by `husky`) will automatically check your commit messages using `commitlint`.

### Branching and Pull Requests

- Create feature branches from the `main` branch.
- Direct commits to `main` are blocked by a `pre-commit` Git hook.
- Submit Pull Requests to the `main` branch of the upstream repository.

### Release Process

- Releases are fully automated using `semantic-release` running in GitHub Actions.
- When commits following the Conventional Commits specification are merged into `main`, `semantic-release` automatically determines the next version, updates the `CHANGELOG.md`, creates a Git tag, and publishes a GitHub Release.
- Manual tagging or changelog updates are not required.

## 🤝 Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more details on reporting bugs, suggesting features, and the pull request process.

## 📜 License

Distributed under the MIT License. See `LICENSE` file for more information.

## 🙏 Credits

- [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim): For inspiration on various features, including creating Markdown notes from templates.
