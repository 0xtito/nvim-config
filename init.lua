--- Neovim configuration file ---

function _G.config_path(dir, ...)
  local sep = package.config:sub(1, 1)
  local segments = { dir, ... }
  return table.concat(segments, sep):gsub('[\\/]', sep)
end

vim.o.exrc = true

-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.encoding = 'utf-8'
vim.opt.fileencoding = 'utf-8'

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- setting which os im on to a global var

if vim.fn.exists 'g:os' == 0 then
  local is_windows = vim.fn.has 'win64' == 1 or vim.fn.has 'win32' == 1
  if is_windows then
    vim.g.os = 'Windows'
    vim.g.SUPER = 'C'

    -- Check if 'pwsh' is executable, otherwise use 'powershell'
    local powershell_options = {
      shell = vim.fn.executable 'pwsh' == 1 and 'pwsh' or 'powershell',
      shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;',
      -- shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait',
      shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode',
      shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode',
      shellquote = '',
      shellxquote = '',
    }

    for option, value in pairs(powershell_options) do
      vim.opt[option] = value
    end
  else
    local uname_output = vim.fn.system 'uname'
    if uname_output:find 'Darwin' then
      vim.g.os = 'MacOS'
      vim.g.SUPER = 'D'
    else
      vim.g.os = string.gsub(uname_output, '\n', '')
      vim.g.SUPER = 'C'
    end
  end
end

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- vim.cmd.colorscheme 'vim'
vim.o.termguicolors = true

vim.opt.guicursor = 'n-v-c:block,i-ci-ve:block,r-cr-o:block,sm:block'

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  -- if vim.fn.has 'clipboard' == 1 then
  vim.opt.clipboard = 'unnamedplus'
  -- end
