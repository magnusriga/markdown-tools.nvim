-- tests/config_spec.lua
local helpers = require("tests.helpers")
require("plenary.busted")
local luassert = require("luassert")

describe("markdown-tools Configuration", function()
  local mt -- markdown-tools module

  before_each(function()
    helpers.reset_nvim()
    mt = require("markdown-tools")
    -- Don't run default setup here, let tests control it
  end)

  it("should load default configuration via setup", function()
    mt.setup({}) -- Run default setup for this test
    local config_module = require("markdown-tools.config")
    luassert.is_table(config_module.options, "Config table should exist after setup")
    luassert.equals("fzf", config_module.options.picker) -- Check default picker
    luassert.is_string(config_module.options.template_dir)
    luassert.is_true(config_module.options.insert_frontmatter)
    luassert.is_table(config_module.options.keymaps)
    luassert.is_string(config_module.options.keymaps.insert_header)
  end)

  it("should allow overriding configuration via setup", function()
    mt.setup({ picker = "telescope", insert_frontmatter = false })
    local config_module = require("markdown-tools.config")
    luassert.is_table(config_module.options, "Config table should exist after setup")
    luassert.equals("telescope", config_module.options.picker)
    luassert.is_false(config_module.options.insert_frontmatter)
  end)
end)
