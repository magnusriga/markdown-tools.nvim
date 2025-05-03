local config = require("markdown-shortcuts.config")
local picker = require("markdown-shortcuts.picker")
local M = {}

-- Helper function to get visual selection
local function get_visual_selection()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- Ensure start is before end, regardless of selection direction
    -- Swap if start line is after end line, or if on same line and start col is after end col
    if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
        start_pos, end_pos = end_pos, start_pos -- Swap them
    end

    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    if #lines == 0 then
        return ""
    end

    local start_col = start_pos[3]
    local end_col = end_pos[3]

    -- Adjust for multi-line selection and extract relevant parts
    if #lines == 1 then
        -- Single line: extract substring between start and end columns
        lines[1] = string.sub(lines[1], start_col, end_col)
    else
        -- Multi-line: take from start column on first line, and up to end column on last line
        lines[1] = string.sub(lines[1], start_col)
        lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end

    -- Concatenate the processed lines
    return table.concat(lines, "\n")
end

-- Insert a Markdown header with level prompt
function M.insert_header(opts)
	opts = opts or {}
	local level = opts.level

	local function insert_header_final(lvl, text_to_insert, delete_selection)
		local header_prefix = string.rep("#", lvl) .. " "
		if delete_selection then
				-- Get visual selection marks again just before deletion/replacement
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")
				-- Ensure start is before end
				if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
					start_pos, end_pos = end_pos, start_pos
				end
				local start_lnum = start_pos[2] - 1
				local start_col = start_pos[3] - 1
				local end_lnum = end_pos[2] - 1
				local end_col = end_pos[3] -- Exclusive for set_text

				-- Replace the selection range with the new header text
				vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, { header_prefix .. text_to_insert })
		else
			-- Insert character-wise if not deleting/replacing selection
			vim.api.nvim_put({ header_prefix .. text_to_insert }, 'c', true, true)
		end
	end

	local mode = vim.api.nvim_get_mode().mode
	-- Determine if we are in a context where a visual selection is expected/relevant
	local is_visual_selection_context = (opts.range == 2) or mode:match("^[vV]")

	local captured_visual_text = nil
	if is_visual_selection_context then
		-- It's safer to get visual selection only if we are sure it's a visual context
		captured_visual_text = get_visual_selection()
	end

	if level then -- Level provided directly (e.g., via keymap count)
		local text_to_use = "Header" -- Default if not visual mode
		local should_delete = false

		if is_visual_selection_context then
			-- Use captured visual text (or empty string if nil/empty)
			text_to_use = captured_visual_text or ""
			should_delete = (captured_visual_text ~= nil and captured_visual_text ~= "") -- Only delete if selection wasn't empty
		else
			-- No visual mode, use opts.text or default
			text_to_use = opts.text or "Header"
			should_delete = false
		end
		insert_header_final(level, text_to_use, should_delete)

	else -- Interactive level prompt needed
		vim.ui.input({ prompt = "Header level (1-6): " }, function(level_input)
			if level_input and level_input:match("^[1-6]$") then
				local selected_level = tonumber(level_input) or 1

				-- Check if it was a visual context *before* this prompt
				if is_visual_selection_context then
					-- Use the captured text (might be nil or empty string).
					local text_to_use = captured_visual_text or ""
					-- Only delete if the original selection was not empty.
					local should_delete = (captured_visual_text ~= nil and captured_visual_text ~= "")
					insert_header_final(selected_level, text_to_use, should_delete)
				else
					-- Not a visual context, prompt for text
					vim.ui.input({ prompt = "Header text: " }, function(text_input)
						-- Insert text if provided, otherwise insert default/nothing
						local text_to_insert = (text_input and text_input ~= "") and text_input or "Header"
						-- Don't delete selection (there was none)
						insert_header_final(selected_level, text_to_insert, false)
					end)
				end
			else
				vim.notify("Invalid header level entered.", vim.log.levels.WARN)
			end
		end)
	end
end

