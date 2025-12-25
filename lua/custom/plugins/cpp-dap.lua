return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
  },
  config = function()
    local dap = require('dap')
    
    -- C++ configuration using codelldb
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
        args = {'--port', '${port}'},
      }
    }

    dap.configurations.cpp = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          -- Get the executable path from the current file
          local file_name = vim.fn.expand('%:t:r')
          local file_dir = vim.fn.expand('%:p:h')
          local executable = file_dir .. '/' .. file_name
          
          -- Check if executable exists, if not, try to compile
          if vim.fn.filereadable(executable) == 0 then
            vim.notify("Executable not found. Compiling...", vim.log.levels.INFO)
            local compile_cmd = string.format(
              'g++ -std=c++17 -g -O0 "%s" -o "%s"',
              vim.fn.expand('%:p'),
              executable
            )
            local result = vim.fn.system(compile_cmd)
            if vim.v.shell_error ~= 0 then
              vim.notify("Compilation failed: " .. result, vim.log.levels.ERROR)
              return nil
            end
          end
          
          return executable
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = function()
          local args_string = vim.fn.input('Program arguments: ')
          return vim.split(args_string, " ", true)
        end,
      },
      {
        name = 'Attach to process',
        type = 'codelldb',
        request = 'attach',
        pid = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
      },
      {
        name = 'Launch with custom executable',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = function()
          local args_string = vim.fn.input('Program arguments: ')
          return vim.split(args_string, " ", true)
        end,
      },
    }

    -- Use the same configuration for C
    dap.configurations.c = dap.configurations.cpp
  end
}