-- test/hooks_spec.lua
-- Tests for plug.hooks module (lazy-loading triggers)

local lu = require('luaunit')
local hooks = require('plug.hooks')

local TestHooks = {}

--- Wipe every autocmd created by plug.hooks so tests do not leak
--- triggers into each other.
function TestHooks:tearDown()
  pcall(vim.api.nvim_clear_autocmds, { group = 'plugin_hooks' })
end

-----------------------------------------------------------
-- on_cmds
-----------------------------------------------------------

function TestHooks:testOnCmdsCreatesUserCommand()
  local spec = { name = 'hooks-test-cmds', cmds = { 'HooksTestCmd' } }
  hooks.on_cmds(spec.cmds, spec)

  -- 2 means the command exists
  lu.assertEquals(vim.fn.exists(':HooksTestCmd'), 2)

  pcall(vim.api.nvim_del_user_command, 'HooksTestCmd')
end

function TestHooks:testOnCmdsAcceptsStringList()
  local spec = { name = 'hooks-test-cmds-multi', cmds = { 'HooksA', 'HooksB' } }
  hooks.on_cmds(spec.cmds, spec)

  lu.assertEquals(vim.fn.exists(':HooksA'), 2)
  lu.assertEquals(vim.fn.exists(':HooksB'), 2)

  pcall(vim.api.nvim_del_user_command, 'HooksA')
  pcall(vim.api.nvim_del_user_command, 'HooksB')
end

function TestHooks:testOnCmdsAcceptsSingleString()
  local spec = { name = 'hooks-test-cmds-single', cmds = { 'HooksSingle' } }
  -- passing a bare string instead of a table must be normalised
  hooks.on_cmds('HooksSingle', spec)

  lu.assertEquals(vim.fn.exists(':HooksSingle'), 2)

  pcall(vim.api.nvim_del_user_command, 'HooksSingle')
end

--- Invoking a lazy command must remove every placeholder command of the
--- spec, so the command defined by the plugin (if any) takes over.
function TestHooks:testOnCmdsInvocationRemovesAllPlaceholders()
  local spec = { name = 'hooks-cmd-multi', cmds = { 'HooksA', 'HooksB' } }
  hooks.on_cmds(spec.cmds, spec)

  local ok = pcall(vim.cmd, 'HooksA')
  lu.assertTrue(ok)
  lu.assertEquals(vim.fn.exists(':HooksA'), 0)
  lu.assertEquals(vim.fn.exists(':HooksB'), 0)
end

--- `cmds = 'Foo'` (bare string, documented in README) must also work.
--- The callback used to read `spec.cmds` directly, so `ipairs()` over a
--- string iterated zero times: the placeholder was never deleted and the
--- command re-invoked itself forever.
function TestHooks:testOnCmdsStringSpecIsNormalisedAndUnloaded()
  local spec = { name = 'hooks-str-cmd', cmds = 'HooksStrCmd' }
  hooks.on_cmds('HooksStrCmd', spec)

  lu.assertEquals(vim.fn.exists(':HooksStrCmd'), 2)
  -- normalised back onto the spec so the callback can delete the dummy
  lu.assertEquals(type(spec.cmds), 'table')

  local ok = pcall(vim.cmd, 'HooksStrCmd')
  lu.assertTrue(ok)
  lu.assertEquals(vim.fn.exists(':HooksStrCmd'), 0)
end

-----------------------------------------------------------
-- on_events
-----------------------------------------------------------

function TestHooks:testOnEventsCreatesAutocmd()
  local spec = { name = 'hooks-test-events' }
  local ok = pcall(hooks.on_events, { 'User' }, spec)
  lu.assertTrue(ok)

  local autocmds = vim.api.nvim_get_autocmds({ event = 'User' })
  lu.assertTrue(#autocmds > 0)
end

function TestHooks:testOnEventsNormalisesStringSpec()
  local spec = { name = 'hooks-events-str', events = 'User' }
  hooks.on_events('User', spec)
  lu.assertEquals(type(spec.events), 'table')
end

--- Triggering an event clears the other lazy triggers of the same spec.
function TestHooks:testOnEventsClearsSiblingTriggers()
  local spec = {
    name = 'hooks-sibling',
    events = { 'User' },
    on_ft = { 'lua' },
  }
  hooks.on_events(spec.events, spec)
  hooks.on_ft(spec.on_ft, spec)

  pcall(vim.cmd, 'doautocmd User')

  local remaining = vim.api.nvim_get_autocmds({
    group = 'plugin_hooks',
    event = 'FileType',
  })
  lu.assertEquals(#remaining, 0)
end

--- Registering the same spec twice must not error when the event fires:
--- the second callback used to delete an autocmd id that was already gone.
function TestHooks:testDoubleRegistrationIsSafeOnTrigger()
  local spec = { name = 'hooks-dup', events = { 'User' } }
  hooks.on_events('User', spec)
  hooks.on_events('User', spec)

  local ok = pcall(vim.cmd, 'doautocmd User')
  lu.assertTrue(ok)
end

-----------------------------------------------------------
-- on_ft
-----------------------------------------------------------

function TestHooks:testOnFtCreatesAutocmd()
  local spec = { name = 'hooks-test-ft' }
  local ok = pcall(hooks.on_ft, { 'lua' }, spec)
  lu.assertTrue(ok)

  local autocmds = vim.api.nvim_get_autocmds({ event = 'FileType' })
  lu.assertTrue(#autocmds > 0)
end

function TestHooks:testOnFtNormalisesStringSpec()
  local spec = { name = 'hooks-ft-str', on_ft = 'lua' }
  hooks.on_ft('lua', spec)
  lu.assertEquals(type(spec.on_ft), 'table')
end

-----------------------------------------------------------
-- on_func
-----------------------------------------------------------

function TestHooks:testOnFuncCreatesAutocmd()
  local spec = { name = 'hooks-test-func' }
  local ok = pcall(hooks.on_func, { 'HooksUndefinedFunc' }, spec)
  lu.assertTrue(ok)

  local autocmds = vim.api.nvim_get_autocmds({ event = 'FuncUndefined' })
  lu.assertTrue(#autocmds > 0)
end

function TestHooks:testOnFuncNormalisesStringSpec()
  local spec = { name = 'hooks-func-str', on_func = 'HooksUndefinedFunc' }
  hooks.on_func('HooksUndefinedFunc', spec)
  lu.assertEquals(type(spec.on_func), 'table')
end

-----------------------------------------------------------
-- on_map
-----------------------------------------------------------

function TestHooks:testOnMapCreatesKeymap()
  local spec = { name = 'hooks-test-map', on_map = { '<Plug>HooksMap' } }
  local ok = pcall(hooks.on_map, spec.on_map, spec)
  lu.assertTrue(ok)

  pcall(vim.keymap.del, 'n', '<Plug>HooksMap')
end

function TestHooks:testOnMapNormalisesStringSpec()
  local spec = { name = 'hooks-map-str', on_map = '<Plug>HooksMapStr' }
  hooks.on_map('<Plug>HooksMapStr', spec)

  lu.assertEquals(type(spec.on_map), 'table')
  local maps = vim.api.nvim_get_keymap('n')
  local found = false
  for _, m in ipairs(maps) do
    if m.lhs:lower() == '<plug>hooksmapstr' then
      found = true
    end
  end
  lu.assertTrue(found)

  pcall(vim.keymap.del, 'n', '<Plug>HooksMapStr')
end

return TestHooks