end)
-- vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
-- vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.listchars = { tab = '| ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 8

-- Limit completions to 8 items at a time
-- vim.opt.pumheight = 8
vim.opt.pumwidth = 24

-- Removing swap file and backup file
vim.opt.swapfile = false
vim.opt.backup = false

-- Delete lines containing whatever input is given
vim.keymap.set('n', '<leader>dL', function()
  local text_to_delete = vim.fn.input 'Delete lines containing: '
  if text_to_delete ~= '' then
    vim.cmd(string.format('g/%s/d', vim.fn.escape(text_to_delete, '/\\')))
  end
end, { desc = '[D]elete [L]ines containing' })

-- Define the function to replace strings with case sensitivity
function ReplaceStrings(old_str, new_str)
  -- Get the current buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Replace the old_str with new_str in each line
  for i, line in ipairs(lines) do
    lines[i] = line:gsub(old_str, new_str)
  end

  -- Set the modified lines back to the buffer
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end
-- Create a command to call the function with arguments
vim.api.nvim_create_user_command('ReplaceWithArgs', function(opts)
  local old_str = opts.fargs[1]
  local new_str = opts.fargs[2]
  ReplaceStrings(old_str, new_str)
end, { desc = 'Replace strings' })

-- Bind the command to <leader>rW
vim.keymap.set('n', '<leader>rW', ':ReplaceWithArgs ', { silent = false, desc = 'Replace strings with args' })

local function replace_highlighted()
  return function()
    -- Get the highlighted text
    local start_pos = vim.fn.getpos "'<"
    local end_pos = vim.fn.getpos "'>"
    local lines = vim.fn.getline(start_pos[2], end_pos[2])
    local n = #lines
    if n == 0 then
      return
    end

    lines[1] = string.sub(lines[1], start_pos[3], -1)
    lines[n] = string.sub(lines[n], 1, end_pos[3] - ((start_pos[2] == end_pos[2]) and start_pos[3] or 0))
    local highlighted_text = table.concat(lines, '\n')

    -- Escape special characters in the highlighted text
    highlighted_text = vim.fn.escape(highlighted_text, [[\/.*~$]])

    -- Prompt for replacement text
    local replacement = vim.fn.input 'Replace with: '

    -- Perform the replacement
    vim.cmd(string.format('%%s/\\V%s/%s/g', highlighted_text, replacement))
  end
end

-- Set up the keybinding
vim.keymap.set('v', '<leader>RA', replace_highlighted(), { noremap = true, silent = true })

-- Easily navigate through panes
vim.keymap.set('n', '<' .. vim.g.SUPER .. '-k>', '<' .. vim.g.SUPER .. '-w>k', { silent = true, desc = 'Move to the split above' })
vim.keymap.set('n', '<' .. vim.g.SUPER .. '-j>', '<' .. vim.g.SUPER .. '-w>j', { silent = true, desc = 'Move to the split below' })
vim.keymap.set('n', '<' .. vim.g.SUPER .. '-h>', '<' .. vim.g.SUPER .. '-w>h', { silent = true, desc = 'Move to the split on the left' })
vim.keymap.set('n', '<' .. vim.g.SUPER .. '-l>', '<' .. vim.g.SUPER .. '-w>l', { silent = true, desc = 'Move to the split on the right' })

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Updating Diagnostic config
vim.diagnostic.config {
  underline = true,
  virtual_text = {
    spacing = 4,
    prefix = '',
  },
  signs = true,
  -- update_in_insert = false,
}

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

--
--  See `:help wincmd` for a list of all window commands
-- vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
-- vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
-- vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
-- vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

pcall(require, 'vim.loader') -- Neovim ≥0.9

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  --  This is equivalent to:
  --    require('Comment').setup({})

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `config` key, the configuration only runs
  -- after the plugin has been loaded:
  --  config = function() ... end

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      mappings = vim.g.have_nerd_font,

      keys = vim.g.have_nerd_font and {} or {
        Up = '<Up> ',
        Down = '<Down> ',
        Left = '<Left> ',
        Right = '<Right> ',
        C = '<C-…> ',
        M = '<M-…> ',
        D = '<D-…> ',
        S = '<S-…> ',
        CR = '<CR> ',
        Esc = '<Esc> ',
        ScrollWheelDown = '<ScrollWheelDown> ',
        ScrollWheelUp = '<ScrollWheelUp> ',
        NL = '<NL> ',
        BS = '<BS> ',
        Space = '<Space> ',
        Tab = '<Tab> ',
        F1 = '<F1>',
        F2 = '<F2>',
        F3 = '<F3>',
        F4 = '<F4>',
        F5 = '<F5>',
        F6 = '<F6>',
        F7 = '<F7>',
        F8 = '<F8>',
        F9 = '<F9>',
        F10 = '<F10>',
        F11 = '<F11>',
        F12 = '<F12>',
      },
    },

    spec = {
      { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
      { '<leader>d', group = '[D]ocument' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>s', group = '[S]earch' },
      { '<leader>w', group = '[W]orkspace' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>gh', group = '[G]it [H]unk', mode = { 'n', 'v' } },
      { '<leader>h', group = '[H]arpoon', mode = { 'n' } },
      { '<leader>a', group = '[A]I', mode = { 'n' } },
      { '<leader>z', group = '[Z]en Mode', mode = { 'n' } },
      { '<leader>o', group = '[O]pen Scratch Pad', mode = { 'n' } },
      { '<leader>T', group = '[T]oggleterm', mode = { 'n' } },
    },
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      --[[ ---- SEARCH GROUP ---- ]]
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>st', builtin.builtin, { desc = '[S]earch Select [T]elescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sR', builtin.resume, { desc = '[S]earch [R]esume' })

      vim.keymap.set('n', '<leader>sT', ':TodoTelescope<CR>', { desc = '[S]earch [T]odos' })

      vim.keymap.set('n', '<leader>sr', function()
        builtin.lsp_references {
          layout_strategy = 'vertical',
          layout_config = {
            vertical = {
              width = 0.95,
              height = 0.90,
              preview_cutoff = 10,
              prompt_position = 'bottom',
              preview_height = 0.65,
            },
          },
          sorting_strategy = 'ascending',
          show_line = false,
          -- prompt_prefix = '',
          -- selection_caret = '',
          -- entry_prefix = '',
          -- initial_mode = 'normal',
          -- include_declaration = false,
          -- include_current_line = true,
        }
      end, { desc = '[S]earch [R]eferences (Hover)' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>si', builtin.lsp_implementations, { desc = '[S]earch [I]mplementations (Hover)' })

      -- LSP Workspace Symbols
      vim.keymap.set('n', '<leader>sw', builtin.lsp_dynamic_workspace_symbols, { desc = '[S]earch [L]SP Workspace Symbols' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },

  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'saghen/blink.cmp',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- 'hrsh7th/cmp-nvim-lsp', -- Autocompletion plugin

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      -- { 'folke/neodev.nvim', opts = {} },
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      -- vim.keymap.set('i', '<C-Space', '<D-Space>', { expr = true })

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local builtin = require 'telescope.builtin'

          map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')

          -- Find references for the word under your cursor.
          map('gr', builtin.lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>D', builtin.lsp_type_definitions, 'Type [D]efinition')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          -- map('<leader>ws', tele_builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

          -- Opens a popup that displays documentation about the word under your cursor
          --  See `:help K` for why this keymap.
          map('K', vim.lsp.buf.hover, 'Hover Documentation')

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Disable formatting for jsonls - we use prettier instead
          if client and client.name == 'jsonls' then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      --  ----- WITH nvim-cmp -----
      -- local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      local capabilities = vim.lsp.protocol.make_client_capabilities()

      capabilities = vim.tbl_deep_extend('force', capabilities, require('blink.cmp').get_lsp_capabilities({}, false))

      capabilities = vim.tbl_deep_extend('force', capabilities, {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
        general = {
          positionEncodings = { 'utf-16' },
        },
      })

      -- Find the pythonPath for the current environment
      local get_python_path = function()
        local cur_py_path = vim.fn.system('which python'):gsub('\n', '')

        local in_conda = vim.fn.system('echo $CONDA_DEFAULT_ENV'):gsub('\n', '') ~= ''

        if in_conda and string.match(cur_py_path, 'OH%-main') then
          local py_version = vim.fn.system('python --version'):gsub('\n', ''):match ' (.+)'
          local po = vim.fn.system('poetry env use ' .. py_version):gsub('\n', '')
          local python_path = po:match(':(.+)$'):gsub('%s+', '')
          return python_path .. '/bin/python'
        end

        -- If no Python found, fall back to system Python
        return vim.fn.exepath 'python3' or vim.fn.exepath 'python' or 'python'
      end

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers =
        {
          clangd = {
            filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
          },
          -- protols = {
          --   filetypes = { 'proto' },
          -- },
          -- gopls = {},
          pyright = {
            settings = {
              pyright = {
                disableOrganizeImports = true, -- Using Ruff
              },
              python = {
                analysis = {
                  -- Ignore all files for analysis to exclusively use Ruff for linting
                  -- ignore = { '*' },
                  typeCheckingMode = 'off', -- Using mypy
                },
                pythonPath = get_python_path(),
              },
            },
            on_init = function(client)
              -- Check for pyrightconfig.json at the project root
              local root_dir = client.config.root_dir
              if root_dir then
                local pyright_config = root_dir .. '/pyrightconfig.json'
                if vim.fn.filereadable(pyright_config) == 1 then
                  -- Log that we found the config file
                  vim.notify('Pyright: Found configuration at ' .. pyright_config, vim.log.levels.INFO)
                  -- Pyright will automatically use the config file, no additional setup needed
                end
              end
              return true
            end,
          },

          lua_ls = {
            -- cmd = {...},
            -- filetypes = { ...},
            -- capabilities = {},
            settings = {
              Lua = {
                completion = {
                  callSnippet = 'Replace',
                },
                -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                -- diagnostics = { disable = { 'missing-fields' } },
              },
            },
          },
        },
        -- Integrating zls with lspconfig, outside of Mason
        require('lspconfig').zls.setup {
          cmd = { 'zls' },
          filetypes = { 'zig', 'zon' },
        }

      -- require('lspconfig').protols.setup {}

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        'pyright', -- Explicitly ensure Pyright is installed
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            local overrides = {}

            if server_name == 'clangd' then
              overrides.offsetEncoding = { 'utf-16' }
            end

            if server_name == 'pylsp' then
              server.on_init = function(client)
                local root_dir = client.workspace_folders and client.workspace_folders[1] and client.workspace_folders[1].name
                if root_dir then
                  local pyproject_toml = root_dir .. '/pyproject.toml'
                  if vim.fn.filereadable(pyproject_toml) == 1 then
                    client.config.settings.pylsp.configurationSources = { 'pyproject' }
                  end
                end
                return true
              end
            end

            server.on_attach = function(client, bufnr)
              require('workspace-diagnostics').populate_workspace_diagnostics(client, bufnr) -- Populate Workspace-Diagnostics plugin information.
            end

            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or overrides)

            require('lspconfig')[server_name].setup(server)
          end,
        },
      }

      local function has_arg(arg)
        for _, v in ipairs(vim.v.argv) do
          if v == arg then
            return true
          end
        end
        return false
      end

      -- setting up gdscript for windows
      local lspconfig = require 'lspconfig'
      local gdscript_config = {
        capabilities = capabilities,
        settings = {},
      }

      if has_arg 'gt' then
        if vim.g.os == 'Windows' then
          gdscript_config['cmd'] = { 'ncat', 'localhost', os.getenv 'GDSCRIPT_PORT' or '6005' }
          lspconfig.gdscript.setup(gdscript_config)
        else
          lspconfig.gdscript.setup {}
          local pipepath = vim.fn.stdpath 'cache' .. '/server.pipe'
          if not vim.loop.fs_stat(pipepath) and vim.fn.filereadable(vim.fn.getcwd() .. '/project.godot') then
            vim.fn.serverstart(pipepath)
          end
        end
      else
        lspconfig.gdscript.setup(gdscript_config)
      end
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>fb',
        function()
          require('conform').format { async = true }
        end,
        mode = '',
        desc = '[F]ormat [b]uffer',
      },
    },
    opts = {
      notify_on_error = false,
      -- Set default options
      default_format_opts = {
        lsp_format = 'fallback',
      },
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true, objc = true, gdscript = false, lua = false, python = true, json = true, jsonc = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 3000, -- Changed from 2000 to 3000 for monorepo overhead
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially

        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        javascript = { 'prettier', stop_after_first = true, prefer_local = 'node_modules/.bin' },
        javascriptreact = { 'prettier', stop_after_first = true, prefer_local = 'node_modules/.bin' },
        typescript = { 'prettier', stop_after_first = true, prefer_local = 'node_modules/.bin' },
        typescriptreact = { 'prettier', stop_after_first = true, prefer_local = 'node_modules/.bin' },
        cpp = { 'clang-format' },
        json = { 'prettier', stop_after_first = true, prefer_local = 'node_modules/.bin' },
        -- c = { 'clang-format' },
        gdscript = { 'gdtoolkit' },
        -- markdown = { 'prettier', 'mdformat', 'cbfmt' },
        -- markdown = { 'mdformat', 'cbfmt' },
      },
      formatters = {
        prettier = {
          command = 'pnpm',
          args = { 'exec', 'prettier', '--stdin-filepath', '$FILENAME' },
          cwd = function(self, ctx)
            return require('conform.util').root_file { 'pnpm-lock.yaml', '.git' }(self, ctx)
          end,
        },
      },
    },
  },

  {
    'folke/ts-comments.nvim',
    opts = {},
    event = 'VeryLazy',
    enabled = vim.fn.has 'nvim-0.10.0' == 1,
  },
  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'vim',
        'vimdoc',
        'javascript',
        'typescript',
        'rust',
        'python',
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },

  require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  { import = 'custom.plugins' },
  {
    'nvzone/typr',
    dependencies = 'nvzone/volt',
    opts = {},
    cmd = { 'Typr', 'TyprStats' },
  },
  -- To integrate with tmux
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
      'TmuxNavigatorProcessList',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

