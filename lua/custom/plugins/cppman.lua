return {
  'madskjeldgaard/cppman.nvim',
  dependencies = {
    { 'MunifTanjim/nui.nvim' },
  },
  config = function()
    local cppman = require 'cppman'
    cppman.setup()

    -- Make a keymap to open the word under cursor in CPPman
    vim.keymap.set('n', '<leader>Cm', function()
      cppman.open_cppman_for(vim.fn.expand '<cword>')
    end)

    -- Open search box
    vim.keymap.set('n', '<leader>Cc', function()
      cppman.input()
    end)
  end,
}
