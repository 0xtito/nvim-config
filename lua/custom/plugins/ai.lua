return {
  'jackMort/ChatGPT.nvim',
  event = 'VeryLazy',
  config = function()
    local gpt = require 'chatgpt'

    local function has_arg(arg)
      for _, v in ipairs(vim.v.argv) do
        if v == arg then
          return true
        end
      end
      return false
    end

    if has_arg 'ai' then
      gpt.setup {
        api_key_cmd = 'op read op://cli-private/neovim_openai/password --no-newline',
      }
    else
      -- gpt.setup {}
    end
    -- Keymaps all start with `a` for "AI", except for opening
    vim.keymap.set('n', '<C-a>', function()
      gpt.openChat()
    end, { desc = 'Open AI chat' })

    -- Edit with Instructions
    vim.keymap.set('v', '<leader>ai', function()
      gpt.edit_with_instructions()
    end, { desc = 'Edit with Instructions' })

    vim.keymap.set('n', '<leader>ai', function()
      local confirm = vim.fn.confirm('Edit with instructions for the entire page?', '&Yes\n&No', 2)

      if confirm == 1 then
        gpt.edit_with_instructions()
      end
    end, { desc = 'Edit with Instructions' })
    ----------------------------

    -- Complete Code
    vim.keymap.set('n', '<leader>aC', function(opts)
      gpt.complete_code(opts)
    end, { desc = 'Complete Code' })

    vim.keymap.set('v', '<leader>aC', function(opts)
      local confirm = vim.fn.confirm('Complete code for the entire page?', '&Yes\n&No', 2)

      if confirm == 1 then
        gpt.complete_code(opts)
      end
    end, { desc = 'Complete Code' })
    ----------------------------

    -- Explain Code
    vim.keymap.set('v', '<leader>aRe', function()
      vim.cmd 'ChatGPTRun explain_code'
    end, { desc = 'Explain Code' })

    vim.keymap.set('n', '<leader>aRe', function()
      local confirm = vim.fn.confirm('Explain code for the entire page?', '&Yes\n&No', 2)

      if confirm == 1 then
        vim.cmd 'ChatGPTRun explain_code'
      end
    end, { desc = 'Explain Code (Full Page)' })
    ----------------------------

    -- Fix Bugs
    vim.keymap.set('v', '<leader>aRf', function()
      vim.cmd 'ChatGPTRun fix_bugs'
    end, { desc = 'Fix Bugs' })

    vim.keymap.set('n', '<leader>aRf', function()
      local confirm = vim.fn.confirm('Fix bugs for the entire page?', '&Yes\n&No', 2)

      if confirm == 1 then
        vim.cmd 'ChatGPTRun fix_bugs'
      end
    end, { desc = 'Fix Bugs (Full Page)' })
    ----------------------------

    -- Summarize
    vim.keymap.set('v', '<leader>aRs', function()
      vim.cmd 'ChatGPTRun summarize'
    end, { desc = 'Summarize' })

    vim.keymap.set('n', '<leader>aRs', function()
      local confirm = vim.fn.confirm('Summarize the entire page?', '&Yes\n&No', 2)

      if confirm == 1 then
        vim.cmd 'ChatGPTRun summarize'
      end
    end, { desc = 'Summarize (Full Page)' })
    ----------------------------

    -- Optimize Code
    vim.keymap.set('v', '<leader>aRo', function()
      vim.cmd 'ChatGPTRun optimize_code'
    end, { desc = 'Optimize Code' })

    vim.keymap.set('n', '<leader>aRo', function()
      local confirm = vim.fn.confirm('Optimize code for the entire page?', '&Yes\n&No', 2)

      if confirm == 1 then
        vim.cmd 'ChatGPTRun optimize_code'
      end
    end, { desc = 'Optimize Code (Full Page)' })
    ----------------------------

    vim.keymap.set('n', '<leader>aA', function()
      gpt.selectAwesomePrompt()
    end, { desc = 'Act as...' })
  end,
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    -- 'folke/trouble.nvim',
    'nvim-telescope/telescope.nvim',
  },
}
