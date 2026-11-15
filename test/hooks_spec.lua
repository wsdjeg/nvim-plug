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

-----------------------------------------------------------
-- on_map
-----------------------------------------------------------

function TestHooks:testOnMapCreatesKeymap()
  local spec = { name = 'hooks-test-map', on_map = { '<Plug>HooksMap' } }
  local ok = pcall(hooks.on_map, spec.on_map, spec)
  lu.assertTrue(ok)

  pcall(vim.keymap.del, 'n', '<Plug>HooksMap')
end

return TestHooks

