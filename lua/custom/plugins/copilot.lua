return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
    config = function()
      -- Change accept key to <C-J> (from Tab)
      vim.keymap.set('i', '<C-J>', function()
        require('copilot.suggestion').accept_line()
      end, {
        expr = true,
        replace_keycodes = false,
        silent = true,
      })

      require('copilot').setup {}
    end,
  },
}
