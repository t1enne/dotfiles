-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
return {
  "jose-elias-alvarez/null-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"
    opts.sources = {
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.prettier_d_slim.with {
        condition = function(utils)
          return utils.root_has_file ".prettierrc"
              or utils.root_has_file ".prettierrc.json"
              or utils.root_has_file ".prettierrc.js"
        end,
      },
      -- null_ls.builtins.diagnostics.eslint_d.with {
      --   condition = function(utils)
      --     return utils.root_has_file ".eslintrc"
      --       or utils.root_has_file ".eslintrc.json"
      --       or utils.root_has_file ".eslintrc.js"
      --   end,
      -- },
    }
    return opts
  end,
}
