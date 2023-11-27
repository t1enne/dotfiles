return {
  {
    'tpope/vim-surround',
    keys = { 'ds', 'cs', 'ys', 'ys', 'yS', 'yss' },
  },
  {
    'numToStr/Comment.nvim',
    keys = {
      { 'gc', mode = { 'n', 'v' }, desc = 'Comment toggle linewise' },
      { 'gb', mode = { 'n', 'v' }, desc = 'Comment toggle blockwise' },
    },
  },
  { 'echasnovski/mini.statusline', events = { 'VeryLazy ' }, version = '*', opts = {} },
  { 'echasnovski/mini.tabline', events = { 'VeryLazy ' }, version = '*', opts = {} },
  {
    'echasnovski/mini.indentscope',
    version = '*',
    events = { 'VeryLazy' },
    opts = function()
      return {
        delay = 0,
        draw = {
          animation = require('mini.indentscope').gen_animation.none(),
        },
        symbol = '',
        -- symbol = '▏',
      }
    end,
  },
  {
    'Exafunction/codeium.nvim',
    event = 'InsertEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
    },
    opts = {},
  },
  { 'max397574/better-escape.nvim', opts = {} },
  {
    'echasnovski/mini.pairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'christoomey/vim-tmux-navigator',
    events = { 'VeryLazy' },
    config = function() end,
    keys = function()
      return {
        { '<C-h>', ':TmuxNavigateLeft<CR>', desc = 'navigate to tmux left', mode = 'n' },
        { '<C-l>', ':TmuxNavigateRight<CR>', desc = 'navigate to tmux right', mode = 'n' },
        { '<C-j>', ':TmuxNavigateDown<CR>', desc = 'navigate to tmux down', mode = 'n' },
        { '<C-k>', ':TmuxNavigateUp<CR>', desc = 'navigate to tmux up', mode = 'n' },
      }
    end,
  },
  {
    'dylanaraps/fff.vim',
    lazy = true,
    cmd = 'F',
    init = function()
      vim.cmd [[
    let g:fff#split = "20new"
    ]]
    end,
  },
  {
    'stevearc/conform.nvim',
    dependencies = { 'mason.nvim', 'williamboman/mason-lspconfig.nvim' },
    opts = function()
      local is_deno = require('lspconfig.util').root_pattern('mod.ts', 'deno.json')
      local is_prettier = require('lspconfig.util').root_pattern '.prettierrc'
      local ts_formatters = {}

      if is_deno then
        table.insert(ts_formatters, 'deno_fmt')
      elseif is_prettier then
        table.insert(ts_formatters, 'prettier')
      end

      return {
        formatters_by_ft = {
          lua = { 'stylua' },
          sh = { 'shfmt' },
          javascript = { ts_formatters },
          typescript = { ts_formatters },
          html = { 'prettier' },
          tsx = { ts_formatters },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      }
    end,
  },
}
