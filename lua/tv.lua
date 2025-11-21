local M = {}

-- Default configuration
M.config = {
  tv_binary = "tv",
  -- Quickfix settings
  quickfix = {
    auto_open = true, -- Automatically open quickfix window after populating it
  },
  -- Global window defaults (can be overridden per channel)
  window = {
    width = 0.8,
    height = 0.8,
    border = "none",
    title = " tv.nvim ",
    title_pos = "center",
  },
  files = {
    args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" },
    -- Window settings specific to files channel (optional)
    -- window = { width = 0.9, title = " Files " }
  },
  text = {
    args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" },
    -- Window settings specific to text channel (optional)
    -- window = { width = 0.7, title = " Text Search " }
  },
  keybindings = {
    files = "<C-p>",
    text = "<leader><leader>",
    channels = "<leader>tv",
    files_qf = "<C-q>",
    text_qf = "<C-q>",
  },
}

-- Helper function to get window configuration for a specific channel
local function get_window_config(channel)
  local base_config = M.config.window
  local channel_config = M.config[channel] and M.config[channel].window or {}
  return vim.tbl_deep_extend("force", base_config, channel_config)
end

-- Helper function to convert Neovim keybinding notation to tv format
-- e.g., "<C-q>" -> "ctrl-q", "<A-x>" -> "alt-x"
local function convert_keybinding_to_tv_format(keybinding)
  if not keybinding then
    return nil
  end

  -- Convert Neovim notation to tv notation
  local converted = keybinding
    :gsub("<C%-([^>]+)>", "ctrl-%1")
    :gsub("<A%-([^>]+)>", "alt-%1")
    :gsub("<M%-([^>]+)>", "alt-%1")
    :gsub("<S%-([^>]+)>", "shift-%1")
    :gsub("<([^>]+)>", "%1")
    :lower()

  return converted
end

-- Helper function to populate quickfix list
local function populate_quickfix(items, title)
  vim.fn.setqflist({}, "r", {
    title = title or "TV",
    items = items,
  })

  if M.config.quickfix.auto_open then
    vim.cmd("copen")
  end
end

local function launch_tv_channel(channel, handler, expect_key, prompt_input)
  M.create_win_and_buf(channel)
  local output = {}

  -- Build command with configurable arguments
  local cmd = { M.config.tv_binary }
  vim.list_extend(cmd, M.config[channel].args)

  -- Add expect flag if provided
  if expect_key then
    vim.list_extend(cmd, { "--expect=" .. expect_key })
  end

  vim.list_extend(cmd, { channel })

  if prompt_input then
    vim.list_extend(cmd, { "-i" .. tostring(prompt_input) })
  end

  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.api.nvim_win_close(0, true)
        return
      end

      -- read lines from the buffer
      output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      -- close the terminal window
      vim.api.nvim_win_close(0, true)

      -- Check if first line matches the expect key (quickfix mode)
      local use_quickfix = false
      local start_idx = 1
      if expect_key and #output > 0 and output[1] == expect_key then
        use_quickfix = true
        start_idx = 2
      end

      -- Extract non-empty entries
      local entries = {}
      for i = start_idx, #output do
        local line = vim.fn.trim(output[i])
        if line ~= "" then
          table.insert(entries, line)
        end
      end

      -- Call the channel-specific handler
      handler(entries, use_quickfix)
    end,
    term = true,
  })
  vim.cmd("startinsert")
end

-- Handler for files channel output
local function handle_files_output(entries, use_quickfix)
  if use_quickfix then
    -- Populate quickfix list
    local qf_items = {}
    for _, line in ipairs(entries) do
      if vim.fn.filereadable(line) == 1 then
        local qf_entry = {
          filename = line,
          lnum = 1,
        }
        -- Read first line of file for preview
        local file_lines = vim.fn.readfile(line, "", 1)
        if #file_lines > 0 then
          qf_entry.text = vim.fn.trim(file_lines[1])
        end
        table.insert(qf_items, qf_entry)
      end
    end
    populate_quickfix(qf_items, "TV Files")
  else
    -- Open files directly
    for _, line in ipairs(entries) do
      if vim.fn.filereadable(line) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(line))
      end
    end
  end
end

