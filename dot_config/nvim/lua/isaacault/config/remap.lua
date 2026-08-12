vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Explore file tree.
-- <leader>e cycles sidebars (explorer -> p4 CL -> none): see plugins/nvim-tree.lua

-- Move visual selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Format ( Visual selection or entire buffer )
vim.keymap.set({ "n", "v" }, "<leader>lf", function() vim.lsp.buf.format() end)
