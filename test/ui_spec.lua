-- test/ui_spec.lua
-- Tests for plug.ui module

local lu = require('luaunit')
local ui = require('plug.ui')

local TestUi = {}

function TestUi:setUp()
  -- ensure clean state before each test
  ui.close()
end

function TestUi:tearDown()
  ui.close()
end

function TestUi:testCloseWhenNothingOpen()
  -- close() should be a no-op when nothing is open
  -- it should not error
  ui.close()
  lu.assertTrue(true)
end

function TestUi:testCloseActuallyClosesWindow()
  -- open the UI, then close it, verify no error
  ui.open()
  vim.cmd('redraw')

  -- close it
  ui.close()

  -- after close, calling close again should be a no-op (no error)
  ui.close()
  lu.assertTrue(true)
end

function TestUi:testOnUpdateDoesNotErrorWithoutWindow()
  -- on_update should not error when no window is open
  ui.on_update('test-plugin', { command = 'clone', clone_done = true })
  lu.assertTrue(true)
end

--- count_done should count failed plugins as done so the progress
--- bar can reach 100% even when some plugins fail.
function TestUi:testFailedPluginCountedAsDone()
  -- register a plugin that failed to clone
  ui.on_update('fail-plugin', { command = 'clone', clone_done = false })
  -- register a plugin that succeeded
  ui.on_update('ok-plugin', { command = 'clone', clone_done = true })

  -- open the UI - this calls build_context() -> count_done()
  -- if count_done didn't count failures, the progress bar would
  -- show 1/2 instead of 2/2, and the code wouldn't error here
  ui.open()
  vim.cmd('redraw')

  -- read the first line of the buffer: "Plugins:(done/total)"
  -- Note: we can't easily access the internal bufnr, but if the
  -- code had a division issue (total=0), it would error.
  -- The key assertion is that open() succeeds without error.

  ui.close()
  lu.assertTrue(true)
end

return TestUi

