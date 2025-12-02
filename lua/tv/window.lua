local config = require("tv.config")

local M = {}

function M.create(channel)
  local editor_height = vim.o.lines
  local editor_width = vim.o.columns
  local window_config = config.get_window_config(channel or "default")

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

return M
