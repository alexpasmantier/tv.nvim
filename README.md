<div align="center" style="color: #abb2bf;font-family: 'Fira Code', monospace;">

# tv.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-7e98e8.svg?style=for-the-badge&logo=neovim)](https://neovim.io/)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-8faf77.svg?style=for-the-badge&logo=lua)

**📺 Neovim integration for [television](https://github.com/alexpasmantier/television).**

</div>

![demo](https://github.com/user-attachments/assets/14e743a5-e839-4eed-963b-e111d4e7d8b2)

The initial idea behind television was to create something like the popular telescope.nvim plugin, but as a standalone terminal application - keeping telescope's modularity without the Neovim dependency, and benefiting from Rust's performance.

This plugin brings Television back into Neovim through a thin Lua wrapper around the binary. It started as a way to dogfood my own project, but might be of interest to other tv enthusiasts as well. Full circle.

## Overview

If you're already familiar with [television](https://github.com/alexpasmantier/television), this plugin basically lets you launch any of its channels from within Neovim, and decide what to do with the selected results (open as buffers, send to
quickfix, copy to clipboard, insert at cursor, checkout with git, etc.) using lua.

### Examples

|                                                                text                                                                |                                                                git-log                                                                |
| :--------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------: |
| <img width="1494" height="974" alt="text" src="https://github.com/user-attachments/assets/4d3d3cf7-6837-48b0-858d-6113bc0b0c3c" /> | <img width="1496" height="977" alt="git-log" src="https://github.com/user-attachments/assets/5f450a3a-47d3-4104-9bdd-41de1a325a27" /> |
|                                                              **tldr**                                                              |                                                              **gh-prs**                                                               |
| <img width="1491" height="973" alt="tldr" src="https://github.com/user-attachments/assets/c438d252-d742-44a5-b4c6-b7d931ea11a1" /> | <img width="1495" height="976" alt="gh-prs" src="https://github.com/user-attachments/assets/25d2235b-3827-4cd1-8a6f-a23e2a4690b1" />  |

<div align="center">

Curious about channels available in television? Check out [this
page](https://alexpasmantier.github.io/television/docs/Users/community-channels-unix).

</div>

## Installation

```lua
-- lazy.nvim
{
  "alexpasmantier/tv.nvim",
  config = function()
    require("tv").setup{
      -- your config here (see Configuration section below)
    }
  end,
}

-- packer.nvim
use {
  "alexpasmantier/tv.nvim",
  config = function()
    require("tv").setup{
      -- your config here (see Configuration section below)
    }
  end,
}
```

**Note**: requires [television](https://github.com/alexpasmantier/television) to be installed and available in your PATH.

## Configuration

### Basic Setup

Here's a minimal setup example to get you started, which includes configuration for the `files` and `text` channels that
are the most commonly used ones:

```lua
  {
    "alexpasmantier/tv.nvim",
    config = function()
      local h = require('tv').handlers

      require('tv').setup({
        -- per-channel configurations
        channels = {
          -- `files`: fuzzy find files in your project
          files = {
            keybinding = '<C-p>',               -- Launch the files channel
            -- what happens when you press a key
            handlers = {
              ['<CR>'] = h.open_as_files,         -- default: open selected files
              ['<C-q>'] = h.send_to_quickfix,     -- send to quickfix list
              ['<C-s>'] = h.open_in_split,       -- open in horizontal split
              ['<C-v>'] = h.open_in_vsplit,      -- open in vertical split
              ['<C-y>'] = h.copy_to_clipboard,   -- copy paths to clipboard
            },
          },
          -- `text`: ripgrep search through file contents
          text = {
            keybinding = '<leader><leader>',
            handlers = {
              ['<CR>'] = h.open_at_line,         -- Jump to line:col in file
              ['<C-q>'] = h.send_to_quickfix,    -- Send matches to quickfix
              ['<C-s>'] = h.open_in_split,       -- Open in horizontal split
              ['<C-v>'] = h.open_in_vsplit,      -- Open in vertical split
              ['<C-y>'] = h.copy_to_clipboard,   -- Copy matches to clipboard
            },
          },
        },
      })
    end,
  }
```

### Advanced Setup

Here's a more comprehensive configuration example demonstrating the plugin's capabilities:

```lua
  {
    "alexpasmantier/tv.nvim",
    config = function()
      -- built-in niceties
      local h = require("tv").handlers

      require("tv").setup({
        -- global window appearance (can be overridden per channel)
        window = {
          width = 0.8, -- 80% of editor width
          height = 0.8, -- 80% of editor height
          border = "none",
          title = " tv.nvim ",
          title_pos = "center",
        },
        -- per-channel configurations
        channels = {
          -- `files`: fuzzy find files in your project
          files = {
            keybinding = "<C-p>", -- Launch the files channel
            -- what happens when you press a key
            handlers = {
              ["<CR>"] = h.open_as_files, -- default: open selected files
              ["<C-q>"] = h.send_to_quickfix, -- send to quickfix list
              ["<C-s>"] = h.open_in_split, -- open in horizontal split
              ["<C-v>"] = h.open_in_vsplit, -- open in vertical split
              ["<C-y>"] = h.copy_to_clipboard, -- copy paths to clipboard
            },
          },

          -- `text`: ripgrep search through file contents
          text = {
            keybinding = "<leader><leader>",
            handlers = {
              ["<CR>"] = h.open_at_line, -- Jump to line:col in file
              ["<C-q>"] = h.send_to_quickfix, -- Send matches to quickfix
              ["<C-s>"] = h.open_in_split, -- Open in horizontal split
              ["<C-v>"] = h.open_in_vsplit, -- Open in vertical split
              ["<C-y>"] = h.copy_to_clipboard, -- Copy matches to clipboard
            },
          },

          -- `git-log`: browse commit history
          ["git-log"] = {
            keybinding = "<leader>gl",
            handlers = {
              -- custom handler: show commit diff in scratch buffer
              ["<CR>"] = function(entries, config)
                if #entries > 0 then
                  vim.cmd("enew | setlocal buftype=nofile bufhidden=wipe")
                  vim.cmd("silent 0read !git show " .. vim.fn.shellescape(entries[1]))
                  vim.cmd("1delete _ | setlocal filetype=git nomodifiable")
                  vim.cmd("normal! gg")
                end
              end,
              -- copy commit hash to clipboard
              ["<C-y>"] = h.copy_to_clipboard,
            },
          },

          -- `git-branch`: browse git branches
          ["git-branch"] = {
            keybinding = "<leader>gb",
            handlers = {
              -- checkout branch using execute_shell_command helper
              -- {} is replaced with the selected entry
              ["<CR>"] = h.execute_shell_command("git checkout {}"),
              ["<C-y>"] = h.copy_to_clipboard,
            },
          },

          -- `docker-images`: browse images and run containers
          ["docker-images"] = {
            keybinding = "<leader>di",
            window = { title = " Docker Images " },
            handlers = {
              -- run a container with the selected image
              ["<CR>"] = function(entries, config)
                if #entries > 0 then
                  vim.ui.input({
                    prompt = "Container name: ",
                    default = "my-container",
                  }, function(name)
                    if name and name ~= "" then
                      local cmd = string.format("docker run -it --name %s %s", name, entries[1])
                      vim.cmd("!" .. cmd)
                    end
                  end)
                end
              end,
              -- copy image name
              ["<C-y>"] = h.copy_to_clipboard,
            },
          },

          -- `env`: search environment variables
          env = {
            keybinding = "<leader>ev",
            handlers = {
              ["<CR>"] = h.insert_at_cursor, -- Insert at cursor position
              ["<C-l>"] = h.insert_on_new_line, -- Insert on new line
              ["<C-y>"] = h.copy_to_clipboard,
            },
          },

          -- `aliases`: search shell aliases
          alias = {
            keybinding = "<leader>al",
            handlers = {
              ["<CR>"] = h.insert_at_cursor,
              ["<C-y>"] = h.copy_to_clipboard,
            },
          },
        },
        -- path to the tv binary (default: 'tv')
        tv_binary = "tv",
        global_keybindings = {
          channels = "<leader>tv", -- opens the channel selector
        },
        quickfix = {
          auto_open = true, -- automatically open quickfix window after populating
        },
      })
    end,
  },
```

### Usage

**Commands:**

```vim
:Tv files              " Find files
:Tv text               " Search text in files
:Tv text @TODO         " Search with pre-populated query
:Tv git-log            " Browse commits
:Tv                    " Open channel selector
```

**Or use the keybindings you configured above.**

TV comes with 30+ built-in channels. Use `:Tv` to see all available channels, or try:

```vim
:Tv git-branch         " Switch branches
:Tv zsh-history        " Browse command history
:Tv procs              " List running processes
```

Tab completion works: `:Tv <Tab>`

### Troubleshooting

If you're on tv <= 0.14.1 and aren't a terminal tv user, you might need to pull the default set of channels from the repo by running:

```sh
tv update-channels
```

Versions >= 0.14.2 bundle a subset of default channels within the binary itself to avoid that inconvenience.

### Built-in Handlers Reference

```lua
local h = require('tv').handlers

-- File operations
h.open_as_files              -- Open selected entries as file buffers
h.open_at_line               -- Open file at specific line:col (for text search results)
h.open_in_split              -- Open in horizontal split
h.open_in_vsplit             -- Open in vertical split
h.open_in_scratch            -- Open in scratch (nofile) buffer

-- List operations
h.send_to_quickfix           -- Populate quickfix list with results

-- Text operations
h.copy_to_clipboard          -- Copy entries to system clipboard
h.insert_at_cursor           -- Insert at cursor position
h.insert_on_new_line         -- Insert each entry on new line

-- Interactive
h.show_in_select             -- Show vim.ui.select() menu for further actions

-- Shell execution
h.execute_shell_command(cmd) -- Execute shell command with selected entry
                             -- Use {} as placeholder for the entry
```

Note: handlers are expected to be of the following signature:

```lua
---@alias tv.Handler fun(entries: string[], config: tv.Config)
```

## License

MIT
