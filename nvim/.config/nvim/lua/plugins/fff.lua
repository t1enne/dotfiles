return {
  "dylanaraps/fff.vim",
  lazy = true,
  cmd = "F",
  init = function()
    vim.cmd[[
    let g:fff#split = "20new"
    ]]
  end
}
