return {
  {
    'olimorris/codecompanion.nvim',
    config = true,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      adapters = {
        deepseek = function()
          return require('codecompanion.adapters').extend('deepseek', {
            schema = {
              model = {
                default = 'deepseek-chat',
              },
            },
          })
        end,
      },
      strategies = {
        cmd = {
          adapter = 'deepseek',
        },
        chat = {
          adapter = 'deepseek',
        },
        inline = {
          adapter = 'deepseek',
        },
      },
    },
  },
  {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = '*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      completion = {
        list = { selection = { preselect = false } },
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        trigger = { show_in_snippet = false },
        accept = {
          auto_brackets = { enabled = false },
        },
      },
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept, C-n/C-p for up/down)
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys for up/down)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-e: Hide menu
      -- C-k: Toggle signature help
      -- See the full "keymap" documentation for information on defining your own keymap.
      keymap = {
        preset = 'super-tab',
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Tab>'] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.snippet_forward()
            end
          end,
          'select_next',
          'fallback',
        },
        ['<CR>'] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            end
            return cmp.select_and_accept()
          end,
          'fallback',
        },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        per_filetype = { codecompanion = { 'codecompanion' } },
      },
      -- fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },
  {
    'neovim/nvim-lspconfig',
    -- event = 'InsertEnter',
    dependencies = {
      { 'saghen/blink.cmp' },
      { 'folke/neoconf.nvim', cmd = 'Neoconf', dependencies = { 'nvim-lspconfig' } },
      { 'folke/neodev.nvim', opts = {} },
      {
        'williamboman/mason.nvim',
        cmd = {
          'Mason',
          'MasonInstall',
          'MasonUninstall',
          'MasonUninstallAll',
          'MasonLog',
        },
        opts = {
          ensure_installed = {
            'stylua',
            'shfmt',
          },
        },
      },
      { 'williamboman/mason-lspconfig.nvim' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'j-hui/fidget.nvim' },
    },
    opts = function()
      return {
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = {
            spacing = 4,
            source = 'if_many',
          },
          severity_sort = true,
        },
        inlay_hints = { enabled = true },
        capabilities = {},
        autoformat = true,
        format = { formatting_options = nil, timeout_ms = nil },
        servers = {
          -- racket = {
          --   default_config = {
          --     cmd = { 'racket', '--lib', 'racket-langserver' },
          --     filetypes = { 'racket', 'scheme' },
          --     single_file_support = true,
          --   },
          -- },
        },
      }
    end,
    config = function(_, opts)
      local lspconfig = require 'lspconfig'
      lspconfig.racket_langserver.setup {
        default_config = {
          cmd = { 'racket', '--lib', 'racket-langserver' },
          filetypes = { 'racket', 'scheme' },
          single_file_support = true,
        },
      }
      for server, config in pairs(opts.servers) do
        config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end
    end,
  },
  { 'mfussenegger/nvim-jdtls' },
}
