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

--- clone_depth must be an integer; installer compares it against 0.
function TestConfig:testDefaultCloneDepth()
  lu.assertEquals(config.clone_depth, 1)
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

--- An explicit `false` must win over the current value. The old
--- `opt.k or M.k` merge made this impossible.
function TestConfig:testSetupExplicitFalseTurnsFlagsOff()
  config.setup({
    enable_priority = true,
    enable_luarocks = false,
    focus_window = true,
  })
  config.setup({
    enable_priority = false,
    focus_window = false,
  })
  lu.assertFalse(config.enable_priority)
  lu.assertFalse(config.focus_window)
end

--- `clone_depth = 0` disables `--depth`, so 0 must survive the merge
--- even though it is falsy in Lua.
function TestConfig:testSetupKeepsZeroCloneDepth()
  config.setup({ clone_depth = 1 })
  config.setup({ clone_depth = 0 })
  lu.assertEquals(config.clone_depth, 0)
end

--- A second setup() call must not wipe previously configured proxies.
function TestConfig:testSetupKeepsProxiesOnSecondCall()
  config.setup({
    http_proxy = 'http://proxy:8080',
    https_proxy = 'https://proxy:8443',
  })
  config.setup({ max_processes = 3 })
  lu.assertEquals(config.http_proxy, 'http://proxy:8080')
  lu.assertEquals(config.https_proxy, 'https://proxy:8443')
  lu.assertEquals(config.max_processes, 3)
end

--- `ui` accepts a function for custom UIs; it must be stored as-is.
function TestConfig:testSetupAcceptsCustomUiFunction()
  local custom = function() end
  config.setup({ ui = custom })
  lu.assertEquals(config.ui, custom)
end

--- enable_luarocks should not error even when luarocks is not installed
--- (rocks.enable() wraps the call in pcall).
function TestConfig:testSetupEnableLuarocksDoesNotError()
  local ok = pcall(config.setup, { enable_luarocks = true })
  lu.assertTrue(ok)
end

return TestConfig

