return {
  "jose-elias-alvarez/null-ls.nvim",
  opts = function(_, config)
    local null_ls = require "null-ls"
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
    null_ls.register(null_ls.builtins.formatting.prettier_d_slim.with {
      condition = function(utils)
        return utils.root_has_file ".prettierrc"
          or utils.root_has_file ".prettierrc.json"
          or utils.root_has_file ".prettierrc.js"
      end,
    })
    return config -- return final config table
  end,
}
