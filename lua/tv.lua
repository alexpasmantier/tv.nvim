local M = {}

-- Default configuration
M.config = {
  tv_binary = "tv",
  window = {
    width = 0.8,
    height = 0.8,
    border = "none",
    title = " tv.nvim ",
    title_pos = "center",
  },
  files = {
    args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" },
  },
  text = {
    args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" },
  },
  keybindings = {
    files = "<leader>tf",
    text = "<leader>tt",
    both = "<leader>tv",
  },
}

-- Function to show selection menu for both commands
M.tv_both = function()
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
    pcall(vim.keymap.del, "n", "<leader>tf")
    pcall(vim.keymap.del, "n", "<leader>tt")
    pcall(vim.keymap.del, "n", "<leader>tv")

    -- Set up custom keybindings if they are configured (and not false)
    if M.config.keybindings.files then
      vim.keymap.set("n", M.config.keybindings.files, M.tv_files, { desc = "TV: Find files" })
    end
    if M.config.keybindings.text then
      vim.keymap.set("n", M.config.keybindings.text, M.tv_text, { desc = "TV: Search text" })
    end
    if M.config.keybindings.both then
      vim.keymap.set("n", M.config.keybindings.both, M.tv_both, { desc = "TV: Select mode" })
    end
  end
end

M.create_win_and_buf = function()
  local editor_height = vim.o.lines
  local editor_width = vim.o.columns

  local tv_height = math.floor(M.config.window.height * editor_height)
  local tv_width = math.floor(M.config.window.width * editor_width)
  local row = (editor_height - tv_height) / 2
  local col = (editor_width - tv_width) / 2

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = tv_width,
    height = tv_height,
    row = row,
    col = col,
    border = M.config.window.border,
    title = M.config.window.title,
    title_pos = M.config.window.title_pos,
  })
end

M.tv_files = function()
  M.create_win_and_buf()
  local output = {}

  -- Build command with configurable arguments
  local cmd = { M.config.tv_binary }
  vim.list_extend(cmd, M.config.files.args)
  vim.list_extend(cmd, { "files" })

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

      for _, line in ipairs(output) do
        local fname = vim.fn.trim(line)
        if fname ~= "" and vim.fn.filereadable(fname) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(fname))
        end
      end
    end,
    term = true,
  })
  vim.cmd("startinsert")
end

M.tv_text = function()
  M.create_win_and_buf()
  local output = {}

  -- Build command with configurable arguments
  local cmd = { M.config.tv_binary }
  vim.list_extend(cmd, M.config.text.args)
  vim.list_extend(cmd, { "text" })

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

      for _, line in ipairs(output) do
        local trimmed_line = vim.fn.trim(line)
        if trimmed_line ~= "" then
          local parts = vim.split(trimmed_line, ":")
          if #parts >= 2 and vim.fn.filereadable(parts[1]) == 1 then
            -- Open file at specific line number
            vim.cmd("edit +" .. parts[2] .. " " .. vim.fn.fnameescape(parts[1]))
          end
        end
      end
    end,
    term = true,
  })
  vim.cmd("startinsert")
end

return M
