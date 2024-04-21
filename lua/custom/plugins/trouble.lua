return {
  {
    'folke/trouble.nvim',
    config = function()
      require('trouble').setup {
        icons = false,
      }

      vim.keymap.set('n', '<leader>tt', function()
        require('trouble').toggle()
      end, { desc = 'Trouble: Toggle' })

      -- vim.keymap.set('n', '<leader>tw', function()
      --   require('trouble').open 'workspace_diagnostic'
      -- end, { desc = 'Trouble: Toggle Workspace Diagnostic' })
      --
      -- vim.keymap.set('n', '<leader>td', function()
      --   require('trouble').open 'document_diagnostic'
      -- end, { desc = 'Trouble: Toggle Document Diagnostic' })

      vim.keymap.set('n', '[t', function()
        require('trouble').next { skip_groups = true, jump = true }
      end, { desc = 'Trouble: Next' })

      vim.keymap.set('n', ']t', function()
        require('trouble').previous { skip_groups = true, jump = true }
      end, { desc = 'Trouble: Previous' })

      -- vim.keymap.set('n', '<leader>tq', function()
      --   require('trouble').open 'quickfix'
      -- end, { desc = 'Trouble: Toggle Quickfix' })
      --
      -- vim.keymap.set('n', '<leader>tl', function()
      --   require('trouble').open 'loclist'
      -- end, { desc = 'Trouble: Toggle Location List' })
      --
      -- vim.keymap.set('n', '<leader>tc', function()
      --   require('trouble').close()
      -- end, { desc = 'Trouble: Close' })
      --
      -- vim.keymap.set('n', 'gR', function()
      --   require('trouble').open 'lsp_references'
      -- end, { desc = 'Trouble: LSP References' })
    end,
  },
}
