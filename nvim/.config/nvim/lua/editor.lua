-- [[ Setting options ]]
-- See `:help vim.o`
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
-- Set highlight on search
vim.o.hlsearch = false
-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true
-- Enable mouse mode
vim.o.mouse = 'a'
-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
vim.o.clipboard = 'unnamedplus'
-- Enable break indent
vim.o.breakindent = true
-- Save undo history
vim.o.undofile = true
-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'
-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300
-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'
-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

vim.opt.tabstop = 2

vim.opt.shiftwidth = 2

vim.opt.splitbelow = true
vim.opt.splitright = true
vim.cmd [[
	set noswapfile
	set nowrap
	iab lmd <C-v>u03bb

	" colorscheme retrobox
	" hi Normal guibg=none ctermbg=none
]]

return {
  { 'jaawerth/fennel.vim', ft = { 'fennel' } },
  { 'Olical/conjure', ft = { 'rkt', 'racket' } },
  { 'echasnovski/mini.surround', events = { 'VeryLazy' }, opts = { n_lines = 10, search_method = 'cover_or_next' } },
  {
    'bettervim/yugen.nvim',
    config = function()
      vim.cmd.colorscheme 'yugen'
    end,
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
        symbol = '▏', -- 
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
          html = { 'prettier' },
          lua = { 'stylua' },
          sh = { 'shfmt' },
          javascript = { ts_formatters },
          typescript = { ts_formatters },
          tsx = { ts_formatters },
          python = { 'black' },
          rust = { 'rustfmt' },
        },
        -- formatters = { deno_fmt_custom = {
        --   command = 'deno',
        --   args = { 'fmt', '--single-quote',  },
        -- } },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      }
    end,
  },
}
