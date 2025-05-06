-- tests/commands_spec.lua
require("plenary.busted")
local helpers = require("tests.helpers")
local luassert = require("luassert")
local spy = require("luassert.spy")

-- NOTE:
-- - `vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i<CR>", true, true, true), "x", false)`
--   calls keymap defined in code, but for some reason that keymap does not show up in
--   `vim.api.nvim_get_keymap("i")` output.
-- - Calling it with `x` is necessary, `t` works, but `n`, i.e. no remap, does not work.
-- - Thus, use `feed("i<CR>", "xt")` to simulate Enter keypresses in tests.

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
  local feed = helpers.feed
  local leader = vim.g.mapleader or "\\"

  it(":MarkdownBold should wrap selection in visual mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Wrap this selected text" })
    set_visual_selection(1, 5, 1, 17) -- Select 'this selected'
    local keys = leader .. "mb"
    feed(keys, "xt")
    luassert.equals("Wrap **this selected** text", get_buffer_content())
  end)

  it(":MarkdownItalic should wrap selection in visual mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Wrap this selected text" })
    set_visual_selection(1, 5, 1, 17) -- Select 'this selected'
    local keys = leader .. "mi"
    feed(keys, "xt")
    luassert.equals("Wrap *this selected* text", get_buffer_content())
  end)

  it(":MarkdownHighlight should wrap selection in visual mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Wrap this selected text" })
    set_visual_selection(1, 5, 1, 17) -- Select 'this selected'
    local keys = leader .. "mh"
    feed(keys, "xt")
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
    set_visual_selection(1, 0, 1, 14) -- Select the whole line

    local keys = leader .. "mH"
    feed(keys, "xt")

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
    set_visual_selection(1, 0, 2, 4) -- Select both lines

    local keys = leader .. "mc"
    feed(keys, "xt")

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
    set_visual_selection(1, 0, 1, 10) -- Select the line

    local keys = leader .. "mc"
    feed(keys, "xt")

    luassert.equals("```lua\nlocal x = 1\n```", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(1)
    ui_input_spy:revert()
  end)

  it(":MarkdownCheckbox should insert checkbox on empty line and enter insert mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local keys = leader .. "mk"
    feed(keys, "xt")

    luassert.equals("- [ ] ", get_buffer_content())
  end)

  it(":MarkdownCheckbox should insert checkbox on line with text and stay in normal mode", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Existing text" })
    vim.api.nvim_win_set_cursor(0, { 1, 4 }) -- Cursor on 't'

    local keys = leader .. "mk"
    feed(keys, "xt")

    luassert.equals("- [ ] Existing text", get_buffer_content())

    -- Ensure cursor position should be left where it was before insertion.
    local cursor = vim.api.nvim_win_get_cursor(0)
    luassert.same({ 1, vim.fn.strchars("- [ ] ") - 1 + 5 }, cursor)
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
    local keys = leader .. "mx"
    feed(keys, "xt")
    luassert.equals("- [ ] Checked item", get_buffer_content())
  end)

  it(":MarkdownToggleCheckbox should ignore non-checkbox lines", function()
    local original_line = "Just some normal text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { original_line })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })

    -- Spy on vim.notify
    local notify_spy = spy.on(vim, "notify")

    local keys = leader .. "mx"
    feed(keys, "xt")

    luassert.equals(original_line, get_buffer_content())
    luassert.spy(notify_spy).was.called_with("Current line is not a checkbox item", vim.log.levels.WARN)
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

    local keys = leader .. "ml"
    feed(keys, "xt")

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
    set_visual_selection(1, 7, 1, 16) -- Select 'this text'

    local keys = leader .. "ml"
    feed(keys, "xt")

    luassert.equals("Select [this text](http://example.com)", get_buffer_content())
    luassert.spy(ui_input_spy).was.called(1) -- Only called for URL
    ui_input_spy:revert()
  end)

  it(":MarkdownInsertTable should insert a 2x2 table", function()
    local ui_input_spy = spy.on(vim.ui, "input")
    -- Simulate entering '2' for columns, then '2' for rows.
    local inputs = { "2", "2" }
    ui_input_spy.callback = function(opts, callback_arg)
      -- Returns first element in list, shifting the others down.
      -- Called twice: Once for columns, once for rows.
      local input_val = table.remove(inputs, 1)
      callback_arg(input_val)
    end

    -- - Calls `commands.insert_table` directly, which does two vim.ui.input calls.
    -- - Spy above is equal to same struct as vim.ui.input in memory, so when callback
    --   is replaced, it also replaces callback of vim.ui.input.
    -- - Purpose of using spy on `vim.ui.input` is to later check how many times `vim.ui.input`
    --   was called, and with what arguments.
    -- - Purpose of replacing `vim.ui.input.callback` via spy, is that when `vim.ui.input(..)`
    --   is called, and thus internal `vim.ui.input.callback` runs with both arguments to `vim.ui.input(..)`
    --   passed in, we simulate user input by calling `callback_arg` i.e. callback user passed in, immediately,
    --   with predefined values (normally `callback_arg` does not run until `on_confirm`, i.e. enter).
    local keys = leader .. "mt"
    feed(keys, "xt")

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

    local keys = leader .. "mnt"
    feed(keys, "xt")

    -- Check if it was called with the effective config.
    -- Can be complex to check deeply, for now just check it was called.
    luassert.spy(select_template_spy).was.called(1)
    select_template_spy:revert()
  end)

  it("should continue unordered list item on Enter", function()
    -- Setup initial list item
    local initial_line = "- List item 1"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { initial_line })

    feed("A<CR>", "xt") -- Simulate Enter press at end of line in insert mode

    -- Assert new list item is created and cursor is positioned correctly
    local expected_marker = "- "
    luassert.equals(initial_line .. "\n" .. expected_marker, get_buffer_content())

    local actual_cursor = vim.api.nvim_win_get_cursor(0)
    -- The columns are 0-indexed, whereas the count is 1-indexed, thus subtract 1.
    luassert.same({ 2, #expected_marker - 1 }, actual_cursor)
  end)

  it("should continue ordered list item on Enter", function()
    -- Setup initial list item
    local initial_line = "1. List item 1"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { initial_line })

    feed("A<CR>", "xt") -- Simulate Enter press at end of line in insert mode

    -- Assert new list item is created and cursor is positioned correctly
    local expected_marker = "2. "
    luassert.equals(initial_line .. "\n" .. expected_marker, get_buffer_content())

    local actual_cursor = vim.api.nvim_win_get_cursor(0)
    -- The columns are 0-indexed, whereas the count is 1-indexed, thus subtract 1.
    luassert.same({ 2, #expected_marker - 1 }, actual_cursor)
  end)

  it("should continue checkbox list item on Enter", function()
    -- Setup initial list item
    local initial_line = "- [ ] List item 1"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { initial_line })

    feed("A<CR>", "xt") -- Simulate Enter press at end of line in insert mode

    -- Assert new list item is created and cursor is positioned correctly
    local expected_marker = "- [ ] "
    luassert.equals(initial_line .. "\n" .. expected_marker, get_buffer_content())

    local actual_cursor = vim.api.nvim_win_get_cursor(0)
    -- The columns are 0-indexed, whereas the count is 1-indexed, thus subtract 1.
    luassert.same({ 2, #expected_marker - 1 }, actual_cursor)
  end)

  it("should remove list marker on Enter on empty list item", function()
    -- Setup empty list item
    local initial_lines = { "- List item 1", "- " }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, initial_lines)
    vim.api.nvim_win_set_cursor(0, { 2, #initial_lines[2] }) -- Cursor at the end of the empty item marker on line 2

    feed("A<CR>", "xt") -- Simulate Enter press at end of line in insert mode

    -- Assert the list marker is removed and an empty line is inserted
    local expected_content = initial_lines[1] .. "\n" -- The "- " line should be replaced by ""
    luassert.equals(expected_content, get_buffer_content())

    local actual_cursor = vim.api.nvim_win_get_cursor(0)
    luassert.same({ 2, 0 }, actual_cursor) -- Cursor at beginning of the (now empty) second line
  end)

  it(
    "should perform default <CR> action via keymap when Enter is pressed in INSERT MODE on a non-list item line",
    function()
      -- Setup non-list item line.
      local original_line = "This is a normal line."

      -- Insert newline.
      feed("i" .. original_line .. "<CR>")

      -- Assert newline is inserted (default insert mode <CR> behavior)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      luassert.same({ original_line, "" }, lines)
    end
  )
end)
