-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 50

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 100

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

-- Set the shiftwidth, which could be inserted with <C-\>> in the visual mode
vim.opt.shiftwidth = 4

-- Set the tab size
vim.opt.tabstop = 4

-- Use space when user types tab
vim.opt.expandtab = true

-- Highlight the column with offset from textwidth
vim.opt.colorcolumn = '+1'

-- Allow :Termdebug
vim.cmd 'packadd termdebug'

-- Termdebug: wide mode enables the vertical split layout, variables window
-- auto-refreshes on each stop. Use wide = 1 (not a large number) so termdebug
-- does NOT force &columns wider than the real terminal; forcing a width makes
-- the gdb terminal reflow/redraw and appear to lose its scrollback.
vim.g.termdebug_config = {
  wide = 1,
  variables_window = 1,
}

-- Highlight the current (stopped) line during :Termdebug.
-- Termdebug marks the stopped line with a 'debugPC' sign that uses the debugPC
-- highlight group. tokyonight overrides debugPC to bg_sidebar (#16161e), which
-- is darker than Normal bg (#1a1b26), so the current line is effectively
-- invisible. Re-set it on every ColorScheme so it survives colorscheme loads
-- and reloads (this fires when tokyonight loads later via lazy).
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('termdebug-pc-highlight', { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, 'debugPC', { bg = '#3d5a40' })
  end,
})
-- Apply immediately in case a colorscheme is already active at this point.
vim.api.nvim_set_hl(0, 'debugPC', { bg = '#3d5a40' })

-- Target layout after :Termdebug (source on the right, debug info stacked left):
--   variables (top-left) | source (right, full height)
--   gdb       (bot-left) |
--
-- Any windows already open when :Termdebug is invoked (splits, file trees, etc.)
-- get folded into termdebug's default layout, so we cannot assume a fixed window
-- structure. Instead we ask termdebug for its own tracked windows via the :Gdb,
-- :Var and :Source commands (authoritative window IDs), close every OTHER window
-- (this only closes windows, buffers stay loaded and listed), then reshape the
-- three remaining windows. Verified to yield row[ col[var, gdb], source ] from a
-- single window, hsplit, vsplit, focused-left, and multi-extra starting states.
vim.api.nvim_create_autocmd('User', {
  pattern = 'TermdebugStartPost',
  callback = function()
    -- Close the program output (pty) window; we don't need program output here
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_name(buf):find('gdb program') then
        pcall(vim.api.nvim_win_close, win, true)
        break
      end
    end

    -- Ask termdebug for its own window IDs (uses s:gdbwin/s:varwin/s:sourcewin)
    vim.cmd 'Gdb'
    local gdb_win = vim.api.nvim_get_current_win()
    vim.cmd 'Var'
    local var_win = vim.api.nvim_get_current_win()
    vim.cmd 'Source'
    local source_win = vim.api.nvim_get_current_win()

    if not vim.api.nvim_win_is_valid(gdb_win) or not vim.api.nvim_win_is_valid(source_win) then
      return
    end

    -- Close every window that isn't one of our three (only closes the window,
    -- not the buffer), removing any pre-existing splits from the debug layout.
    local keep = { [gdb_win] = true, [var_win] = true, [source_win] = true }
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if not keep[win] then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end

    -- Reshape: variables to far-left full height, gdb dropped below it,
    -- source to far-right full height. (See comment above for verified result.)
    if vim.api.nvim_win_is_valid(var_win) then
      vim.api.nvim_set_current_win(var_win)
      vim.cmd 'wincmd H'
    end
    vim.api.nvim_set_current_win(gdb_win)
    vim.cmd 'wincmd J'
    vim.api.nvim_set_current_win(source_win)
    vim.cmd 'wincmd L'

    -- Size: source ~60% width, variables ~1/3 of the left column height
    vim.api.nvim_set_current_win(source_win)
    vim.cmd('vertical resize ' .. math.floor(vim.o.columns * 0.6))
    if vim.api.nvim_win_is_valid(var_win) then
      vim.api.nvim_set_current_win(var_win)
      vim.cmd('resize ' .. math.floor(vim.o.lines / 3))
    end

    -- Land in the gdb window ready for input
    vim.api.nvim_set_current_win(gdb_win)
    vim.cmd 'startinsert'
  end,
})


-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