-- Insert a Markdown code block
function M.insert_code_block(opts)
	opts = opts or {}

	vim.ui.input({ prompt = "Language (leave empty for no language): " }, function(lang)
		local opening = "```" .. (lang or "")

		-- Check if we're in visual mode
		local mode = vim.api.nvim_get_mode().mode
		if mode:match("^[vV]") then
			local text = get_visual_selection()
			vim.api.nvim_command("normal! gvd")
			vim.api.nvim_put({ opening, text, "```" }, "l", true, true)
		else
			vim.api.nvim_put({ opening, "", "```" }, "l", true, true)
			vim.api.nvim_command("normal! k")
		end
	end)
end

-- Insert bold text
function M.insert_bold(opts)
	opts = opts or {}

	-- Check if the command was called with a range (visual mode)
	if opts.range == 2 then
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")

		-- Check for invalid positions (e.g., first use before selection)
		if start_pos[2] == 0 or end_pos[2] == 0 then
			vim.notify("MarkdownTools: No visual selection marks found. Select text first.", vim.log.levels.WARN)
			return -- Exit if marks are invalid
		end

		-- Ensure start_pos is always before end_pos
		if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
			start_pos, end_pos = end_pos, start_pos -- Swap them
		end

		 -- No need to set/restore marks, get_visual_selection uses current ones
		local text = get_visual_selection() -- Get the actual text content
		local new_text = { "**" .. text .. "**" }

		-- Calculate 0-based indices for nvim_buf_set_text using the ordered positions
		local start_lnum = start_pos[2] - 1
		local start_col = start_pos[3] - 1
		local end_lnum = end_pos[2] - 1
		local end_col = end_pos[3] -- end_col is exclusive

		-- Replace the selected text directly
		vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, new_text)

		-- Re-select the modified text
		vim.cmd('normal! gv')
	else
		vim.ui.input({ prompt = "Bold text: " }, function(text)
			if text and text ~= "" then
				vim.api.nvim_put({ "**" .. text .. "**" }, "c", true, true)
			else
				vim.api.nvim_put({ "**bold text**" }, "c", true, true)
			end
		end)
	end
end

-- Insert italic text
function M.insert_italic(opts)
	opts = opts or {}

	-- Check if the command was called with a range (visual mode)
	if opts.range == 2 then
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")

		-- Check for invalid positions (e.g., first use before selection)
		if start_pos[2] == 0 or end_pos[2] == 0 then
			vim.notify("MarkdownTools: No visual selection marks found. Select text first.", vim.log.levels.WARN)
			return -- Exit if marks are invalid
		end

		-- Ensure start_pos is always before end_pos
		if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
			start_pos, end_pos = end_pos, start_pos -- Swap them
		end

		 -- No need to set/restore marks, get_visual_selection uses current ones
		local text = get_visual_selection() -- Get the actual text content
		local new_text = { "*" .. text .. "*" }

		-- Calculate 0-based indices for nvim_buf_set_text using the ordered positions
		local start_lnum = start_pos[2] - 1
		local start_col = start_pos[3] - 1
		local end_lnum = end_pos[2] - 1
		local end_col = end_pos[3] -- end_col is exclusive

		-- Replace the selected text directly
		vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, new_text)

		-- Re-select the modified text
		vim.cmd('normal! gv')
	else
		vim.ui.input({ prompt = "Italic text: " }, function(text)
			if text and text ~= "" then
				vim.api.nvim_put({ "*" .. text .. "*" }, "l", true, true)
			else
				vim.api.nvim_put({ "*italic text*" }, "l", true, true)
			end
		end)
	end
end

