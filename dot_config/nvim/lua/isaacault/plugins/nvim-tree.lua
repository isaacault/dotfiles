-- File explorer on <leader>e (trialing vs netrw's :Ex).
-- The p4 CL panel is a separate thing: open it with :P4 cl.
return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    },
    opts = {},
  },
}
