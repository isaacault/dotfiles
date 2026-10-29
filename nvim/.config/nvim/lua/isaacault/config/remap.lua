vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Explore file tree.
-- <leader>e toggles the file explorer (see plugins/nvim-tree.lua); p4 CL panel is :P4 cl

-- Move visual selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Clear search highlight.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Keep cursor centered when paging and searching.
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste over selection without clobbering the register.
-- (which-key labels <leader>p as the perforce group; this is visual mode only.)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Diagnostics.
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- Format ( Visual selection or entire buffer )
vim.keymap.set({ "n", "v" }, "<leader>lf", function() vim.lsp.buf.format() end)
-- Option-l on a macOS US layout types "¬"
vim.keymap.set({ "n", "v" }, "¬", function() vim.lsp.buf.format() end)
