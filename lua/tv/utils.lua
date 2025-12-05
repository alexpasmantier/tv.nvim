local M = {}

---Convert Neovim keybinding notation to tv format
---@param keybinding string
---@return string?
function M.convert_keybinding_to_tv_format(keybinding)
  if not keybinding then
    return nil
  end

  local special_keys = {
    ["<CR>"] = "enter",
    ["<Enter>"] = "enter",
    ["<Return>"] = "enter",
    ["<Tab>"] = "tab",
    ["<Esc>"] = "esc",
    ["<Space>"] = "space",
    ["<BS>"] = "backspace",
    ["<Backspace>"] = "backspace",
    ["<Del>"] = "delete",
    ["<Delete>"] = "delete",
    ["<Up>"] = "up",
    ["<Down>"] = "down",
    ["<Left>"] = "left",
    ["<Right>"] = "right",
    ["<Home>"] = "home",
    ["<End>"] = "end",
    ["<PageUp>"] = "page-up",
    ["<PageDown>"] = "page-down",
  }

  for nvim_key, tv_key in pairs(special_keys) do
    if keybinding:lower() == nvim_key:lower() then
      return tv_key
    end
  end

  return keybinding
    :gsub("<C%-([^>]+)>", "ctrl-%1")
    :gsub("<A%-([^>]+)>", "alt-%1")
    :gsub("<M%-([^>]+)>", "alt-%1")
    :gsub("<S%-([^>]+)>", "shift-%1")
    :gsub("<([^>]+)>", "%1")
    :lower()
end

---@param items table[]
---@param title string
---@param config tv.Config
function M.populate_quickfix(items, title, config)
  vim.fn.setqflist({}, "r", {
    title = title or "TV",
    items = items,
  })

  if config.quickfix.auto_open then
    vim.cmd("copen")
  end
end

return M
