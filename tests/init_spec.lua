-- tests/init_spec.lua
local helpers = require("tests.helpers")
require("plenary.busted")
local luassert = require("luassert")

describe("markdown-tools Initialization", function()
  local mt -- markdown-tools module

  before_each(function()
    helpers.reset_nvim()
    mt = require("markdown-tools")
    mt.setup({}) -- Run default setup
  end)

  it("should load the main module and submodules", function()
    helpers.reset_nvim() -- Ensure clean state for this specific test
    mt = require("markdown-tools")
    luassert.is_table(mt, "markdown-tools module should be a table")
    luassert.is_function(mt.setup, "setup function should exist")

    -- Check if core submodules are loaded (or can be required)
    luassert.is_table(require("markdown-tools.config"), "config module should load")
    luassert.is_table(require("markdown-tools.commands"), "commands module should load")
    luassert.is_table(require("markdown-tools.template"), "template module should load")
    luassert.is_table(require("markdown-tools.keymaps"), "keymaps module should load")
    luassert.is_table(require("markdown-tools.lists"), "lists module should load")
  end)

  it("should register user commands", function()
    -- setup({}) was called in before_each
    -- Check if some core commands exist
    luassert.is_number(vim.fn.exists(":MarkdownNewTemplate"), "MarkdownNewTemplate command should exist")
    luassert.is_number(vim.fn.exists(":MarkdownHeader"), "MarkdownHeader command should exist")
    luassert.is_number(vim.fn.exists(":MarkdownBold"), "MarkdownBold command should exist")
    luassert.is_number(vim.fn.exists(":MarkdownToggleCheckbox"), "MarkdownToggleCheckbox command should exist")
  end)
end)
