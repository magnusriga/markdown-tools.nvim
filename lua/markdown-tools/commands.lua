local config = require("markdown-tools.config")
local picker = require("markdown-tools.picker")

local M = {}

-- Helper function to get visual selection text and positions
local function get_visual_selection_info()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Check if marks are valid (line number > 0)
	if start_pos[2] == 0 or end_pos[2] == 0 then
		-- vim.notify("MarkdownTools: Invalid visual selection marks.", vim.log.levels.WARN) -- Don't notify here, let caller handle
		return nil -- Return nil if marks are invalid
	end

	-- Ensure start is before end
	if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
		start_pos, end_pos = end_pos, start_pos
	end

	local lines = vim.fn.getline(start_pos[2], end_pos[2])
	if #lines == 0 then
		-- This might happen if the selection is somehow empty or getline fails
		-- vim.notify("MarkdownTools: Could not get lines for visual selection.", vim.log.levels.WARN) -- Don't notify here
		return nil -- No lines selected or error getting lines
	end

	local start_lnum = start_pos[2] -- 1-based
	local end_lnum = end_pos[2] -- 1-based
	local start_col = start_pos[3] -- 1-based character col
	local end_col = end_pos[3] -- 1-based character col

	local text
	if start_lnum == end_lnum then
		-- Single line selection
		text = string.sub(lines[1], start_col, end_col)
	else
		-- Multi-line selection
		lines[1] = string.sub(lines[1], start_col)
		lines[#lines] = string.sub(lines[#lines], 1, end_col)
		text = table.concat(lines, "\n")
	end

	return {
		text = text,
		start_lnum = start_lnum, -- 1-based
		end_lnum = end_lnum, -- 1-based
		start_col = start_col, -- 1-based char col
		end_col = end_col, -- 1-based char col,
	}
end

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
			vim.api.nvim_buf_set_lines(
				0,
				current_cursor_row_after_prompt - 1,
				current_cursor_row_after_prompt,
				false,
				{ text_with_prefix }
			)
			vim.api.nvim_win_set_cursor(0, { current_cursor_row_after_prompt, vim.fn.strchars(text_with_prefix) })
		elseif replacement_mode == "insert" then
			-- Insert on new line or empty line
			local text_with_prefix = header_prefix .. final_text
			vim.api.nvim_put({ text_with_prefix }, "c", true, true)
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
			-- In visual mode, text_to_use is nil and ignored by perform_insertion
			perform_insertion(selected_level, text_to_use)
		end
	end)
end

