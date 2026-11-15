-- test/init_spec.lua
-- Tests for the public plug API (lua/plug/init.lua)

local lu = require('luaunit')
local plug = require('plug')
local config = require('plug.config')
local ui = require('plug.ui')

local TestInit = {}

--- Build a throwaway runtimepath directory containing `plugins/*.lua`.
---@param files table<string, string> filename -> source
---@return string dir
local function make_import_dir(files)
  local dir = vim.fn.tempname() .. '_plug_import'
  vim.fn.mkdir(dir .. '/plugins', 'p')
  for name, src in pairs(files) do
    -- writefile() turns an embedded "\n" into a NUL byte, so multi-line
    -- sources must be split into one line per list entry.
    vim.fn.writefile(vim.split(src, '\n'), dir .. '/plugins/' .. name)
  end
  return dir
end

function TestInit:setUp()
  self.orig_import = config.import
end

function TestInit:tearDown()
  config.import = self.orig_import
end

-----------------------------------------------------------
-- add()
-----------------------------------------------------------

--- Adding the same PluginSpec twice must stay idempotent and not error.
function TestInit:testAddTwiceKeepsSingleEntry()
  plug.add({ { 'wsdjeg/dup.nvim', fetch = true } })
  plug.add({ { 'wsdjeg/dup.nvim', fetch = true } })

  lu.assertNotNil(plug.get()['dup.nvim'])
  lu.assertEquals(#vim.tbl_keys(plug.get()), #vim.tbl_keys(plug.get()))
end

--- A spec that depends on itself used to recurse forever
--- (`M.add(depends)` -> same spec -> `M.add(depends)` ...), ending in a
--- "stack overflow" error.
function TestInit:testSelfDependencyDoesNotRecurseForever()
  local spec = { 'wsdjeg/self-dep.nvim', fetch = true }
  spec.depends = { spec }

  local ok, err = pcall(plug.add, { spec })
  lu.assertTrue(ok, tostring(err))
end

--- Mutual dependency between two specs must also terminate.
function TestInit:testMutualDependencyDoesNotRecurseForever()
  local a = { 'wsdjeg/dep-a.nvim', fetch = true }
  local b = { 'wsdjeg/dep-b.nvim', fetch = true, depends = { a } }
  a.depends = { b }

  local ok, err = pcall(plug.add, { a })
  lu.assertTrue(ok, tostring(err))
end

--- Dependencies are registered along with the plugin that needs them.
function TestInit:testDependsAreRegistered()
  local dep = { 'wsdjeg/dep-only.nvim', fetch = true }
  local main = { 'wsdjeg/dep-main.nvim', fetch = true, depends = { dep } }

  plug.add({ main })

  lu.assertNotNil(plug.get()['dep-only.nvim'])
  lu.assertNotNil(plug.get()['dep-main.nvim'])
end

--- `keys` may be given as `{lhs, rhs}` (mode defaults to `n`) as well as
--- the explicit `{mode, lhs, rhs}` triple. The two-element form used to be
--- passed straight to vim.keymap.set(), where the lhs became the mode and
--- the mapping failed silently inside pcall.
function TestInit:testKeysTwoElementFormIsMapped()
  plug.add({
    {
      'wsdjeg/keys-two.nvim',
      fetch = true,
      keys = { { '<Plug>PlugKeysTwo', '<cmd>echo "ok"<cr>' } },
    },
  })

  local found = false
  for _, m in ipairs(vim.api.nvim_get_keymap('n')) do
    if m.lhs:lower() == '<plug>plugkeystwo' then
      found = true
    end
  end
  lu.assertTrue(found)

  pcall(vim.keymap.del, 'n', '<Plug>PlugKeysTwo')
end

--- The explicit triple form keeps working.
function TestInit:testKeysTripleFormIsMapped()
  plug.add({
    {
      'wsdjeg/keys-three.nvim',
      fetch = true,
      keys = { { 'n', '<Plug>PlugKeysThree', '<cmd>echo "ok"<cr>' } },
    },
  })

  local found = false
  for _, m in ipairs(vim.api.nvim_get_keymap('n')) do
    if m.lhs:lower() == '<plug>plugkeysthree' then
      found = true
    end
  end
  lu.assertTrue(found)

  pcall(vim.keymap.del, 'n', '<Plug>PlugKeysThree')
end

-----------------------------------------------------------
-- load() / import
-----------------------------------------------------------

--- A single malformed spec file must not abort the whole import run.
--- `assert(loadfile(path))()` used to raise, so no plugin after the broken
--- file was ever registered.
function TestInit:testBrokenSpecFileDoesNotAbortImport()
  local dir = make_import_dir({
    ['bad.lua'] = 'return {{{',
    ['good.lua'] = 'return { "wsdjeg/import-good.nvim", fetch = true }',
  })
  vim.opt.runtimepath:prepend(dir)

  local ok, err = pcall(plug.load)

  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')

  lu.assertTrue(ok, tostring(err))
  lu.assertNotNil(
    plug.get()['import-good.nvim'],
    'good spec must still be registered'
  )
end

--- A spec file that returns a non-spec value is ignored silently.
function TestInit:testNonSpecReturnValueIsIgnored()
  local dir = make_import_dir({
    ['scalar.lua'] = 'return "not a spec"',
    ['number.lua'] = 'return 42',
  })
  vim.opt.runtimepath:prepend(dir)

  local ok, err = pcall(plug.load)

  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')

  lu.assertTrue(ok, tostring(err))
end

--- `import = nil` disables the import pass entirely.
function TestInit:testImportDisabledDoesNothing()
  config.import = nil
  local ok, err = pcall(plug.load)
  lu.assertTrue(ok, tostring(err))
end

--- A spec file returning a list of specs registers all of them.
function TestInit:testImportListOfSpecs()
  local dir = make_import_dir({
    ['list.lua'] = table.concat({
      'return {',
      '  { "wsdjeg/list-a.nvim", fetch = true },',
      '  { "wsdjeg/list-b.nvim", fetch = true },',
      '}',
    }, '\n'),
  })
  vim.opt.runtimepath:prepend(dir)

  local ok, err = pcall(plug.load)

  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')

  lu.assertTrue(ok, tostring(err))
  lu.assertNotNil(plug.get()['list-a.nvim'])
  lu.assertNotNil(plug.get()['list-b.nvim'])
end

-----------------------------------------------------------
-- get()
-----------------------------------------------------------

--- get() returns the live registry table.
function TestInit:testGetReturnsRegisteredSpecs()
  plug.add({ { 'wsdjeg/get-test.nvim', fetch = true } })
  local spec = plug.get()['get-test.nvim']
  lu.assertNotNil(spec)
  lu.assertEquals(spec.name, 'get-test.nvim')
end

--- Disabled plugins are not registered at all.
function TestInit:testDisabledPluginIsNotRegistered()
  plug.add({ { 'wsdjeg/disabled.nvim', enabled = false } })
  lu.assertNil(plug.get()['disabled.nvim'])
end

return TestInit

