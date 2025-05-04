-- Plugin specification for lazy.nvim
return {
  "magnusriga/markdown-tools.nvim",
  name = "markdown-tools",
  version = "*",
  lazy = true,
  ft = { "markdown" },
  cmd = {
    "MarkdownNewTemplate",
    "MarkdownHeader",
    "MarkdownCodeBlock",
    "MarkdownBold",
    "MarkdownItalic",
    "MarkdownLink",
    "MarkdownInsertTable",
    "MarkdownCheckbox",
    "MarkdownToggleCheckbox",
    "MarkdownPreview",
  },
  dependencies = {
    -- Optional dependencies, will be used if available
    { "folke/snacks.nvim", optional = true },
  },
  config = function(_, opts)
    require("markdown-tools").setup(opts)
  end,
  -- Default configuration
  opts = {
    template_dir = vim.fn.stdpath("config") .. "/templates",
    picker = "fzf",
    alias = {},
    tags = {},
    keymaps = {
      create_from_template = "",
      insert_header = "",
      insert_list_item = "",
      insert_code_block = "",
      insert_bold = "",
      insert_italic = "",
      insert_link = "",
      insert_table = "",
      insert_checkbox = "",
      toggle_checkbox = "",
      preview = "",
    },
    preview_command = nil,
    enable_local_options = true,
    wrap = true,
    conceallevel = 2,
    concealcursor = "nc",
    spell = true,
    spelllang = "en_us",
  },
}
