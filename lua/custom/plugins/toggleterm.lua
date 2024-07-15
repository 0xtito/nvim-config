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

    local filetype_commands = setmetatable({}, {
      __index = function()
        return "echo 'You need to set a command for this filetype'"
      end,
    })

    local function get_current_filetype()
      return vim.bo.filetype
    end

    -- Set the command for the current filetype
    vim.keymap.set('n', '<leader>tS', function()
      local filetype = get_current_filetype()
      -- local command = vim.fn.input 'Enter Command for ' .. filetype .. ': '
      local command = vim.fn.input 'Enter Command: '
      if command and command ~= '' then
        filetype_commands[filetype] = command
        print('Command saved for ' .. filetype .. ': ' .. command)
      end
    end, { desc = 'Terminal Set' })

    vim.keymap.set('n', '<F9>', function()
      local filetype = get_current_filetype()
      local command = filetype_commands[filetype]
      if command then
        -- tt.send_lines_to_terminal(command)
        tt.exec(command)
      else
        print('No command set for ' .. filetype)
      end
    end, { desc = 'Terminal Run' })
  end,
}
