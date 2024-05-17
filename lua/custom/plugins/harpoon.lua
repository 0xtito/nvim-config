-- harpoon

--- Creates a tabline from a given HarpoonList.
-- @param harpoonList HarpoonList The Harpoon list to create the tabline from.
-- @return string The tabline string.
-- local function create_harpoon_tabline(harpoonList)
--   local s = '' -- Initialize the tabline string.
--   local hl = '%#TabLine#' -- Default highlight group for non-selected items.
--   local sel_hl = '%#TabLineSel#' -- Highlight group for the selected item.
--
--   -- Iterate through each item in the Harpoon list.
--   for idx, item in ipairs(harpoonList.items) do
--     -- Apply the selected highlight if this item is the current index.
--     local current_hl = (idx == harpoonList._index) and sel_hl or hl
--
--     -- Add the item to the string, using the index and value.
--     s = s .. current_hl .. ' ' .. idx .. ': ' .. item.value .. ' '
--   end
--
--   vim.api.nvim_echo({ { s, 'Normal' } }, false, {})
--   return s
-- end

-- vim.api.nvim_create_autocmd('BufEnter', {
--   pattern = '*',
--   callback = function()
--     vim.o.tabline = custom_tabline()
--   end,
-- })

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- DOES NOT WORK
    -- local function set_tabline()
    --   local list = harpoon:list()
    --
    --   return create_harpoon_tabline(list)
    -- end

    -- vim.api.nvim_create_autocmd('DirChanged', {
    --   pattern = '*',
    --   callback = function()
    --     vim.o.tabline = set_tabline()
    --   end,
    -- })

    -- vim.o.tabline = set_tabline()

    -- local function refresh_tabline()
    --   custom_tabline()
    --   vim.o.tabline = set_tabline()
    -- end

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
