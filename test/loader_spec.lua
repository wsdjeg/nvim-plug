-- test/loader_spec.lua
-- Tests for plug.loader module - PluginSpec parsing logic

local lu = require('luaunit')
local loader = require('plug.loader')
local config = require('plug.config')
local util = require('plug.util')

local TestLoader = {}

-- helper: parse a spec and return it
local function parse(spec)
  return loader.parser(spec)
end

-----------------------------------------------------------
-- name derivation
-----------------------------------------------------------

function TestLoader:testNameFromRepo()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertEquals(spec.name, 'foo.nvim')
end

function TestLoader:testNameFromDeepRepo()
  local spec = parse({ 'org/sub/deep-plugin' })
  lu.assertEquals(spec.name, 'deep-plugin')
end

function TestLoader:testEmptyRepoSetsDisabled()
  local spec = parse({})
  lu.assertFalse(spec.enabled)
end

-----------------------------------------------------------
-- module derivation
-----------------------------------------------------------

function TestLoader:testDefaultModuleStripsNvimPrefix()
  local spec = parse({ 'wsdjeg/nvim-foo' })
  lu.assertEquals(spec.module, 'foo')
end

function TestLoader:testDefaultModuleStripsVimPrefix()
  local spec = parse({ 'wsdjeg/vim-bar' })
  lu.assertEquals(spec.module, 'bar')
end

function TestLoader:testDefaultModuleFromDotNvim()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertEquals(spec.module, 'foo')
end

function TestLoader:testCustomModulePreserved()
  local spec = parse({ 'wsdjeg/foo.nvim', module = 'custom-mod' })
  lu.assertEquals(spec.module, 'custom-mod')
end

-----------------------------------------------------------
-- enabled handling
-----------------------------------------------------------

function TestLoader:testEnabledDefaultsTrue()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertTrue(spec.enabled)
end

function TestLoader:testEnabledFalse()
  local spec = parse({ 'wsdjeg/foo.nvim', enabled = false })
  lu.assertFalse(spec.enabled)
end

function TestLoader:testEnabledFunctionTrue()
  local spec = parse({ 'wsdjeg/foo.nvim', enabled = function() return true end })
  lu.assertTrue(spec.enabled)
end

function TestLoader:testEnabledFunctionFalse()
  local spec = parse({ 'wsdjeg/foo.nvim', enabled = function() return false end })
  lu.assertFalse(spec.enabled)
end

function TestLoader:testEnabledFunctionNonBooleanReturnsFalse()
  local spec = parse({ 'wsdjeg/foo.nvim', enabled = function() return 'yes' end })
  lu.assertFalse(spec.enabled)
end

-----------------------------------------------------------
-- url / path / rtp for git type (default)
-----------------------------------------------------------

function TestLoader:testGitDefaultUrl()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertEquals(spec.url, config.base_url .. '/wsdjeg/foo.nvim')
end

function TestLoader:testGitDefaultPath()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertEquals(spec.path, config.bundle_dir .. '/wsdjeg/foo.nvim')
end

function TestLoader:testGitDefaultRtp()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertEquals(spec.rtp, config.bundle_dir .. '/wsdjeg/foo.nvim')
end

-----------------------------------------------------------
-- script_type variants
-----------------------------------------------------------

function TestLoader:testScriptTypeColor()
  local spec = parse({ 'wsdjeg/colors', script_type = 'color' })
  lu.assertEquals(spec.path, config.bundle_dir .. '/wsdjeg/colors/color')
  lu.assertEquals(spec.rtp, config.bundle_dir .. '/wsdjeg/colors')
end

function TestLoader:testScriptTypePlugin()
  local spec = parse({ 'wsdjeg/plugin', script_type = 'plugin' })
  lu.assertEquals(spec.path, config.bundle_dir .. '/wsdjeg/plugin/plugin')
  lu.assertEquals(spec.rtp, config.bundle_dir .. '/wsdjeg/plugin')
end

-----------------------------------------------------------
-- raw type
-----------------------------------------------------------

function TestLoader:testRawTypeWithoutScriptTypeDisabled()
  local spec = parse({ 'wsdjeg/foo.lua', type = 'raw' })
  lu.assertFalse(spec.enabled)
