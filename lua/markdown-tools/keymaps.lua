---@mod markdown-tools.keymaps Keymap setup functionality
local M = {}

--- Set up a keymap if the key is defined
---@param mode string|string[] The mode(s) for the keymap
---@param key string|nil The key to map
---@param cmd string|function The command to execute or function to call
---@param desc string Description of the keymap
---@param opts? table Additional options for the keymap
local function setup_keymap(mode, key, cmd, desc, opts)
  if key and key ~= "" then
    opts = opts or {}
    opts.desc = desc
    vim.keymap.set(mode, key, cmd, opts)
  end
end

--- Setup keymaps for markdown files
---@param keymaps table Keymap configuration
---@param commands_enabled table Command enable configuration
---@param file_types string[] List of file types to apply keymaps to
function M.setup_keymaps(keymaps, commands_enabled, file_types)
  -- Register the global keymap for create_from_template first
  if commands_enabled.create_from_template then
    setup_keymap(
      "n", -- Mode
      keymaps.create_from_template, -- Key
      "<cmd>MarkdownNewTemplate<CR>", -- Command
      "Create from template", -- Description
      {} -- Global keymap, no buffer option needed
    )
  end

  -- Create a dedicated augroup for buffer-local keymaps
  local augroup = vim.api.nvim_create_augroup("MarkdownShortcutsBufferKeymaps", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = file_types, -- Use the configured file types
    callback = function()
      -- Define keymap configurations (excluding create_from_template)
      local keymap_configs = {
        {
          command_key = "insert_header",
          mode = { "n", "v" },
          key = keymaps.insert_header,
          cmd = "<cmd>MarkdownHeader<CR>",
          desc = "Header",
        },
        {
          command_key = "insert_code_block",
          mode = "n", -- Normal mode only
          key = keymaps.insert_code_block,
          cmd = function()
            require("markdown-tools.commands").insert_code_block({ range = 0 })
          end,
          desc = "Code block (Normal)",
        },
        {
          command_key = "insert_code_block",
          mode = "v", -- Visual mode only
          key = keymaps.insert_code_block,
          cmd = function()
            require("markdown-tools.commands").insert_code_block({ range = 2 })
          end,
          desc = "Code block (Visual)",
        },
        {
          command_key = "insert_bold",
          mode = "n", -- Normal mode only
          key = keymaps.insert_bold,
          cmd = function()
            -- Call command function (prompts for input in normal mode)
            require("markdown-tools.commands").insert_bold({ range = 0 }) -- Explicitly pass range 0
          end,
          desc = "Bold text (Normal)",
        },
        {
          command_key = "insert_bold",
          mode = "v", -- Visual mode only
          key = keymaps.insert_bold,
          -- Use Vim command sequence for visual wrapping
          cmd = 's**<C-r>"**<Esc>',
          desc = "Bold text (Visual)",
          opts = { remap = true }, -- Allow remapping <C-r>
        },
        {
          command_key = "insert_highlight",
          mode = "n", -- Normal mode only
          key = keymaps.insert_highlight,
          cmd = function()
            -- Call command function (prompts for input in normal mode)
            require("markdown-tools.commands").insert_highlight({ range = 0 }) -- Explicitly pass range 0
          end,
          desc = "Highlight text (Normal)",
        },
        {
          command_key = "insert_highlight",
          mode = "v", -- Visual mode only
          key = keymaps.insert_highlight,
          -- Use Vim command sequence for visual wrapping
          cmd = 's==<C-r>"==<Esc>',
          desc = "Highlight text (Visual)",
          opts = { remap = true }, -- Allow remapping <C-r>
        },
        {
          command_key = "insert_italic",
          mode = "n", -- Normal mode only
          key = keymaps.insert_italic,
          cmd = function()
            -- Call command function (prompts for input in normal mode)
            require("markdown-tools.commands").insert_italic({ range = 0 }) -- Explicitly pass range 0
          end,
          desc = "Italic text (Normal)",
        },
        {
          command_key = "insert_italic",
          mode = "v", -- Visual mode only
          key = keymaps.insert_italic,
          -- Use Vim command sequence for visual wrapping
          cmd = 's*<C-r>"*<Esc>',
          desc = "Italic text (Visual)",
          opts = { remap = true }, -- Allow remapping <C-r>
        },
        {
          command_key = "insert_link",
          mode = "n", -- Normal mode only
          key = keymaps.insert_link,
          cmd = function()
            require("markdown-tools.commands").insert_link({ range = 0 })
          end,
          desc = "Link (Normal)",
        },
        {
          command_key = "insert_link",
          mode = "v", -- Visual mode only
          key = keymaps.insert_link,
          -- Use Vim command sequence + Lua helper for prompt
          -- 1. Substitute selection: `s[<C-r>"]()`
          -- 2. Exit substitute mode: `<Esc>`
          -- 3. Move cursor left: `<Cmd>normal! h<CR>`
          -- 4. Enter insert mode (before cursor): `<Cmd>startinsert<CR>`
          -- 5. Call Lua helper to prompt and insert URL
          cmd = 's[<C-r>"]()<Esc><Cmd>normal! h<CR><Cmd>startinsert<CR><Cmd>lua require("markdown-tools.commands").prompt_and_insert_url()<CR>',
          desc = "Link (Visual)",
        },
        {
          command_key = "insert_table",
          mode = "n",
          key = keymaps.insert_table,
          cmd = "<cmd>MarkdownInsertTable<CR>",
          desc = "Insert table",
        },
        {
          command_key = "insert_checkbox",
          mode = { "n", "v" },
          key = keymaps.insert_checkbox,
          cmd = function()
            -- Esc first, in case in visual mode.
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
            require("markdown-tools.commands").insert_checkbox()
          end,
          desc = "Checkbox",
        },
        {
          command_key = "toggle_checkbox", -- Renamed key
          mode = "n",
          key = keymaps.toggle_checkbox, -- Renamed key
          cmd = "<cmd>MarkdownToggleCheckbox<CR>", -- Renamed command
          desc = "Toggle checkbox", -- Updated description
        },
        {
          command_key = "preview",
          mode = "n",
          key = keymaps.preview,
          cmd = "<cmd>MarkdownPreview<CR>",
          desc = "Preview markdown",
        },
      }

      -- Apply all buffer-local keymap configurations
      for _, config in ipairs(keymap_configs) do
        -- Only set keymap if the command is enabled
        if commands_enabled[config.command_key] then
          -- Combine base opts with config-specific opts
          -- Add buffer = true for these buffer-local keymaps
          local base_opts = { desc = config.desc, buffer = true }
          local final_opts = vim.tbl_extend("force", base_opts, config.opts or {})

          -- Use setup_keymap helper
          setup_keymap(config.mode, config.key, config.cmd, config.desc, final_opts)
        end
      end

      -- Add keymap for continuing lists on Enter if enabled (buffer-local)
      if require("markdown-tools.config").options.continue_lists_on_enter then
        vim.keymap.set(
          "i",
          "<CR>",
          require("markdown-tools.lists").keymap_init,
          { buffer = true, desc = "Continue Markdown List", expr = true }
        )
      end
    end,
  })
end

return M
