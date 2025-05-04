local config = require("markdown-tools.config")
local picker = require("markdown-tools.picker")
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
	local level_override = opts.level -- Level from count, etc.

	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	local current_line_content = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, false)[1] or ""
	-- Check if the line contains any non-whitespace characters
	local line_has_text = current_line_content:match("%S")

	local mode = vim.api.nvim_get_mode().mode
	local is_visual = (opts.range == 2) or mode:match("^[vV]")

	local text_to_use = nil
	local should_prompt_for_text = true
	local replacement_mode = "insert" -- "insert", "replace_line", "replace_visual"

	-- Determine behavior based on context
	if is_visual then
		-- text_to_use = get_visual_selection() -- Text selection is ignored for visual header insertion
		should_prompt_for_text = false -- Don't prompt for text in visual mode
		replacement_mode = "replace_visual" -- Use this mode, but behavior changes below
	elseif line_has_text then
		-- Use trimmed line content if line has text (and not in visual mode)
		text_to_use = current_line_content:match("^%s*(.-)%s*$") or current_line_content
		should_prompt_for_text = false
		replacement_mode = "replace_line"
	else
		-- Normal mode on empty/whitespace line: prompt for both
		text_to_use = "Header" -- Default if prompt is skipped/empty
		should_prompt_for_text = true
		replacement_mode = "insert"
	end

	-- Helper function to perform the actual insertion/replacement
	local function perform_insertion(selected_level, final_text) -- final_text is used for non-visual modes
		local header_prefix = string.rep("#", selected_level) .. " "

		if replacement_mode == "replace_visual" then
			-- Visual Mode: Prepend header to the start line of the selection
			local start_pos = vim.fn.getpos("'<")
			local end_pos = vim.fn.getpos("'>")
			-- Ensure start is before end (only need start line, but good practice)
			if start_pos[2] > end_pos[2] then
				start_pos, end_pos = end_pos, start_pos
			end
			local start_lnum = start_pos[2] -- 1-based line number

			 -- Exit visual mode *before* buffer modification
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

			-- Get the content of the line where the visual selection started
			local line_content = vim.api.nvim_buf_get_lines(0, start_lnum - 1, start_lnum, false)[1] or ""

			-- Prepend the header prefix to the existing line content
			local text_with_prefix = header_prefix .. line_content

			-- Replace the entire line
			vim.api.nvim_buf_set_lines(0, start_lnum - 1, start_lnum, false, { text_with_prefix })

			-- Place cursor at the end of the inserted prefix
			vim.api.nvim_win_set_cursor(0, { start_lnum, vim.fn.strchars(header_prefix) })

			-- No need for vim.cmd('normal! <Esc>') anymore as we exited earlier
		elseif replacement_mode == "replace_line" then
			-- Replace current line content
			local text_with_prefix = header_prefix .. final_text
			local current_cursor_row_after_prompt = vim.api.nvim_win_get_cursor(0)[1]
			vim.api.nvim_buf_set_lines(0, current_cursor_row_after_prompt - 1, current_cursor_row_after_prompt, false, { text_with_prefix })
			vim.api.nvim_win_set_cursor(0, { current_cursor_row_after_prompt, vim.fn.strchars(text_with_prefix) })
		elseif replacement_mode == "insert" then
			-- Insert on new line or empty line
			local text_with_prefix = header_prefix .. final_text
			vim.api.nvim_put({ text_with_prefix }, 'c', true, true)
		end
	end

	-- Prompting logic: Get level first
	local function get_level_and_proceed(callback)
		if level_override then
			-- Use level from count if provided
			if level_override >= 1 and level_override <= 6 then
				callback(level_override)
			else
				vim.notify("Invalid header level count: " .. level_override, vim.log.levels.WARN)
			end
		else
			-- Prompt for level if not provided by count
			vim.ui.input({ prompt = "Header level (1-6): " }, function(level_input)
				if level_input and level_input:match("^[1-6]$") then
					callback(tonumber(level_input))
				else
					vim.notify("Invalid header level entered.", vim.log.levels.WARN)
				end
			end)
		end
	end

	-- Execute the logic: get level, then maybe text, then insert
	get_level_and_proceed(function(selected_level)
		if should_prompt_for_text then
			-- Prompt for text only if needed (empty line, normal mode)
			vim.ui.input({ prompt = "Header text: " }, function(text_input)
				-- Use prompted text if provided, otherwise use an empty string or handle as needed
				local final_text = (text_input and text_input ~= "") and text_input or "" -- Use empty string if no input
				perform_insertion(selected_level, final_text)
			end)
		else
			-- Use the predetermined text (from current line) or handle visual mode
			-- In visual mode, text_to_use (visual selection) is passed but ignored by perform_insertion
			perform_insertion(selected_level, text_to_use)
		end
	end)
end

-- Insert a Markdown code block
function M.insert_code_block(opts)
	opts = opts or {}

	vim.ui.input({ prompt = "Language (leave empty for no language): " }, function(lang)
		local opening = "```" .. (lang or "")

		-- Check if we're in visual mode
		local mode = vim.api.nvim_get_mode().mode
		if mode:match("^[vV]") then
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
			local new_text = { opening, text, "```" }

			-- Calculate 0-based indices for nvim_buf_set_text
			local start_lnum = start_pos[2] - 1
			local start_col = start_pos[3] - 1
			local end_lnum = end_pos[2] - 1
			local end_col = end_pos[3] -- end_col is exclusive

			-- Replace the selected text directly
			vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, new_text)

			-- Exit visual mode
			vim.cmd('normal! <Esc>')
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

