-- change some telescope options and a keymap to browse plugin files
return {

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { { "nvim-lua/plenary.nvim", lazy = true }, { "nvim-telescope/telescope-fzf-native.nvim" } },
    cmd = { "Telescope" },
    keys = function()
      return {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
        { "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Find word" },
        { "<leader>fb", "<cmd>Telescope <cr>", desc = "Find buffer" },
      }
    end,
    opts = function()
      local actions = require("telescope.actions")
      return {
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          },
        },
        defaults = {
          border = true,
          borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
          winblend = 0,
          git_worktrees = vim.g.git_worktrees,
          path_display = { "truncate" },
          layout_strategy = "vertical",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          width = 0.75,
          height = 0.80,
          preview_cutoff = 120,
          n = {
            ["q"] = actions.close,
          },
          highlights = {
            TelescopeBorder = { fg = "none", bg = "none" },
            TelescopePreviewBorder = { fg = "none", bg = "none" },
            TelescopePromptBorder = { fg = "none", bg = "none" },
            TelescopeResultsBorder = { fg = "none", bg = "none" },
          },
        },
      }
    end,
  },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
}