end

function TestLoader:testRawTypeWithScriptTypeNoneDisabled()
  local spec = parse({ 'wsdjeg/foo.lua', type = 'raw', script_type = 'none' })
  lu.assertFalse(spec.enabled)
end

function TestLoader:testRawTypeWithPath()
  local spec = parse({ 'wsdjeg/foo.lua', type = 'raw', script_type = 'plugin' })
  lu.assertTrue(spec.enabled)
  lu.assertEquals(spec.path, config.raw_plugin_dir .. '/plugin/foo.lua')
end

-----------------------------------------------------------
-- autoload default
-----------------------------------------------------------

function TestLoader:testAutoloadDefaultsTrueForGit()
  local spec = parse({ 'wsdjeg/foo.nvim' })
  lu.assertTrue(spec.autoload)
end

function TestLoader:testAutoloadNilForRaw()
  local spec = parse({ 'wsdjeg/foo.lua', type = 'raw', script_type = 'plugin' })
  lu.assertNil(spec.autoload)
end

function TestLoader:testAutoloadNilForFetch()
  local spec = parse({ 'wsdjeg/foo.nvim', fetch = true })
  lu.assertNil(spec.autoload)
end

function TestLoader:testAutoloadExplicitTrueOverridesRaw()
  local spec = parse({ 'wsdjeg/foo.lua', type = 'raw', script_type = 'plugin', autoload = true })
  lu.assertTrue(spec.autoload)
end

-----------------------------------------------------------
-- config_before hook
-----------------------------------------------------------

function TestLoader:testConfigBeforeCalled()
  local called = false
  local spec = parse({ 'wsdjeg/foo.nvim', config_before = function() called = true end })
  lu.assertTrue(called)
end

function TestLoader:testConfigBeforeNotCalledWhenDisabled()
  local called = false
  local spec = parse({ 'wsdjeg/foo.nvim', enabled = false, config_before = function() called = true end })
  lu.assertFalse(called)
end

-----------------------------------------------------------
-- local plugin
-----------------------------------------------------------

function TestLoader:testLocalPluginDetectsDirectory()
  local tmp = vim.fn.tempname() .. '_local_plugin'
  vim.fn.mkdir(tmp, 'p')
  local spec = parse({ tmp })
  lu.assertTrue(spec.is_local)
  lu.assertEquals(spec.rtp, tmp)
  lu.assertEquals(spec.path, tmp)
  lu.assertNil(spec.url)
  vim.fn.delete(tmp, 'rf')
end

function TestLoader:testLocalPluginExplicitFlag()
  local spec = parse({ 'wsdjeg/foo.nvim', is_local = true })
  lu.assertTrue(spec.is_local)
end

-----------------------------------------------------------
-- dev path
-----------------------------------------------------------

function TestLoader:testDevPathUsesConfigDevPath()
  local orig_dev = config.dev_path
  local tmp = vim.fn.tempname() .. '_dev'
  vim.fn.mkdir(tmp .. '/foo.nvim', 'p')
  config.dev_path = tmp

  local spec = parse({ 'wsdjeg/foo.nvim', dev = true })
  lu.assertEquals(spec.dev_path, util.unify_path(tmp) .. 'foo.nvim')

  config.dev_path = orig_dev
  vim.fn.delete(tmp, 'rf')
end

function TestLoader:testDevPathNotSetWhenDirMissing()
  local orig_dev = config.dev_path
  config.dev_path = '/nonexistent/path'

  local spec = parse({ 'wsdjeg/foo.nvim', dev = true })
  lu.assertNil(spec.dev_path)

  config.dev_path = orig_dev
end

-----------------------------------------------------------
-- depends handling (tested via plug.add)
-----------------------------------------------------------

function TestLoader:testParserDoesNotProcessDepends()
  -- parser itself does not recurse into depends; that's plug.add's job
  local spec = parse({
    'wsdjeg/foo.nvim',
    depends = { { 'wsdjeg/bar.nvim' } },
  })
  lu.assertEquals(spec.name, 'foo.nvim')
  -- depends should still be present, untouched
  lu.assertNotNil(spec.depends)
end

return TestLoader

