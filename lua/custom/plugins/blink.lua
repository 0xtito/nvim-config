return {
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets', 'fang2hou/blink-copilot' },
    version = '1.*',
    opts = {
      enabled = function()
        return not vim.tbl_contains({ 'lua', 'markdown' }, vim.bo.filetype)
      end,
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      sources = {
        -- default = { 'jupynium', 'lsp', 'path', 'snippets', 'buffer', 'copilot' },
        default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot' },
        per_filetype = {
          sql = { 'snippets', 'dadbod', 'buffer' },
        },
        providers = {
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' },
          copilot = {
            name = 'copilot',
            module = 'blink-copilot',
            score_offset = 100,
            async = true,
          },
          -- jupynium = {
          --   name = 'Jupynium',
          --   module = 'jupynium.blink_cmp',
          --   -- Consider higher priority than LSP
          --   score_offset = 1000,
          -- },
        },
      },
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { 'lsp' },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = vim.g.ai_cmp,
        },
      },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      signature = { enabled = true },
    },
    -- opts_extend = { 'sources.default' },
  },
}
