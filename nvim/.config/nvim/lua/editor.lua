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
	" hi Normal guibg=none ctermbg=none
]]

return {
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
    'slugbyte/lackluster.nvim',
    config = function()
      vim.cmd.colorscheme 'lackluster'
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
    event = { 'BufReadPre', 'BufNewFile', 'BufEnter' },
    config = function()
      local conform = require 'conform'

      -- Global variable to store the current formatter
      vim.g.current_formatter = 'None'

      local formatters_by_ft = {
        javascript = { 'prettier', 'biome', 'deno_fmt' },
        typescript = { 'prettier', 'biome', 'deno_fmt' },
        javascriptreact = { 'prettier', 'biome', 'deno_fmt' },
        typescriptreact = { 'prettier', 'biome', 'deno_fmt' },
        -- For other file types, keep using Prettier as before
        css = { 'prettier' },
        html = { 'prettier' },
        json = { 'prettier', 'deno_fmt', 'biome' },
        yaml = { 'prettier' },
        markdown = { 'prettier' },
        graphql = { 'prettier' },
        liquid = { 'prettier' },
        lua = { 'stylua' },
        python = { 'isort', 'black' },
      }

      conform.setup {
        formatters_by_ft = formatters_by_ft,
        format_on_save = {
          lsp_fallback = true,
          timeout_ms = 500,
        },
      }

      -- Function to find the first config file by walking up the directory tree
      local function find_first_config()
        local current_dir = vim.fn.expand '%:p:h'
        local home_dir = vim.fn.expand '$HOME'

        local config_files = {
          prettier = { '.prettierrc', '.prettierrc.json', '.prettierrc.js' },
          biome = { 'biome.json' },
          deno = { 'deno.json', 'deno.jsonc' },
        }

        while current_dir ~= home_dir and current_dir ~= '/' do
          for formatter, patterns in pairs(config_files) do
            for _, pattern in ipairs(patterns) do
              local config_file = current_dir .. '/' .. pattern
              if vim.fn.filereadable(config_file) == 1 then
                return formatter
              end
            end
          end
          current_dir = vim.fn.fnamemodify(current_dir, ':h')
        end
        return nil
      end

      -- Function to determine the formatter based on config files and file type
      local function get_formatter()
        local filetype = vim.bo.filetype
        local available_formatters = formatters_by_ft[filetype] or {}
        local formatter = find_first_config()

        if formatter then
          if formatter == 'prettier' and vim.tbl_contains(available_formatters, 'prettier') then
            vim.g.current_formatter = 'prettier'
            return { 'prettier' }
          elseif formatter == 'biome' and vim.tbl_contains(available_formatters, 'biome') then
            vim.g.current_formatter = 'biome'
            return { 'biome' }
          elseif formatter == 'deno' and vim.tbl_contains(available_formatters, 'deno_fmt') then
            vim.g.current_formatter = 'deno_fmt'
            return { 'deno_fmt' }
          end
        end

        -- Default to the first available formatter for the file type, or prettier if none specified
        vim.g.current_formatter = available_formatters[1] or 'prettier'
        return { vim.g.current_formatter }
      end

      -- Function to update the current formatter
      local function update_current_formatter()
        get_formatter()
      end

      -- Create autocmd for updating the formatter on buffer open
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile', 'BufEnter' }, {
        callback = update_current_formatter,
      })

      -- Create autocmd for formatting on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*',
        callback = function(args)
          local formatters = get_formatter()
          conform.format {
            bufnr = args.buf,
            formatters = formatters,
            timeout_ms = 1000,
          }
        end,
      })

      -- Keymap for manual formatting
      vim.keymap.set({ 'n', 'v' }, '<leader>mp', function()
        local formatters = get_formatter()
        conform.format {
          formatters = formatters,
          async = false,
          timeout_ms = 1000,
        }
      end, { desc = 'Format file or range (in visual mode)' })
    end,
  },
}
