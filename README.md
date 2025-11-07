# tv.nvim

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/your-username/tv.nvim/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin that integrates the [tv](https://github.com/alexhallam/tv) (television) terminal fuzzy finder into Neovim. Launch tv for file and text searching with results opened directly in Neovim buffers.

## Features

- 🔍 **File Search**: Launch tv for fuzzy file finding
- 📝 **Text Search**: Search text across files with line number navigation
- ⚙️ **Configurable**: Customize tv arguments, window appearance, and keybindings
- 🎯 **Direct Integration**: Selected files open directly in Neovim buffers
- ⌨️ **Default Keybindings**: `<leader>tf` for files, `<leader>tt` for text, `<leader>tv` for mode selection
- 📦 **Commands**: `:TvFiles`, `:TvText`, and `:Tv` user commands

## Requirements

- Neovim >= 0.8.0
- [tv](https://github.com/alexhallam/tv) command-line tool installed and available in PATH

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

**Simple installation (uses defaults):**
```lua
{
  "your-username/tv.nvim",
}
```

**With custom configuration:**
```lua
{
  "your-username/tv.nvim",
  config = function()
    require("tv").setup({
      -- Your custom configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

**Simple installation (uses defaults):**
```lua
use "your-username/tv.nvim"
```

**With custom configuration:**
```lua
use {
  "your-username/tv.nvim",
  config = function()
    require("tv").setup({
      -- Your custom configuration here
    })
  end,
}
```

## Configuration

The plugin works out of the box with default keybindings and settings. The `setup()` function is only needed for customization.

### Default Configuration

```lua
require("tv").setup({
  tv_binary = "tv",
  window = {
    width = 0.8,         -- 80% of editor width
    height = 0.8,        -- 80% of editor height
    border = "none",     -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
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
    files = "<leader>tf",  -- Set to false to disable
    text = "<leader>tt",   -- Set to false to disable
    both = "<leader>tv",   -- Set to false to disable
  },
})
```

### Custom Configuration Examples

#### Custom TV Arguments
```lua
require("tv").setup({
  files = {
    args = { "--no-remote", "--no-status-bar", "--preview-size", "50", "--layout", "landscape" },
  },
  text = {
    args = { "--no-remote", "--no-status-bar", "--preview-size", "80" },
  },
})
```

#### Custom Window Appearance
```lua
require("tv").setup({
  window = {
    width = 0.9,
    height = 0.7,
    border = "rounded",   -- Add border
    title = " File Finder ",
  },
})
```

#### Custom Keybindings
```lua
require("tv").setup({
  keybindings = {
    files = "<C-p>",      -- Ctrl+p for files
    text = "<C-f>",       -- Ctrl+f for text search
    both = "<C-t>",       -- Ctrl+t for mode selection
  },
})
```

#### Disable Default Keybindings
```lua
require("tv").setup({
  keybindings = {
    files = false,  -- Disable default keybinding
    text = false,   -- Disable default keybinding
    both = false,   -- Disable default keybinding
  },
})
```

## Usage

### Commands

- `:TvFiles` - Launch tv for file searching
- `:TvText` - Launch tv for text searching
- `:Tv` - Show selection menu for files or text search

### Default Keybindings

- `<leader>tf` - Launch file search
- `<leader>tt` - Launch text search
- `<leader>tv` - Show mode selection menu

### Manual Keybinding Setup

If you prefer to set up your own keybindings:

```lua
vim.keymap.set("n", "<C-p>", require("tv").tv_files, { desc = "TV: Find files" })
vim.keymap.set("n", "<C-f>", require("tv").tv_text, { desc = "TV: Search text" })
vim.keymap.set("n", "<C-t>", require("tv").tv_both, { desc = "TV: Select mode" })
```

## How It Works

1. **File Search**: Launches tv with the `files` channel, capturing selected file paths
2. **Text Search**: Launches tv with the `text` channel, parsing `file:line` output format
3. **Integration**: Selected files are opened in Neovim buffers, with text search results jumping to specific line numbers
4. **Window Management**: Creates floating windows with configurable dimensions and appearance

## Development

### Running Tests

```bash
make test
```

### Code Formatting

This project uses StyLua for formatting. Configuration is in `.stylua.toml`.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.