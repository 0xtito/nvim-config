return {
  'sudo-tee/opencode.nvim',
  config = function()
    require('opencode').setup {
      prefered_picker = nil, -- 'telescope', 'fzf', 'mini.pick', 'snacks', if nil, it will use the best available picker
      default_global_keymaps = false, -- If false, disables all default global keymaps
      default_mode = 'build', -- 'build' or 'plan' or any custom configured. @see [OpenCode Agents](https://opencode.ai/docs/modes/)
      config_file_path = nil, -- Path to opencode configuration file if different from the default `~/.config/opencode/config.json` or `~/.config/opencode/opencode.json`
      keymap_prefix = '<leader>o',
      keymap = {
        editor = {
          ['<leader>oa'] = { 'toggle' },
          ['<leader>oi'] = { 'open_input' },
          ['<leader>oI'] = { 'open_input_new_session' },
          ['<leader>oo'] = { 'open_output' },
          ['<leader>ot'] = { 'toggle_focus' },
          ['<leader>oq'] = { 'close' },
          ['<leader>os'] = { 'select_session' },
          ['<leader>op'] = { 'configure_provider' },
          ['<leader>od'] = { 'diff_open' },
          ['<leader>o]'] = { 'diff_next' },
          ['<leader>o['] = { 'diff_prev' },
          ['<leader>oc'] = { 'diff_close' },
          ['<leader>ora'] = { 'diff_revert_all_last_prompt' },
          ['<leader>ort'] = { 'diff_revert_this_last_prompt' },
          ['<leader>orA'] = { 'diff_revert_all' },
          ['<leader>orT'] = { 'diff_revert_this' },
          ['<leader>orr'] = { 'diff_restore_snapshot_file' },
          ['<leader>orR'] = { 'diff_restore_snapshot_all' },
          ['<leader>ox'] = { 'swap_position' },
          ['<leader>opa'] = { 'permission_accept' },
          ['<leader>opA'] = { 'permission_accept_all' },
          ['<leader>opd'] = { 'permission_deny' },
        },
        input_window = {
          ['<cr>'] = { 'submit_input_prompt', mode = { 'n', 'i' } },
          ['<esc>'] = { 'close' },
          ['<C-c>'] = { 'stop' },
          ['@'] = { 'mention', mode = 'i' },
          ['/'] = { 'slash_commands', mode = 'i' },
          ['<tab>'] = { 'toggle_pane', mode = { 'n', 'i' } },
          ['<up>'] = { 'prev_prompt_history', mode = { 'n', 'i' } },
          ['<down>'] = { 'next_prompt_history', mode = { 'n', 'i' } },
          ['<M-m>'] = { 'switch_mode' },
        },
        output_window = {
          ['<esc>'] = { 'close' },
          ['<C-c>'] = { 'stop' },
          [']]'] = { 'next_message' },
          ['[['] = { 'prev_message' },
          ['<tab>'] = { 'toggle_pane', mode = { 'n', 'i' } },
          ['<C-i>'] = { 'focus_input' },
          ['<leader>oS'] = { 'select_child_session' },
          ['<leader>oD'] = { 'debug_message' },
          ['<leader>oO'] = { 'debug_output' },
          ['<leader>ods'] = { 'debug_session' },
        },
        permission = {
          accept = 'a',
          accept_all = 'A',
          deny = 'd',
        },
      },
      ui = {
        position = 'right', -- 'right' (default) or 'left'. Position of the UI split
        input_position = 'bottom', -- 'bottom' (default) or 'top'. Position of the input window
        window_width = 0.40, -- Width as percentage of editor width
        input_height = 0.15, -- Input height as percentage of window height
        display_model = true, -- Display model name on top winbar
        display_context_size = true, -- Display context size in the footer
        display_cost = true, -- Display cost in the footer
        window_highlight = 'Normal:OpencodeBackground,FloatBorder:OpencodeBorder', -- Highlight group for the opencode window
        icons = {
          preset = 'text', -- 'emoji' | 'text'. Choose UI icon style (default: 'emoji')
          overrides = {}, -- Optional per-key overrides, see section below
        },
        output = {
          tools = {
            show_output = true, -- Show tools output [diffs, cmd output, etc.] (default: true)
          },
        },
        input = {
          text = {
            wrap = false, -- Wraps text inside input window
          },
        },
      },
      context = {
        cursor_data = true, -- send cursor position and current line to opencode
        diagnostics = {
          info = true, -- Include diagnostics info in the context (default to false
          warn = true, -- Include diagnostics warnings in the context
          error = true, -- Include diagnostics errors in the context
        },
      },
      debug = {
        enabled = false, -- Enable debug messages in the output window
      },
    }
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        anti_conceal = { enabled = false },
        file_types = { 'markdown', 'opencode_output' },
      },
      ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
    },
    -- Optional, for file mentions and commands completion, pick only one
    'saghen/blink.cmp',
    -- 'hrsh7th/nvim-cmp',

    -- Optional, for file mentions picker, pick only one
    'folke/snacks.nvim',
    -- 'nvim-telescope/telescope.nvim',
    -- 'ibhagwan/fzf-lua',
    -- 'nvim_mini/mini.nvim',
  },
  -- event = 'VeryLazy',
  -- lazy = true,
  keys = {
    {
      '<leader>oa',
      function()
        require('opencode.api').toggle()
      end,
      desc = 'Toggle opencode',
    },
    {
      '<leader>oi',
      function()
        require('opencode.api').open_input()
      end,
      desc = 'Open input',
    },
    {
      '<leader>oI',
      function()
        require('opencode.api').open_input_new_session()
      end,
      desc = 'Open input (new session)',
    },
    {
      '<leader>oo',
      function()
        require('opencode.api').open_output()
      end,
      desc = 'Open output',
    },
  },
}
