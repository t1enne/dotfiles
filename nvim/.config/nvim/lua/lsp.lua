return {
  {
    'neovim/nvim-lspconfig',
    -- event = 'InsertEnter',
    dependencies = {
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
          racket = {
            default_config = {
              cmd = { 'racket', '--lib', 'racket-langserver' },
              filetypes = { 'racket', 'scheme' },
              single_file_support = true,
            },
          },
        },
        setup = {
          rust_analyzer = {
            diagnostics = {
              enable = true,
            },
          },
        },
      }
    end,
    config = function(_, __)
      require('lspconfig').racket_langserver.setup {
        default_config = {
          cmd = { 'racket', '--lib', 'racket-langserver' },
          filetypes = { 'racket', 'scheme' },
          single_file_support = true,
        },
      }
    end,
  },
  { 'mfussenegger/nvim-jdtls' },
}
