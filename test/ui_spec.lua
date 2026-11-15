-- test/ui_spec.lua
-- Tests for plug.ui module

local lu = require('luaunit')
local ui = require('plug.ui')

local TestUi = {}

--- Locate the UI buffer by its title line.
---
--- Note: this must not use a Lua pattern with real parentheses - `(` starts
--- a capture in Lua patterns and would never match the literal title.
---@return integer bufnr
local function find_ui_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      if lines[1] and vim.startswith(lines[1], 'Plugins:(') then
        return buf
      end
    end
  end
  return -1
end

---@return string[] lines
local function ui_lines()
  local buf = find_ui_buffer()
  if buf == -1 then
    return {}
  end
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

---@param lines string[]
---@param pattern string plain substring
---@return boolean found
local function any_line_contains(lines, pattern)
  for _, line in ipairs(lines) do
    if line:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

function TestUi:setUp()
  ui.close()
  ui.reset()
end

function TestUi:tearDown()
  ui.close()
  ui.reset()
end

function TestUi:testCloseWhenNothingOpen()
  -- close() should be a no-op when nothing is open
  ui.close()
  lu.assertTrue(true)
end

function TestUi:testCloseActuallyClosesWindow()
  ui.open()
  vim.cmd('redraw')

  ui.close()

  -- after close, calling close again should be a no-op (no error)
  ui.close()
  lu.assertEquals(find_ui_buffer(), -1)
end

function TestUi:testOnUpdateDoesNotErrorWithoutWindow()
  -- on_update should not error when no window is open
  ui.on_update('test-plugin', { command = 'clone', clone_done = true })
  lu.assertTrue(true)
end

--- count_done should count failed plugins as done so the progress
--- bar can reach 100% even when some plugins fail.
function TestUi:testFailedPluginCountedAsDone()
  ui.on_update('fail-plugin', { command = 'clone', clone_done = false })
  ui.on_update('ok-plugin', { command = 'clone', clone_done = true })

  ui.open()
  local lines = ui_lines()
  ui.close()

  lu.assertEquals(lines[1], 'Plugins:(2/2)', table.concat(lines, '\n'))
end

--- An empty status table must not divide by zero. Doing so produced a
--- nan progress bar width and `string.rep` then errored out.
function TestUi:testOpenWithNoPluginsDoesNotError()
  ui.open()
  local lines = ui_lines()
  ui.close()

  lu.assertEquals(lines[1], 'Plugins:(0/0)', table.concat(lines, '\n'))
end

--- `weight` is derived from the window width; a window narrower than the
--- constant offset made it negative, and `string.rep(' ', negative)` errors.
function TestUi:testProgressBarToleratesNarrowWindow()
  ui.on_update('narrow', { command = 'clone', clone_done = true })
  ui.open()

  local buf = find_ui_buffer()
  local win = buf ~= -1 and vim.fn.bufwinid(buf) or -1
  if win ~= -1 then
    pcall(vim.api.nvim_win_set_width, win, 1)
  end

  local ok, err = pcall(ui.on_update, 'narrow', { clone_process = '50%' })
  ui.close()

  lu.assertTrue(ok, tostring(err))
end

--- reset() must clear data from a previous run, otherwise a second
--- `:Plug install` shows stale plugins in the window.
function TestUi:testResetClearsPreviousRun()
  ui.on_update('old-run', { command = 'clone', clone_done = true })
  ui.reset()

  ui.open()
  local lines = ui_lines()
  ui.close()

  lu.assertEquals(lines[1], 'Plugins:(0/0)', table.concat(lines, '\n'))
  lu.assertFalse(
    any_line_contains(lines, 'old-run'),
    table.concat(lines, '\n')
  )
end

--- Download success message must be spelled correctly.
function TestUi:testDownloadSuccessMessage()
  ui.on_update('curl-plugin', { command = 'curl', curl_done = true })

  ui.open()
  local lines = ui_lines()
  ui.close()

  lu.assertFalse(
    any_line_contains(lines, 'dowload'),
    table.concat(lines, '\n')
  )
  lu.assertFalse(
    any_line_contains(lines, 'failed to dowload'),
    table.concat(lines, '\n')
  )
  lu.assertTrue(
    any_line_contains(lines, 'curl-plugin'),
    table.concat(lines, '\n')
  )
end

--- Local plugins are reported as skipped and counted as done.
function TestUi:testLocalPluginIsCountedDone()
  ui.on_update('local-plugin', { is_local = true })

  ui.open()
  local lines = ui_lines()
  ui.close()

  lu.assertEquals(lines[1], 'Plugins:(1/1)', table.concat(lines, '\n'))
  lu.assertTrue(
    any_line_contains(lines, 'skip local plugin'),
    table.concat(lines, '\n')
  )
end

return TestUi

