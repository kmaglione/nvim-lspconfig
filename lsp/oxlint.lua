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
--- Type-aware linting will automatically be enabled if `tsgolint` exists in your
--- path and your `.oxlintrc.json` contains the string "typescript".
---
--- The default `on_attach` function provides an `:LspOxlintFixAll` command which
--- can be used to fix all fixable diagnostics. See the `eslint` config entry for
--- an example of how to use this to automatically fix all errors on write.

local util = require 'lspconfig.util'

local function oxlint_conf_mentions_typescript(root_dir)
  local fn = vim.fs.joinpath(root_dir, '.oxlintrc.json')
  for line in io.lines(fn) do
    if line:find('typescript') then
      return true
    end
  end
  return false
end

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
  before_init = function(init_params, config)
    local settings = config.settings or {}
    if settings.typeAware == nil and vim.fn.executable('tsgolint') == 1 then
      local ok, res = pcall(oxlint_conf_mentions_typescript, config.root_dir)
      if ok and res then
        settings = vim.tbl_extend('force', settings, { typeAware = true })
      end
    end
    local init_options = config.init_options or {}
    init_options.settings = vim.tbl_extend('force', init_options.settings or {} --[[@as table]], settings)

    init_params.initializationOptions = init_options
  end,
}