require 'custom'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

if vim.fn.filereadable(vim.fn.getcwd() .. '/project.godot') == 1 and vim.g.os == 'Windows' then
  vim.fn.serverstart '127.0.0.1:6004'
end

-- C++ compile and run functionality moved to lua/custom/plugins/cpp-tmux.lua

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gdscript',
  callback = function()
    vim.keymap.set('n', '<leader>Gr', function()
      vim.cmd 'silent !godot '
    end, { buffer = true, desc = 'Run Godot' })
  end,
})

local function display_time()
  local current_time = os.date '%H:%M:%S'
  vim.api.nvim_echo({ { current_time, 'Normal' } }, false, {})
end

-- NOTE: Mapping to display current time
vim.keymap.set('n', '<leader>tt', display_time, { noremap = true, silent = true })

local scratch_buffer = nil
local last_buffer = nil

local function get_path_separator()
  return vim.loop.os_uname().sysname:match 'Windows' and '\\' or '/'
end

local function open_scratch_buffer()
  local path_sep = get_path_separator()
  local scratch_dir = vim.fn.stdpath 'data' .. path_sep .. 'scratch'
  local scratch_file = scratch_dir .. path_sep .. 'scratch.md'

  -- Create the scratch directory if it doesn't exist
  if vim.fn.isdirectory(scratch_dir) == 0 then
    vim.fn.mkdir(scratch_dir, 'p')
  end

  -- Open the scratch file in a new buffer if it's not already open
  if not scratch_buffer or not vim.api.nvim_buf_is_valid(scratch_buffer) then
    vim.cmd('edit ' .. scratch_file)
    scratch_buffer = vim.api.nvim_get_current_buf()

    -- Set some buffer-local options
    vim.bo[scratch_buffer].filetype = 'markdown'
    vim.bo[scratch_buffer].bufhidden = 'hide'
    vim.bo[scratch_buffer].swapfile = false

    -- vim.cmd 'ZenMode'
  else
    vim.api.nvim_set_current_buf(scratch_buffer)
    -- vim.cmd 'ZenMode'
  end
end

local function toggle_scratch_buffer()
  if vim.api.nvim_get_current_buf() == scratch_buffer then
    if last_buffer and vim.api.nvim_buf_is_valid(last_buffer) then
      vim.api.nvim_set_current_buf(last_buffer)
    else
      vim.cmd 'bnext'
    end
    -- vim.cmd 'ZenMode'
  else
    last_buffer = vim.api.nvim_get_current_buf()
    open_scratch_buffer()
  end
end

-- Set up the keybinding
vim.keymap.set('n', '<leader>q', toggle_scratch_buffer, { desc = 'Toggle scratch pad' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'zig',
  callback = function()
    vim.bo.textwidth = 100
    -- vim.opt.colorcolumn = '100'
  end,
})

-- Set up mapping for avante.nvim
vim.api.nvim_set_keymap('n', '<leader>at', ':AvanteToggle<CR>', { noremap = true, silent = true })
