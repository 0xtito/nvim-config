-- harpoon
--

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- vim.api.nvim_create_autocmd('LspAttach', {
    -- group = vim.api.nvim_create_augroup('harpoon-lsp-attach', { clear = true }),
    -- callback = function(event) {
    -- maybe use this idk

    -- }

    -- }
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

    -- local map = function(keys, func, desc)
    --  vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    -- end

    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    -- map 'n'

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end)

    -- vim.keymap.set('n', '<leader>')

    vim.keymap.set('n', '<C-h>', function()
      harpoon:list():select(1)
    end)
    vim.keymap.set('n', '<C-t>', function()
      harpoon:list():select(2)
    end)
    vim.keymap.set('n', '<C-n>', function()
      harpoon:list():select(3)
    end)
    vim.keymap.set('n', '<C-s>', function()
      harpoon:list():select(4)
    end)

    vim.keymap.set('n', '<leader><C-h>', function()
      harpoon:list():replace_at(1)
    end)
    vim.keymap.set('n', '<leader><C-t>', function()
      harpoon:list():replace_at(2)
    end)
    vim.keymap.set('n', '<leader><C-n>', function()
      harpoon:list():replace_at(3)
    end)
    vim.keymap.set('n', '<leader><C-s>', function()
      harpoon:list():replace_at(4)
    end)

    vim.keymap.set('n', '<C-e>', function()
      toggle_telescope(harpoon:list())
    end, { desc = 'Open harpoon window' })
  end,
}
