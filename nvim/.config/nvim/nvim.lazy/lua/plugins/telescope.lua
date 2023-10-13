-- change some telescope options and a keymap to browse plugin files
return {
	"nvim-telescope/telescope.nvim",
	dependencies = { 'nvim-lua/plenary.nvim', lazy= true},
  cmd = { "Telescope" },
  keys = function()
    return {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Grep in files" },
    }
  end,
	opts = function()
    local actions = require("telescope.actions")
		return {
			defaults = {
				git_worktrees = vim.g.git_worktrees,
        path_display = { "truncate" },
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
				width = 0.87,
				height = 0.80,
        preview_cutoff = 120,
        n = {
          ["q"] = actions.close,
        },
      },
    }
  end
}
