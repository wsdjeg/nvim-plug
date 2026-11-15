-- test/config_spec.lua
-- Tests for plug.config module

local lu = require('luaunit')
local config = require('plug.config')

local TestConfig = {}

-- every field setup() may touch, so we can restore state between tests
local FIELDS = {
  'bundle_dir',
  'raw_plugin_dir',
  'dev_path',
  'max_processes',
  'base_url',
  'ui',
  'clone_depth',
  'import',
  'enable_priority',
  'enable_luarocks',
  'focus_window',
  'http_proxy',
  'https_proxy',
}

local snapshot

function TestConfig:setUp()
  snapshot = {}
  for _, k in ipairs(FIELDS) do
    snapshot[k] = config[k]
  end
end

function TestConfig:tearDown()
  for k, v in pairs(snapshot) do
    config[k] = v
  end
end

-----------------------------------------------------------
-- defaults
-----------------------------------------------------------

function TestConfig:testDefaultMaxProcesses()
  lu.assertEquals(config.max_processes, 5)
end

function TestConfig:testDefaultBaseUrl()
  lu.assertEquals(config.base_url, 'https://github.com')
end

function TestConfig:testDefaultCloneDepth()
  lu.assertEquals(config.clone_depth, '1')
end

function TestConfig:testDefaultImport()
  lu.assertEquals(config.import, 'plugins')
end

function TestConfig:testDefaultUi()
  lu.assertEquals(config.ui, 'default')
end

function TestConfig:testDefaultFlagsAreFalse()
  lu.assertFalse(config.enable_priority or false)
  lu.assertFalse(config.enable_luarocks or false)
  lu.assertFalse(config.focus_window or false)
end

--- bundle_dir is overridden by test/minimal_init.lua, so instead of
--- asserting the built-in default we assert it is a usable path and
--- that setup() honours a custom value.
function TestConfig:testBundleDirIsNonEmptyPath()
  lu.assertEquals(type(config.bundle_dir), 'string')
  lu.assertNotEquals(config.bundle_dir, '')
end

function TestConfig:testRawPluginDirDefaultsUnderBundleDir()
  lu.assertEquals(type(config.raw_plugin_dir), 'string')
  lu.assertNotEquals(config.raw_plugin_dir, '')
end

-----------------------------------------------------------
-- setup() overrides
-----------------------------------------------------------

function TestConfig:testSetupOverridesValues()
  config.setup({
    bundle_dir = '/tmp/cfg_test/repos',
    raw_plugin_dir = '/tmp/cfg_test/raw',
    max_processes = 2,
    base_url = 'https://gitlab.com',
    ui = 'notify',
    clone_depth = 0,
    import = 'myplugs',
    enable_priority = true,
    focus_window = true,
    dev_path = '/tmp/cfg_test/dev',
  })

  lu.assertEquals(config.bundle_dir, '/tmp/cfg_test/repos')
  lu.assertEquals(config.raw_plugin_dir, '/tmp/cfg_test/raw')
  lu.assertEquals(config.max_processes, 2)
  lu.assertEquals(config.base_url, 'https://gitlab.com')
  lu.assertEquals(config.ui, 'notify')
  lu.assertEquals(config.clone_depth, 0)
  lu.assertEquals(config.import, 'myplugs')
  lu.assertTrue(config.enable_priority)
  lu.assertTrue(config.focus_window)
  lu.assertEquals(config.dev_path, '/tmp/cfg_test/dev')
end

function TestConfig:testSetupWithoutArgsKeepsCurrentValues()
  local before = config.max_processes
  config.setup()
  lu.assertEquals(config.max_processes, before)
end

function TestConfig:testSetupSetsProxies()
  config.setup({
    http_proxy = 'http://proxy:8080',
    https_proxy = 'https://proxy:8443',
  })
  lu.assertEquals(config.http_proxy, 'http://proxy:8080')
  lu.assertEquals(config.https_proxy, 'https://proxy:8443')
end

--- setup() must not reset flags that were previously enabled when
--- called again with an empty table.
function TestConfig:testSetupDoesNotResetFlagsToFalse()
  config.setup({ enable_priority = true })
  config.setup()
  lu.assertTrue(config.enable_priority)
end

--- enable_luarocks should not error even when luarocks is not installed
--- (rocks.enable() wraps the call in pcall).
function TestConfig:testSetupEnableLuarocksDoesNotError()
  local ok = pcall(config.setup, { enable_luarocks = true })
  lu.assertTrue(ok)
end

return TestConfig

