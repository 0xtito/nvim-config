return {
  'folke/zen-mode.nvim',
  config = function()
    vim.keymap.set('n', '<leader>zz', function()
      require('zen-mode').setup {
        window = {
          width = 90,
          options = {},
        },
      }
      require('zen-mode').toggle()
      vim.wo.wrap = false
      vim.wo.number = true
      vim.wo.rnu = true
      ColorMyPencils()
    end, {
      desc = 'Zen Mode',
    })

    vim.keymap.set('n', '<leader>zZ', function()
      require('zen-mode').setup {
        window = {
          width = 80,
          options = {},
        },
      }
      require('zen-mode').toggle()
      vim.wo.wrap = false
      vim.wo.number = false
      vim.wo.rnu = false
      vim.opt.colorcolumn = '0'
      ColorMyPencils()
    end, {
      desc = 'Zen Mode (Full Immersion)',
    })

    vim.keymap.set('n', '<leader>zW', function()
      require('zen-mode').setup {}
      require('zen-mode').toggle()
      vim.wo.wrap = true
      vim.wo.number = false
      vim.wo.rnu = false
      vim.opt.colorcolumn = '0'
      ColorMyPencils()
    end, {
      desc = 'Zen Mode (Wide Screen)',
    })
  end,
}
