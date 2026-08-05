return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  -- or if using mini.icons/mini.nvim
  -- dependencies = { "nvim-mini/mini.icons" },
  ---@module "fzf-lua"
  ---@type fzf-lua.Config|{}
  ---@diagnostic disable: missing-fields
  opts = {},
  ---@diagnostic enable: missing-fields
  ---
  config = function()
    local builtin = require 'fzf-lua'
    builtin.setup { 'telescope', winopts = { preview = { default = 'bat' } } }

    vim.keymap.set('n', '<leader>sf', builtin.files, { desc = '[S]Search [F]Files' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]Search by [G]Grep' })

    vim.keymap.set('n', '<leader>sn', function()
      builtin.files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]Search [N]Neovim files' })

    vim.keymap.set('n', '<leader>sp', function()
      builtin.files { cwd = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy') }
    end, { desc = '[S]Search Neovim [P]Plugins files' })
  end,
}
