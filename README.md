# 📺 tv.nvim

Neovim integration for [television](https://github.com/alexpasmantier/television).

The initial idea behind [television](https://github.com/alexpasmantier/television) was to create something like the popular [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) plugin, but as a standalone terminal application - keeping telescope's modularity without the Neovim dependency, and benefiting from Rust's performance.

This plugin brings Television back into Neovim through a thin Lua wrapper around the binary. It started as a way to dogfood my own project, but might be of interest to other tv enthusiasts as well. Full circle.

[![asciicast](https://asciinema.org/a/754777.svg?t=9&)](https://asciinema.org/a/754777)

## 🗒️ Requirements

- Neovim >= 0.8.0
- [television](https://github.com/alexpasmantier/television) binary in PATH

## 📦 Installation

```lua
-- lazy.nvim
{ "alexpasmantier/tv.nvim" }

-- packer.nvim
use "alexpasmantier/tv.nvim"
```

## 🖥️ Usage

**Default keybindings:**

| Keybinding                                  | Action         |
| ------------------------------------------- | -------------- |
| <kbd>Ctrl</kbd>+<kbd>p</kbd>                | Find files     |
| <kbd>Leader</kbd>+<kbd>Leader</kbd>         | Search text    |
| <kbd>Leader</kbd>+<kbd>t</kbd>+<kbd>v</kbd> | Select channel |

**Commands:**

- `:TvFiles` - Find files
- `:TvText` - Search text
- `:Tv` - Select channel

**Inside tv:**

| Keybinding                   | Action                           |
| ---------------------------- | -------------------------------- |
| <kbd>Enter</kbd>             | Open file(s) in buffers          |
| <kbd>Ctrl</kbd>+<kbd>q</kbd> | Send selections to quickfix list |

## ⚙️ Configuration

Optional `setup()` for customization:

```lua
require("tv").setup({
  keybindings = {
    files = "<C-p>",            -- or false to disable
    text = "<leader><leader>",
    channels = "<leader>tv",    -- channel selector
    files_qf = "<C-q>",         -- quickfix binding (inside tv)
    text_qf = "<C-q>",
  },
  quickfix = {
    auto_open = true,      -- auto-open quickfix window
  },
  window = {
    width = 0.8,           -- 80% of editor
    height = 0.8,
    border = "rounded",    -- none|single|double|rounded|solid|shadow
    title = " tv ",
  },
  files = {
    args = { "--preview-size", "70" },
    window = {},           -- override window config for files
  },
  text = {
    args = { "--preview-size", "70" },
    window = {},           -- override window config for text
  },
})
```

## Quickfix Workflow

Use `<C-q>` inside tv to send selections to quickfix:

1. Launch tv with files or text search
2. Mark files/results in tv
3. Press `<C-q>` to populate quickfix
4. Navigate with `:cnext`, `:cprev`, perform actions with `:cdo`, etc.

## License

MIT
