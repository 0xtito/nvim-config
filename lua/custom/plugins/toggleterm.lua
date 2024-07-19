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

    -- local filetype_commands = setmetatable({}, {
    --   __index = function()
    --     return "echo 'You need to set a command for this filetype'"
    --   end,
    -- })

    local function get_current_filetype()
      return vim.bo.filetype
    end

    local filetype_commands = {
      [1] = {},
      [2] = {},
      [3] = {},
    }

    -- Set the command for the current filetype
    local function set_command(index)
      return function()
        local filetype = get_current_filetype()
        local command = vim.fn.input('Enter Command for F' .. (index + 8) .. ': ')
        if command and command ~= '' then
          filetype_commands[index][filetype] = command
          print('Command saved for F' .. (index + 8) .. ' on ' .. filetype .. ': ' .. command)
        end
      end
    end

    vim.keymap.set('n', '<leader>ts1', set_command(1), { desc = 'Terminal Set F9' })
    vim.keymap.set('n', '<leader>ts2', set_command(2), { desc = 'Terminal Set F10' })
    vim.keymap.set('n', '<leader>ts3', set_command(3), { desc = 'Terminal Set F11' })

    local function run_command(index)
      return function()
        local filetype = get_current_filetype()
        local command = filetype_commands[index][filetype]
        if command then
          tt.exec(command)
        else
          print('No command set for F' .. (index + 8) .. ' on ' .. filetype)
        end
      end
    end

    vim.keymap.set('n', '<F9>', run_command(1), { desc = 'Terminal Run F9' })
    vim.keymap.set('n', '<F10>', run_command(2), { desc = 'Terminal Run F10' })
    vim.keymap.set('n', '<F11>', run_command(3), { desc = 'Terminal Run F11' })
  end,
}
