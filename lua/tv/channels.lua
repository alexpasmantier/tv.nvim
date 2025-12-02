local config = require("tv.config")
local window = require("tv.window")
local handlers = require("tv.handlers")
local utils = require("tv.utils")

local M = {}

local function launch_channel(channel, handler_map, prompt_input)
  window.create(channel)
  local output = {}
  local error_output = {}

  local cmd = { config.current.tv_binary }
  local channel_config = config.get_channel_config(channel)
  vim.list_extend(cmd, channel_config.args)

  if handler_map and type(handler_map) == "table" then
    local expect_keys = {}
    for nvim_key, _ in pairs(handler_map) do
      local tv_key = utils.convert_keybinding_to_tv_format(nvim_key)
      if tv_key then
        table.insert(expect_keys, tv_key)
      end
    end

    if #expect_keys > 0 then
      vim.list_extend(cmd, { "--expect", table.concat(expect_keys, ";") })
    end
  end

  vim.list_extend(cmd, { channel })

  if prompt_input then
    vim.list_extend(cmd, { "-i" .. tostring(prompt_input) })
  end

  vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(error_output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      pcall(vim.api.nvim_win_close, 0, true)

      if exit_code ~= 0 then
        local error_msg = "TV exited with code " .. exit_code
        if #error_output > 0 then
          error_msg = error_msg .. ":\n" .. table.concat(error_output, "\n")
        end
        vim.notify(error_msg, vim.log.levels.ERROR, { title = "tv.nvim" })
        return
      end

      if #error_output > 0 then
        vim.notify(table.concat(error_output, "\n"), vim.log.levels.WARN, { title = "tv.nvim" })
      end

      local pressed_key = nil
      local start_idx = 1

      if handler_map and #output > 0 and output[1] ~= "" then
        for nvim_key, _ in pairs(handler_map) do
          local tv_key = utils.convert_keybinding_to_tv_format(nvim_key)
          if tv_key and output[1] == tv_key then
            pressed_key = nvim_key
            start_idx = 2
            break
          end
        end
      end

      local entries = {}
      for i = start_idx, #output do
        local line = vim.fn.trim(output[i])
        if line ~= "" then
          table.insert(entries, line)
        end
      end

      if pressed_key and handler_map[pressed_key] then
        handler_map[pressed_key](entries, config.current)
      else
        handlers.open_as_files(entries, config.current)
      end
    end,
    term = true,
  })
  vim.cmd("startinsert")
end

function M.launch(channel_name, prompt_input)
  if not channel_name or channel_name == "" then
    vim.notify("Channel name is required", vim.log.levels.ERROR)
    return
  end

  local channel_config = config.get_channel_config(channel_name)
  launch_channel(channel_name, channel_config.handlers, prompt_input)
end

function M.select()
  local handle = io.popen(config.current.tv_binary .. " list-channels 2>/dev/null")
  if not handle then
    vim.notify("Failed to get available channels", vim.log.levels.ERROR)
    return
  end

  local result = handle:read("*a")
  handle:close()

  local channels = {}
  for channel in result:gmatch("[^\r\n]+") do
    if channel ~= "" then
      table.insert(channels, channel)
    end
  end

  if #channels == 0 then
    vim.notify("No channels available", vim.log.levels.WARN)
    return
  end

  table.sort(channels, function(a, b)
    if a == "files" then
      return true
    elseif b == "files" then
      return false
    elseif a == "text" then
      return true
    elseif b == "text" then
      return false
    else
      return a < b
    end
  end)

  vim.ui.select(channels, {
    prompt = "Select TV channel:",
    format_item = function(item)
      local descriptions = {
        files = "🔍 Search and open files",
        text = "📝 Search text content",
        ["git-log"] = "📜 Browse git commit history",
        ["git-branch"] = "🌿 Switch git branches",
        ["git-repos"] = "📁 Browse git repositories",
        ["docker-images"] = "🐳 Browse docker images",
        ["bash-history"] = "💻 Search bash command history",
        ["zsh-history"] = "💻 Search zsh command history",
        ["fish-history"] = "💻 Search fish command history",
        ["k8s-pods"] = "☸️  Browse Kubernetes pods",
        ["k8s-services"] = "☸️  Browse Kubernetes services",
        ["k8s-deployments"] = "☸️  Browse Kubernetes deployments",
        ["aws-instances"] = "☁️  Browse AWS EC2 instances",
        ["aws-buckets"] = "☁️  Browse AWS S3 buckets",
        ["github-issues"] = "🐙 Browse GitHub issues",
        sesh = "🪢 Manage tmux sessions",
        dotfiles = "💼 Manage dotfiles",
        ["man-pages"] = "📖 Browse man pages",
        ["just-recipes"] = "📋 Browse justfile recipes",
        ["git-reflog"] = "🔄 Browse git reflog",
        alias = "🔤 Browse shell aliases",
        guix = "🛍️  Browse Guix packages",
        procs = "⚙️  Browse system processes",
        ["git-diff"] = "🆚 Browse git diffs",
        channels = "📡 Browse available TV channels",
        dirs = "📂 Browse directories",
        ["distrobox-list"] = "🐧 Browse Distrobox containers",
        env = "🌐 Browse environment variables",
        ["nu-history"] = "📜 Browse Nushell command history",
        tldr = "📚 Browse tldr pages",
      }
      local desc = descriptions[item]
      if desc then
        return desc
      else
        return item:gsub("-", " "):gsub("^%l", string.upper)
      end
    end,
  }, function(choice)
    if choice then
      M.launch(choice)
    end
  end)
end

return M
