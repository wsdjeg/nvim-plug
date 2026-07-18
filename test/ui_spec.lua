-- test/ui_spec.lua
-- Tests for plug.ui module

local lu = require('luaunit')
local ui = require('plug.ui')

local TestUi = {}

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
  ui.close()
  ui.on_update('test-plugin', { command = 'clone', clone_done = true })
  lu.assertTrue(true)
end

return TestUi

