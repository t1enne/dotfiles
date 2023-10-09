return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = { "c", "query", "vim", "vimdoc", "lua", "typescript", "go", "vim", "lua", "cmake" },
    highlight = { -- disable = { "go" }
    },
    matchup = { enable = true },
    indent = { enable = true, disable = { "python" } },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn", -- set to `false` to disable one of the mappings
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
  },
}
