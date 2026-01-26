return {
  {
    'Olical/conjure',
    ft = { 'clojure', 'scheme' }, -- etc
    lazy = true,
    init = function()
      -- Set configuration options here
      -- Uncomment this to get verbose logging to help diagnose internal Conjure issues
      -- This is VERY helpful when reporting an issue with the project
      -- vim.g["conjure#debug"] = true
      -- Disable tree-sitter completion for scheme (causes errors)
      vim.g['conjure#extract#tree_sitter#enabled'] = false
      -- Or disable it only for scheme:
      -- vim.g["conjure#client#scheme#stdio#tree_sitter#enabled"] = false

      vim.g['conjure#mapping#doc_word'] = false
    end,

    -- Optional cmp-conjure integration
    dependencies = { 'PaterJason/cmp-conjure' },
  },
  {
    'PaterJason/cmp-conjure',
    ft = { 'clojure', 'scheme' }, -- etc
    lazy = true,
    config = function()
      local cmp = require 'cmp'
      local config = cmp.get_config()
      table.insert(config.sources, { name = 'conjure' })
      return cmp.setup(config)
    end,
  },
  -- {
  --   'eraserhd/parinfer-rust',
  --   ft = { 'scheme', 'clojure', 'lisp' },
  --   build = 'cargo build --release',
  -- },
}
