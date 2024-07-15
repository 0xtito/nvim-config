return {
  'github/copilot.vim',
  config = function()
    -- Turn off Copilot
    vim.keymap.set('', '<leader>cd', ':Copilot disable<CR>', { noremap = true, silent = true, desc = 'Turn off Copilot' })
    -- Turn on Copilot
    vim.keymap.set('', '<leader>ce', ':Copilot enable<CR>', { noremap = true, silent = true, desc = 'Turn on Copilot' })

    -- Change accept key to <C-J> (from Tab)
    vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
      silent = true,
    })
    vim.g.copilot_no_tab_map = true
  end,
}