-- Insert highlight text
function M.insert_highlight(opts)
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
		local new_text = { "==" .. text .. "==" }

		-- Calculate 0-based indices for nvim_buf_set_text using the ordered positions
		local start_lnum = start_pos[2] - 1
		local start_col = start_pos[3] - 1
		local end_lnum = end_pos[2] - 1
		local end_col = end_pos[3] -- end_col is exclusive

		-- Replace the selected text directly
		vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, new_text)
	else
		vim.ui.input({ prompt = "Highlight text: " }, function(text)
			if text and text ~= "" then
				vim.api.nvim_put({ "==" .. text .. "==" }, "c", true, true)
			else
				vim.api.nvim_put({ "==highlight text==" }, "c", true, true)
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

-- Helper function specifically for the visual keymap to prompt for URL
function M.prompt_and_insert_url()
	vim.ui.input({ prompt = "URL: " }, function(url)
		local final_url = (url and url ~= "") and url or "url"
		-- Insert the URL at the current cursor position (which should be inside the parens)
		vim.api.nvim_put({ final_url }, "c", true, true) -- 'c' for characterwise insertion
		-- Exit insert mode after inserting the URL
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	end)
end

-- Insert a link (The visual mode part of this function is now only for direct command usage)
function M.insert_link(opts)
	opts = opts or {}
	-- Check if the command was called with a range
	if opts.range == 2 then
		-- THIS VISUAL LOGIC IS NO LONGER USED BY THE KEYMAP
		-- It's kept for direct :'<,'>MarkdownLink usage
		-- Use passed positions if available, otherwise get them now
		local start_pos = opts.start_pos or vim.fn.getpos("'<")
		local end_pos = opts.end_pos or vim.fn.getpos("'>")

		-- Check for invalid positions
		if start_pos[2] == 0 or end_pos[2] == 0 then
			vim.notify("MarkdownTools: No visual selection marks found (Direct Command).", vim.log.levels.WARN) -- Clarify message
			return
		end

		-- Ensure start_pos is always before end_pos
		if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
			start_pos, end_pos = end_pos, start_pos -- Swap them
		end

		-- Get visual selection content (still needed)
		-- We need to temporarily restore marks if they were passed,
		-- as get_visual_selection relies on them being set.
		local original_start = vim.fn.getpos("'<")
		local original_end = vim.fn.getpos("'>")
		vim.fn.setpos("'<", start_pos)
		vim.fn.setpos("'>", end_pos)
		local text = get_visual_selection()
		-- Restore original marks (optional, but good practice)
		vim.fn.setpos("'<", original_start)
		vim.fn.setpos("'>", original_end)


		-- Exit visual mode *before* prompting
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

		-- Schedule the input prompt and attempt to start insert mode
		vim.schedule(function()
			vim.cmd("startinsert") -- Attempt to enter insert mode
			vim.ui.input({ prompt = "URL: " }, function(url)
				local final_url = (url and url ~= "") and url or "url"
				local new_text = { "[" .. text .. "](" .. final_url .. ")" }

				-- Calculate 0-based indices for nvim_buf_set_text using the (potentially passed) positions
				local start_lnum = start_pos[2] - 1
				local start_col = start_pos[3] - 1
				local end_lnum = end_pos[2] - 1
				local end_col = end_pos[3] -- end_col is exclusive

				-- Replace the selected text directly
				vim.api.nvim_buf_set_text(0, start_lnum, start_col, end_lnum, end_col, new_text)
			end)
		end)
	else
		vim.ui.input({ prompt = "Link text: " }, function(text)
			if text and text ~= "" then
				-- Schedule the URL prompt and attempt to start insert mode
				vim.schedule(function()
					vim.cmd("startinsert")
					vim.ui.input({ prompt = "URL: " }, function(url)
						if url and url ~= "" then
							vim.api.nvim_put({ "[" .. text .. "](" .. url .. ")" }, "l", true, true)
						else
							vim.api.nvim_put({ "[" .. text .. "](url)" }, "l", true, true)
						end
					end)
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
	local table_module = require("markdown-tools.table")

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
function M.insert_checkbox()
	local win = 0 -- Current window
	local buf = 0 -- Current buffer
	local cursor_pos = vim.api.nvim_win_get_cursor(win)
	local row = cursor_pos[1] - 1 -- 0-based row index
	local original_col = cursor_pos[2] -- 0-based original column index

	local original_line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	local is_line_empty = original_line:match("^%s*$") -- Check if line is empty or whitespace

	-- Check if the line already starts with a checkbox pattern (checked or unchecked)
	if original_line:match("^%s*-%s*%[[ x%]%]") then
		vim.notify("Line already contains a checkbox.", vim.log.levels.INFO)
		return
	end

	-- Insert checkbox at the beginning of the line, preserving existing content
	local checkbox_str = "- [ ] "
	local new_line = checkbox_str .. original_line

	-- Replace the current line content
	vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { new_line })

	-- Adjust cursor position and mode based on whether the line was originally empty
	if is_line_empty then
		-- Place cursor ON the space (index 5, which is length - 1)
		vim.api.nvim_win_set_cursor(win, { row + 1, #checkbox_str - 1 })
		-- Use feedkeys 'a' to append after the cursor position
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), "n", false)
	else
		-- Restore cursor position relative to original content, stay in normal mode
		vim.api.nvim_win_set_cursor(win, { row + 1, original_col + #checkbox_str })
		-- Ensure we are in normal mode (redundant if already in normal, but safe)
		vim.cmd("stopinsert")
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
