-- test/command_spec.lua
-- Tests for plug.command module

local lu = require('luaunit')
local config = require('plug.config')
local command = require('plug.command')
local plug = require('plug')

local TestCommand = {}

local orig_ui

function TestCommand:setUp()
  orig_ui = config.ui
  -- register two plugins so spec collection has something to find
  plug.add({
    { 'wsdjeg/alpha.nvim', fetch = true },
    { 'wsdjeg/beta.nvim', fetch = true },
  })
end

function TestCommand:tearDown()
  config.ui = orig_ui
end

-----------------------------------------------------------
-- collect()
-----------------------------------------------------------

--- Without plugin names the subcommand applies to every plugin.
function TestCommand:testCollectAllWhenNoNames()
  local specs, force = command.collect({ 'install' })
  lu.assertEquals(#specs, #vim.tbl_values(plug.get()))
  lu.assertFalse(force)
end

--- With plugin names only those specs are returned, and update becomes forced.
function TestCommand:testCollectNamedPlugins()
  local specs, force = command.collect({ 'update', 'alpha.nvim' })
  lu.assertEquals(#specs, 1)
  lu.assertEquals(specs[1].name, 'alpha.nvim')
  lu.assertTrue(force)
end

--- Unknown plugin names are dropped instead of producing nil specs.
function TestCommand:testCollectIgnoresUnknownNames()
  local specs = command.collect({ 'install', 'alpha.nvim', 'nope.nvim' })
  lu.assertEquals(#specs, 1)
  lu.assertEquals(specs[1].name, 'alpha.nvim')
end

--- `install` never forces, even when explicit names are given.
function TestCommand:testCollectInstallIsNotForced()
  local _, force = command.collect({ 'install', 'alpha.nvim' })
  lu.assertFalse(force)
end

-----------------------------------------------------------
-- open_ui()
-----------------------------------------------------------

--- The default window only opens for the `default` ui.
function TestCommand:testOpenUiCallsDefaultUi()
  local ui = require('plug.ui')
  local called = 0
  local orig_open = ui.open

  ui.open = function()
    called = called + 1
  end
  config.ui = 'default'
  command.open_ui()
  ui.open = orig_open

  lu.assertEquals(called, 1)
end

--- A custom ui function must not trigger the default window.
function TestCommand:testOpenUiSkippedForCustomUi()
  local ui = require('plug.ui')
  local called = 0
  local orig_open = ui.open

  ui.open = function()
    called = called + 1
  end
  config.ui = function() end
  command.open_ui()
  ui.open = orig_open

  lu.assertEquals(called, 0)
end

-----------------------------------------------------------
-- run()
-----------------------------------------------------------

--- An empty command line is a no-op.
function TestCommand:testRunWithoutArgsDoesNothing()
  local ok = pcall(command.run, { fargs = {} })
  lu.assertTrue(ok)
end

--- An unknown subcommand must not raise and must not dispatch anything.
function TestCommand:testRunUnknownSubcommandDoesNothing()
  local installer = require('plug.installer')
  local calls = 0
  local orig_install = installer.install

  installer.install = function()
    calls = calls + 1
  end
  local ok = pcall(command.run, { fargs = { 'bogus' } })
  installer.install = orig_install

  lu.assertTrue(ok)
  lu.assertEquals(calls, 0)
end

--- `install` dispatches to installer.install without forcing.
function TestCommand:testRunInstallDispatches()
  local installer = require('plug.installer')
  local seen ---@type PluginSpec[]|nil
  local orig_install = installer.install

  installer.install = function(specs)
    seen = specs
  end
  local ok = pcall(command.run, { fargs = { 'install', 'alpha.nvim' } })
  installer.install = orig_install

  lu.assertTrue(ok)
  lu.assertEquals(#seen, 1)
  lu.assertEquals(seen[1].name, 'alpha.nvim')
end

--- `update` passes `force = true` when specific plugins are named.
function TestCommand:testRunUpdateForcesNamedPlugins()
  local installer = require('plug.installer')
  local seen ---@type boolean|nil
  local orig_update = installer.update

  installer.update = function(_, force)
    seen = force
  end
  local ok = pcall(command.run, { fargs = { 'update', 'alpha.nvim' } })
  installer.update = orig_update

  lu.assertTrue(ok)
  lu.assertTrue(seen)
end

--- `update` without names updates everything, unfrozen plugins included,
--- so `force` stays false.
function TestCommand:testRunUpdateAllIsNotForced()
  local installer = require('plug.installer')
  local seen ---@type boolean|nil
  local orig_update = installer.update

  installer.update = function(_, force)
    seen = force
  end
  local ok = pcall(command.run, { fargs = { 'update' } })
  installer.update = orig_update

  lu.assertTrue(ok)
  lu.assertFalse(seen)
end

-----------------------------------------------------------
-- complete()
-----------------------------------------------------------

function TestCommand:testCompleteSubcommands()
  local items = command.complete('i', 'Plug i', 6)
  lu.assertEquals(items, { 'install' })
end

function TestCommand:testCompletePluginNames()
  local items = command.complete('alpha', 'Plug install alpha', 18)
  lu.assertEquals(items, { 'alpha.nvim' })
end

return TestCommand