-- Insert a link
function M.insert_link(opts)
	opts = opts or {}

	-- Check if the command was called with a range
	if opts.range == 2 then
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")

		-- Check for invalid positions
		if start_pos[2] == 0 or end_pos[2] == 0 then
			vim.notify("MarkdownTools: No visual selection marks found.", vim.log.levels.WARN)
			return
		end

		-- Ensure start_pos is always before end_pos
		if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
			start_pos, end_pos = end_pos, start_pos -- Swap them
		end

		local text = get_visual_selection() -- Get the selected text

		vim.ui.input({ prompt = "URL: " }, function(url)
			local final_url = (url and url ~= "") and url or "url"
			local new_text = { "[" .. text .. "](" .. final_url .. ")" }

			-- Calculate 0-based indices for nvim_buf_set_text
			local start_lnum = start_pos[2] - 1
			local start_col = start_pos[3] - 1
			local end_lnum = end_pos[2] - 1
			local end_col = end_pos[3] -- end_col is exclusive

			-- Replace the selected text directly
			vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, new_text)
		end)
	else
		-- No range, prompt for input
		vim.ui.input({ prompt = "Link text: " }, function(text)
			if text and text ~= "" then
				vim.ui.input({ prompt = "URL: " }, function(url)
					if url and url ~= "" then
						vim.api.nvim_put({ "[" .. text .. "](" .. url .. ")" }, "l", true, true)
					else
						vim.api.nvim_put({ "[" .. text .. "](url)" }, "l", true, true)
					end
				end)
			else
				vim.api.nvim_put({ "[link text](url)" }, "l", true, true)
			end
		end)
	end
end

-- Insert a table
function M.insert_table(opts)
	opts = opts or {}
	local table_module = require("markdown-shortcuts.table")

	vim.ui.input({ prompt = "Number of columns: " }, function(cols_input)
		if not cols_input or not cols_input:match("^%d+$") then
			vim.notify("Invalid number of columns", vim.log.levels.WARN)
			return
		end

		local cols = tonumber(cols_input) or 1
		if cols < 1 then
			vim.notify("Number of columns must be at least 1", vim.log.levels.WARN)
			return
		end

		vim.ui.input({ prompt = "Number of rows: " }, function(rows_input)
			if not rows_input or not rows_input:match("^%d+$") then
				vim.notify("Invalid number of rows", vim.log.levels.WARN)
				return
			end

			local rows = tonumber(rows_input) or 1
			if rows < 1 then
				vim.notify("Number of rows must be at least 1", vim.log.levels.WARN)
				return
			end

			-- Use the table module to insert the table
			table_module.insert_table(rows + 2, cols) -- +2 for header and separator rows
		end)
	end)
end

-- Insert a checkbox list item
function M.insert_checkbox(opts)
	opts = opts or {}
	local checked = opts.checked or false
	local checkbox_char = checked and "[x]" or "[ ]"

	-- Check if the command was called with a range
	if opts.range == 2 then
		local text = get_visual_selection()
		vim.api.nvim_command("normal! gvd")
		vim.api.nvim_put({ "- " .. checkbox_char .. " " .. text }, "c", false, true)
	else
		-- No range, just insert checkbox and enter insert mode
		local checkbox_str = "- " .. checkbox_char .. " "
		local row = vim.api.nvim_win_get_cursor(0)[1] - 1
		-- Replace the current line content with just the checkbox markdown
		vim.api.nvim_buf_set_lines(0, row, row + 1, false, { checkbox_str })
		-- Move cursor to the position *of* the trailing space (0-based index)
		vim.api.nvim_win_set_cursor(0, { row + 1, #checkbox_str - 1 })
		-- Schedule feedkeys 'a' to run after cursor update
		vim.schedule(function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), 'n', false)
		end)
	end
end

-- Toggle checkbox completion status
function M.toggle_checkbox()
	local line = vim.api.nvim_get_current_line()
	local new_line

	if line:match("^%s*-%s*%[%s%]") then
		-- Unchecked to checked
		new_line = line:gsub("^(%s*-%s*)%[%s%]", "%1[x]")
	elseif line:match("^%s*-%s*%[x%]") then
		-- Checked to unchecked
		new_line = line:gsub("^(%s*-%s*)%[x%]", "%1[ ]")
	else
		vim.notify("Current line is not a checkbox item", vim.log.levels.WARN)
		return
	end

	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	vim.api.nvim_buf_set_lines(0, row, row + 1, false, { new_line })
end

--- Creates a new Markdown file from a selected template.
--- Uses configured picker with optional overrides.
---@param opts? Config Optional overrides for creating a new Markdown file.
function M.create_from_template(opts)
	local current_opts = vim.tbl_deep_extend("force", config.options, opts or {})
	picker.select_template(current_opts)
end

return M
