local utils = require("tv.utils")

local M = {}

---@class tv.Config
---@field tv_binary string
---@field quickfix { auto_open: boolean }
---@field window { width: number, height: number, border: string, title: string, title_pos: string }
---@field global_keybindings { channels: string }
---@field channels table<string, tv.ChannelConfig>

---@class tv.ChannelConfig
---@field keybinding? string
---@field args? string[]
---@field window? { width?: number, height?: number, border?: string, title?: string, title_pos?: string }
---@field handlers? table<string, tv.Handler>

---@alias tv.Handler fun(entries: string[], config: tv.Config)

---Copy entries to system clipboard
---@param entries string[]
---@param _ tv.Config
function M.copy_to_clipboard(entries, _)
  if #entries == 0 then
    return
  end
  local text = table.concat(entries, "\n")
  vim.fn.setreg("+", text)
  vim.notify(string.format("Copied %d item(s) to clipboard", #entries), vim.log.levels.INFO, { title = "tv.nvim" })
end

---Insert entries at cursor position
---@param entries string[]
---@param _ tv.Config
function M.insert_at_cursor(entries, _)
  if #entries == 0 then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- Insert first entry at cursor position
  local new_line = line:sub(1, col) .. entries[1] .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)

  -- Insert remaining entries as new lines
  if #entries > 1 then
    local remaining = vim.list_slice(entries, 2)
    vim.api.nvim_buf_set_lines(0, row, row, false, remaining)
  end
end

---Insert entries on new lines after cursor
---@param entries string[]
---@param _ tv.Config
function M.insert_on_new_line(entries, _)
  if #entries == 0 then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, entries)
end

---Open entries as files
---@param entries string[]
---@param _ tv.Config
function M.open_as_files(entries, _)
  for _, entry in ipairs(entries) do
    local file = vim.fn.trim(entry)
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
    end
  end
end

---Open files at line numbers (file:line:col format)
---@param entries string[]
---@param _ tv.Config
function M.open_at_line(entries, _)
  for _, entry in ipairs(entries) do
    local parts = vim.split(entry, ":", { plain = true })
    if #parts >= 2 then
      local filename = vim.fn.trim(parts[1])
      if vim.fn.filereadable(filename) == 1 then
        local lnum = tonumber(vim.fn.trim(parts[2])) or 1
        local col = #parts >= 3 and tonumber(vim.fn.trim(parts[3])) or nil

        vim.cmd("edit +" .. lnum .. " " .. vim.fn.fnameescape(filename))

        if col then
          vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
        end
      end
    end
  end
end

---Open entries as files in vertical splits
---@param entries string[]
---@param _ tv.Config
function M.open_in_vsplit(entries, _)
  for _, entry in ipairs(entries) do
    local file = vim.fn.trim(entry)
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("vsplit " .. vim.fn.fnameescape(file))
    end
  end
end

---Open entries as files in horizontal splits
---@param entries string[]
---@param _ tv.Config
function M.open_in_split(entries, _)
  for _, entry in ipairs(entries) do
    local file = vim.fn.trim(entry)
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("split " .. vim.fn.fnameescape(file))
    end
  end
end

---Open entries in a scratch buffer
---@param entries string[]
---@param _ tv.Config
function M.open_in_scratch(entries, _)
  if #entries == 0 then
    return
  end
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, entries)
end

---Send entries to quickfix (auto-detects file formats)
---@param entries string[]
---@param config tv.Config
function M.send_to_quickfix(entries, config)
  local qf_items = {}
  for _, entry in ipairs(entries) do
    local trimmed = vim.fn.trim(entry)
    local parts = vim.split(trimmed, ":", { plain = true })
    if #parts >= 2 then
      local filename = vim.fn.trim(parts[1])
      local lnum = tonumber(vim.fn.trim(parts[2]))

      if vim.fn.filereadable(filename) == 1 and lnum then
        local qf_entry = {
          filename = filename,
          lnum = lnum,
        }

        local text_start_idx = 3
        if #parts >= 3 then
          local potential_col = tonumber(vim.fn.trim(parts[3]))
          if potential_col then
            qf_entry.col = potential_col
            text_start_idx = 4
          end
        end

        if #parts >= text_start_idx then
          local text = table.concat(vim.list_slice(parts, text_start_idx), ":")
          text = vim.fn.trim(text)
          if text ~= "" then
            qf_entry.text = text
          end
        end

        if not qf_entry.text then
          local file_lines = vim.fn.readfile(filename, "", lnum)
          if #file_lines > 0 then
            qf_entry.text = vim.fn.trim(file_lines[#file_lines])
          end
        end

        table.insert(qf_items, qf_entry)
        goto continue
      end
    end

    if vim.fn.filereadable(trimmed) == 1 then
      local qf_entry = {
        filename = trimmed,
        lnum = 1,
      }
      local file_lines = vim.fn.readfile(trimmed, "", 1)
      if #file_lines > 0 then
        qf_entry.text = vim.fn.trim(file_lines[1])
      end
      table.insert(qf_items, qf_entry)
      goto continue
    end

    table.insert(qf_items, { text = trimmed })

    ::continue::
  end
  utils.populate_quickfix(qf_items, "TV", config)
end

---Execute shell command (use {} as placeholder)
---@param command_template string Command template (e.g., "git checkout {}")
---@return tv.Handler
function M.execute_shell_command(command_template)
  return function(entries, _)
    if #entries > 0 then
      local entry = vim.fn.shellescape(entries[1])
      local command = command_template:gsub("{}", entry)
      vim.cmd("!" .. command)
    end
  end
end

---Show entries in vim.ui.select for further action
---@param entries string[]
---@param _ tv.Config
function M.show_in_select(entries, _)
  if #entries == 0 then
    return
  end
  vim.ui.select(entries, {
    prompt = "Select entry:",
  }, function(choice)
    if choice then
      vim.fn.setreg("+", choice)
      vim.notify("Copied: " .. choice, vim.log.levels.INFO, { title = "tv.nvim" })
    end
  end)
end

return M
