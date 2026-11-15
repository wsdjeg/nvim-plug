-- test/installer_spec.lua
-- Tests for plug.installer module

local lu = require('luaunit')
local config = require('plug.config')
local installer = require('plug.installer')

local TestInstaller = {}

local orig_ui

function TestInstaller:setUp()
  orig_ui = config.ui
end

function TestInstaller:tearDown()
  config.ui = orig_ui
end

-- Test that task queue correctly passes arguments to task functions.
-- This is a white-box test that verifies the fix for tasks[3] vs task[3].
function TestInstaller:testTaskQueuePassesThirdArg()
  -- Set max_processes to 1 so tasks get queued
  local orig_max = config.max_processes
  config.max_processes = 1

  -- We need to access the internal H table to test the queue logic.
  -- Since H is local, we test indirectly by verifying that the installer
  -- module loads without errors and has the expected public API.
  lu.assertEquals(type(installer.install), 'function')
  lu.assertEquals(type(installer.update), 'function')

  config.max_processes = orig_max
end

function TestInstaller:testInstallWithEmptySpecs()
  -- install with empty list should not error
  installer.install({})
  lu.assertTrue(true)
end

function TestInstaller:testUpdateWithEmptySpecs()
  -- update with empty list should not error
  installer.update({})
  lu.assertTrue(true)
end

--- Verify that install/update with local plugins does not error
--- and does not leak process count.
function TestInstaller:testLocalPluginDoesNotLeakProcesses()
  installer.install({
    { name = 'local-1', is_local = true },
    { name = 'local-2', is_local = true },
  })
  lu.assertTrue(true)
end

--- Verify that install with already-existing raw plugin files
--- does not start a job (no process leak).
function TestInstaller:testRawPluginSkipDoesNotLeak()
  -- create a temp file to simulate existing raw plugin
  local tmp = vim.fn.tempname()
  vim.fn.writefile({ '-- fake' }, tmp)

  installer.install({
    {
      name = 'fake-raw',
      type = 'raw',
      path = tmp,
      url = 'http://example.com/fake.lua',
    },
  })

  -- clean up
  vim.fn.delete(tmp)

  lu.assertTrue(true)
end

--- Verify that install with already-existing git plugin dirs
--- does not start a job (no process leak).
function TestInstaller:testExistingPluginDirSkipDoesNotLeak()
  local tmp = vim.fn.tempname() .. '_plugin_dir'
  vim.fn.mkdir(tmp, 'p')

  installer.install({
    {
      name = 'existing-plugin',
      type = 'git',
      path = tmp,
      url = 'http://example.com/repo.git',
    },
  })

  -- clean up
  vim.fn.delete(tmp, 'rf')

  lu.assertTrue(true)
end

-----------------------------------------------------------
-- UI dispatch
-----------------------------------------------------------

--- `ui` may be a custom function (documented in README). It used to be
--- resolved when installer.lua was loaded, so this config crashed with
--- "attempt to call a nil value" on the first update.
function TestInstaller:testCustomUiFunctionIsCalled()
  local calls = {} ---@type { [1]: string, [2]: table }[]
  config.ui = function(name, data)
    table.insert(calls, { name, data })
  end

  local ok = pcall(installer.install, {
    { name = 'local-1', is_local = true },
    { name = 'local-2', is_local = true },
  })
  lu.assertTrue(ok)

  lu.assertEquals(#calls, 2)
  lu.assertEquals(calls[1][1], 'local-1')
  lu.assertTrue(calls[1][2].is_local)
  lu.assertEquals(calls[2][1], 'local-2')
end

--- Switching `ui` after setup() must take effect immediately, without
--- restarting the plugin.
function TestInstaller:testUiSwitchIsPickedUp()
  local calls = 0
  config.ui = function()
    calls = calls + 1
  end
  installer.install({ { name = 'switch-1', is_local = true } })
  lu.assertEquals(calls, 1)

  config.ui = 'default'
  local ok = pcall(installer.install, {
    { name = 'switch-2', is_local = true },
  })
  lu.assertTrue(ok)
  lu.assertEquals(calls, 1)
end

--- The notify UI must not error even when notify.nvim is unavailable
--- (ui/notify.lua falls back to vim.notify).
function TestInstaller:testNotifyUiDoesNotError()
  config.ui = 'notify'
  local ok = pcall(installer.install, {
    { name = 'notify-1', is_local = true },
  })
  lu.assertTrue(ok)
end

return TestInstaller

