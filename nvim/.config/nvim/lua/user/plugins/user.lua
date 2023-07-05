return {
  { "akinsho/toggleterm.nvim", enabled = false },
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  { "s1n7ax/nvim-window-picker", enabled = false },
  { "famiu/bufdelete.nvim", enabled = false },
  { "nvim-treesitter/nvim-treesitter-context", lazy = false },
  { "mbbill/undotree", cmd = { "UndotreeToggle" } },
  { "mrjones2014/smart-splits.nvim", enabled = false },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
  },
  {
    "Exafunction/codeium.vim",
    lazy = false,
    init = function()
      vim.g.codeium_disable_bindings = 1
      vim.g.codeium_idle_delay = 1500
    end,
    config = function()
      vim.keymap.set("i", "<C-l>", function() return vim.fn["codeium#Accept"]() end, { expr = true })
      vim.keymap.set("i", "<C-j>", function() return vim.fn["codeium#CycleCompletions"](1) end, { expr = true })
      vim.keymap.set("i", "<C-k>", function() return vim.fn["codeium#CycleCompletions"](-1) end, { expr = true })
      vim.keymap.set("i", "<C-x>", function() return vim.fn["codeium#Clear"]() end, { expr = true })
    end,
  },
  -- {
  --   "mcchrish/nnn.vim",
  --   config = function(plugin, opts)
  --     require("nnn").setup {
  --       command = "nnn -ao -AC",
  --       set_default_mappings = 0,
  --       action = {
  --         ["<c-t>"] = "tab split",
  --         ["<c-s>"] = "split",
  --         ["<c-v>"] = "vsplit",
  --         -- ["<c-o>"] = copy_to_clipboard,
  --       },
  --     }
  --   end,
  --   cmd = { "NnnPicker", "NnnExplorer" },
  -- },
}
