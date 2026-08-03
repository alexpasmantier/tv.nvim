local tv = require("tv")
local tv_config = require("tv.config")

describe("tv.nvim", function()
  before_each(function()
    -- Reset config to defaults before each test
    -- We need to reset config.current directly since tv.config is a reference to it
    for k in pairs(tv_config.current) do
      tv_config.current[k] = nil
    end
    for k, v in pairs(tv_config.defaults) do
      tv_config.current[k] = vim.deepcopy(v)
    end
  end)

  describe("setup", function()
    it("works with default config", function()
      tv.setup()
      assert.are.equal("tv", tv.config.tv_binary)
      assert.are.equal(0.8, tv.config.window.width)
      assert.is_nil(tv.config.channels.files.keybinding)
      assert.are.equal("<leader>tv", tv.config.global_keybindings.channels)
    end)

    it("works without calling setup (defaults available)", function()
      -- Config should have defaults even without calling setup
      assert.are.equal("tv", tv.config.tv_binary)
      assert.are.equal(0.8, tv.config.window.width)
      assert.is_nil(tv.config.channels.files.keybinding)
    end)

    it("merges custom config with defaults", function()
      tv.setup({
        tv_binary = "custom-tv",
        window = {
          width = 0.9,
          border = "single",
        },
        channels = {
          files = {
            args = { "--custom-arg" },
          },
        },
      })

      -- Access config.current directly since tv.config reference may break after merge
      assert.are.equal("custom-tv", tv_config.current.tv_binary)
      assert.are.equal(0.9, tv_config.current.window.width)
      assert.are.equal(0.8, tv_config.current.window.height) -- should keep default
      assert.are.equal("single", tv_config.current.window.border)
      assert.are.same({ "--custom-arg" }, tv_config.current.channels.files.args)
      assert.is_nil(tv_config.current.channels.files.keybinding) -- should keep default (nil)
    end)

    it("allows per-channel window configuration", function()
      tv.setup({
        channels = {
          files = {
            window = {
              width = 0.9,
              title = " Files ",
              border = "rounded",
            },
          },
          text = {
            window = {
              width = 0.7,
              title = " Text Search ",
            },
          },
        },
      })

      -- Files channel should have custom window settings
      assert.are.equal(0.9, tv_config.current.channels.files.window.width)
      assert.are.equal(" Files ", tv_config.current.channels.files.window.title)
      assert.are.equal("rounded", tv_config.current.channels.files.window.border)

      -- Text channel should have custom window settings
      assert.are.equal(0.7, tv_config.current.channels.text.window.width)
      assert.are.equal(" Text Search ", tv_config.current.channels.text.window.title)

      -- Global defaults should remain
      assert.are.equal(0.8, tv_config.current.window.width)
      assert.are.equal("none", tv_config.current.window.border)
    end)

    it("allows disabling keybindings", function()
      tv.setup({
        global_keybindings = {
          channels = false,
        },
        channels = {
          files = {
            keybinding = false,
          },
          text = {
            keybinding = false,
          },
        },
      })

      assert.are.equal(false, tv_config.current.global_keybindings.channels)
      assert.are.equal(false, tv_config.current.channels.files.keybinding)
      assert.are.equal(false, tv_config.current.channels.text.keybinding)
    end)
  end)

  describe("configuration", function()
    it("has expected default values", function()
      assert.are.equal("tv", tv.config.tv_binary)
      assert.are.equal(0.8, tv.config.window.width)
      assert.are.equal(0.8, tv.config.window.height)
      assert.are.equal("none", tv.config.window.border)
      assert.are.equal(" tv.nvim ", tv.config.window.title)
      assert.are.equal("center", tv.config.window.title_pos)
    end)

    it("has expected default quickfix config", function()
      assert.are.equal(true, tv.config.quickfix.auto_open)
    end)

    it("passes no layout unless explicitly configured", function()
      assert.is_nil(tv_config.get_layout("files"))

      tv.setup({ layout = "portrait" })
      assert.are.equal("portrait", tv_config.get_layout("files"))

      tv.setup({ channels = { files = { layout = "landscape" } } })
      assert.are.equal("landscape", tv_config.get_layout("files"))
    end)
  end)

  describe("ad-hoc channels", function()
    local original = {}
    local state

    before_each(function()
      state = {}
      original.jobstart = vim.fn.jobstart
      original.tempname = vim.fn.tempname

      vim.fn.tempname = function()
        state.source_path = original.tempname()
        return state.source_path
      end
      vim.fn.jobstart = function(command, options)
        state.job = { command = vim.deepcopy(command), options = options }
        state.window = vim.api.nvim_get_current_win()
        state.buffer = vim.api.nvim_get_current_buf()
        return 1
      end
    end)

    after_each(function()
      vim.fn.jobstart = original.jobstart
      vim.fn.tempname = original.tempname

      if state.window and vim.api.nvim_win_is_valid(state.window) then
        vim.api.nvim_win_close(state.window, true)
      end
      if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
        vim.api.nvim_buf_delete(state.buffer, { force = true })
      end
      if state.source_path then
        vim.fn.delete(state.source_path)
      end
    end)

    it("passes arguments and routes exact selections", function()
      local received
      tv.pick({ "1\tFirst", "2\tSecond" }, {
        args = { "--source-display", "{split:\\t:1}" },
        handlers = {
          ["<CR>"] = function() end,
          ["<C-s>"] = function(entries)
            received = entries
          end,
        },
      })

      local read_command = vim.fn.has("win32") == 1 and "type" or "cat"
      assert.are.same({
        "tv",
        "--source-display",
        "{split:\\t:1}",
        "--source-command",
        read_command .. " " .. vim.fn.shellescape(state.source_path),
        "--expect",
        "ctrl-s;enter",
      }, state.job.command)
      vim.api.nvim_buf_set_lines(state.buffer, 0, -1, false, { "ctrl-s", "  first  ", "second" })
      state.job.options.on_exit(1, 0)

      assert.are.same({ "  first  ", "second" }, received)
      assert.are.equal(0, vim.fn.filereadable(state.source_path))
    end)

    it("does not mistake an automatic selection for a confirmation key", function()
      local received
      local ctrl_s_called = false
      tv.pick({ "ctrl-s" }, {
        args = { "--take-1" },
        handlers = {
          ["<CR>"] = function(entries)
            received = entries
          end,
          ["<C-s>"] = function()
            ctrl_s_called = true
          end,
        },
      })

      assert.is_false(vim.tbl_contains(state.job.command, "--expect"))
      vim.api.nvim_buf_set_lines(state.buffer, 0, -1, false, { "ctrl-s" })
      state.job.options.on_exit(1, 0)

      assert.are.same({ "ctrl-s" }, received)
      assert.is_false(ctrl_s_called)
    end)
  end)

  describe("_convert_keybinding_to_tv_format", function()
    local convert = tv._convert_keybinding_to_tv_format

    describe("control key combinations", function()
      it("converts <C-q> to ctrl-q", function()
        assert.are.equal("ctrl-q", convert("<C-q>"))
      end)

      it("converts uppercase <C-Q> to ctrl-q", function()
        assert.are.equal("ctrl-q", convert("<C-Q>"))
      end)
    end)

    describe("alt key combinations", function()
      it("converts <A-q> to alt-q", function()
        assert.are.equal("alt-q", convert("<A-q>"))
      end)

      it("converts <M-q> to alt-q (meta as alt)", function()
        assert.are.equal("alt-q", convert("<M-q>"))
      end)
    end)

    describe("shift key combinations", function()
      it("converts <S-f> to shift-f", function()
        assert.are.equal("shift-f", convert("<S-f>"))
      end)
    end)

    describe("special keys", function()
      it("converts <Enter> to enter", function()
        assert.are.equal("enter", convert("<Enter>"))
      end)

      it("converts <Esc> to esc", function()
        assert.are.equal("esc", convert("<Esc>"))
      end)

      it("converts <Tab> to tab", function()
        assert.are.equal("tab", convert("<Tab>"))
      end)

      it("converts <Space> to space", function()
        assert.are.equal("space", convert("<Space>"))
      end)
    end)

    describe("edge cases", function()
      it("returns nil for nil input", function()
        assert.is_nil(convert(nil))
      end)

      it("converts plain text without brackets", function()
        assert.are.equal("ctrl-q", convert("ctrl-q"))
      end)

      it("handles case conversion", function()
        assert.are.equal("ctrl-q", convert("<C-Q>"))
      end)
    end)

    describe("complex combinations", function()
      it("handles multiple modifier keys in sequence", function()
        -- While uncommon, test that the function handles text with multiple patterns
        local input = "<C-a> and <A-b>"
        local expected = "ctrl-a and alt-b"
        assert.are.equal(expected, convert(input))
      end)
    end)
  end)
end)
