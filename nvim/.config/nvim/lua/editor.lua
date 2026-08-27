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
vim.g.clipboard = 'xclip'
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
	colorscheme habamax
	hi Normal guibg=none ctermbg=none
]]

vim.diagnostic.config {
  virtual_text = { current_line = true },
  -- virtual_lines = true,
}

return {
  { 'folke/twilight.nvim', opts = {}, keys = {
    { '<leader>tt', ':Twilight<CR>', mode = { 'n' }, desc = 'Toggle twilight' },
  } },
  {
    'luukvbaal/nnn.nvim',
    cmd = { 'NnnExplorer', 'NnnPicker' },
    keys = {
      { '<leader>fe', ':NnnPicker %:p:h<CR>', mode = { 'n' }, desc = 'Open file picker' },
    },
    opts = {
      picker = {
        cmd = 'nnn -oAe',
      },
    },
  },
  { 'jaawerth/fennel.vim', ft = { 'fennel' } },
  {
    'Olical/conjure',
    ft = { 'rkt', 'racket' },
    events = { 'BufEnter' },
    config = function()
      vim.cmd [[
				iabbr lmd <C-v>u03bb
				iabbr lmd~> <C-v>u03bb~>
			]]
    end,
    dependencies = { 'gpanders/nvim-parinfer' },
  },
  { 'echasnovski/mini.surround', events = { 'VeryLazy' }, opts = { n_lines = 10, search_method = 'cover_or_next' } },
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
    'max397574/better-escape.nvim',
    opts = {
      default_mappings = false,
      mappings = {
        i = {
          j = {
            k = '<Esc>',
          },
        },
      },
    },
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
  -- {
  --   'dylanaraps/fff.vim',
  --   lazy = true,
  --   cmd = 'F',
  --   init = function()
  --     vim.cmd [[
  -- 		let g:fff#split = "20new"
  --   ]]
  --   end,
  -- },
  {
    'stevearc/conform.nvim',
    dependencies = { 'mason.nvim' },
    event = { 'BufReadPre', 'BufNewFile', 'BufEnter' },
    config = function()
      local conform = require 'conform'
      local formatters_by_ft = {
        javascript = { 'prettierd', 'biome' },
        typescript = { 'prettierd', 'biome' },
        javascriptreact = { 'prettierd', 'biome' },
        typescriptreact = { 'prettierd', 'biome' },
        -- For other file types, keep using Prettier as before
        css = { 'prettierd' },
        html = { 'prettierd' },
        json = { 'prettierd', 'biome' },
        yaml = { 'prettierd' },
        markdown = { 'prettierd' },
        graphql = { 'prettierd' },
        liquid = { 'prettierd' },
        lua = { 'stylua' },
        python = { 'ruff_format' },
      }

      conform.setup {
        formatters_by_ft = formatters_by_ft,
        format_on_save = {
          lsp_fallback = true,
          timeout_ms = 500,
        },
      }

      -- Create autocmd for formatting on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*',
        callback = function(args)
          require('conform').format { bufnr = args.buf }
        end,
      })
    end,
  },
}
