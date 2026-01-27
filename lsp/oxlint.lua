--- @brief
---
--- https://github.com/oxc-project/oxc
---
--- `oxc` is a linter / formatter for JavaScript / Typescript supporting over 500 rules from ESLint and its popular plugins
--- It can be installed via `npm`:
---
--- ```sh
--- npm i -g oxlint
--- ```
---
--- The default `on_attach` function provides an `:LspOxlintFixAll` command which
--- can be used to fix all fixable diagnostics. See the `eslint` config entry for
--- an example of how to use this to automatically fix all errors on write.

local util = require 'lspconfig.util'

---@type vim.lsp.Config
return {
  cmd = { 'oxlint', '--lsp' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root_markers = util.insert_package_json({ '.oxlintrc.json' }, 'oxlint', fname)
    on_dir(vim.fs.dirname(vim.fs.find(root_markers, { path = fname, upward = true })[1]))
  end,
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspOxlintFixAll', function()
      client:exec_cmd({
        title = 'Fix all Oxlint diagnostics',
        command = 'oxc.fixAll',
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
          },
        },
      }, { bufnr = bufnr })
    end, { desc = 'Fix all Oxlint diagnostics' })
  end,
}
