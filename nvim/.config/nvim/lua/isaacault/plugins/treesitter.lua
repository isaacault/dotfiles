return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- The config below uses the master-branch API (nvim-treesitter.configs).
    -- master is archived and frozen; the default branch (main) is a rewrite
    -- with a different API, so an unpinned install would break this config.
    branch = "master",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "c",
          "cmake",
          "cpp",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "rust",
          "vim",
          "vimdoc",
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
  },
}
