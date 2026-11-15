-- test/logger_spec.lua
-- Tests for plug.logger module
--
-- logger.nvim is an optional dependency, so plug.logger must degrade
-- gracefully when it is missing, broken, or incomplete.

local lu = require('luaunit')
local log = require('plug.logger')

local TestLogger = {}

local orig_preload
local orig_loaded

--- Install a fake `logger` module and return a table collecting calls.
---@param methods string[]|nil methods the fake module supports
---@param derive_scope_check? boolean
---@return table calls, table<integer, integer> counts
local function fake_logger(methods, derive_scope_check)
  local calls = {} ---@type { [1]: string, [2]: string, [3]: string }[]
  local module_returns = nil ---@type table|nil

  package.preload['logger'] = function()
    return {
      derive = function(scope)
        if derive_scope_check then
          table.insert(calls, { '_scope', scope, '' })
        end
        module_returns = {}
        for _, name in ipairs(methods or {}) do
          module_returns[name] = function(msg)
            table.insert(calls, { name, scope, msg })
          end
        end
        return module_returns
      end,
    }
  end

  return calls
end

--- Reload plug.logger so its internal cache starts empty.
---@return Plug.Logger
local function fresh_logger()
  package.loaded['plug.logger'] = nil
  return require('plug.logger')
end

function TestLogger:setUp()
  orig_preload = package.preload['logger']
  orig_loaded = package.loaded['logger']
  package.loaded['plug.logger'] = nil
end

function TestLogger:tearDown()
  package.preload['logger'] = orig_preload
  package.loaded['logger'] = orig_loaded
  package.loaded['plug.logger'] = nil
end

-----------------------------------------------------------
-- pass-through
-----------------------------------------------------------

function TestLogger:testForwardsAllLevels()
  local calls = fake_logger({ 'info', 'debug', 'warn', 'error' })
  local l = fresh_logger()

  l.info('first')
  l.debug('second')
  l.warn('third')
  l.error('fourth')

  lu.assertEquals(#calls, 4)
  lu.assertEquals(calls[1][1], 'info')
  lu.assertEquals(calls[1][3], 'first')
  lu.assertEquals(calls[4][1], 'error')
  lu.assertEquals(calls[4][3], 'fourth')
end

--- The logger scope must be `plug`.
function TestLogger:testDerivesPlugScope()
  local calls = fake_logger({ 'info' }, true)
  fresh_logger().info('msg')

  lu.assertTrue(#calls >= 2)
  lu.assertEquals(calls[1][1], '_scope')
  lu.assertEquals(calls[1][2], 'plug')
end

-----------------------------------------------------------
-- missing / broken logger
-----------------------------------------------------------

--- Without logger.nvim every level must be a no-op instead of raising.
function TestLogger:testMissingLoggerIsSilent()
  package.preload['logger'] = function()
    error('module logger not found')
  end
  local l = fresh_logger()

  local ok, err = pcall(function()
    l.info('a')
    l.debug('b')
    l.warn('c')
    l.error('d')
  end)

  lu.assertTrue(ok, tostring(err))
end

--- A logger module without `derive` (different major version) must not break
--- plugin loading.
function TestLogger:testLoggerWithoutDeriveIsSilent()
  package.preload['logger'] = function()
    return { info = function() end }
  end
  local l = fresh_logger()

  local ok, err = pcall(l.info, 'msg')
  lu.assertTrue(ok, tostring(err))
end

--- `derive` returning a table that lacks a level must not raise.
--- The old code only wrapped the very first call in pcall, so the second
--- call reached `logger[f](msg)` unprotected and crashed.
function TestLogger:testMissingLevelIsSilentOnRepeatedCalls()
  fake_logger({ 'info' })
  local l = fresh_logger()

  local ok, err = pcall(function()
    l.warn('first')
    l.warn('second')
    l.error('third')
  end)

  lu.assertTrue(ok, tostring(err))
end

--- A logger method that throws must not propagate into plugin loading.
function TestLogger:testThrowingLoggerIsSilent()
  package.preload['logger'] = function()
    return {
      derive = function()
        return {
          info = function()
            error('logger exploded')
          end,
        }
      end,
    }
  end
  local l = fresh_logger()

  local ok, err = pcall(function()
    l.info('first')
    l.info('second')
  end)

  lu.assertTrue(ok, tostring(err))
end

-----------------------------------------------------------
-- caching
-----------------------------------------------------------

--- A failed lookup must be cached. The old implementation left `logger`
--- nil and retried require() on every single log call.
function TestLogger:testFailedLookupIsCached()
  local attempts = 0
  package.preload['logger'] = function()
    attempts = attempts + 1
    error('module logger not found')
  end
  local l = fresh_logger()

  l.info('a')
  l.debug('b')
  l.warn('c')
  l.error('d')

  lu.assertEquals(attempts, 1)
end

--- A successful lookup must be cached too.
function TestLogger:testSuccessfulLookupIsCached()
  local attempts = 0
  package.preload['logger'] = function()
    attempts = attempts + 1
    return {
      derive = function()
        return { info = function() end }
      end,
    }
  end
  local l = fresh_logger()

  l.info('a')
  l.info('b')

  lu.assertEquals(attempts, 1)
end

-----------------------------------------------------------
-- module shape
-----------------------------------------------------------

function TestLogger:testAllLevelsExist()
  for _, name in ipairs({ 'info', 'debug', 'warn', 'error' }) do
    lu.assertEquals(type(log[name]), 'function', name)
  end
end

return TestLogger

