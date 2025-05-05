-- tests/commands_spec.lua
require("plenary.busted")
local helpers = require("tests.helpers")
local luassert = require("luassert")
local spy = require("luassert.spy")

describe("markdown-tools Commands", function()
  local commands
  local mt
  local picker_module -- For mocking

  before_each(function()
    -- Reset Neovim environment and reload the plugin before each test
    helpers.reset_nvim()
    mt = require("markdown-tools")
    mt.setup({}) -- Run default setup

    -- Ensure a clean buffer for command tests
    vim.cmd("enew!")
    vim.bo.filetype = "markdown"
    commands = require("markdown-tools.commands")
    picker_module = require("markdown-tools.picker") -- Get picker module for spying
  end)

  -- Use helpers for visual selection and buffer content
  local set_visual_selection = helpers.set_visual_selection
  local get_buffer_content = helpers.get_buffer_content

  it(":MarkdownBold should wrap word under cursor (simulated via visual)", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Some text here" })
    set_visual_selection(1, 6, 1, 9) -- Select 'text'
    commands.insert_bold({ range = 2 })
    luassert.equals("Some **text** here", get_buffer_content())
  end)

  it(":MarkdownBold should wrap selection in visual mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Wrap this selected text" })
    set_visual_selection(1, 6, 1, 18) -- Select 'this selected'
    commands.insert_bold({ range = 2 })
    luassert.equals("Wrap **this selected** text", get_buffer_content())
  end)

  it(":MarkdownItalic should wrap selection in visual mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Wrap this selected text" })
    set_visual_selection(1, 6, 1, 18) -- Select 'this selected'
    commands.insert_italic({ range = 2 })
    luassert.equals("Wrap *this selected* text", get_buffer_content())
  end)

  it(":MarkdownHighlight should wrap selection in visual mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Wrap this selected text" })
    set_visual_selection(1, 6, 1, 18) -- Select 'this selected'
    commands.insert_highlight({ range = 2 })
    luassert.equals("Wrap ==this selected== text", get_buffer_content())
  end)

  it(":MarkdownHeader should prepend header in visual mode (level 2)", function()
    -- Spy on vim.ui.input and replace its implementation
    local ui_input_spy = spy.on(vim.ui, "input")
    ui_input_spy.callback = function(opts, callback_arg)
      if opts.prompt:match("Header level") then
        callback_arg("2") -- Simulate user entering '2'
      else
        error("Unexpected vim.ui.input prompt: " .. opts.prompt)
      end
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "My Heading Text" })
    set_visual_selection(1, 1, 1, 15) -- Select the whole line
    commands.insert_header({ range = 2 }) -- Simulate visual call

    luassert.equals("## My Heading Text", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(1)
  end)

  it(":MarkdownCodeBlock should wrap selection in visual mode (no lang)", function()
    -- Spy on vim.ui.input and replace its implementation
    local ui_input_spy = spy.on(vim.ui, "input")
    ui_input_spy.callback = function(opts, callback_arg)
      if opts.prompt:match("Language") then
        callback_arg("") -- Simulate user entering nothing
      else
        error("Unexpected vim.ui.input prompt: " .. opts.prompt)
      end
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "line1", "line2" })
    set_visual_selection(1, 1, 2, 5) -- Select both lines
    commands.insert_code_block({ range = 2 }) -- Simulate visual call

    luassert.equals("```\nline1\nline2\n```", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(1)
  end)

  it(":MarkdownCodeBlock should wrap selection in visual mode (with lang)", function()
    -- Spy on vim.ui.input and replace its implementation
    local ui_input_spy = spy.on(vim.ui, "input")
    ui_input_spy.callback = function(opts, callback_arg)
      if opts.prompt:match("Language") then
        callback_arg("lua") -- Simulate user entering 'lua'
      else
        error("Unexpected vim.ui.input prompt: " .. opts.prompt)
      end
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1" })
    set_visual_selection(1, 1, 1, 11) -- Select the line
    commands.insert_code_block({ range = 2 }) -- Simulate visual call

    luassert.equals("```lua\nlocal x = 1\n```", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(1)
  end)

  it(":MarkdownCheckbox should insert checkbox on empty line and enter insert mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    commands.insert_checkbox()

    -- Increase wait time to 100ms
    vim.wait(100)

    luassert.equals("- [ ] ", get_buffer_content())
  end)

  it(":MarkdownCheckbox should insert checkbox on line with text and stay in normal mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Existing text" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 }) -- Cursor on 't'
    local feedkeys_spy = spy.on(vim.api, "nvim_feedkeys")

    commands.insert_checkbox()

    luassert.equals("- [ ] Existing text", get_buffer_content())
    -- Check cursor position (should be after the inserted checkbox prefix)
    local cursor = vim.api.nvim_win_get_cursor(0)
    luassert.same({ 1, vim.fn.strchars("- [ ] ") }, cursor) -- {1, 6}

    -- Check that Esc was fed to ensure normal mode
    luassert.spy(feedkeys_spy).was.called_with(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    feedkeys_spy:revert()
  end)

  it(":MarkdownToggleCheckbox should check an unchecked box", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- [ ] Unchecked item" })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    commands.toggle_checkbox()
    luassert.equals("- [x] Unchecked item", get_buffer_content())
  end)

  it(":MarkdownToggleCheckbox should uncheck a checked box", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- [x] Checked item" })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    commands.toggle_checkbox()
    luassert.equals("- [ ] Checked item", get_buffer_content())
  end)

  it(":MarkdownToggleCheckbox should ignore non-checkbox lines", function()
    local original_line = "Just some normal text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { original_line })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })

    -- Spy on vim.notify
    local notify_spy = spy.on(vim, "notify")

    commands.toggle_checkbox() -- Should do nothing and not error

    -- Assert the line content is unchanged
    luassert.equals(original_line, get_buffer_content())

    -- Assert that vim.notify was called with the specific message and level
    luassert.spy(notify_spy).was.called_with("Current line is not a checkbox item", vim.log.levels.WARN)

    -- Revert the spy
    notify_spy:revert()
  end)

  it(":MarkdownLink should insert link in normal mode", function()
    local ui_input_spy = spy.on(vim.ui, "input")
    -- Correct order: URL first, then link text
    local inputs = { "http://example.com", "link text" }
    ui_input_spy.callback = function(opts, callback_arg)
      local input_val = table.remove(inputs, 1)
      callback_arg(input_val)
    end

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    commands.insert_link()

    -- Need vim.wait to allow scheduled callbacks to run
    vim.wait(50)

    luassert.equals("[link text](http://example.com)", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(2)
    ui_input_spy:revert()
  end)

  it(":MarkdownLink should insert link in visual mode", function()
    local ui_input_spy = spy.on(vim.ui, "input")
    -- Simulate entering 'http://example.com' for the URL
    ui_input_spy.callback = function(opts, callback_arg)
      if opts.prompt:match("URL") then
        callback_arg("http://example.com")
      else
        error("Unexpected vim.ui.input prompt: " .. opts.prompt)
      end
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Select this text" })
    set_visual_selection(1, 8, 1, 17) -- Select 'this text'
    commands.insert_link({ range = 2 }) -- Simulate visual call

    -- Need vim.wait to allow scheduled callbacks to run
    vim.wait(50)

    luassert.equals("Select [this text](http://example.com)", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(1) -- Only called for URL
    ui_input_spy:revert()
  end)

  it(":MarkdownInsertTable should insert a 2x2 table", function()
    local ui_input_spy = spy.on(vim.ui, "input")
    -- Simulate entering '2' for columns, then '2' for rows
    local inputs = { "2", "2" }
    ui_input_spy.callback = function(opts, callback_arg)
      local input_val = table.remove(inputs, 1)
      callback_arg(input_val)
    end

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    commands.insert_table()

    -- Increase wait time to 100ms
    vim.wait(100)

    local expected_table = {
      "| Header 1 | Header 2 |",
      "| --- | --- |",
      "| Cell 1,1 | Cell 1,2 |",
      "| Cell 2,1 | Cell 2,2 |",
      "",
    }
    luassert.equals(table.concat(expected_table, "\n"), get_buffer_content())
    luassert.spy(ui_input_spy).was.called(2)
    ui_input_spy:revert()
  end)

  it(":MarkdownNewTemplate should call picker.select_template", function()
    local select_template_spy = spy.on(picker_module, "select_template")

    commands.create_from_template()

    luassert.spy(select_template_spy).was.called(1)
    -- Check if it was called with the effective config (can be complex to check deeply)
    -- For now, just check it was called.
    select_template_spy:revert()
  end)
end)
