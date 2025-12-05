if vim.g.loaded_tv_nvim == 1 then
  return
end
vim.g.loaded_tv_nvim = 1

vim.api.nvim_create_user_command("Tv", function(opts)
  local args = vim.trim(opts.args)

  if args == "" then
    require("tv").tv_channels()
    return
  end

  local parts = vim.split(args, "%s+", { trimempty = true })
  local channel = parts[1]
  local prompt_input = #parts > 1 and table.concat(vim.list_slice(parts, 2), " ") or nil

  require("tv").tv_channel(channel, prompt_input)
end, {
  desc = "Launch tv channel (usage: :Tv [channel] [query])",
  nargs = "*",
  complete = function(arg_lead, cmdline, _)
    local args = vim.split(vim.trim(cmdline:sub(4)), "%s+", { trimempty = true })

    if #args <= 1 then
      local handle = io.popen("tv list-channels 2>/dev/null")
      if not handle then
        return {}
      end
      local result = handle:read("*a")
      handle:close()

      local channels = {}
      for channel in result:gmatch("[^\r\n]+") do
        if channel:match("^" .. vim.pesc(arg_lead)) then
          table.insert(channels, channel)
        end
      end
      return channels
    end

    return {}
  end,
})
