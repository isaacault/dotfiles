-- Show line numbers.
vim.opt.number = true
vim.opt.relativenumber = true

-- Tabs are 2 spaces.
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Auto indent new lines.
vim.opt.smartindent = true

-- Show where 80 char count is.
vim.opt.colorcolumn = "80"

-- Show result as we type.
vim.opt.incsearch = true

-- Smart case-sensitive search.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Scroll offset.
vim.opt.scrolloff = 10

-- Colors and UI.
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

-- Open splits to the right and below.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Don't wrap long lines.
vim.opt.wrap = false

-- Highlight search matches (cleared with <Esc>, see remap.lua).
vim.opt.hlsearch = true

-- Persistent undo instead of swap files.
vim.opt.swapfile = false
vim.opt.undofile = true

-- Faster CursorHold / swap events (diagnostics, LSP highlights).
vim.opt.updatetime = 250

-- Use the system clipboard.
vim.opt.clipboard = "unnamedplus"

-- Enable the mouse.
vim.opt.mouse = "a"

-- Show whitespace.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
