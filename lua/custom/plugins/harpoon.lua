-- harpoon
--

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- telescope + harpoon config
    local conf = require('telescope.config').values

    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table {
            results = file_paths,
          },
          previewer = conf.file_previewer {},
          sorter = conf.generic_sorter {},
        })
        :find()
    end

    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    -- Toggle harpoon window
    vim.keymap.set('n', '<C-e>', function()
      toggle_telescope(harpoon:list())
    end, { desc = 'Open harpoon window' })

    -- Add file
    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Harp: Add file' })

    -- Select file
    vim.keymap.set('n', '<leader>h1', function()
      harpoon:list():select(1)
    end, { desc = 'Harp: Select file 1' })
    vim.keymap.set('n', '<leader>h2', function()
      harpoon:list():select(2)
    end, { desc = 'Harp: Select file 2' })
    vim.keymap.set('n', '<leader>h3', function()
      harpoon:list():select(3)
    end, { desc = 'Harp: Select file 3' })
    vim.keymap.set('n', '<leader>h4', function()
      harpoon:list():select(4)
    end, { desc = 'Harp: Select file 4' })

    -- Replace file
    vim.keymap.set('n', '<leader><C-1>', function()
      harpoon:list():replace_at(1)
    end, { desc = 'Harp: Replace file 1' })
    vim.keymap.set('n', '<leader><C-2>', function()
      harpoon:list():replace_at(2)
    end, { desc = 'Harp: Replace file 2' })
    vim.keymap.set('n', '<leader><C-3>', function()
      harpoon:list():replace_at(3)
    end, { desc = 'Harp: Replace file 3' })
    vim.keymap.set('n', '<leader><C-4>', function()
      harpoon:list():replace_at(4)
    end, { desc = 'Harp: Replace file 4' })

    -- Close file
    vim.keymap.set('n', '<leader>hd1', function()
      harpoon:list():remove_at(1)
    end, { desc = 'Harp: Close file 1' })

    vim.keymap.set('n', '<leader>hd2', function()
      harpoon:list():remove_at(2)
    end, { desc = 'Harp: Close file 2' })

    vim.keymap.set('n', '<leader>hd3', function()
      harpoon:list():remove_at(3)
    end, { desc = 'Harp: Close file 3' })

    vim.keymap.set('n', '<leader>hd4', function()
      harpoon:list():remove_at(4)
    end, { desc = 'Harp: Close file 4' })

    -- Close all files
    vim.keymap.set('n', '<leader>hdd', function()
      harpoon:list():clear()
    end, { desc = 'Harp: Close all files' })
  end,
}
