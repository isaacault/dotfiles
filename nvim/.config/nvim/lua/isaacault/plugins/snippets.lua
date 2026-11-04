return {
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!).
    build = "make install_jsregexp",
    config = function()
      local ls = require("luasnip")
      -- Only jump when a snippet is active; otherwise fall through to the
      -- literal key so Tab still indents.
      vim.keymap.set({ "i", "s" }, "<Tab>", function()
        return ls.locally_jumpable(1) and "<Plug>luasnip-jump-next" or "<Tab>"
      end, { silent = true, expr = true })
      vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        return ls.locally_jumpable(-1) and "<Plug>luasnip-jump-prev" or "<S-Tab>"
      end, { silent = true, expr = true })
    end,
  },
}
