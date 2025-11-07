-- tv.nvim - Television integration for Neovim
-- Plugin commands and initialization

if vim.g.loaded_tv_nvim == 1 then
  return
end
vim.g.loaded_tv_nvim = 1

-- Create user commands
vim.api.nvim_create_user_command("TvFiles", function()
  require("tv").tv_files()
end, {
  desc = "Launch tv for file searching",
})

vim.api.nvim_create_user_command("TvText", function()
  require("tv").tv_text()
end, {
  desc = "Launch tv for text searching",
})

vim.api.nvim_create_user_command("Tv", function()
  require("tv").tv_both()
end, {
  desc = "Launch tv with mode selection",
})

-- Set up default keybindings
vim.keymap.set("n", "<leader>tf", function()
  require("tv").tv_files()
end, { desc = "TV: Find files" })

vim.keymap.set("n", "<leader>tt", function()
  require("tv").tv_text()
end, { desc = "TV: Search text" })

vim.keymap.set("n", "<leader>tv", function()
  require("tv").tv_both()
end, { desc = "TV: Select mode" })
