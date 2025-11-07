local tv = require("tv")

describe("tv.nvim", function()
  before_each(function()
    -- Reset config to defaults before each test
    tv.config = {
      tv_binary = "tv",
      window = {
        width = 0.8,
        height = 0.8,
        border = "none",
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
        files = "<leader>tf",
        text = "<leader>tt",
        both = "<leader>tv",
      },
    }
  end)

  describe("setup", function()
    it("works with default config", function()
      tv.setup()
      assert.are.equal("tv", tv.config.tv_binary)
      assert.are.equal(0.8, tv.config.window.width)
      assert.are.equal("<leader>tf", tv.config.keybindings.files)
    end)

    it("works without calling setup (defaults available)", function()
      -- Config should have defaults even without calling setup
      assert.are.equal("tv", tv.config.tv_binary)
      assert.are.equal(0.8, tv.config.window.width)
      assert.are.equal("<leader>tf", tv.config.keybindings.files)
    end)

    it("merges custom config with defaults", function()
      tv.setup({
        tv_binary = "custom-tv",
        window = {
          width = 0.9,
          border = "single",
        },
        files = {
          args = { "--custom-arg" },
        },
      })

      assert.are.equal("custom-tv", tv.config.tv_binary)
      assert.are.equal(0.9, tv.config.window.width)
      assert.are.equal(0.8, tv.config.window.height) -- should keep default
      assert.are.equal("single", tv.config.window.border)
      assert.are.same({ "--custom-arg" }, tv.config.files.args)
      assert.are.equal("<leader>tf", tv.config.keybindings.files) -- should keep default
    end)

    it("allows disabling keybindings", function()
      tv.setup({
        keybindings = {
          files = false,
          text = false,
          both = false,
        },
      })

      assert.are.equal(false, tv.config.keybindings.files)
      assert.are.equal(false, tv.config.keybindings.text)
      assert.are.equal(false, tv.config.keybindings.both)
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

    it("has expected default arguments", function()
      local expected_files_args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" }
      local expected_text_args = { "--no-remote", "--no-status-bar", "--preview-size", "70", "--layout", "portrait" }

      assert.are.same(expected_files_args, tv.config.files.args)
      assert.are.same(expected_text_args, tv.config.text.args)
    end)

    it("has expected default keybindings", function()
      assert.are.equal("<leader>tf", tv.config.keybindings.files)
      assert.are.equal("<leader>tt", tv.config.keybindings.text)
      assert.are.equal("<leader>tv", tv.config.keybindings.both)
    end)
  end)

  describe("functions", function()
    it("has tv_files function", function()
      assert.is_function(tv.tv_files)
    end)

    it("has tv_text function", function()
      assert.is_function(tv.tv_text)
    end)

    it("has tv_both function", function()
      assert.is_function(tv.tv_both)
    end)

    it("has create_win_and_buf function", function()
      assert.is_function(tv.create_win_and_buf)
    end)

    it("has setup function", function()
      assert.is_function(tv.setup)
    end)
  end)
end)
