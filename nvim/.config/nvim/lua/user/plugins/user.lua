return {
  { "akinsho/toggleterm.nvim", enabled = false },
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  { "s1n7ax/nvim-window-picker", enabled = false },
  { "famiu/bufdelete.nvim", enabled = false },
  { "nvim-treesitter/nvim-treesitter-context", lazy = false },
  { "mbbill/undotree", cmd = { "UndotreeToggle" } },
  { "mrjones2014/smart-splits.nvim", enabled = false },
  { "rebelot/kanagawa.nvim", lazy = false },
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
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        -- vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
        -- vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
      end,
    },
    ---@class PluginLspOpts
    opts = {
      servers = {
        tsserver = {},
      },
      setup = {
        tsserver = function(_, opts)
          require("typescript").setup { server = opts }
          return true
        end,
      },
    },
  },
}
