local M = {}

local handlers = nil
local function get_handlers()
  if not handlers then
    handlers = require("tv.handlers")
  end
  return handlers
end

local DEFAULT_TV_ARGS = { "--no-remote", "--no-status-bar" }

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
      args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" },
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
      args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" },
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

local discovered_channels = nil
local function discover_channels(tv_binary)
  if discovered_channels then
    return discovered_channels
  end

  local handle = io.popen(tv_binary .. " list-channels 2>/dev/null")
  if not handle then
    return {}
  end

  local result = handle:read("*a")
  handle:close()

  local channels = {}
  for channel in result:gmatch("[^\r\n]+") do
    if channel ~= "" then
      table.insert(channels, channel)
    end
  end

  discovered_channels = channels
  return channels
end

function M.initialize_channel_defaults()
  local channels = discover_channels(M.current.tv_binary)
  local defaults = { args = DEFAULT_TV_ARGS }

  for _, channel_name in ipairs(channels) do
    local user_config = M.current.channels[channel_name]
    if user_config then
      M.current.channels[channel_name] = vim.tbl_deep_extend("force", defaults, user_config)
    else
      M.current.channels[channel_name] = defaults
    end
  end
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
  if not discovered_channels then
    M.initialize_channel_defaults()
  end

  if M.current.channels[channel] then
    return M.current.channels[channel]
  end

  return { args = DEFAULT_TV_ARGS }
end

function M.merge(user_config)
  M.current = vim.tbl_deep_extend("force", M.current, user_config or {})
end

return M
