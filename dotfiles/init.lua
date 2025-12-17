-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- Commenting plugin
    'preservim/nerdcommenter',

    -- Surround text objects
    'tpope/vim-surround',

    -- Telescope fuzzy finder with dependencies
    {
      'nvim-telescope/telescope.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons', -- Optional but recommended
      },
      config = function()
        require('telescope').setup({})
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
      end
    },

    -- Treesitter syntax highlighting
    {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate'
    },

    -- Zettelkasten note-taking
    {
      'zk-org/zk-nvim',
      dependencies = {
        'nvim-lua/plenary.nvim', -- Already included above with telescope
      }
    },

    -- LSP configuration with Mason
    {
      'neovim/nvim-lspconfig',
      dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
      }
    },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true, notify = false },
  rocks = { enabled = false },
})

vim.cmd [[
  set nocompatible
  filetype off

  " Use color syntax highlighting.
  syntax on

  " Search ignores case
  set smartcase

  " Copy to clipboard with +y
  set clipboard+=unnamedplus

  "my tabs
  set tabstop=2
  set shiftwidth=2
  set softtabstop=2
  set expandtab

  "4 space tabs for C/C++
  autocmd Filetype cpp setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
  autocmd Filetype c setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
]]

-- map F12 in normal mode to toggle paste
local function toggle_paste()
  -- flip the paste setting
  vim.opt.paste = not vim.opt.paste:get()
  -- echo the new state
  print("paste mode: " .. (vim.opt.paste:get() and "ON" or "OFF"))
end

vim.keymap.set("n", "<F12>", toggle_paste, {
  noremap = true,
  silent = true,
  desc = "Toggle paste mode"
})

-- Mason setup for automatic server installation
require('mason').setup({
  ui = {
    border = 'rounded',
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

require('mason-lspconfig').setup({
  ensure_installed = {
    'pyright',
    'ruff',
  },
  automatic_installation = true,
})

-- set up LSP
-- Enable pyright using lspconfig's built-in configuration
-- This automatically handles cmd, filetypes, root detection, etc.
vim.lsp.enable({
  --python
  'pyright',
  'ruff',
})

-- Diagnostic configuration
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    spacing = 4,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    focusable = false,
    style = 'minimal',
    border = 'rounded',
    source = 'always',
  },
})

-- Key mappings function
local function setup_keymaps(client, bufnr)

  local function keymap(lhs, rhs, opts, mode)
    opts = type(opts) == 'string' and { desc = opts }
      or vim.tbl_extend('error', opts, { buffer = bufnr })
    mode = mode or 'n'
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  local opts = { noremap = true, silent = true, buffer = bufnr }
        -- Navigation
  keymap('gd', vim.lsp.buf.definition, 'Go to definition')
  keymap('gD', vim.lsp.buf.declaration, 'Go to declaration')
  keymap('gr', vim.lsp.buf.references, 'Show references')
  keymap('gi', vim.lsp.buf.implementation, 'Go to implementation')
  
  -- Documentation
  keymap('K', vim.lsp.buf.hover, 'Show hover documentation')
  keymap('<C-k>', vim.lsp.buf.signature_help, 'Show signature help', 'i')
  
  -- Code actions
  keymap('<leader>ca', vim.lsp.buf.code_action, 'Code actions')
  keymap('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
  
  -- Diagnostics
  keymap('[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
  keymap(']d', vim.diagnostic.goto_next, 'Next diagnostic')
  keymap('<leader>d', vim.diagnostic.open_float, 'Show diagnostic')
  keymap('<leader>q', vim.diagnostic.setloclist, 'Diagnostic list')
  
  -- Formatting
  keymap('<leader>f', function()
    vim.lsp.buf.format({ async = true })
  end, 'Format buffer')
end

-- Set up keymaps when LSP attaches to any buffer
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    setup_keymaps(client, args.buf)
  end,
})

-- set up zk
require("zk").setup({
  -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
  -- or select" (`vim.ui.select`).
  picker = "telescope",

  lsp = {
    -- `config` is passed to `vim.lsp.start(config)`
    config = {
      name = "zk",
      cmd = { "zk", "lsp" },
      filetypes = { "markdown" },
      -- on_attach = ...
      -- etc, see `:h vim.lsp.start()`
    },

    -- automatically attach buffers in a zk notebook that match the given filetypes
    auto_attach = {
      enabled = true,
    },
  },
})
