return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "j-hui/fidget.nvim",
  },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    -- Set up lspconfig.
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    require("fidget").setup()
    require("mason").setup({ PATH = "append" })

    -- mason-lspconfig v2 enables installed servers itself (automatic_enable),
    -- so configure them up front with vim.lsp.config.
    vim.lsp.config("*", { capabilities = capabilities })
    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" }
          }
        }
      }
    })
    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "rust_analyzer",
      },
    })

    -- Don't ensure_installed clangd to allow for local clangd
    vim.lsp.config('clangd', {
      cmd = {
        "clangd",
        "--header-insertion=never",
      },
    })
    vim.lsp.enable('clangd')

    -- Set up nvim-cmp.
    local cmp = require('cmp')
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
          require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ['<C-Space>'] = cmp.mapping.complete(),
      }),
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' }, -- For luasnip users.
      }, {
        { name = 'buffer' },
      })
    })

    vim.diagnostic.config({
      -- update_in_insert = true,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
  end,
}
