-- debug.lua
-- Enhanced DAP configuration with cpp-runner integration

return {
  'mfussenegger/nvim-dap',
  event = 'VeryLazy',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local widgets = require 'dap.ui.widgets'

    -- Track arrow key mappings for session-only stepping
    local arrow_keys_mapped = false

    -- Mason DAP setup
    require('mason-nvim-dap').setup {
      ensure_installed = { 'codelldb' },
      automatic_installation = true,
      handlers = {
        function(config)
          require('mason-nvim-dap').default_setup(config)
        end,
      },
    }

    -- DAP UI setup
    dapui.setup()

    -- Better signs for breakpoints
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◉', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })

    -- Highlight groups for signs
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = '#f0a000' })
    vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef' })
    vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98c379' })
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#2e3d29' })
    vim.api.nvim_set_hl(0, 'DapBreakpointRejected', { fg = '#555555' })

    -- Arrow key stepping (session-only)
    local function setup_arrow_keys()
      if arrow_keys_mapped then
        return
      end
      arrow_keys_mapped = true
      vim.keymap.set('n', '<Up>', dap.restart, { desc = 'Debug: Restart' })
      vim.keymap.set('n', '<Down>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<Left>', dap.step_out, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<Right>', dap.step_into, { desc = 'Debug: Step Into' })
    end

    local function remove_arrow_keys()
      if not arrow_keys_mapped then
        return
      end
      arrow_keys_mapped = false
      pcall(vim.keymap.del, 'n', '<Up>')
      pcall(vim.keymap.del, 'n', '<Down>')
      pcall(vim.keymap.del, 'n', '<Left>')
      pcall(vim.keymap.del, 'n', '<Right>')
    end

    -- Auto open/close UI on debug events
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
      setup_arrow_keys()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
      remove_arrow_keys()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
      remove_arrow_keys()
    end

    -- Also setup arrow keys when stopped (breakpoint hit)
    dap.listeners.after.event_stopped.arrow_keys = function()
      setup_arrow_keys()
    end

    -- Existing keymaps (preserved)
    vim.keymap.set('n', '<leader>bb', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>bc', dap.continue, { desc = 'Debug: Continue' })
    vim.keymap.set('n', '<leader>bi', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<leader>bo', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<leader>bt', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>br', dap.repl.open, { desc = 'Debug: Open REPL' })
    vim.keymap.set('n', '<leader>bl', dap.run_last, { desc = 'Debug: Run Last' })
    vim.keymap.set('n', '<leader>bq', function()
      dap.terminate()
      dapui.close()
      remove_arrow_keys()
    end, { desc = 'Debug: Terminate' })
    vim.keymap.set('n', '<leader>bu', dapui.toggle, { desc = 'Debug: Toggle UI' })

    -- New keymaps

    -- Conditional breakpoint
    vim.keymap.set('n', '<leader>bB', function()
      vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(condition)
        if condition then
          dap.set_breakpoint(condition)
        end
      end)
    end, { desc = 'Debug: Conditional Breakpoint' })

    -- Log points
    vim.keymap.set('n', '<leader>bp', function()
      vim.ui.input({ prompt = 'Log message: ' }, function(message)
        if message then
          dap.set_breakpoint(nil, nil, message)
        end
      end)
    end, { desc = 'Debug: Log Point' })

    vim.keymap.set('n', '<leader>bP', function()
      local word = vim.fn.expand '<cword>'
      local message = word .. ' = {' .. word .. '}'
      dap.set_breakpoint(nil, nil, message)
      vim.notify('Log point: ' .. message, vim.log.levels.INFO)
    end, { desc = 'Debug: Log Variable at Cursor' })

    -- DAP widgets (floating windows)
    vim.keymap.set('n', '<leader>bs', function()
      widgets.centered_float(widgets.frames)
    end, { desc = 'Debug: Stack Frames' })

    vim.keymap.set('n', '<leader>bT', function()
      widgets.centered_float(widgets.threads)
    end, { desc = 'Debug: Threads' })

    vim.keymap.set('n', '<leader>bv', function()
      widgets.centered_float(widgets.scopes)
    end, { desc = 'Debug: Scopes/Variables' })

    vim.keymap.set('n', '<leader>bh', widgets.hover, { desc = 'Debug: Hover Inspect' })

    vim.keymap.set({ 'n', 'v' }, '<leader>be', function()
      widgets.preview()
    end, { desc = 'Debug: Evaluate/Preview' })

    -- Navigation
    vim.keymap.set('n', '<leader>bC', dap.run_to_cursor, { desc = 'Debug: Run to Cursor' })

    vim.keymap.set('n', '<leader>bg', function()
      dap.goto_(tonumber(vim.fn.line '.'))
    end, { desc = 'Debug: Goto Line' })

    vim.keymap.set('n', '<leader>bj', dap.down, { desc = 'Debug: Stack Frame Down' })
    vim.keymap.set('n', '<leader>bk', dap.up, { desc = 'Debug: Stack Frame Up' })

    vim.keymap.set('n', '<leader>bR', function()
      local word = vim.fn.expand '<cword>'
      dap.repl.open()
      dap.repl.execute(word)
    end, { desc = 'Debug: Evaluate at Cursor in REPL' })

    -- F-key bindings (normal + terminal mode)
    vim.keymap.set({ 'n', 't' }, '<F3>', function()
      dap.terminate()
      dapui.close()
      remove_arrow_keys()
    end, { desc = 'Debug: Terminate' })

    vim.keymap.set({ 'n', 't' }, '<F5>', dap.continue, { desc = 'Debug: Continue' })

    -- User commands
    vim.api.nvim_create_user_command('DapSidebar', function()
      local sidebar = widgets.sidebar(widgets.scopes)
      sidebar.open()
    end, { desc = 'Open DAP sidebar with scopes' })

    vim.api.nvim_create_user_command('DapBreakpoints', function()
      local breakpoints = require('dap.breakpoints').get()
      local qf_list = {}
      for bufnr, buf_bps in pairs(breakpoints) do
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        for _, bp in ipairs(buf_bps) do
          table.insert(qf_list, {
            bufnr = bufnr,
            filename = bufname,
            lnum = bp.line,
            text = bp.condition or bp.logMessage or 'breakpoint',
          })
        end
      end
      vim.fn.setqflist(qf_list, 'r')
      vim.cmd 'copen'
    end, { desc = 'List breakpoints in quickfix' })

    vim.api.nvim_create_user_command('DapSessions', function()
      local sessions = dap.sessions()
      if vim.tbl_isempty(sessions) then
        vim.notify('No active debug sessions', vim.log.levels.INFO)
        return
      end
      local items = {}
      for id, session in pairs(sessions) do
        table.insert(items, string.format('%d: %s', id, session.config.name or 'unnamed'))
      end
      vim.notify('Sessions:\n' .. table.concat(items, '\n'), vim.log.levels.INFO)
    end, { desc = 'List active DAP sessions' })

    vim.api.nvim_create_user_command('DapClearBreakpoints', function()
      dap.clear_breakpoints()
      vim.notify('All breakpoints cleared', vim.log.levels.INFO)
    end, { desc = 'Clear all breakpoints' })

    -- codelldb adapter
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.stdpath 'data' .. '/mason/bin/codelldb',
        args = { '--port', '${port}' },
      },
    }

    -- Helper to get executable from cpp-runner
    local function get_cpp_runner_executable()
      if _G.CppRunner and _G.CppRunner.get_current_executable then
        return _G.CppRunner.get_current_executable()
      end
      return nil
    end

    local function get_cpp_runner_args()
      if _G.CppRunner and _G.CppRunner.get_run_args then
        local args_str = _G.CppRunner.get_run_args()
        if args_str and args_str ~= '' then
          -- Split args string into table
          local args = {}
          for arg in args_str:gmatch '%S+' do
            table.insert(args, arg)
          end
          return args
        end
      end
      return {}
    end

    -- C/C++ configurations with cpp-runner integration
    dap.configurations.cpp = {
      {
        name = 'Launch (auto-detect)',
        type = 'codelldb',
        request = 'launch',
        program = function()
          local exe = get_cpp_runner_executable()
          if exe then
            vim.notify('Debug: ' .. exe, vim.log.levels.INFO)
            return exe
          end
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        args = get_cpp_runner_args,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
      {
        name = 'Launch executable',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
      {
        name = 'Attach to process',
        type = 'codelldb',
        request = 'attach',
        pid = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
      },
    }

    dap.configurations.c = dap.configurations.cpp

    dap.configurations.odin = {
      {
        name = 'Debug Odin Game',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.getcwd() .. '/build/mac_debug/game.exe'
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
      {
        name = 'Debug Odin (Custom Path)',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }
  end,
}
