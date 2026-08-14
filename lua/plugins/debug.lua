-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Display virtual text for variables inline
    'theHamsta/nvim-dap-virtual-text',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    -- Track whether Termdebug is the active debugger
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TermdebugStartPost',
      callback = function()
        vim.g.termdebug_active = true
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TermdebugStopPost',
      callback = function()
        vim.g.termdebug_active = false
      end,
    })

    -- Unified debugging keymaps: dispatch to Termdebug or DAP at press-time
    vim.keymap.set('n', '<leader>dc', function()
      if vim.g.termdebug_active then
        vim.cmd 'Continue'
      else
        dap.continue()
      end
    end, { desc = 'Debug: Start/Continue' })

    vim.keymap.set('n', '<leader>di', function()
      if vim.g.termdebug_active then
        vim.cmd 'Step'
      else
        dap.step_into()
      end
    end, { desc = 'Debug: Step Into' })

    vim.keymap.set('n', '<leader>dn', function()
      if vim.g.termdebug_active then
        vim.cmd 'Over'
      else
        dap.step_over()
      end
    end, { desc = 'Debug: Step Over' })

    vim.keymap.set('n', '<leader>do', function()
      if vim.g.termdebug_active then
        vim.cmd 'Finish'
      else
        dap.step_out()
      end
    end, { desc = 'Debug: Step Out' })

    vim.keymap.set('n', '<leader>dr', function()
      if vim.g.termdebug_active then
        vim.cmd 'Run'
      else
        dap.restart()
      end
    end, { desc = 'Debug: Restart' })

    vim.keymap.set('n', '<leader>df', function()
      if vim.g.termdebug_active then
        vim.cmd 'Stop'
      else
        dap.terminate()
      end
    end, { desc = 'Debug: Stop' })

    vim.keymap.set('n', '<leader>b', function()
      if vim.g.termdebug_active then
        vim.cmd 'Break'
      else
        dap.toggle_breakpoint()
      end
    end, { desc = 'Debug: Toggle Breakpoint' })

    vim.keymap.set('n', '<leader>B', function()
      if vim.g.termdebug_active then
        vim.cmd 'Clear'
      else
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end
    end, { desc = 'Debug: Set Breakpoint / Clear (Termdebug)' })

    vim.keymap.set('n', '<leader>ds', function()
      if vim.g.termdebug_active then
        vim.fn.TermDebugSendCommand('bt')
      end
    end, { desc = 'Debug: Show Stack (Termdebug)' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {}

    -- Display variable values inline during debug
    require('nvim-dap-virtual-text').setup {
      display_callback = function(variable)
        if #variable.value > 15 then
          return ' ' .. string.sub(variable.value, 1, 15) .. '... '
        end

        return ' ' .. variable.value
      end,
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<leader>dl', dapui.toggle, { desc = 'Debug: See last session result.' })
    vim.keymap.set('n', '<leader>dd', function()
      if vim.g.termdebug_active then
        -- Find the gdb terminal buffer and wipe it, which kills the job
        -- and triggers termdebug's normal cleanup path (EndTermDebug)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            if name:find('term://') and not name:find('gdb program') and not name:find('gdb communication') then
              vim.cmd('bwipe! ' .. buf)
              return
            end
          end
        end
      else
        dap.terminate()
        dapui.close()
      end
    end, { desc = 'Debug: Close Debugger' })

    -- Eval var under cursor
    vim.keymap.set('n', '<space>?', function()
      if vim.g.termdebug_active then
        vim.cmd 'Evaluate'
      else
        dapui.eval(nil, { enter = true })
      end
    end)

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    vim.api.nvim_set_hl(0, 'blue', { fg = '#3d59a1' })
    vim.api.nvim_set_hl(0, 'green', { fg = '#9ece6a' })
    vim.api.nvim_set_hl(0, 'yellow', { fg = '#FFFF00' })
    vim.api.nvim_set_hl(0, 'orange', { fg = '#f09000' })

    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'blue', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '●', texthl = 'blue', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '●', texthl = 'orange', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
    vim.fn.sign_define('DapStopped', { text = '●', texthl = 'green', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
    vim.fn.sign_define('DapLogPoint', { text = '●', texthl = 'yellow', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })

    -- Install golang specific config
    require('dap-go').setup()
    require('dap-python').setup()
    dap.defaults.fallback.auto_continue_if_many_stopped = false

    dap.adapters.cppdbg = {
      id = 'cppdbg',
      type = 'executable',
      command = '/usr/local/share/extension/debugAdapters/bin/OpenDebugAD7',
      options = {
        detached = false,
      },
    }

    dap.configurations.cpp = {
      {
        name = 'Launch file',
        type = 'cppdbg',
        request = 'launch',
        program = function()
          local filename = vim.fn.expand('%:t:r')  -- Get current file name without extension
          local filepath = vim.fn.getcwd() .. '/' .. filename
          return vim.fn.input('Path to executable: ', filepath, 'file')
        end,
        cwd = '${workspaceFolder}',
        stopAtEntry = true,
        setupCommands = {
          {
            text = '-enable-pretty-printing',
            description = 'enable pretty printing',
            ignoreFailures = false,
          },
        },
        args = function()
            local args_string = vim.fn.input("Input arguments: ")
            local raw_args = vim.split(args_string, " ", true)
            local filtered_args = {}
            for _, arg in ipairs(raw_args) do
              if arg ~= "" then
                table.insert(filtered_args, arg)
              end
            end
            return filtered_args
        end,
      },
      {
        name = 'Attach to gdbserver :1234',
        type = 'cppdbg',
        request = 'launch',
        MIMode = 'gdb',
        miDebuggerServerAddress = 'localhost:1234',
        miDebuggerPath = '/usr/bin/gdb',
        cwd = '${workspaceFolder}',
        program = function()
          local filename = vim.fn.expand('%:t:r')  -- Get current file name without extension
          local filepath = vim.fn.getcwd() .. '/' .. filename
          return vim.fn.input('Path to executable: ', filepath, 'file')
        end,
        setupCommands = {
          {
            text = '-enable-pretty-printing',
            description = 'enable pretty printing',
            ignoreFailures = false,
          },
        },
        args = function()
            local args_string = vim.fn.input("Input arguments: ")
            local raw_args = vim.split(args_string, " ", true)
            local filtered_args = {}
            for _, arg in ipairs(raw_args) do
              if arg ~= "" then
                table.insert(filtered_args, arg)
              end
            end
            return filtered_args
        end,
      },
    }
    dap.configurations.c = dap.configurations.cpp
  end,
}
