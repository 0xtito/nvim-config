-- cpp-runner.lua
-- Native Neovim C++ runner with Conjure-style output display
-- Features: Floating HUD, Log panel, Async execution, Interactive config

local M = {}

-- State
local state = {
  log_buf = nil,
  log_win = nil,
  float_win = nil,
  float_buf = nil,
  last_output = {},
  last_errors = {}, -- {file, line, col, message}
  has_errors = false,
  job_id = nil,
  source_file = nil, -- Track the file we're compiling
  run_args = '', -- Command line arguments for the executable
  custom_run_cmd = nil, -- Custom run command (nil = use default executable)
  config_win = nil, -- Config popup window
  config_buf = nil, -- Config popup buffer
  cursor_line = 1, -- Current line in config popup
}

-- Available compiler flags with descriptions and documentation links
local FLAG_DEFINITIONS = {
  -- Standard selection
  { flag = '-std=c++20', category = 'Standard', desc = 'Use C++20 standard', url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html' },
  { flag = '-std=c++23', category = 'Standard', desc = 'Use C++23 standard (experimental)', url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html' },
  { flag = '-std=c++17', category = 'Standard', desc = 'Use C++17 standard', url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html' },
  { flag = '-std=c++14', category = 'Standard', desc = 'Use C++14 standard', url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html' },

  -- Warnings
  { flag = '-Wall', category = 'Warnings', desc = 'Enable common warnings', url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wall' },
  { flag = '-Wextra', category = 'Warnings', desc = 'Enable extra warnings', url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wextra' },
  {
    flag = '-Wpedantic',
    category = 'Warnings',
    desc = 'Strict ISO C++ compliance',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wpedantic',
  },
  { flag = '-Werror', category = 'Warnings', desc = 'Treat warnings as errors', url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Werror' },
  {
    flag = '-Wshadow',
    category = 'Warnings',
    desc = 'Warn when variable shadows another',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wshadow',
  },
  {
    flag = '-Wconversion',
    category = 'Warnings',
    desc = 'Warn on implicit type conversions',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wconversion',
  },
  {
    flag = '-Wsign-conversion',
    category = 'Warnings',
    desc = 'Warn on sign conversion',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wsign-conversion',
  },
  {
    flag = '-Wnull-dereference',
    category = 'Warnings',
    desc = 'Warn on null pointer dereference',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wnull-dereference',
  },
  {
    flag = '-Wdouble-promotion',
    category = 'Warnings',
    desc = 'Warn on float to double promotion',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wdouble-promotion',
  },
  {
    flag = '-Wformat=2',
    category = 'Warnings',
    desc = 'Extra format string checks',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wformat',
  },
  {
    flag = '-Wundef',
    category = 'Warnings',
    desc = 'Warn if undefined macro is used',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wundef',
  },
  {
    flag = '-Wcast-qual',
    category = 'Warnings',
    desc = 'Warn on cast removing qualifier',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wcast-qual',
  },
  {
    flag = '-Wcast-align',
    category = 'Warnings',
    desc = 'Warn on alignment issues',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wcast-align',
  },
  { flag = '-Wunused', category = 'Warnings', desc = 'Warn on unused entities', url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wunused' },
  {
    flag = '-Woverloaded-virtual',
    category = 'Warnings',
    desc = 'Warn when function hides virtual',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Woverloaded-virtual',
  },

  -- Optimization
  {
    flag = '-O0',
    category = 'Optimization',
    desc = 'No optimization (fast compile)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-O0',
  },
  { flag = '-O1', category = 'Optimization', desc = 'Basic optimization', url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-O1' },
  {
    flag = '-O2',
    category = 'Optimization',
    desc = 'Standard optimization (recommended)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-O2',
  },
  { flag = '-O3', category = 'Optimization', desc = 'Aggressive optimization', url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-O3' },
  { flag = '-Os', category = 'Optimization', desc = 'Optimize for size', url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-Os' },
  { flag = '-Og', category = 'Optimization', desc = 'Optimize for debugging', url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-Og' },
  {
    flag = '-Ofast',
    category = 'Optimization',
    desc = 'Fast math + O3 (non-standard)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-Ofast',
  },
  {
    flag = '-march=native',
    category = 'Optimization',
    desc = 'Optimize for current CPU',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-march',
  },
  { flag = '-mtune=native', category = 'Optimization', desc = 'Tune for current CPU', url = 'https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-mtune' },
  { flag = '-flto', category = 'Optimization', desc = 'Link-time optimization', url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-flto' },

  -- Debugging
  { flag = '-g', category = 'Debug', desc = 'Include debug symbols', url = 'https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html#index-g' },
  { flag = '-g3', category = 'Debug', desc = 'Max debug info + macros', url = 'https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html#index-g' },
  { flag = '-ggdb', category = 'Debug', desc = 'GDB-specific debug info', url = 'https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html#index-ggdb' },
  {
    flag = '-fno-omit-frame-pointer',
    category = 'Debug',
    desc = 'Keep frame pointer (better stack traces)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-fomit-frame-pointer',
  },

  -- Sanitizers
  {
    flag = '-fsanitize=address',
    category = 'Sanitizers',
    desc = 'Memory error detection (ASan)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html#index-fsanitize_003daddress',
  },
  {
    flag = '-fsanitize=undefined',
    category = 'Sanitizers',
    desc = 'Undefined behavior detection (UBSan)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html#index-fsanitize_003dundefined',
  },
  {
    flag = '-fsanitize=thread',
    category = 'Sanitizers',
    desc = 'Thread sanitizer (TSan)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html#index-fsanitize_003dthread',
  },
  {
    flag = '-fsanitize=leak',
    category = 'Sanitizers',
    desc = 'Memory leak detection (LSan)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html#index-fsanitize_003dleak',
  },

  -- Security
  {
    flag = '-fstack-protector-strong',
    category = 'Security',
    desc = 'Stack buffer overflow protection',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html#index-fstack-protector',
  },
  {
    flag = '-D_FORTIFY_SOURCE=2',
    category = 'Security',
    desc = 'Buffer overflow checks',
    url = 'https://man7.org/linux/man-pages/man7/feature_test_macros.7.html',
  },
  {
    flag = '-D_GLIBCXX_ASSERTIONS',
    category = 'Security',
    desc = 'Enable libstdc++ assertions',
    url = 'https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_macros.html',
  },
  {
    flag = '-fPIE',
    category = 'Security',
    desc = 'Position independent executable',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/Code-Gen-Options.html#index-fpie',
  },

  -- C standard (for .c files)
  { flag = '-std=c11', category = 'C Standard', desc = 'Use C11 standard', url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html', c_only = true },
  { flag = '-std=c17', category = 'C Standard', desc = 'Use C17 standard', url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html', c_only = true },
  {
    flag = '-std=c23',
    category = 'C Standard',
    desc = 'Use C23 standard (experimental)',
    url = 'https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html',
    c_only = true,
  },
}

-- Default enabled flags for each build mode
local DEFAULT_DEBUG_FLAGS = {
  '-std=c++20',
  '-Wall',
  '-Wextra',
  '-g',
  '-O0',
  '-fno-omit-frame-pointer',
}

local DEFAULT_RELEASE_FLAGS = {
  '-std=c++20',
  '-Wall',
  '-Wextra',
  '-O2',
  '-DNDEBUG',
}

local DEFAULT_DEBUG_C_FLAGS = {
  '-std=c11',
  '-Wall',
  '-Wextra',
  '-g',
  '-O0',
  '-fno-omit-frame-pointer',
}

local DEFAULT_RELEASE_C_FLAGS = {
  '-std=c11',
  '-Wall',
  '-Wextra',
  '-O2',
  '-DNDEBUG',
}

-- Config (runtime)
local config = {
  float = {
    width = 55,
    height = 12,
    border = 'rounded',
    position = 'NE', -- NE, NW, SE, SW
  },
  panel = {
    width = 0.3, -- 30% of screen width
    position = 'right', -- 'right' or 'left'
  },
  compiler = {
    cpp = 'g++',
    c = 'gcc',
  },
  icons = {
    building = '',
    success = '',
    error = '',
    running = '',
    output = '',
  },
}

-- Project config (loaded from file)
local project_config = {
  build_mode = 'debug', -- 'debug' or 'release'
  -- C++ flags
  debug_flags = vim.deepcopy(DEFAULT_DEBUG_FLAGS),
  release_flags = vim.deepcopy(DEFAULT_RELEASE_FLAGS),
  custom_debug_flags = '',
  custom_release_flags = '',
  -- C flags
  debug_c_flags = vim.deepcopy(DEFAULT_DEBUG_C_FLAGS),
  release_c_flags = vim.deepcopy(DEFAULT_RELEASE_C_FLAGS),
  custom_debug_c_flags = '',
  custom_release_c_flags = '',
  -- Run settings
  run_args = '',
  custom_run_cmd = nil,
}

-- Utilities
local function get_timestamp()
  return os.date '%H:%M:%S'
end

local function get_file_info()
  return {
    full_path = vim.fn.expand '%:p',
    dir = vim.fn.expand '%:p:h',
    name = vim.fn.expand '%:t:r',
    ext = vim.fn.expand '%:e',
  }
end

local function is_cpp_file(ext)
  return vim.tbl_contains({ 'cpp', 'cc', 'cxx', 'c', 'h', 'hpp' }, ext)
end

-- Config file handling
local CONFIG_FILE_NAME = '.cpprunner.json'

local function get_project_root()
  -- Try to find project root via git
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel 2>/dev/null')[1]
  if git_root and git_root ~= '' and vim.fn.isdirectory(git_root) == 1 then
    return git_root
  end
  -- Fall back to current file's directory
  return vim.fn.expand '%:p:h'
end

local function get_config_file_path()
  return get_project_root() .. '/' .. CONFIG_FILE_NAME
end

-- Helper to convert vim.NIL to Lua nil
local function from_json_value(val, default)
  if val == nil or val == vim.NIL then
    return default
  end
  return val
end

local function load_project_config()
  local config_path = get_config_file_path()
  if vim.fn.filereadable(config_path) == 1 then
    local content = vim.fn.readfile(config_path)
    if #content > 0 then
      local ok, data = pcall(vim.fn.json_decode, table.concat(content, '\n'))
      if ok and data then
        project_config.build_mode = from_json_value(data.build_mode, 'debug')
        -- C++ flags
        project_config.debug_flags = from_json_value(data.debug_flags, vim.deepcopy(DEFAULT_DEBUG_FLAGS))
        project_config.release_flags = from_json_value(data.release_flags, vim.deepcopy(DEFAULT_RELEASE_FLAGS))
        project_config.custom_debug_flags = from_json_value(data.custom_debug_flags, '')
        project_config.custom_release_flags = from_json_value(data.custom_release_flags, '')
        -- C flags
        project_config.debug_c_flags = from_json_value(data.debug_c_flags, vim.deepcopy(DEFAULT_DEBUG_C_FLAGS))
        project_config.release_c_flags = from_json_value(data.release_c_flags, vim.deepcopy(DEFAULT_RELEASE_C_FLAGS))
        project_config.custom_debug_c_flags = from_json_value(data.custom_debug_c_flags, '')
        project_config.custom_release_c_flags = from_json_value(data.custom_release_c_flags, '')
        -- Run settings
        project_config.run_args = from_json_value(data.run_args, '')
        project_config.custom_run_cmd = from_json_value(data.custom_run_cmd, nil)
        -- Also load into runtime state
        state.run_args = project_config.run_args
        state.custom_run_cmd = project_config.custom_run_cmd
        return true
      end
    end
  end
  -- Reset to defaults
  project_config.build_mode = 'debug'
  project_config.debug_flags = vim.deepcopy(DEFAULT_DEBUG_FLAGS)
  project_config.release_flags = vim.deepcopy(DEFAULT_RELEASE_FLAGS)
  project_config.custom_debug_flags = ''
  project_config.custom_release_flags = ''
  project_config.debug_c_flags = vim.deepcopy(DEFAULT_DEBUG_C_FLAGS)
  project_config.release_c_flags = vim.deepcopy(DEFAULT_RELEASE_C_FLAGS)
  project_config.custom_debug_c_flags = ''
  project_config.custom_release_c_flags = ''
  project_config.run_args = ''
  project_config.custom_run_cmd = nil
  return false
end

local function save_project_config()
  local config_path = get_config_file_path()

  -- Build properly formatted JSON manually
  local lines = {
    '{',
  }

  -- Helper to format a string array
  local function format_array(arr)
    local items = {}
    for _, v in ipairs(arr) do
      table.insert(items, '"' .. v .. '"')
    end
    return '[ ' .. table.concat(items, ', ') .. ' ]'
  end

  -- Helper to escape and quote a string (or return null)
  local function format_string(s)
    if s == nil then
      return 'null'
    end
    -- Escape backslashes and quotes
    local escaped = s:gsub('\\', '\\\\'):gsub('"', '\\"')
    return '"' .. escaped .. '"'
  end

  table.insert(lines, '  "build_mode": ' .. format_string(project_config.build_mode) .. ',')
  table.insert(lines, '  "debug_flags": ' .. format_array(project_config.debug_flags) .. ',')
  table.insert(lines, '  "release_flags": ' .. format_array(project_config.release_flags) .. ',')
  table.insert(lines, '  "custom_debug_flags": ' .. format_string(project_config.custom_debug_flags) .. ',')
  table.insert(lines, '  "custom_release_flags": ' .. format_string(project_config.custom_release_flags) .. ',')
  table.insert(lines, '  "debug_c_flags": ' .. format_array(project_config.debug_c_flags) .. ',')
  table.insert(lines, '  "release_c_flags": ' .. format_array(project_config.release_c_flags) .. ',')
  table.insert(lines, '  "custom_debug_c_flags": ' .. format_string(project_config.custom_debug_c_flags) .. ',')
  table.insert(lines, '  "custom_release_c_flags": ' .. format_string(project_config.custom_release_c_flags) .. ',')
  table.insert(lines, '  "run_args": ' .. format_string(state.run_args or '') .. ',')
  table.insert(lines, '  "custom_run_cmd": ' .. format_string(state.custom_run_cmd))
  table.insert(lines, '}')

  vim.fn.writefile(lines, config_path)
  vim.notify('Config saved to ' .. config_path, vim.log.levels.INFO)
end

-- Get the current flags based on build mode and language
local function get_current_flags(is_c)
  local mode = project_config.build_mode
  if is_c then
    return mode == 'debug' and project_config.debug_c_flags or project_config.release_c_flags
  else
    return mode == 'debug' and project_config.debug_flags or project_config.release_flags
  end
end

-- Get the current custom flags based on build mode and language
local function get_current_custom_flags(is_c)
  local mode = project_config.build_mode
  if is_c then
    return mode == 'debug' and project_config.custom_debug_c_flags or project_config.custom_release_c_flags
  else
    return mode == 'debug' and project_config.custom_debug_flags or project_config.custom_release_flags
  end
end

-- Set the current custom flags based on build mode and language
local function set_current_custom_flags(is_c, value)
  local mode = project_config.build_mode
  if is_c then
    if mode == 'debug' then
      project_config.custom_debug_c_flags = value
    else
      project_config.custom_release_c_flags = value
    end
  else
    if mode == 'debug' then
      project_config.custom_debug_flags = value
    else
      project_config.custom_release_flags = value
    end
  end
end

-- Build flags string from enabled flags
local function build_flags_string(is_c)
  local enabled = get_current_flags(is_c)
  local custom = get_current_custom_flags(is_c)
  local flags = table.concat(enabled, ' ')
  if custom and custom ~= '' then
    flags = flags .. ' ' .. custom
  end
  return flags
end

-- Check if flag is enabled
local function is_flag_enabled(flag, is_c)
  local enabled = get_current_flags(is_c)
  return vim.tbl_contains(enabled, flag)
end

-- Get the key for current flags array based on build mode and language
local function get_flags_key(is_c)
  local mode = project_config.build_mode
  if is_c then
    return mode == 'debug' and 'debug_c_flags' or 'release_c_flags'
  else
    return mode == 'debug' and 'debug_flags' or 'release_flags'
  end
end

-- Toggle a flag
local function toggle_flag(flag, is_c)
  local enabled = get_current_flags(is_c)
  local key = get_flags_key(is_c)

  -- Handle mutually exclusive flags (optimization levels, standards)
  local exclusive_groups = {
    { '-O0', '-O1', '-O2', '-O3', '-Os', '-Og', '-Ofast' },
    { '-std=c++14', '-std=c++17', '-std=c++20', '-std=c++23' },
    { '-std=c11', '-std=c17', '-std=c23' },
    { '-g', '-g3', '-ggdb' },
  }

  -- Check if this flag is in an exclusive group
  for _, group in ipairs(exclusive_groups) do
    if vim.tbl_contains(group, flag) then
      -- Remove all flags in this group first
      for _, gflag in ipairs(group) do
        for i, eflag in ipairs(enabled) do
          if eflag == gflag then
            table.remove(enabled, i)
            break
          end
        end
      end
      -- If we're enabling, add the flag
      if not vim.tbl_contains(enabled, flag) then
        table.insert(enabled, flag)
      end
      project_config[key] = enabled
      return
    end
  end

  -- Regular toggle
  local found = false
  for i, eflag in ipairs(enabled) do
    if eflag == flag then
      table.remove(enabled, i)
      found = true
      break
    end
  end
  if not found then
    table.insert(enabled, flag)
  end
  project_config[key] = enabled
end

-- Config popup rendering
local function render_config_popup(is_c)
  local lines = {}
  local highlights = {}
  local line_data = {} -- Store data for each line

  -- Header
  table.insert(lines, ' C++ Runner Configuration')
  table.insert(highlights, { line = #lines, hl = 'Title' })
  table.insert(line_data, { type = 'header' })

  table.insert(lines, string.rep('─', 70))
  table.insert(line_data, { type = 'separator' })

  -- Build mode selector
  local mode = project_config.build_mode
  local debug_indicator = mode == 'debug' and '●' or '○'
  local release_indicator = mode == 'release' and '●' or '○'
  table.insert(lines, ' Build Mode:  ' .. debug_indicator .. ' Debug    ' .. release_indicator .. ' Release')
  table.insert(line_data, { type = 'build_mode' })
  if mode == 'debug' then
    table.insert(highlights, { line = #lines, hl = 'DiagnosticInfo', col_start = 14, col_end = 23 })
  else
    table.insert(highlights, { line = #lines, hl = 'DiagnosticOk', col_start = 26, col_end = 36 })
  end

  table.insert(lines, '')
  table.insert(line_data, { type = 'empty' })

  -- Current flags preview
  local flags_str = build_flags_string(is_c)
  local mode_label = mode == 'debug' and '[Debug]' or '[Release]'
  table.insert(lines, ' ' .. mode_label .. ' Flags: ' .. (flags_str ~= '' and flags_str or '(none)'))
  table.insert(highlights, { line = #lines, hl = 'Comment' })
  table.insert(line_data, { type = 'preview' })

  table.insert(lines, '')
  table.insert(line_data, { type = 'empty' })

  -- Group flags by category
  local categories = {}
  local category_order = { 'Standard', 'Warnings', 'Optimization', 'Debug', 'Sanitizers', 'Security', 'C Standard' }

  for _, def in ipairs(FLAG_DEFINITIONS) do
    -- Skip C++ flags when editing C config and vice versa
    if is_c and def.category == 'Standard' then
      goto continue
    end
    if not is_c and def.c_only then
      goto continue
    end

    if not categories[def.category] then
      categories[def.category] = {}
    end
    table.insert(categories[def.category], def)
    ::continue::
  end

  -- Render each category
  for _, category in ipairs(category_order) do
    if categories[category] and #categories[category] > 0 then
      table.insert(lines, '')
      table.insert(line_data, { type = 'empty' })

      table.insert(lines, ' ' .. category)
      table.insert(highlights, { line = #lines, hl = 'Special' })
      table.insert(line_data, { type = 'category', name = category })

      for _, def in ipairs(categories[category]) do
        local enabled = is_flag_enabled(def.flag, is_c)
        local checkbox = enabled and '[x]' or '[ ]'
        local line = '   ' .. checkbox .. ' ' .. def.flag
        -- Pad to align descriptions
        line = line .. string.rep(' ', math.max(1, 28 - #line)) .. def.desc

        table.insert(lines, line)
        table.insert(line_data, { type = 'flag', flag = def.flag, url = def.url, enabled = enabled })

        if enabled then
          table.insert(highlights, { line = #lines, hl = 'String', col_start = 3, col_end = 6 })
        end
      end
    end
  end

  -- Custom flags section
  table.insert(lines, '')
  table.insert(line_data, { type = 'empty' })
  table.insert(lines, ' Custom Flags')
  table.insert(highlights, { line = #lines, hl = 'Special' })
  table.insert(line_data, { type = 'category', name = 'Custom' })

  local custom = get_current_custom_flags(is_c)
  table.insert(lines, '   [Edit] ' .. (custom ~= '' and custom or '(none)'))
  table.insert(line_data, { type = 'custom_flags', is_c = is_c })
  table.insert(highlights, { line = #lines, hl = 'Function', col_start = 3, col_end = 9 })

  -- Run args section
  table.insert(lines, '')
  table.insert(line_data, { type = 'empty' })
  table.insert(lines, ' Run Settings')
  table.insert(highlights, { line = #lines, hl = 'Special' })
  table.insert(line_data, { type = 'category', name = 'Run' })

  table.insert(lines, '   [Edit] Arguments: ' .. (state.run_args ~= '' and state.run_args or '(none)'))
  table.insert(line_data, { type = 'run_args' })
  table.insert(highlights, { line = #lines, hl = 'Function', col_start = 3, col_end = 9 })

  local cmd_display = (state.custom_run_cmd and state.custom_run_cmd ~= vim.NIL) and state.custom_run_cmd or '(default)'
  table.insert(lines, '   [Edit] Command: ' .. cmd_display)
  table.insert(line_data, { type = 'run_cmd' })
  table.insert(highlights, { line = #lines, hl = 'Function', col_start = 3, col_end = 9 })

  -- Footer
  table.insert(lines, '')
  table.insert(line_data, { type = 'empty' })
  table.insert(lines, string.rep('─', 70))
  table.insert(line_data, { type = 'separator' })

  local loaded = vim.fn.filereadable(get_config_file_path()) == 1
  local config_status = loaded and ' (loaded)' or ' (defaults)'
  table.insert(lines, ' d:debug/release  Space:toggle  o:docs  s:save  r:reset  q:close' .. config_status)
  table.insert(highlights, { line = #lines, hl = 'Comment' })
  table.insert(line_data, { type = 'footer' })

  return lines, highlights, line_data
end

-- Config popup window
function M.open_config()
  local file_info = get_file_info()
  local is_c = file_info.ext == 'c'

  -- Load project config first
  load_project_config()

  local lines, highlights, line_data = render_config_popup(is_c)

  -- Close existing
  if state.config_win and vim.api.nvim_win_is_valid(state.config_win) then
    vim.api.nvim_win_close(state.config_win, true)
  end
  if state.config_buf and vim.api.nvim_buf_is_valid(state.config_buf) then
    vim.api.nvim_buf_delete(state.config_buf, { force = true })
  end

  -- Create buffer
  state.config_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.config_buf, 0, -1, false, lines)

  -- Store line data for later use
  vim.b[state.config_buf].line_data = line_data
  vim.b[state.config_buf].is_c = is_c

  -- Apply highlights
  local ns = vim.api.nvim_create_namespace 'cpprunner_config'
  for _, hl in ipairs(highlights) do
    local col_start = hl.col_start or 0
    local col_end = hl.col_end or -1
    vim.api.nvim_buf_add_highlight(state.config_buf, ns, hl.hl, hl.line - 1, col_start, col_end)
  end

  -- Calculate size and position
  local width = 72
  local height = math.min(#lines, math.floor(vim.o.lines * 0.8))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create window
  state.config_win = vim.api.nvim_open_win(state.config_buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = is_c and ' C Compiler Config ' or ' C++ Compiler Config ',
    title_pos = 'center',
  })

  -- Buffer options
  vim.bo[state.config_buf].modifiable = false
  vim.bo[state.config_buf].bufhidden = 'wipe'

  -- Window options
  vim.wo[state.config_win].cursorline = true
  vim.wo[state.config_win].wrap = false

  -- Move cursor to first flag line
  for i, data in ipairs(line_data) do
    if data.type == 'flag' then
      vim.api.nvim_win_set_cursor(state.config_win, { i, 0 })
      break
    end
  end

  -- Setup keymaps
  local opts = { buffer = state.config_buf, silent = true, nowait = true }

  -- Close
  vim.keymap.set('n', 'q', function()
    M.close_config()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close_config()
  end, opts)

  -- Toggle flag with Space or Enter
  vim.keymap.set('n', '<Space>', function()
    M.config_toggle_or_edit()
  end, opts)
  vim.keymap.set('n', '<CR>', function()
    M.config_toggle_or_edit()
  end, opts)

  -- Open docs
  vim.keymap.set('n', 'o', function()
    M.config_open_docs()
  end, opts)

  -- Save config
  vim.keymap.set('n', 's', function()
    save_project_config()
    M.refresh_config_popup()
  end, opts)

  -- Toggle debug/release mode
  vim.keymap.set('n', 'd', function()
    if project_config.build_mode == 'debug' then
      project_config.build_mode = 'release'
      vim.notify('Switched to Release mode', vim.log.levels.INFO)
    else
      project_config.build_mode = 'debug'
      vim.notify('Switched to Debug mode', vim.log.levels.INFO)
    end
    M.refresh_config_popup()
  end, opts)

  -- Reset to defaults
  vim.keymap.set('n', 'r', function()
    project_config.build_mode = 'debug'
    project_config.debug_flags = vim.deepcopy(DEFAULT_DEBUG_FLAGS)
    project_config.release_flags = vim.deepcopy(DEFAULT_RELEASE_FLAGS)
    project_config.custom_debug_flags = ''
    project_config.custom_release_flags = ''
    project_config.debug_c_flags = vim.deepcopy(DEFAULT_DEBUG_C_FLAGS)
    project_config.release_c_flags = vim.deepcopy(DEFAULT_RELEASE_C_FLAGS)
    project_config.custom_debug_c_flags = ''
    project_config.custom_release_c_flags = ''
    state.run_args = ''
    state.custom_run_cmd = nil
    M.refresh_config_popup()
    vim.notify('Config reset to defaults', vim.log.levels.INFO)
  end, opts)

  -- Navigation
  vim.keymap.set('n', 'j', function()
    local pos = vim.api.nvim_win_get_cursor(state.config_win)
    local ld = vim.b[state.config_buf].line_data
    for i = pos[1] + 1, #ld do
      if ld[i].type == 'flag' or ld[i].type == 'custom_flags' or ld[i].type == 'run_args' or ld[i].type == 'run_cmd' or ld[i].type == 'build_mode' then
        vim.api.nvim_win_set_cursor(state.config_win, { i, 0 })
        break
      end
    end
  end, opts)

  vim.keymap.set('n', 'k', function()
    local pos = vim.api.nvim_win_get_cursor(state.config_win)
    local ld = vim.b[state.config_buf].line_data
    for i = pos[1] - 1, 1, -1 do
      if ld[i].type == 'flag' or ld[i].type == 'custom_flags' or ld[i].type == 'run_args' or ld[i].type == 'run_cmd' or ld[i].type == 'build_mode' then
        vim.api.nvim_win_set_cursor(state.config_win, { i, 0 })
        break
      end
    end
  end, opts)
end

function M.close_config()
  if state.config_win and vim.api.nvim_win_is_valid(state.config_win) then
    vim.api.nvim_win_close(state.config_win, true)
    state.config_win = nil
  end
  if state.config_buf and vim.api.nvim_buf_is_valid(state.config_buf) then
    vim.api.nvim_buf_delete(state.config_buf, { force = true })
    state.config_buf = nil
  end
end

function M.refresh_config_popup()
  if not state.config_buf or not vim.api.nvim_buf_is_valid(state.config_buf) then
    return
  end

  local is_c = vim.b[state.config_buf].is_c
  local pos = vim.api.nvim_win_get_cursor(state.config_win)

  local lines, highlights, line_data = render_config_popup(is_c)

  vim.bo[state.config_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.config_buf, 0, -1, false, lines)
  vim.bo[state.config_buf].modifiable = false

  vim.b[state.config_buf].line_data = line_data

  -- Reapply highlights
  local ns = vim.api.nvim_create_namespace 'cpprunner_config'
  vim.api.nvim_buf_clear_namespace(state.config_buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    local col_start = hl.col_start or 0
    local col_end = hl.col_end or -1
    vim.api.nvim_buf_add_highlight(state.config_buf, ns, hl.hl, hl.line - 1, col_start, col_end)
  end

  -- Restore cursor
  if pos[1] <= #lines then
    vim.api.nvim_win_set_cursor(state.config_win, pos)
  end
end

function M.config_toggle_or_edit()
  if not state.config_buf or not vim.api.nvim_buf_is_valid(state.config_buf) then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(state.config_win)
  local line_data = vim.b[state.config_buf].line_data
  local is_c = vim.b[state.config_buf].is_c
  local data = line_data[pos[1]]

  if not data then
    return
  end

  if data.type == 'build_mode' then
    -- Toggle build mode
    if project_config.build_mode == 'debug' then
      project_config.build_mode = 'release'
      vim.notify('Switched to Release mode', vim.log.levels.INFO)
    else
      project_config.build_mode = 'debug'
      vim.notify('Switched to Debug mode', vim.log.levels.INFO)
    end
    M.refresh_config_popup()
  elseif data.type == 'flag' then
    toggle_flag(data.flag, is_c)
    M.refresh_config_popup()
  elseif data.type == 'custom_flags' then
    local current = get_current_custom_flags(is_c)
    local mode_label = project_config.build_mode == 'debug' and 'Debug' or 'Release'
    vim.ui.input({
      prompt = mode_label .. ' custom flags: ',
      default = current,
    }, function(input)
      if input ~= nil then
        set_current_custom_flags(is_c, input)
        vim.schedule(function()
          M.refresh_config_popup()
        end)
      end
    end)
  elseif data.type == 'run_args' then
    vim.ui.input({
      prompt = 'Run arguments: ',
      default = state.run_args or '',
    }, function(input)
      if input ~= nil then
        state.run_args = input
        vim.schedule(function()
          M.refresh_config_popup()
        end)
      end
    end)
  elseif data.type == 'run_cmd' then
    local current_cmd = (state.custom_run_cmd and state.custom_run_cmd ~= vim.NIL) and state.custom_run_cmd or ''
    vim.ui.input({
      prompt = 'Run command (empty for default): ',
      default = current_cmd,
    }, function(input)
      if input ~= nil then
        state.custom_run_cmd = input ~= '' and input or nil
        vim.schedule(function()
          M.refresh_config_popup()
        end)
      end
    end)
  end
end

function M.config_open_docs()
  if not state.config_buf or not vim.api.nvim_buf_is_valid(state.config_buf) then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(state.config_win)
  local line_data = vim.b[state.config_buf].line_data
  local data = line_data[pos[1]]

  if data and data.url then
    -- Open URL in default browser
    local cmd
    if vim.fn.has 'mac' == 1 then
      cmd = 'open'
    elseif vim.fn.has 'unix' == 1 then
      cmd = 'xdg-open'
    else
      cmd = 'start'
    end
    vim.fn.jobstart({ cmd, data.url }, { detach = true })
    vim.notify('Opening docs: ' .. data.flag, vim.log.levels.INFO)
  else
    vim.notify('No documentation available for this item', vim.log.levels.WARN)
  end
end

-- Parse compiler errors (gcc/clang format: file:line:col: error: message)
local function parse_errors(output)
  local errors = {}
  for _, line in ipairs(output) do
    -- Match: file.cpp:10:5: error: message or file.cpp:10: error: message
    local file, lnum, col, msg = line:match '^([^:]+):(%d+):(%d+):%s*error:%s*(.+)$'
    if not file then
      file, lnum, msg = line:match '^([^:]+):(%d+):%s*error:%s*(.+)$'
      col = '1'
    end
    if file and lnum then
      table.insert(errors, {
        file = file,
        line = tonumber(lnum),
        col = tonumber(col) or 1,
        message = msg or 'Unknown error',
        full_line = line,
      })
    end
  end
  return errors
end

-- Log buffer management
function M.get_log_buf()
  if state.log_buf and vim.api.nvim_buf_is_valid(state.log_buf) then
    return state.log_buf
  end

  state.log_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.log_buf, 'cpp-output')
  vim.bo[state.log_buf].filetype = 'cpp-output'
  vim.bo[state.log_buf].bufhidden = 'hide'
  vim.bo[state.log_buf].swapfile = false

  -- Set up highlighting
  vim.api.nvim_buf_call(state.log_buf, function()
    vim.cmd [[
      syntax match CppRunnerSuccess /^.*✓.*/
      syntax match CppRunnerError /^.*✗.*/
      syntax match CppRunnerInfo /^.*⚙.*/
      syntax match CppRunnerOutput /^.*│.*/
      syntax match CppRunnerTimestamp /\[\d\d:\d\d:\d\d\]/
      syntax match CppRunnerSeparator /^─.*$/

      hi link CppRunnerSuccess DiagnosticOk
      hi link CppRunnerError DiagnosticError
      hi link CppRunnerInfo DiagnosticInfo
      hi link CppRunnerOutput Normal
      hi link CppRunnerTimestamp Comment
      hi link CppRunnerSeparator Comment
    ]]
  end)

  return state.log_buf
end

function M.append_to_log(lines, prefix)
  local buf = M.get_log_buf()
  if type(lines) == 'string' then
    lines = { lines }
  end

  local formatted = {}
  local timestamp = '[' .. get_timestamp() .. ']'

  for i, line in ipairs(lines) do
    if i == 1 and prefix then
      table.insert(formatted, timestamp .. ' ' .. prefix .. ' ' .. line)
    else
      -- Indent continuation lines
      table.insert(formatted, '         │ ' .. line)
    end
  end

  local count = vim.api.nvim_buf_line_count(buf)
  -- If buffer is empty (just one empty line), replace it
  if count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '' then
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, formatted)
  else
    vim.api.nvim_buf_set_lines(buf, count, count, false, formatted)
  end

  -- Scroll to bottom if log window is open
  if state.log_win and vim.api.nvim_win_is_valid(state.log_win) then
    local new_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(state.log_win, { new_count, 0 })
  end

  return formatted
end

function M.add_separator()
  local buf = M.get_log_buf()
  local sep =
    '─────────────────────────────────────────────────'
  local count = vim.api.nvim_buf_line_count(buf)
  if count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '' then
    return -- Don't add separator to empty buffer
  end
  vim.api.nvim_buf_set_lines(buf, count, count, false, { sep })
end

function M.clear_log()
  local buf = M.get_log_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
  vim.notify('C++ output log cleared', vim.log.levels.INFO)
end

-- Setup keymaps for float buffer
local function setup_float_keymaps(buf)
  local opts = { buffer = buf, silent = true, nowait = true }

  -- q or Esc to close
  vim.keymap.set('n', 'q', function()
    M.close_float()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close_float()
  end, opts)

  -- e to jump to error
  vim.keymap.set('n', 'e', function()
    M.jump_to_error()
  end, opts)

  -- l to open log panel (close float first)
  vim.keymap.set('n', 'l', function()
    M.float_to_panel()
  end, opts)

  -- r to re-run
  vim.keymap.set('n', 'r', function()
    M.close_float()
    M.run { mode = 'float' }
  end, opts)

  -- R to re-run with panel
  vim.keymap.set('n', 'R', function()
    M.close_float()
    M.run { mode = 'panel' }
  end, opts)

  -- y to copy output to clipboard
  vim.keymap.set('n', 'y', function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = table.concat(lines, '\n')
    vim.fn.setreg('+', text)
    vim.notify('Output copied to clipboard', vim.log.levels.INFO)
  end, opts)

  -- a to set run arguments
  vim.keymap.set('n', 'a', function()
    M.close_float()
    M.set_run_args()
  end, opts)
end

-- Floating window (HUD)
function M.show_float(lines, title, hl_group, is_error)
  if not lines or #lines == 0 then
    return
  end

  state.has_errors = is_error or false

  -- Limit lines and add title
  local display_lines = {}
  if title then
    table.insert(display_lines, title)
    table.insert(display_lines, string.rep('─', config.float.width - 4))
  end

  for i, line in ipairs(lines) do
    if i <= config.float.height - 4 then
      -- Truncate long lines
      if #line > config.float.width - 4 then
        line = line:sub(1, config.float.width - 7) .. '...'
      end
      table.insert(display_lines, line)
    end
  end

  if #lines > config.float.height - 4 then
    table.insert(display_lines, '... (' .. (#lines - config.float.height + 4) .. ' more lines)')
  end

  -- Calculate position
  local width = config.float.width
  local height = math.min(#display_lines + 1, config.float.height) -- +1 for some padding
  local row, col

  if config.float.position == 'NE' then
    row = 1
    col = vim.o.columns - width - 2
  elseif config.float.position == 'NW' then
    row = 1
    col = 2
  elseif config.float.position == 'SE' then
    row = vim.o.lines - height - 4
    col = vim.o.columns - width - 2
  else -- SW
    row = vim.o.lines - height - 4
    col = 2
  end

  -- Close existing float window and buffer
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
    vim.api.nvim_win_close(state.float_win, true)
    state.float_win = nil
  end
  if state.float_buf and vim.api.nvim_buf_is_valid(state.float_buf) then
    vim.api.nvim_buf_delete(state.float_buf, { force = true })
    state.float_buf = nil
  end

  -- Create fresh buffer
  state.float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.float_buf, 0, -1, false, display_lines)
  vim.bo[state.float_buf].modifiable = false
  vim.bo[state.float_buf].bufhidden = 'wipe'

  -- Build footer with keymaps
  local footer_parts = { 'q:close' }
  if state.has_errors and #state.last_errors > 0 then
    table.insert(footer_parts, 'e:error')
  end
  table.insert(footer_parts, 'l:log')
  table.insert(footer_parts, 'r:run')
  table.insert(footer_parts, 'y:copy')
  table.insert(footer_parts, '<leader>cg:config')
  local footer = ' ' .. table.concat(footer_parts, '  ') .. ' '

  -- Create window with footer
  state.float_win = vim.api.nvim_open_win(state.float_buf, true, { -- true = enter window
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    style = 'minimal',
    border = config.float.border,
    title = ' C++ ',
    title_pos = 'center',
    footer = footer,
    footer_pos = 'center',
  })

  -- Set highlight
  if hl_group then
    vim.wo[state.float_win].winhl = 'Normal:Normal,FloatBorder:' .. hl_group .. ',FloatFooter:Comment'
  else
    vim.wo[state.float_win].winhl = 'FloatFooter:Comment'
  end

  -- Setup keymaps
  setup_float_keymaps(state.float_buf)
end

function M.close_float()
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
    vim.api.nvim_win_close(state.float_win, true)
    state.float_win = nil
  end
  if state.float_buf and vim.api.nvim_buf_is_valid(state.float_buf) then
    vim.api.nvim_buf_delete(state.float_buf, { force = true })
    state.float_buf = nil
  end
end

-- Focus the float window (jump back to it)
function M.focus_float()
  if state.float_win and vim.api.nvim_win_is_valid(state.float_win) then
    vim.api.nvim_set_current_win(state.float_win)
  else
    vim.notify('No output window open', vim.log.levels.INFO)
  end
end

-- Jump to first error
function M.jump_to_error()
  if #state.last_errors == 0 then
    vim.notify('No errors to jump to', vim.log.levels.INFO)
    return
  end

  local err = state.last_errors[1]
  M.close_float()

  -- Check if file exists
  local file_path = err.file
  -- Handle relative paths
  if not vim.fn.filereadable(file_path) and state.source_file then
    local dir = vim.fn.fnamemodify(state.source_file, ':h')
    file_path = dir .. '/' .. err.file
  end

  if vim.fn.filereadable(file_path) == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
    vim.api.nvim_win_set_cursor(0, { err.line, err.col - 1 })
    vim.notify('Error: ' .. err.message, vim.log.levels.ERROR)
  else
    vim.notify('Could not find file: ' .. err.file, vim.log.levels.WARN)
  end
end

-- Close float and open panel
function M.float_to_panel()
  M.close_float()
  M.open_log_panel()
end

-- Log panel (split window)
function M.toggle_log_panel()
  if state.log_win and vim.api.nvim_win_is_valid(state.log_win) then
    vim.api.nvim_win_close(state.log_win, false)
    state.log_win = nil
  else
    M.open_log_panel()
  end
end

function M.open_log_panel()
  if state.log_win and vim.api.nvim_win_is_valid(state.log_win) then
    vim.api.nvim_set_current_win(state.log_win)
    return
  end

  local buf = M.get_log_buf()
  local width = math.floor(vim.o.columns * config.panel.width)

  if config.panel.position == 'right' then
    vim.cmd 'botright vsplit'
  else
    vim.cmd 'topleft vsplit'
  end

  state.log_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.log_win, buf)
  vim.api.nvim_win_set_width(state.log_win, width)

  -- Window options
  vim.wo[state.log_win].number = false
  vim.wo[state.log_win].relativenumber = false
  vim.wo[state.log_win].signcolumn = 'no'
  vim.wo[state.log_win].wrap = true
  vim.wo[state.log_win].cursorline = true

  -- Go back to previous window
  vim.cmd 'wincmd p'

  -- Scroll to bottom
  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(state.log_win, { line_count, 0 })
end

function M.close_log_panel()
  if state.log_win and vim.api.nvim_win_is_valid(state.log_win) then
    vim.api.nvim_win_close(state.log_win, false)
    state.log_win = nil
  end
end

-- Compilation and execution
function M.run(opts)
  opts = opts or {}
  local output_mode = opts.mode or 'float' -- 'float', 'panel', 'both'

  local file_info = get_file_info()

  if not is_cpp_file(file_info.ext) then
    vim.notify('Not a C/C++ file', vim.log.levels.ERROR)
    return
  end

  -- Stop any running job
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end

  -- Reset error state
  state.last_errors = {}
  state.has_errors = false
  state.source_file = file_info.full_path

  -- Save file
  vim.cmd 'silent! write'

  local is_c = file_info.ext == 'c'
  local compiler = is_c and config.compiler.c or config.compiler.cpp
  local flags = build_flags_string(is_c)
  local executable = file_info.dir .. '/' .. file_info.name

  -- Load project config if available
  load_project_config()

  M.add_separator()
  M.append_to_log(file_info.name .. '.' .. file_info.ext, config.icons.building .. ' Building')

  -- Show building status in float
  if output_mode == 'float' or output_mode == 'both' then
    M.show_float({ 'Compiling ' .. file_info.name .. '...' }, config.icons.building .. ' Building', 'DiagnosticInfo', false)
  end

  -- Compile command
  local compile_cmd = string.format('%s %s "%s" -o "%s" 2>&1', compiler, flags, file_info.full_path, executable)

  local compile_output = {}
  local run_output = {}

  -- Start compile job
  state.job_id = vim.fn.jobstart(compile_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(compile_output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(compile_output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          -- Compilation failed
          state.last_errors = parse_errors(compile_output)
          state.has_errors = true

          M.append_to_log('Compilation failed (exit code: ' .. exit_code .. ')', config.icons.error)
          for _, line in ipairs(compile_output) do
            M.append_to_log(line, '')
          end

          if output_mode == 'float' or output_mode == 'both' then
            local display = { 'Compilation failed!' }
            vim.list_extend(display, compile_output)
            M.show_float(display, config.icons.error .. ' Build Error', 'DiagnosticError', true)
          end

          if output_mode == 'panel' or output_mode == 'both' then
            M.open_log_panel()
          end

          state.job_id = nil
          return
        end

        M.append_to_log('Build successful', config.icons.success)

        -- Build run command
        local run_cmd
        if state.custom_run_cmd and state.custom_run_cmd ~= '' and state.custom_run_cmd ~= vim.NIL then
          run_cmd = state.custom_run_cmd
        else
          run_cmd = executable
          if state.run_args and state.run_args ~= '' then
            run_cmd = run_cmd .. ' ' .. state.run_args
          end
        end

        M.append_to_log('Running: ' .. run_cmd, config.icons.running)

        -- Run the executable
        state.job_id = vim.fn.jobstart(run_cmd, {
          stdout_buffered = true,
          stderr_buffered = true,
          on_stdout = function(_, data)
            if data then
              for _, line in ipairs(data) do
                if line ~= '' then
                  table.insert(run_output, line)
                end
              end
            end
          end,
          on_stderr = function(_, data)
            if data then
              for _, line in ipairs(data) do
                if line ~= '' then
                  table.insert(run_output, line)
                end
              end
            end
          end,
          on_exit = function(_, run_exit_code)
            vim.schedule(function()
              state.last_output = run_output
              state.job_id = nil

              if #run_output > 0 then
                M.append_to_log('Output:', config.icons.output)
                for _, line in ipairs(run_output) do
                  M.append_to_log(line, '')
                end
              else
                M.append_to_log('(no output)', config.icons.output)
              end

              local status_icon = run_exit_code == 0 and config.icons.success or config.icons.error
              local status_text = run_exit_code == 0 and 'Finished successfully' or 'Exited with code ' .. run_exit_code
              M.append_to_log(status_text, status_icon)

              -- Show output in float
              if output_mode == 'float' or output_mode == 'both' then
                local display = {}
                if #run_output > 0 then
                  vim.list_extend(display, run_output)
                else
                  table.insert(display, '(no output)')
                end
                table.insert(display, '')
                table.insert(display, status_text)

                local hl = run_exit_code == 0 and 'DiagnosticOk' or 'DiagnosticWarn'
                M.show_float(display, status_icon .. ' Output', hl, false)
              end

              -- Open panel if mode is 'panel' or 'both'
              if output_mode == 'panel' or output_mode == 'both' then
                M.open_log_panel()
              end
            end)
          end,
        })
      end)
    end,
  })
end

function M.run_float()
  M.run { mode = 'float' }
end

function M.run_panel()
  M.run { mode = 'panel' }
end

function M.run_both()
  M.run { mode = 'both' }
end

function M.stop()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    M.append_to_log('Process stopped by user', config.icons.error)
    state.job_id = nil
    vim.notify('C++ process stopped', vim.log.levels.WARN)
  else
    vim.notify('No running process', vim.log.levels.INFO)
  end
end

-- Compile only (no run)
function M.compile(opts)
  opts = opts or {}
  local output_mode = opts.mode or 'float'

  local file_info = get_file_info()

  if not is_cpp_file(file_info.ext) then
    vim.notify('Not a C/C++ file', vim.log.levels.ERROR)
    return
  end

  -- Stop any running job
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end

  -- Reset error state
  state.last_errors = {}
  state.has_errors = false
  state.source_file = file_info.full_path

  -- Save file
  vim.cmd 'silent! write'

  local is_c = file_info.ext == 'c'
  local compiler = is_c and config.compiler.c or config.compiler.cpp
  local flags = build_flags_string(is_c)
  local executable = file_info.dir .. '/' .. file_info.name

  -- Load project config if available
  load_project_config()

  M.add_separator()
  M.append_to_log(file_info.name .. '.' .. file_info.ext, config.icons.building .. ' Compiling')

  if output_mode == 'float' or output_mode == 'both' then
    M.show_float({ 'Compiling ' .. file_info.name .. '...' }, config.icons.building .. ' Compile', 'DiagnosticInfo', false)
  end

  local compile_cmd = string.format('%s %s "%s" -o "%s" 2>&1', compiler, flags, file_info.full_path, executable)
  local compile_output = {}

  state.job_id = vim.fn.jobstart(compile_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(compile_output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(compile_output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        state.job_id = nil

        if exit_code ~= 0 then
          state.last_errors = parse_errors(compile_output)
          state.has_errors = true

          M.append_to_log('Compilation failed (exit code: ' .. exit_code .. ')', config.icons.error)
          for _, line in ipairs(compile_output) do
            M.append_to_log(line, '')
          end

          if output_mode == 'float' or output_mode == 'both' then
            local display = { 'Compilation failed!' }
            vim.list_extend(display, compile_output)
            M.show_float(display, config.icons.error .. ' Build Error', 'DiagnosticError', true)
          end
        else
          M.append_to_log('Compilation successful', config.icons.success)

          if output_mode == 'float' or output_mode == 'both' then
            local display = { 'Compilation successful!', '', 'Binary: ' .. executable }
            if #compile_output > 0 then
              table.insert(display, '')
              table.insert(display, 'Warnings:')
              vim.list_extend(display, compile_output)
            end
            M.show_float(display, config.icons.success .. ' Compiled', 'DiagnosticOk', false)
          end
        end

        if output_mode == 'panel' or output_mode == 'both' then
          M.open_log_panel()
        end
      end)
    end,
  })
end

function M.compile_float()
  M.compile { mode = 'float' }
end

-- Set run arguments
function M.set_run_args()
  vim.ui.input({
    prompt = 'Run arguments: ',
    default = state.run_args or '',
  }, function(input)
    if input ~= nil then
      state.run_args = input
      if input == '' then
        vim.notify('Run arguments cleared', vim.log.levels.INFO)
      else
        vim.notify('Run arguments set: ' .. input, vim.log.levels.INFO)
      end
    end
  end)
end

-- Set custom run command (overrides default executable)
function M.set_run_cmd()
  local file_info = get_file_info()
  local default_cmd = file_info.dir .. '/' .. file_info.name
  if state.run_args and state.run_args ~= '' then
    default_cmd = default_cmd .. ' ' .. state.run_args
  end

  local current_cmd = (state.custom_run_cmd and state.custom_run_cmd ~= vim.NIL) and state.custom_run_cmd or default_cmd
  vim.ui.input({
    prompt = 'Run command: ',
    default = current_cmd,
  }, function(input)
    if input ~= nil then
      if input == '' or input == default_cmd then
        state.custom_run_cmd = nil
        vim.notify('Using default run command', vim.log.levels.INFO)
      else
        state.custom_run_cmd = input
        vim.notify('Custom run command set: ' .. input, vim.log.levels.INFO)
      end
    end
  end)
end

-- Clear custom run settings
function M.clear_run_settings()
  state.run_args = ''
  state.custom_run_cmd = nil
  vim.notify('Run settings cleared', vim.log.levels.INFO)
end

-- Get current run info
function M.show_run_info()
  local file_info = get_file_info()
  local is_c = file_info.ext == 'c'
  local executable = file_info.dir .. '/' .. file_info.name

  -- Load config
  load_project_config()

  local mode_label = project_config.build_mode == 'debug' and 'Debug' or 'Release'
  local info = { 'Current configuration:' }
  table.insert(info, '')
  table.insert(info, 'Build Mode: ' .. mode_label)
  table.insert(info, 'Compiler: ' .. (is_c and config.compiler.c or config.compiler.cpp))
  table.insert(info, 'Flags: ' .. build_flags_string(is_c))
  table.insert(info, '')
  table.insert(info, 'Executable: ' .. executable)
  table.insert(info, 'Arguments: ' .. (state.run_args ~= '' and state.run_args or '(none)'))
  if state.custom_run_cmd and state.custom_run_cmd ~= vim.NIL then
    table.insert(info, 'Custom cmd: ' .. state.custom_run_cmd)
  end
  table.insert(info, '')
  local config_loaded = vim.fn.filereadable(get_config_file_path()) == 1
  table.insert(info, 'Config: ' .. (config_loaded and get_config_file_path() or '(defaults)'))

  M.show_float(info, ' Config', 'DiagnosticInfo', false)
end

-- Setup keymaps
local function setup_keymaps()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'cpp', 'c', 'cc', 'cxx' },
    callback = function()
      local opts = { buffer = true, silent = true }

      vim.keymap.set('n', '<leader>cr', M.run_float, vim.tbl_extend('force', opts, { desc = 'Run (float)' }))
      vim.keymap.set('n', '<leader>cR', M.run_panel, vim.tbl_extend('force', opts, { desc = 'Run (panel)' }))
      vim.keymap.set('n', '<leader>cb', M.run_both, vim.tbl_extend('force', opts, { desc = 'Run (both)' }))
      vim.keymap.set('n', '<leader>cc', M.compile_float, vim.tbl_extend('force', opts, { desc = 'Compile only' }))
      vim.keymap.set('n', '<leader>cp', M.set_run_args, vim.tbl_extend('force', opts, { desc = 'Set run params' }))
      vim.keymap.set('n', '<leader>cC', M.set_run_cmd, vim.tbl_extend('force', opts, { desc = 'Set run command' }))
      vim.keymap.set('n', '<leader>c?', M.show_run_info, vim.tbl_extend('force', opts, { desc = 'Show run config' }))
      vim.keymap.set('n', '<leader>cg', M.open_config, vim.tbl_extend('force', opts, { desc = 'Config popup' }))
      vim.keymap.set('n', '<leader>cl', M.toggle_log_panel, vim.tbl_extend('force', opts, { desc = 'Toggle log panel' }))
      vim.keymap.set('n', '<leader>cL', M.clear_log, vim.tbl_extend('force', opts, { desc = 'Clear log' }))
      vim.keymap.set('n', '<leader>cs', M.stop, vim.tbl_extend('force', opts, { desc = 'Stop process' }))
      vim.keymap.set('n', '<leader>cq', M.close_float, vim.tbl_extend('force', opts, { desc = 'Close output float' }))
      vim.keymap.set('n', '<leader>co', M.focus_float, vim.tbl_extend('force', opts, { desc = 'Focus output float' }))
      vim.keymap.set('n', '<leader>ce', M.jump_to_error, vim.tbl_extend('force', opts, { desc = 'Jump to error' }))
    end,
  })
end

-- Initialize
setup_keymaps()

-- Expose module for global access
_G.CppRunner = M

return {}
