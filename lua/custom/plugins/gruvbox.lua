return {
  'ellisonleao/gruvbox.nvim',
  enabled = false,
  priority = 1000,
  opts = ...,
  config = function()
    -- Default options:
    require('gruvbox').setup {
      terminal_colors = true, -- add neovim terminal colors
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = false,
        emphasis = false,
        comments = false,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      inverse = true, -- invert background for search, diffs, statuslines and errors
      contrast = '', -- can be "hard", "soft" or empty string
      palette_overrides = {},
      overrides = {},
      dim_inactive = false,
      transparent_mode = false,
    }

    vim.o.background = 'dark' -- or "light" for light mode
    vim.cmd 'colorscheme gruvbox'
  end,
}
