local config = require("tv.config")
local channels = require("tv.channels")
local handlers = require("tv.handlers")
local utils = require("tv.utils")

local M = {}

---@class tv.Module
---@field tv_channel fun(channel: string, prompt_input?: string): nil
---@field tv_channels fun(): nil
---@field tv_files fun(prompt_input?: string): nil
---@field tv_text fun(prompt_input?: string): nil
---@field setup fun(opts?: tv.Config): nil
---@field handlers tv.HandlersModule

---@class tv.HandlersModule
---@field copy_to_clipboard tv.Handler
---@field insert_at_cursor tv.Handler
---@field insert_on_new_line tv.Handler
---@field open_as_files tv.Handler
---@field open_at_line tv.Handler
---@field open_in_split tv.Handler
---@field open_in_vsplit tv.Handler
---@field open_in_scratch tv.Handler
---@field send_to_quickfix tv.Handler
---@field show_in_select tv.Handler
---@field execute_shell_command fun(command_template: string): tv.Handler

M.tv_channel = channels.launch
M.tv_channels = channels.select

M.handlers = handlers
M.config = config.current

local function setup_keybindings()
  if config.current.global_keybindings.channels then
    pcall(vim.keymap.del, "n", config.current.global_keybindings.channels)
    vim.keymap.set("n", config.current.global_keybindings.channels, M.tv_channels, { desc = "TV: Select channel" })
  end

  if config.current.channels then
    for channel_name, channel_config in pairs(config.current.channels) do
      if channel_config.keybinding then
        pcall(vim.keymap.del, "n", channel_config.keybinding)
        local desc = "TV: " .. channel_name:gsub("-", " "):gsub("^%l", string.upper)
        vim.keymap.set("n", channel_config.keybinding, function()
          M.tv_channel(channel_name)
        end, { desc = desc })
      end
    end
  end
end

---@param opts? tv.Config
function M.setup(opts)
  if opts then
    config.merge(opts)
  end
  config.initialize_channel_defaults()
  setup_keybindings()
end

M._convert_keybinding_to_tv_format = utils.convert_keybinding_to_tv_format

---@type tv.Module
return M
