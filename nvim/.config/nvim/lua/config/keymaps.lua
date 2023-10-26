-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local function map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

map("x", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("x", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })

-- save file
map("n", "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
-- file explorer
map("n", "<leader>e", ":F<cr>", { desc = "Open FFF in root dir" })
map("n", "<leader>E", ":F %:p:h<cr>", { desc = "Open FFF in here" })

map("n", "<leader>d", ":bd<CR>", { desc = "Close buffer" })
-- map("n", "<leader>l",  )
map(
  "n",
  "<leader>/",
  ":lua require('Comment.api').toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)<CR>",
  { desc = "Toggle comment line" }
)
map(
  "v",
  "<leader>/",
  "<esc>:lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
  { desc = "Toggle comment line" }
)
-- better indents
map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

-- nav buffers
map("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })
