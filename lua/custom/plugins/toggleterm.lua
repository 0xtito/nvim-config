return {
  'akinsho/toggleterm.nvim',
  version = '*',
  -- config = true,
  config = function()
    local tt = require 'toggleterm'

    tt.setup {
      size = function(term)
        if term.direction == 'horizontal' then
          return 15
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = 'vertical',
    }

    vim.keymap.set('n', '<leader>tv', function()
      local sizeAsString = tostring(vim.o.columns * 0.35)
      tt.toggle(nil, nil, sizeAsString, 'vertical', nil)
    end, { desc = 'Toggle Terminal (Vertical)' })

    vim.keymap.set('n', '<leader>th', function()
      tt.toggle(nil, nil, '15', 'horizontal', nil)
    end, { desc = 'Toggle Terminal (Horiztonal)' })
  end,
}