-- Handler for text channel output
local function handle_text_output(entries, use_quickfix)
  if use_quickfix then
    -- Populate quickfix list
    local qf_items = {}
    for _, line in ipairs(entries) do
      local parts = vim.split(line, ":", { plain = true })
      if #parts >= 2 then
        local filename = vim.fn.trim(parts[1])
        if vim.fn.filereadable(filename) == 1 then
          local lnum = tonumber(vim.fn.trim(parts[2])) or 1
          local qf_entry = {
            filename = filename,
            lnum = lnum,
          }

          -- Check if parts[3] is a column number or text
          local text_start_idx = 3
          if #parts >= 3 then
            local potential_col = tonumber(vim.fn.trim(parts[3]))
            if potential_col then
              qf_entry.col = potential_col
              text_start_idx = 4
            end
          end

          -- Add text (everything from text_start_idx onwards)
          if #parts >= text_start_idx then
            local text = table.concat(vim.list_slice(parts, text_start_idx), ":")
            text = vim.fn.trim(text)
            if text ~= "" then
              qf_entry.text = text
            end
          end

          -- If no text was provided, read it from the file
          if not qf_entry.text then
            local file_lines = vim.fn.readfile(filename, "", lnum)
            if #file_lines > 0 then
              qf_entry.text = vim.fn.trim(file_lines[#file_lines])
            end
          end

          table.insert(qf_items, qf_entry)
        end
      end
    end
    populate_quickfix(qf_items, "TV Text")
  else
    -- Open files directly
    for _, line in ipairs(entries) do
      local parts = vim.split(line, ":")
      if #parts >= 2 and vim.fn.filereadable(parts[1]) == 1 then
        -- Open file at specific line number
        vim.cmd("edit +" .. parts[2] .. " " .. vim.fn.fnameescape(parts[1]))
      end
    end
  end
end

-- Function to show selection menu for available channels
M.tv_channels = function()
  vim.ui.select({ "Files", "Text" }, {
    prompt = "Select TV mode:",
    format_item = function(item)
      if item == "Files" then
        return "🔍 Files - Search and open files"
      else
        return "📝 Text - Search text content"
      end
    end,
  }, function(choice)
    if choice == "Files" then
      M.tv_files()
    elseif choice == "Text" then
      M.tv_text()
    end
  end)
end

-- Setup function to configure the plugin
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Override default keybindings if custom ones are provided
  if opts and opts.keybindings then
    -- Remove default keybindings first
    pcall(vim.keymap.del, "n", "<C-p>")
    pcall(vim.keymap.del, "n", "<leader><leader>")
    pcall(vim.keymap.del, "n", "<leader>tv")

    -- Set up custom keybindings if they are configured (and not false)
    if M.config.keybindings.files then
      vim.keymap.set("n", M.config.keybindings.files, M.tv_files, { desc = "TV: Find files" })
    end
    if M.config.keybindings.text then
      vim.keymap.set("n", M.config.keybindings.text, M.tv_text, { desc = "TV: Search text" })
    end
    if M.config.keybindings.channels then
      vim.keymap.set("n", M.config.keybindings.channels, M.tv_channels, { desc = "TV: Select channel" })
    end
  end
end

M.create_win_and_buf = function(channel)
  local editor_height = vim.o.lines
  local editor_width = vim.o.columns

  -- Get window config for the specific channel
  local window_config = get_window_config(channel or "default")

  local tv_height = math.floor(window_config.height * editor_height)
  local tv_width = math.floor(window_config.width * editor_width)
  local row = (editor_height - tv_height) / 2
  local col = (editor_width - tv_width) / 2

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = tv_width,
    height = tv_height,
    row = row,
    col = col,
    border = window_config.border,
    title = window_config.title,
    title_pos = window_config.title_pos,
  })
end

M.tv_files = function()
  local expect_key = convert_keybinding_to_tv_format(M.config.keybindings.files_qf)
  launch_tv_channel("files", handle_files_output, expect_key)
end

M.tv_text = function(prompt_input)
  local expect_key = convert_keybinding_to_tv_format(M.config.keybindings.text_qf)
  launch_tv_channel("text", handle_text_output, expect_key, prompt_input)
end

-- Expose for testing
M._convert_keybinding_to_tv_format = convert_keybinding_to_tv_format

return M
