return {
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
    { 'j-hui/fidget.nvim', opts = {} },
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
      servers = {},
      setup = {},
    }
  end,
  config = function(_, opts) end,
}
