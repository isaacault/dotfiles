-- BufRead is what triggers filetype detection, but Harpoon skips this. If the
-- filetype hasn't been loaded then syntax highlighting won't show. This checks
-- that the filetype hasn't been defined and that a normal file buffer is open
-- before detecting filetype.
vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("filetype_detect_on_enter", { clear = true }),
    callback = function()
        if vim.bo.filetype == "" and vim.bo.buftype == "" then
            vim.cmd("filetype detect")
        end
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach_auto_diag", { clear = true }),
    callback = function(ev)
        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set({ "n", "v" }, "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
    end,
})

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
    callback = function() vim.highlight.on_yank() end,
})

-- Strip trailing whitespace on save.
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("trim_trailing_whitespace", { clear = true }),
    pattern = "*",
    command = [[%s/\s\+$//e]],
})
