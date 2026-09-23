-- Laravel LSP (https://github.com/laravel/lsp)
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- nvim-lspconfig ships the config: runs `laravel-lsp` for php and
        -- blade buffers, but only in a project with an `artisan` file.
        laravel_lsp = {
          -- Installed globally by composer (config/composer/composer.json)
          -- so the version lives in this repo, not in mason's state.
          mason = false,
        },
      },
    },
  },
}
