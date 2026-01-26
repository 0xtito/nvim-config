-- C/C++ development enhancements with clangd_extensions
return {
  {
    'p00f/clangd_extensions.nvim',
    lazy = true,
    ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    opts = {
      inlay_hints = {
        inline = true,
        only_current_line = false,
        only_current_line_autocmd = { 'CursorHold' },
        show_parameter_hints = true,
        parameter_hints_prefix = '<- ',
        other_hints_prefix = '=> ',
        max_len_align = false,
        max_len_align_padding = 1,
        right_align = false,
        right_align_padding = 7,
        highlight = 'Comment',
        priority = 100,
      },
      ast = {
        role_icons = {
          type = '',
          declaration = '',
          expression = '',
          specifier = '',
          statement = '',
          ['template argument'] = '',
        },
        kind_icons = {
          Compound = '',
          Recovery = '',
          TranslationUnit = '',
          PackExpansion = '',
          TemplateTypeParm = '',
          TemplateTemplateParm = '',
          TemplateParamObject = '',
        },
        highlights = {
          detail = 'Comment',
        },
      },
      memory_usage = {
        border = 'rounded',
      },
      symbol_info = {
        border = 'rounded',
      },
    },
    config = function(_, opts)
      require('clangd_extensions').setup(opts)

      -- Keymaps for clangd_extensions features
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('clangd-extensions-attach', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == 'clangd' then
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = args.buf, desc = 'C++: ' .. desc })
            end

            -- Switch between source/header
            map('<leader>ch', '<cmd>ClangdSwitchSourceHeader<cr>', 'Switch Source/Header')
            -- Show AST
            map('<leader>cA', '<cmd>ClangdAST<cr>', 'Show AST')
            -- Show symbol info
            map('<leader>ci', '<cmd>ClangdSymbolInfo<cr>', 'Symbol Info')
            -- Show type hierarchy
            map('<leader>cH', '<cmd>ClangdTypeHierarchy<cr>', 'Type Hierarchy')
            -- Show memory usage
            map('<leader>cm', '<cmd>ClangdMemoryUsage<cr>', 'Memory Usage')
          end
        end,
      })
    end,
  },
}