-- Insert a Markdown code block
function M.insert_code_block(opts)
	opts = opts or {}

	vim.ui.input({ prompt = "Language (leave empty for no language): " }, function(lang)
		local opening = "```" .. (lang or "")
		local closing = "```"

		-- Check if we're in visual mode or simulating it
		local mode = vim.api.nvim_get_mode().mode
		if mode:match("^[vV]") or opts.range == 2 then -- Added opts.range check
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

			-- Get info about the start line
			local start_lnum_1based = start_pos[2]
			local start_col_1based = start_pos[3]
			local start_line_content = vim.api.nvim_buf_get_lines(0, start_lnum_1based - 1, start_lnum_1based, false)[1]
				or ""
			local text_before_selection = string.sub(start_line_content, 1, start_col_1based - 1)
			local has_text_before = text_before_selection:match("%S")

			local text_content = get_visual_selection() -- Get the selected text as a single string
			local selected_lines = vim.split(text_content, "\n", { plain = true }) -- Use plain=true for literal \n
			-- Construct the new text lines table for insertion/replacement
			local new_text_lines = { opening }
			for _, line in ipairs(selected_lines) do
				table.insert(new_text_lines, line)
			end
			table.insert(new_text_lines, closing)

			-- Calculate 0-based indices for nvim_buf_set_text/nvim_buf_set_lines
			local start_lnum_0based = start_lnum_1based - 1
			local start_col_0based = start_col_1based - 1
			local end_lnum_0based = end_pos[2] - 1
			local end_col_0based = end_pos[3] -- end_col is exclusive byte index for set_text

			if has_text_before then
				-- Delete original selection first
				vim.api.nvim_buf_set_text(0, start_lnum_0based, start_col_0based, end_lnum_0based, end_col_0based, {})
				-- Insert the new code block lines *after* the original starting line
				vim.api.nvim_buf_set_lines(0, start_lnum_1based, start_lnum_1based, false, new_text_lines)
			else
				-- Replace the selected text directly in place
				vim.api.nvim_buf_set_text(
					0,
					start_lnum_0based,
					start_col_0based,
					end_lnum_0based,
					end_col_0based,
					new_text_lines
				)
			end

			-- Exit visual mode only if actually in visual mode
			if mode:match("^[vV]") then
				vim.cmd("normal! <Esc>")
			end
		else
			-- Normal mode insertion
			vim.api.nvim_put({ opening, "", closing }, "l", true, true)
			vim.api.nvim_command("normal! k") -- Move cursor up into the block
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

		local text = get_visual_selection() -- Get the actual text content
		text = vim.trim(text) -- Trim whitespace just in case
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

-- Insert a Markdown link
function M.insert_link(opts)
	opts = opts or {}
	local mode = vim.api.nvim_get_mode().mode
	local is_visual = (opts.range == 2) or mode:match("^[vV]")

	local selected_text = ""
	local visual_info = nil

	if is_visual then
		visual_info = get_visual_selection_info()
		if visual_info then
			selected_text = visual_info.text
		else
			print("Error getting visual selection.")
			return -- Exit if visual selection failed
		end
	end

	vim.ui.input({ prompt = "Enter URL: " }, function(url)
		if url == nil or url == "" then
			print("Link insertion cancelled.")
			return
		end

		local link_text = selected_text
		if not is_visual or link_text == "" then
			-- Prompt for text if not visual mode or visual selection was empty
			vim.ui.input({ prompt = "Enter link text: ", default = link_text }, function(text)
				if text == nil then
					print("Link insertion cancelled.")
					return
				end
				link_text = text
				local markdown_link = string.format("[%s](%s)", link_text, url)
				-- Insert at cursor position in normal/insert mode
				vim.api.nvim_put({ markdown_link }, "c", true, true)
			end)
		else
			-- Visual mode with selected text
			local markdown_link = string.format("[%s](%s)", link_text, url)

			-- Calculate byte offsets for nvim_buf_set_text
			local start_lnum_zero = visual_info.start_lnum - 1
			local end_lnum_zero = visual_info.end_lnum - 1

			-- Get the line content to calculate byte offsets correctly
			local start_line_content = vim.api.nvim_buf_get_lines(0, start_lnum_zero, start_lnum_zero + 1, false)[1]
				or ""
			local end_line_content = vim.api.nvim_buf_get_lines(0, end_lnum_zero, end_lnum_zero + 1, false)[1] or ""

			-- Convert 1-based character columns to 0-based byte columns
			local start_col_byte = vim.fn.byteidx(start_line_content, visual_info.start_col - 1)
			local end_col_byte = vim.fn.byteidx(end_line_content, visual_info.end_col) -- byteidx for end needs careful handling

			-- If selection spans multiple lines, end_col_byte should be calculated based on the end line content
			-- and the character index visual_info.end_col
			if start_lnum_zero ~= end_lnum_zero then
				end_col_byte = vim.fn.byteidx(end_line_content, visual_info.end_col)
			else
				-- For single line, end_col is exclusive in char terms for slicing, so byteidx needs the char index
				end_col_byte = vim.fn.byteidx(start_line_content, visual_info.end_col)
			end

			-- Ensure end_col_byte is valid
			local end_line_len_bytes = #end_line_content
			if end_col_byte > end_line_len_bytes then
				end_col_byte = end_line_len_bytes
			end
			-- Ensure start_col_byte is valid
			if start_col_byte < 0 then
				start_col_byte = 0
			end -- byteidx returns -1 if invalid

			-- Replace the visual selection range with the markdown link
			vim.api.nvim_buf_set_text(
				0,
				start_lnum_zero,
				start_col_byte,
				end_lnum_zero,
				end_col_byte,
				{ markdown_link }
			)

			-- Optional: Move cursor to the end of the inserted link
			-- vim.api.nvim_win_set_cursor(0, { visual_info.start_lnum, start_col_byte + #markdown_link })
		end
	end)
end

-- Insert a Markdown checkbox
function M.insert_checkbox()
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
	local current_line_content = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, false)[1] or ""
	local trimmed_line = current_line_content:match("^%s*(.-)%s*$") or ""

	local checkbox = "- [ ] "
	local checkbox_len_chars = vim.fn.strchars(checkbox)

	if trimmed_line == "" then
		-- Line is empty or only whitespace, replace it and stay in insert mode
		vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, false, { checkbox })
		-- Use feedkeys 'a' to enter insert mode at the end of the line
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), "n", false)
	else
		-- Line has content, insert checkbox at the beginning and return to normal mode
		local new_line = checkbox .. current_line_content
		vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, false, { new_line })
		-- Set cursor position using 0-based index
		vim.api.nvim_win_set_cursor(0, { cursor_row, checkbox_len_chars }) -- Move cursor after checkbox
		-- Ensure Normal mode by sending Esc
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
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
---@param opts? MarkdownToolsConfig Optional overrides for creating a new Markdown file.
function M.create_from_template(opts)
	local current_opts = vim.tbl_deep_extend("force", config.options, opts or {})
	picker.select_template(current_opts)
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

return M
