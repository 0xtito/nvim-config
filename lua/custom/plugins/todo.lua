return {
  name = 'project-todo',
  dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins/project-todo',
  lazy = false,
  config = function()
    local M = {}

    -- Get the project root (git root or current working directory)
    local function get_project_root()
      -- Try to find git root first
      local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
      if vim.v.shell_error == 0 and git_root ~= '' then
        return git_root
      end
      -- Fall back to current working directory
      return vim.fn.getcwd()
    end

    -- Generate the todo file path with directory structure
    local function get_todo_path()
      local project_root = get_project_root()
      local home = vim.fn.expand '~'
      local todo_base = vim.fn.stdpath 'data' .. '/project-todos'

      -- Remove home directory prefix to simplify path
      local relative_path = project_root
      if project_root:sub(1, #home) == home then
        relative_path = project_root:sub(#home + 2) -- +2 to skip the trailing slash
      end

      -- Construct the todo file path
      local todo_dir = todo_base .. '/' .. relative_path
      local todo_file = todo_dir .. '/.todo.md'

      return todo_file, todo_dir
    end

    -- Main function to open/create project todo
    local function open_project_todo()
      local todo_file, todo_dir = get_todo_path()

      -- Create directory if it doesn't exist
      if vim.fn.isdirectory(todo_dir) == 0 then
        vim.fn.mkdir(todo_dir, 'p')
      end

      -- Open the todo file
      vim.cmd.edit(todo_file)

      -- Set buffer options
      vim.bo.filetype = 'markdown'
      vim.bo.bufhidden = 'hide'

      -- If file is new, add a header
      if vim.fn.getfsize(todo_file) <= 0 then
        local project_name = vim.fn.fnamemodify(get_project_root(), ':t')
        local header = {
          '# TODO: ' .. project_name,
          '',
          '## Tasks',
          '',
          '- [ ] ',
        }
        vim.api.nvim_buf_set_lines(0, 0, -1, false, header)
        -- Position cursor at the first task
        vim.api.nvim_win_set_cursor(0, { 5, 6 })
      end
    end

    -- Set up the keymap
    vim.keymap.set('n', '<leader>td', open_project_todo, {
      desc = 'Open project [T]o[D]o file',
      noremap = true,
      silent = true,
    })
  end,
}
