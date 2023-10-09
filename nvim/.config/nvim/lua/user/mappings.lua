-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    ["<leader>b"] = { name = "Buffers" },
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bd"] = { "<cmd>bd<cr>", desc = "Close tab" },
    ["<leader>e"] = { "<cmd>F<cr>", desc = "Open fff picker in $PWD" },
    ["<leader>E"] = { "<cmd>F %:p:h<cr>", desc = "Open fff picker in current dir" },
    ["<leader><F5>"] = { "<cmd>UndotreeToggle<cr>", desc = "Toggle UndoTree" },
    ["<C-k>"] = { "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Split Up" },
    ["<C-l>"] = { "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Split Left" },
    ["<C-j>"] = { "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Split Down" },
    ["<C-h>"] = { "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Split Right" },
    ["<C-s>"] = { ":w!<cr>" },
    ["H"] = { ":bp<cr>" },
    ["L"] = { ":bn<cr>" },
    ["<C-d>"] = { "<C-d>zz" },
    ["<C-u>"] = { "<C-u>zz" },
    ["n"] = { "nzz" },
    ["N"] = { "Nzz" },
    ["<C-q>"] = function(bufnr)
      require("telescope.actions").smart_send_to_qflist(bufnr)
      require("telescope.builtin").quickfix()
    end,
    -- ["<leader>q"] = { "<cmd>silent bd<cr>", desc = "Quit buffer" },
    ["[q"] = { ":cprev<cr>" },
    ["]q"] = { ":cnext<cr>" },
    ["[Q"] = { ":cfirst<cr>" },
    ["]Q"] = { ":clast<cr>" },
    ["<C-n>"] = { "O<esc>" },
    ["<C-m>"] = { "o<esc>" },
  },
  t = {
    ["<esc>"] = { "<Esc> <C-\\><C-n>" },
    ["<leader>c"] = { "<cmd>silent bd!<cr>" },
  },
  x = {
    ["J"] = { ":m '>+1<CR>gv=gv", desc = "Move line down" },
    ["K"] = { ":m '>-2<CR>gv=gv", desc = "Move line up" },
    [">"] = { ">", desc = "Move line up" },
  },
  i = {
    ["<M-l>"] = { "<C-O>$" },
    ["<M-h>"] = { "<C-O>^" },
    -- ["<C-j>"] = { "<C-O>j" },
    -- ["<C-k>"] = { "<C-O>k" },
  },
}
