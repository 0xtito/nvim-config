return {
  {
    'folke/trouble.nvim',
    branch = 'main',
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = 'Trouble',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>cs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>cl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xL',
        '<cmd>Trouble loclist toggle<cr>',
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xQ',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
    },
  },
}

-- return {
--   {
--     'folke/trouble.nvim',
--     -- branch = 'dev',
--     -- opts = {
--     --   follow = false,
--     --   restore = true,
--     --   auto_preview = false,
--     --   auto_refresh = false,
--     -- },
--     opts = {},
--     cmd = 'Trouble',
--     config = function()
--       require('trouble').setup()
--
--       vim.keymap.set('n', '<leader>tt', function()
--         -- require('trouble').toggle()
--         vim.cmd 'Trouble diagnostics toggle'
--       end, { desc = 'Trouble: Diagnostics' })
--
--       vim.keymap.set('n', '<leader>td', function()
--         -- require('trouble').open 'workspace_diagnostic'
--         vim.cmd 'Trouble diagnostics toggle filter.buf=0'
--       end, { desc = 'Trouble: Buffer Diagnostics (trouble)' })
--       --
--       -- vim.keymap.set('n', '<leader>xs', function()
--       --   -- require('trouble').open 'document_diagnostic'
--       --   vim.cmd 'Trouble symbols focus=false'
--       -- end, { desc = 'Trouble: Symbols' })
--
--       vim.keymap.set('n', '<leader>ts', function()
--         -- require('trouble').open 'document_diagnostic'
--         vim.cmd 'Trouble lsp toggle focus=false win.position=right'
--       end, { desc = 'Trouble: Symbols' })
--
--       vim.keymap.set('n', '<leader>tl', function()
--         -- require('trouble').open 'document_diagnostic'
--         vim.cmd 'Trouble lsp toggle focus=false win.position=right'
--       end, { desc = 'Trouble: LSP Defintions/References' })
--
--       vim.keymap.set('n', '[t', function()
--         require('trouble').next { skip_groups = true, jump = true }
--       end, { desc = 'Trouble: Next' })
--
--       vim.keymap.set('n', ']t', function()
--         require('trouble').previous { skip_groups = true, jump = true }
--       end, { desc = 'Trouble: Previous' })
--
--       vim.keymap.set('n', '<leader>tq', function()
--         require('trouble').open 'quickfix'
--       end, { desc = 'Trouble: Toggle Quickfix' })
--
--       vim.keymap.set('n', '<leader>tL', function()
--         require('trouble').open 'loclist'
--       end, { desc = 'Trouble: Toggle Location List' })
--
--       vim.keymap.set('n', '<leader>tc', function()
--         require('trouble').close()
--       end, { desc = 'Trouble: Close' })
--
--       -- vim.keymap.set('n', '<leader>tgR', function()
--       --   require('trouble').open 'lsp_references'
--       -- end, { desc = 'Trouble: LSP References' })
--
--       -- --- Trouble v2 keymaps --- --
--       -- vim.keymap.set('n', '<leader>tt', function()
--       --   -- require('trouble').toggle()
--       --   vim.cmd 'Trouble diagnostics toggle'
--       -- end, { desc = 'Trouble: Toggle' })
--       --
--       -- vim.keymap.set('n', '<leader>tw', function()
--       --   -- require('trouble').open 'workspace_diagnostic'
--       --   vim.cmd 'Trouble workspace_diagnostic'
--       -- end, { desc = 'Trouble: Toggle Workspace Diagnostic' })
--       -- --
--       -- vim.keymap.set('n', '<leader>td', function()
--       --   -- require('trouble').open 'document_diagnostic'
--       --   vim.cmd 'Trouble document_diagnostic'
--       -- end, { desc = 'Trouble: Toggle Document Diagnostic' })
--       --
--       -- vim.keymap.set('n', '[t', function()
--       --   require('trouble').next { skip_groups = true, jump = true }
--       -- end, { desc = 'Trouble: Next' })
--       --
--       -- vim.keymap.set('n', ']t', function()
--       --   require('trouble').previous { skip_groups = true, jump = true }
--       -- end, { desc = 'Trouble: Previous' })
--       --
--       -- vim.keymap.set('n', '<leader>tq', function()
--       --   require('trouble').open 'quickfix'
--       -- end, { desc = 'Trouble: Toggle Quickfix' })
--       --
--       -- vim.keymap.set('n', '<leader>tl', function()
--       --   require('trouble').open 'loclist'
--       -- end, { desc = 'Trouble: Toggle Location List' })
--       --
--       -- vim.keymap.set('n', '<leader>tc', function()
--       --   require('trouble').close()
--       -- end, { desc = 'Trouble: Close' })
--       --
--       -- vim.keymap.set('n', '<leader>tgR', function()
--       --   require('trouble').open 'lsp_references'
--       -- end, { desc = 'Trouble: LSP References' })
--     end,
--   },
-- }
