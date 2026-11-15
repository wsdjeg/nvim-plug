-- test/notify_spec.lua
-- Tests for plug.ui.notify module

local lu = require('luaunit')

local TestNotify = {}

local orig_notify
local messages ---@type string[]

--- Reload plug.ui.notify so its load-time notify binding is refreshed.
---@return Plug.Ui.Notify
local function fresh_notify_ui()
  package.loaded['plug.ui.notify'] = nil
  return require('plug.ui.notify')
end

function TestNotify:setUp()
  orig_notify = vim.notify
  messages = {}
  vim.notify = function(msg)
    table.insert(messages, msg)
  end
  package.loaded['plug.ui.notify'] = nil
end

function TestNotify:tearDown()
  vim.notify = orig_notify
  package.loaded['plug.ui.notify'] = nil
end

---@param pattern string plain substring
---@return boolean found
local function any_message_contains(pattern)
  for _, msg in ipairs(messages) do
    if msg:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

-----------------------------------------------------------
-- clone / curl
-----------------------------------------------------------

function TestNotify:testCloneSuccess()
  fresh_notify_ui().on_update('alpha', { command = 'clone', clone_done = true })
  lu.assertTrue(any_message_contains('alpha'))
  lu.assertTrue(any_message_contains('downloaded'))
end

--- A failed clone must be reported. Before, `clone_done == false` was falsy,
--- so neither the success nor the failure branch fired and the user got no
--- feedback at all.
function TestNotify:testCloneFailure()
  fresh_notify_ui().on_update(
    'alpha',
    { command = 'clone', clone_done = false }
  )
  lu.assertTrue(any_message_contains('alpha'), table.concat(messages, '\n'))
  lu.assertTrue(any_message_contains('fail'), table.concat(messages, '\n'))
end

function TestNotify:testCurlSuccess()
  fresh_notify_ui().on_update('raw', { command = 'curl', curl_done = true })
  lu.assertTrue(any_message_contains('downloaded'))
end

function TestNotify:testCurlFailure()
  fresh_notify_ui().on_update('raw', { command = 'curl', curl_done = false })
  lu.assertTrue(any_message_contains('raw'), table.concat(messages, '\n'))
  lu.assertTrue(any_message_contains('fail'), table.concat(messages, '\n'))
end

--- Progress updates must not spam the user.
function TestNotify:testCloneProgressIsSilent()
  fresh_notify_ui().on_update(
    'alpha',
    { command = 'clone', clone_process = '42% (420/1000)' }
  )
  lu.assertEquals(#messages, 0, table.concat(messages, '\n'))
end

-----------------------------------------------------------
-- pull
-----------------------------------------------------------

function TestNotify:testPullSuccess()
  fresh_notify_ui().on_update('alpha', { command = 'pull', pull_done = true })
  lu.assertTrue(any_message_contains('updated'))
end

function TestNotify:testPullFailure()
  fresh_notify_ui().on_update(
    'alpha',
    { command = 'pull', pull_done = false }
  )
  lu.assertTrue(any_message_contains('alpha'), table.concat(messages, '\n'))
  lu.assertTrue(any_message_contains('fail'), table.concat(messages, '\n'))
end

function TestNotify:testPullProgressIsSilent()
  fresh_notify_ui().on_update(
    'alpha',
    { command = 'pull', pull_process = '10%' }
  )
  lu.assertEquals(#messages, 0, table.concat(messages, '\n'))
end

-----------------------------------------------------------
-- build
-----------------------------------------------------------

function TestNotify:testBuildSuccess()
  fresh_notify_ui().on_update('alpha', { command = 'build', build_done = true })
  lu.assertTrue(any_message_contains('build done'))
end

function TestNotify:testBuildFailure()
  fresh_notify_ui().on_update(
    'alpha',
    { command = 'build', build_done = false }
  )
  lu.assertTrue(any_message_contains('alpha'), table.concat(messages, '\n'))
  lu.assertTrue(any_message_contains('fail'), table.concat(messages, '\n'))
end

-----------------------------------------------------------
-- luarocks
-----------------------------------------------------------

--- LuaRocks results were ignored entirely by the notify UI.
function TestNotify:testLuarocksSuccess()
  fresh_notify_ui().on_update(
    'rock',
    { command = 'luarocks', luarocks_done = true }
  )
  lu.assertTrue(any_message_contains('rock'), table.concat(messages, '\n'))
end

function TestNotify:testLuarocksFailure()
  fresh_notify_ui().on_update(
    'rock',
    { command = 'luarocks', luarocks_done = false }
  )
  lu.assertTrue(any_message_contains('rock'), table.concat(messages, '\n'))
  lu.assertTrue(any_message_contains('fail'), table.concat(messages, '\n'))
end

-----------------------------------------------------------
-- local plugins
-----------------------------------------------------------

function TestNotify:testLocalPluginIsReported()
  fresh_notify_ui().on_update('local', { is_local = true })
  lu.assertTrue(any_message_contains('local'), table.concat(messages, '\n'))
end

-----------------------------------------------------------
-- robustness
-----------------------------------------------------------

function TestNotify:testEmptyDataDoesNotNotify()
  fresh_notify_ui().on_update('alpha', {})
  lu.assertEquals(#messages, 0, table.concat(messages, '\n'))
end

--- A throwing notify backend must not break installer callbacks.
function TestNotify:testThrowingBackendIsContained()
  vim.notify = function()
    error('notify exploded')
  end
  local ui = fresh_notify_ui()
  local ok = pcall(ui.on_update, 'alpha', { command = 'clone', clone_done = true })
  lu.assertTrue(ok, 'notify errors must not propagate')
end

return TestNotify

