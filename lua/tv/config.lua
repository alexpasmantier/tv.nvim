local M = {}

local handlers = nil
local function get_handlers()
  if not handlers then
    handlers = require("tv.handlers")
  end
  return handlers
end

local VALID_LAYOUTS = { landscape = true, portrait = true }

M.defaults = {
  tv_binary = "tv",
  quickfix = {
    auto_open = true,
  },
  window = {
    width = 0.8,
    height = 0.8,
    border = "none",
    title = " tv.nvim ",
    title_pos = "center",
  },
  global_keybindings = {
    channels = "<leader>tv",
  },
  channels = {
    files = {
      keybinding = nil,
      handlers = {
        ["<CR>"] = function(entries, config)
          return get_handlers().open_as_files(entries, config)
        end,
        ["<C-q>"] = function(entries, config)
          return get_handlers().send_to_quickfix(entries, config)
        end,
      },
    },
    text = {
      keybinding = nil,
      handlers = {
        ["<CR>"] = function(entries, config)
          return get_handlers().open_at_line(entries, config)
        end,
        ["<C-q>"] = function(entries, config)
          return get_handlers().send_to_quickfix(entries, config)
        end,
      },
    },
  },
}

M.current = vim.deepcopy(M.defaults)

function M.get_layout(channel)
  local layout = M.current.layout
  if channel and M.current.channels[channel] and M.current.channels[channel].layout then
    layout = M.current.channels[channel].layout
  end
  if layout and VALID_LAYOUTS[layout] then
    return layout
  end
  return nil
end

function M.get_window_config(channel)
  local base_config = M.current.window
  local channel_config = {}
  if M.current.channels[channel] and M.current.channels[channel].window then
    channel_config = M.current.channels[channel].window
  end
  return vim.tbl_deep_extend("force", base_config, channel_config)
end

function M.get_channel_config(channel)
  return M.current.channels[channel] or {}
end

function M.merge(user_config)
  M.current = vim.tbl_deep_extend("force", M.current, user_config or {})
end

return M
