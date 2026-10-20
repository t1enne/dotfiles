--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used) vim.g.mapleader = ' '
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require 'keymaps'
require 'autocommands'

--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { require 'editor' },
  { 'folke/which-key.nvim', opts = {} },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
    },
    config = true,
  },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '▎' },
        change = { text = '~' },
        delete = { text = '' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        vim.keymap.set('n', '<leader>ghp', gs.preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })
        vim.keymap.set('n', '<leader>ghs', ':Gitsigns stage_hunk<CR>', { buffer = bufnr, desc = 'Preview git hunk' })
        vim.keymap.set({ 'n', 'v' }, '<leader>ghr', ':Gitsigns reset_hunk<CR>', { buffer = bufnr, desc = 'Reset git hunk' })
        vim.keymap.set('n', '<leader>ghS', gs.stage_buffer, { buffer = bufnr, desc = 'Stage Buffer' })
        vim.keymap.set('n', '<leader>ghd', gs.diffthis, { buffer = bufnr, desc = 'Diff This' })

        vim.keymap.set({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
        vim.keymap.set({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
      end,
    },
  },
  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
    },
  },
  { require 'lsp' },
}, {
  checker = { enabled = false, notify = false }, -- automatically check for plugin updates
  change_detection = { enabled = false },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        'gzip',
        -- "matchit",
        -- "matchparen",
        -- 'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
})

-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    border = true,
    borderchars = { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' },
    winblend = 0,
    git_worktrees = vim.g.git_worktrees,
    path_display = { 'truncate' },
    layout_strategy = 'vertical',
    layout_config = { prompt_position = 'top' },
    sorting_strategy = 'ascending',
    width = 0.75,
    height = 0.80,
    preview_cutoff = 120,
    highlights = {
      TelescopeBorder = { fg = 'none', bg = 'none' },
      TelescopePreviewBorder = { fg = 'none', bg = 'none' },
      TelescopePromptBorder = { fg = 'none', bg = 'none' },
      TelescopeResultsBorder = { fg = 'none', bg = 'none' },
    },
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
  pickers = {
    colorscheme = {
      enable_preview = true,
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == '' then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep {
      search_dirs = { git_root },
    }
  end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})
-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader>fb', require('telescope.builtin').current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Find [G]it [F]iles' })
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '[F]ind [F]iles' })
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = '[F]ind [H]elp' })
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').grep_string, { desc = '[F]ind current by [G]rep' })
vim.keymap.set('n', '<leader>fw', require('telescope.builtin').live_grep, { desc = '[F]ind [W]ord' })
vim.keymap.set('n', '<leader>fW', ':LiveGrepGitRoot<cr>', { desc = '[F]ind by [G]rep on Git Root' })
vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = '[F]ind [D]iagnostics' })
vim.keymap.set('n', '<leader>fr', require('telescope.builtin').resume, { desc = '[F]ind [R]esume' })
vim.keymap.set('n', '<leader>fc', require('telescope.builtin').colorscheme, { desc = '[F]ind [C]olorscheme' })
vim.keymap.set('n', '<leader>fl', ':lua require("telescope.builtin").find_files { cwd = vim.fn.expand("%:p:h") } <cr>', { desc = '[F]ind [L]ocally' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  -- Install parsers (async). Add languages here as needed.
  require('nvim-treesitter').install {
    'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash',
  }
end, 0)

-- Enable treesitter features per filetype (highlight, folds, indent).
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    -- Avoid starting treesitter in special/non-file buffers.
    if vim.tbl_contains({ 'nofile', 'prompt', 'quickfix', 'help', 'man' }, vim.bo[args.buf].buftype) then
      return
    end
    local ok, parser = pcall(vim.treesitter.get_parser, args.buf)
    if not ok or not parser then
      return
    end

    -- Highlighting (built into Neovim).
    vim.treesitter.start(args.buf)

    -- Folds (built into Neovim).
    vim.wo[args.win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo[args.win][0].foldmethod = 'expr'

    -- Experimental treesitter indentation.
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Configure textobjects (new API) + keymaps.
require('nvim-treesitter-textobjects').setup {
  select = {
    lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
    selection_modes = {
      ['@parameter.outer'] = 'v', -- charwise
      ['@function.outer'] = 'V', -- linewise
      ['@class.outer'] = 'V', -- linewise
    },
    include_surrounding_whitespace = false,
  },
  move = {
    set_jumps = true, -- whether to set jumps in the jumplist
  },
}

-- select keymaps
vim.keymap.set({ 'x', 'o' }, 'aa', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@parameter.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ia', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@parameter.inner', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'af', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'if', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ac', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ic', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
end)

-- move keymaps
vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
  require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
  require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, ']M', function()
  require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '][', function()
  require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
  require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
  require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[M', function()
  require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'n', 'x', 'o' }, '[]', function()
  require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
end)

-- swap keymaps
vim.keymap.set('n', '<leader>a', function()
  require('nvim-treesitter-textobjects.swap').swap_next('@parameter.inner')
end)
vim.keymap.set('n', '<leader>A', function()
  require('nvim-treesitter-textobjects.swap').swap_previous('@parameter.inner')
end)

-- document existing key chains
require('which-key').setup {
  { '<leader>d', name = '[D]ocument' },
  { '<leader>d_', hidden = true },
  { '<leader>g', name = '[G]it' },
  { '<leader>g_', hidden = true },
  { '<leader>h', name = 'More git' },
  { '<leader>h_', hidden = true },
  { '<leader>l', name = '[L]sp' },
  { '<leader>l_', hidden = true },
  { '<leader>f', name = '[F]ind' },
  { '<leader>f_', hidden = true },
  { '<leader>w', name = '[W]orkspace' },
  { '<leader>w_', hidden = true },
}

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
-- require('mason-lspconfig').setup()
-- Setup neovim lua configuration
require('neodev').setup()

-- -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
-- local mason_lspconfig = require 'mason-lspconfig'
-- mason_lspconfig.setup {
--   ensure_installed = vim.tbl_keys(servers),
-- }
-- mason_lspconfig.setup_handlers {
--   function(server_name)
--     -- Skip ts_ls and denols as they're configured in lsp.lua
--     if server_name ~= 'ts_ls' and server_name ~= 'denols' then
--       require('lspconfig')[server_name].setup {
--         -- capabilities = capabilities,
--         on_attach = on_attach,
--         settings = servers[server_name],
--         filetypes = (servers[server_name] or {}).filetypes,
--       }
--     end
--   end,
-- }

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
