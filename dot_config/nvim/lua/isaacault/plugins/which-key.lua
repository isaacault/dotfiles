-- Pops up a menu of available keybindings after <leader> (and friends).
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        -- Group labels; the maps themselves live with their plugins.
        { "<leader>p", group = "perforce" },
        { "<leader>l", group = "lsp" },
      },
    },
  },
}
