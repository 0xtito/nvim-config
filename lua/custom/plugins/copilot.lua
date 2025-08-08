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

-- NOTE: OLD VERSION
--
-- return {
--   'github/copilot.vim',
--   config = function()
--     -- Turn off Copilot
--     vim.keymap.set('n', '<leader>cd', ':Copilot disable<CR>', { noremap = true, silent = true, desc = 'Turn off Copilot' })
--     -- Turn on Copilot
--     vim.keymap.set('n', '<leader>ce', ':Copilot enable<CR>', { noremap = true, silent = true, desc = 'Turn on Copilot' })
--
--     -- Change accept key to <C-J> (from Tab)
--     vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
--       expr = true,
--       replace_keycodes = false,
--       silent = true,
--     })
--     vim.g.copilot_no_tab_map = true
--   end,
-- }
