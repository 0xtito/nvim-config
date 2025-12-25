-- C++ Tmux Integration
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cpp", "c", "cc", "cxx" },
  callback = function()
    local M = {}

    -- Helper function to check if we're in tmux
    local function is_in_tmux()
      return vim.env.TMUX ~= nil
    end

    -- Helper function to get current file info
    local function get_file_info()
      local file = vim.fn.expand '%:p'
      local file_dir = vim.fn.expand '%:p:h'
      local file_name = vim.fn.expand '%:t:r'
      local file_ext = vim.fn.expand '%:e'

      return {
        full_path = file,
        dir = file_dir,
        name = file_name,
        ext = file_ext,
        executable = file_dir .. '/' .. file_name,
      }
    end

    -- Find project root (git root or current directory)
    local function find_project_root()
      local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
      if vim.v.shell_error == 0 and git_root ~= '' then
        return git_root
      end
      return vim.fn.getcwd()
    end

    -- Load .cppbuild configuration
    local function load_cpp_config()
      local root = find_project_root()
      local config_path = root .. '/.cppbuild'
      
      if vim.fn.filereadable(config_path) == 1 then
        local content = vim.fn.readfile(config_path)
        local config = {}
        
        -- Simple parser for key=value format
        for _, line in ipairs(content) do
          -- Skip comments and empty lines
          if line:match('^%s*#') or line:match('^%s*$') then
            goto continue
          end
          
          local key, value = line:match('^%s*([%w_]+)%s*=%s*(.+)%s*$')
          if key and value then
            -- Remove quotes if present
            value = value:gsub('^"(.*)"$', '%1'):gsub("^'(.*)'$", '%1')
            config[key] = value
          end
          
          ::continue::
        end
        
        return config, root
      end
      
      return nil, root
    end

    -- Function to send command to tmux pane
    local function send_to_tmux_pane(cmd, create_pane)
      if not is_in_tmux() then
        vim.notify('Not in tmux session', vim.log.levels.ERROR)
        return
      end

      -- Get current window
      local current_window = vim.fn.system('tmux display-message -p "#{window_index}"'):gsub('\n', '')

      -- Check if right pane exists (pane index 1)
      local pane_count_str = vim.fn.system('tmux list-panes | wc -l'):gsub('%s+', '')
      local pane_count = tonumber(pane_count_str) or 1

      if create_pane and pane_count == 1 then
        -- Create right pane if it doesn't exist
        vim.fn.system 'tmux split-window -h -c "#{pane_current_path}"'
      end

      -- Target the right pane (index 1)
      local target_pane = current_window .. '.1'

      -- Send command to right pane
      vim.fn.system(string.format('tmux send-keys -t %s C-c', target_pane)) -- Clear any running process
      vim.fn.system(string.format('tmux send-keys -t %s "%s" Enter', target_pane, cmd))
    end

    -- Function to compile and run C++ file
    function M.cpp_run()
      local config, project_root = load_cpp_config()
      local file_info = get_file_info()
      
      -- Determine what to compile
      local source_file, output_path, output_name
      
      if config then
        -- Use config if available
        if config.main_file then
          source_file = project_root .. '/' .. config.main_file
          -- Check if file exists
          if vim.fn.filereadable(source_file) == 0 then
            vim.notify('Main file not found: ' .. source_file, vim.log.levels.ERROR)
            return
          end
        else
          source_file = file_info.full_path
        end
        
        -- Determine output path
        if config.output_dir then
          local output_dir = project_root .. '/' .. config.output_dir
          -- Create output directory if it doesn't exist
          vim.fn.system('mkdir -p "' .. output_dir .. '"')
          output_name = config.output_name or vim.fn.fnamemodify(source_file, ':t:r')
          output_path = output_dir .. '/' .. output_name
        else
          output_path = file_info.executable
        end
      else
        -- Default behavior
        if file_info.ext ~= 'cpp' and file_info.ext ~= 'cc' and file_info.ext ~= 'cxx' and file_info.ext ~= 'c' then
          vim.notify('Not a C/C++ file', vim.log.levels.ERROR)
          return
        end
        source_file = file_info.full_path
        output_path = file_info.executable
      end

      -- Save all files
      vim.cmd 'wa'

      -- Determine compiler and flags
      local file_ext = vim.fn.fnamemodify(source_file, ':e')
      local compiler = (file_ext == 'c') and 'gcc' or 'g++'
      local std_flag = (file_ext == 'c') and '-std=c11' or '-std=c++17'
      
      -- Build compiler flags
      local flags = std_flag .. ' -Wall -Wextra -g -O2'
      if config and config.compiler_flags then
        flags = flags .. ' ' .. config.compiler_flags
      end
      
      -- Compile command
      local compile_cmd = string.format('%s %s "%s" -o "%s"', 
        compiler, flags, source_file, output_path)

      -- Run command (with optional arguments from config)
      local run_cmd = string.format('"%s"', output_path)
      if config and config.run_args then
        run_cmd = run_cmd .. ' ' .. config.run_args
      end

      -- Change to project root if using config
      local cd_cmd = ''
      if config then
        cd_cmd = string.format('cd "%s" && ', project_root)
      end

      -- Get just the executable name for display
      local exe_name = vim.fn.fnamemodify(output_path, ':t')
      
      -- Combined command with cleaner output and error handling
      local full_cmd = string.format(
        [[%sclear && echo '⚙  Building %s...' && ]] ..
        [[if %s > /tmp/cpp_build.log 2>&1; then ]] ..
        [[  echo '✓ Running %s' && echo && %s && echo; ]] ..
        [[else ]] ..
        [[  echo '✗ Build failed:' && echo && cat /tmp/cpp_build.log; ]] ..
        [[fi]], 
        cd_cmd, exe_name, compile_cmd, exe_name, run_cmd
      )

      send_to_tmux_pane(full_cmd, true)
    end

    -- Function to start debugging current C++ file
    function M.cpp_debug()
      local config, project_root = load_cpp_config()
      local file_info = get_file_info()
      
      -- Determine what to compile (same logic as cpp_run)
      local source_file, output_path
      
      if config then
        if config.main_file then
          source_file = project_root .. '/' .. config.main_file
          if vim.fn.filereadable(source_file) == 0 then
            vim.notify('Main file not found: ' .. source_file, vim.log.levels.ERROR)
            return
          end
        else
          source_file = file_info.full_path
        end
        
        if config.output_dir then
          local output_dir = project_root .. '/' .. config.output_dir
          vim.fn.system('mkdir -p "' .. output_dir .. '"')
          local output_name = config.output_name or vim.fn.fnamemodify(source_file, ':t:r')
          output_path = output_dir .. '/' .. output_name
        else
          output_path = file_info.executable
        end
      else
        if file_info.ext ~= 'cpp' and file_info.ext ~= 'cc' and file_info.ext ~= 'cxx' and file_info.ext ~= 'c' then
          vim.notify('Not a C/C++ file', vim.log.levels.ERROR)
          return
        end
        source_file = file_info.full_path
        output_path = file_info.executable
      end

      -- Save all files
      vim.cmd 'wa'

      -- Determine compiler and flags
      local file_ext = vim.fn.fnamemodify(source_file, ':e')
      local compiler = (file_ext == 'c') and 'gcc' or 'g++'
      local std_flag = (file_ext == 'c') and '-std=c11' or '-std=c++17'

      -- Build debug flags
      local flags = std_flag .. ' -g -O0'
      if config and config.debug_flags then
        flags = std_flag .. ' ' .. config.debug_flags
      end

      -- Compile with debug symbols
      local compile_cmd = string.format('%s %s "%s" -o "%s"', 
        compiler, flags, source_file, output_path)

      -- Change to project root if using config
      if config then
        local cd_cmd = string.format('cd "%s"', project_root)
        vim.fn.system(cd_cmd)
      end

      -- Execute compile command
      local result = vim.fn.system(compile_cmd)
      if vim.v.shell_error ~= 0 then
        vim.notify('Compilation failed: ' .. result, vim.log.levels.ERROR)
        return
      end

      -- Update DAP configuration to use the correct executable
      require('dap').configurations.cpp[1].program = function()
        return output_path
      end

      -- Start DAP debugging
      require('dap').continue()
    end

    -- Set up buffer-local keybindings for C/C++ files
    vim.keymap.set('n', '<leader>cr', M.cpp_run, { 
      buffer = true, 
      desc = 'C++ Run in tmux' 
    })
    
    vim.keymap.set('n', '<leader>cd', M.cpp_debug, { 
      buffer = true, 
      desc = 'C++ Debug with DAP' 
    })

    -- Store module functions globally for tmux integration
    _G.CppTmux = M
  end
})

return {}