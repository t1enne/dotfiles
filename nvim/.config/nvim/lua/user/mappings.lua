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
    ["[q"] = { ":cprev<cr>" },
    ["]q"] = { ":cnext<cr>" },
    ["[Q"] = { ":cfirst<cr>" },
    ["]Q"] = { ":clast<cr>" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
  x = {
    ["J"] = { ":m '>+1<CR>gv=gv", desc = "Move line down" },
    ["K"] = { ":m '>-2<CR>gv=gv", desc = "Move line up" },
    ["s["] = { "c[]<ESC>hpl", desc = "Surround with" },
    ["s{"] = { "c{}<ESC>hpl", desc = "Surround with" },
    ["s("] = { "c()<ESC>hpl", desc = "Surround with" },
    ["s'"] = { "c''<ESC>hpl", desc = "Surround with" },
    ['s"'] = { 'c""<ESC>hpl', desc = "Surround with" },
    ["s<"] = { "c<><ESC>hpl", desc = "Surround with" },
  },
}
