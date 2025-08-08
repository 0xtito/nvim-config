return {
  'rose-pine/neovim',
  name = 'rose-pine',
  config = function()
    require('rose-pine').setup {
      variant = 'main',
      disable_background = true,
      extend_background_behind_borders = true,
      styles = {
        italic = false,
      },
    }

    vim.cmd 'colorscheme rose-pine'
  end,
}
