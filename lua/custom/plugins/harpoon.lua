return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- telescope + harpoon config
    local conf = require('telescope.config').values

    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    vim.keymap.set('n', '<C-e>', function()
      -- toggle_telescope(harpoon:list())
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Open harpoon window' })

    -- Add file
    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():add()
    end, { desc = 'Harp: Add file' })

    -- Remove All Files
    vim.keymap.set('n', '<leader>hdd', function()
      harpoon:list():clear()
    end, { desc = 'Harp: Close all files' })

    -- Loop to set up key mappings for selecting, replacing, and closing files using Harpoon
    for i = 1, 9 do
      -- Select file mappings
      vim.keymap.set('n', '<leader>h' .. i, function()
        harpoon:list():select(i)
      end, { desc = 'Harp: Select file ' .. i })

      -- Replace file mappings
      vim.keymap.set('n', '<leader>h<C-' .. i .. '>', function()
        harpoon:list():replace_at(i)
      end, { desc = 'Harp: Replace file ' .. i })

      -- Close file mappings
      vim.keymap.set('n', '<leader>hd' .. i, function()
        harpoon:list():remove_at(i)
      end, { desc = 'Harp: Close file ' .. i })
    end

    local function show_harpoon_tabs()
      local filenames = harpoon:list():display()
      local tabline = ''

      for idx, filename in ipairs(filenames) do
        if filename then
          -- Truncate filename for display
          local display_name = vim.fn.fnamemodify(filename, ':t')
          tabline = tabline .. idx .. ':' .. display_name .. '  '
        end
      end
      -- Display the tab list at the top
      vim.api.nvim_echo({ { tabline, 'Normal' } }, false, {})
    end

    vim.keymap.set('n', '<leader>hst', show_harpoon_tabs, {
      desc = 'Harp: Show tabs',
      noremap = true,
      silent = true,
    })
  end,
}
