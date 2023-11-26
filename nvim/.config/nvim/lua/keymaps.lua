local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

map('x', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move down' })
map('x', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move up' })
-- navigation
map('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up' })
map('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down' })
-- save file
map('n', '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save file' })
-- close all
map('n', '<leader>qq', '<cmd>qa!<cr>', { desc = 'Save file' })
-- file explorer
map('n', '<leader>e', ':F %:p:h<cr>', { desc = 'Open FFF in here' })
map('n', '<leader>E', ':F<cr>', { desc = 'Open FFF in root dir' })

map('n', '<leader>c', ':bd<CR>', { desc = 'Close buffer' })

map('n', '<leader>/', ":lua require('Comment.api').toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)<CR>", { desc = 'Toggle comment line' })
map('v', '<leader>/', "<esc>:lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { desc = 'Toggle comment line' })

-- better indents
map('v', '<', '<gv')
map('v', '>', '>gv')

-- quickfix
map('n', '[q', vim.cmd.cprev, { desc = 'Previous quickfix' })
map('n', ']q', vim.cmd.cnext, { desc = 'Next quickfix' })

map('n', '<leader>xl', '<cmd>lopen<cr>', { desc = 'Location List' })
map('n', '<leader>xq', '<cmd>copen<cr>', { desc = 'Quickfix List' })

-- nav buffers
map('n', 'H', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
map('n', 'L', '<cmd>bnext<cr>', { desc = 'Next buffer' })
