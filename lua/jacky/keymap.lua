vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set(
  'n',
  '[d',
  '<Cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})<CR>',
  { desc = 'Go to previous [D]diagnostic message' }
)
vim.keymap.set('n', ']d', '<Cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})<CR>', { desc = 'Go to next [D]diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]error messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setqflist, { desc = 'Open diagnostic [Q]quickfix list' })
vim.keymap.set('n', '[q', '<cmd>cprev<cr>', { desc = 'Go to prev [Q]quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>', { desc = 'Go to next [Q]quickfix item' })

vim.keymap.set('n', 'z/', function()
  vim.bo.filetype = 'terminal'
  vim.o.wrap = true
end)

-- Navigate vim panes without Ctrl-w
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>', { silent = true })
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>', { silent = true })
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>', { silent = true })
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>', { silent = true })

vim.keymap.set('n', '<a-s>', '<CMD>horizontal terminal<CR>', { silent = true })
vim.keymap.set('n', '<a-v>', '<CMD>vertical terminal<CR>', { silent = true })

vim.keymap.set('t', '<c-h>', '<c-\\><c-n><c-w>h<cr>', { silent = true })
vim.keymap.set('t', '<c-j>', '<c-\\><c-n><c-w>j<cr>', { silent = true })
vim.keymap.set('t', '<c-k>', '<c-\\><c-n><c-w>k<cr>', { silent = true })
vim.keymap.set('t', '<c-l>', '<c-\\><c-n><c-w>l<cr>', { silent = true })

vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })
vim.keymap.set('n', '}', '}zz', { silent = true })
vim.keymap.set('n', '{', '{zz', { silent = true })
vim.keymap.set('n', '<c-u>', '<c-u>zz', { silent = true })
vim.keymap.set('n', '<c-d>', '<c-d>zz', { silent = true })
vim.keymap.set('n', '<c-b>', '<c-b>zz', { silent = true })
vim.keymap.set('n', '<c-f>', '<c-f>zz', { silent = true })

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('nvim-terminal', { clear = true }),
  callback = function(_)
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.cmd.startinsert()
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'term://*',
  group = vim.api.nvim_create_augroup('nvim-terminal-enter', { clear = true }),
  callback = function(_)
    vim.cmd.startinsert()
  end,
})

vim.keymap.set('n', '<a-r>', '<cmd>source %<cr>', { desc = 'Reload current file' })
vim.keymap.set('n', '<leader>x', ':.lua<CR>')
vim.keymap.set('v', '<leader>x', ':lua<CR>')

vim.api.nvim_create_user_command('SortLines', function()
  local start_row = vim.api.nvim_buf_get_mark(0, '<')[1]
  local end_row = vim.api.nvim_buf_get_mark(0, '>')[1]

  if start_row > end_row then
    end_row, start_row = start_row, end_row
  end

  local selected_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)

  local sorted_lines = vim.fn.sort(selected_lines)
  vim.api.nvim_buf_set_lines(0, start_row, end_row, false, sorted_lines)
end, { desc = 'sort the selected lines', range = 2 })
