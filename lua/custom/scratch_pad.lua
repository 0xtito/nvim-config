local O = {}

function O.open_scratch_buffer()
  local scratch_dir = vim.fn.stdpath 'data' .. '/scratch'
  print(scratch_dir)
  print '----'
  local scratch_file = scratch_dir .. '/scratch.md'

  -- Create the scratch directory if it doesn't exist
  if vim.fn.isdirectory(scratch_dir) == 0 then
    vim.fn.mkdir(scratch_dir, 'p')
  end

  -- Open the scratch file in a new buffer
  vim.cmd('edit ' .. scratch_file)

  -- Set some buffer-local options
  vim.bo.filetype = 'markdown'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'hide'
  vim.bo.swapfile = false
end

-- Set up the keybinding
-- vim.api.nvim_set_keymap('n', '<C-S-n>', '<cmd>lua open_scratch_buffer()<CR>', { noremap = true, silent = true })

-- O.open_scratch_buffer = open_scratch_buffer

vim.keymap.set('n', '<leader>q', function()
  O.open_scratch_buffer()
end, { desc = 'Open scratch pad' })
