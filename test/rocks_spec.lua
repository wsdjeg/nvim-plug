-- test/rocks_spec.lua
-- Tests for plug.rocks module

local lu = require('luaunit')
local rocks = require('plug.rocks')

local TestRocks = {}

local orig_system
local orig_executable

function TestRocks:setUp()
  orig_system = vim.system
  orig_executable = vim.fn.executable
end

function TestRocks:tearDown()
  vim.system = orig_system
  vim.fn.executable = orig_executable
  rocks.refresh()
end

-----------------------------------------------------------
-- parse_list()
-----------------------------------------------------------

--- `luarocks list --porcelain` is tab separated:
--- name, version, status, deploy dir.
function TestRocks:testParseListReadsValidLine()
  local parsed = rocks.parse_list('foo\t1.0\tinstalled\t/tmp/deploy/lua\n')
  lu.assertNotNil(parsed['foo'])
  -- the deploy dir must be joined with a separator even when it does not
  -- end with one (the directory need not exist on disk)
  lu.assertEquals(parsed['foo'].rtp, '/tmp/deploy/lua/foo/1.0')
end

--- A trailing separator must not be doubled.
function TestRocks:testParseListHandlesTrailingSlash()
  local parsed = rocks.parse_list('bar\t2.0\tinstalled\t/tmp/deploy/lua/\n')
  lu.assertEquals(parsed['bar'].rtp, '/tmp/deploy/lua/bar/2.0')
end

--- Blank lines and short lines must be skipped. Indexing them produced
--- nil keys in the cache table.
function TestRocks:testParseListSkipsMalformedLines()
  local parsed = rocks.parse_list(table.concat({
    '',
    'only-name',
    'name\tversion',
    'good\t1.0\tinstalled\t/tmp/deploy',
    '',
  }, '\n'))

  lu.assertNotNil(parsed['good'])
  lu.assertNil(parsed['only-name'])
  lu.assertNil(parsed['name'])
  lu.assertEquals(#vim.tbl_keys(parsed), 1)
end

function TestRocks:testParseListEmptyInput()
  lu.assertEquals(rocks.parse_list(''), {})
  lu.assertEquals(rocks.parse_list(nil), {})
end

-----------------------------------------------------------
-- get()
-----------------------------------------------------------

function TestRocks:testGetReturnsNilForUnknownRock()
  local result = rocks.get('nonexistent-rock-12345')
  lu.assertNil(result)
end

--- The `luarocks list` subprocess must run at most once per cache
--- generation. It used to run again for every rock that was not installed,
--- i.e. once per rocks plugin being loaded.
function TestRocks:testGetScansOnlyOnce()
  local calls = 0
  vim.fn.executable = function()
    return 1
  end
  vim.system = function(cmd)
    if cmd[1] == 'luarocks' and cmd[2] == 'list' then
      calls = calls + 1
    end
    return {
      wait = function()
        return { stdout = 'seed\t1.0\tinstalled\t/tmp/deploy\n' }
      end,
    }
  end

  rocks.refresh()
  local found = rocks.get('seed')
  local missing = rocks.get('unknown')

  lu.assertNotNil(found)
  lu.assertEquals(found.rtp, '/tmp/deploy/seed/1.0')
  lu.assertNil(missing)
  lu.assertEquals(calls, 1)
end

--- refresh() drops the cache so a newly installed rock is found.
function TestRocks:testRefreshPicksUpNewRocks()
  local output = 'first\t1.0\tinstalled\t/tmp/deploy\n'
  vim.fn.executable = function()
    return 1
  end
  vim.system = function()
    return {
      wait = function()
        return { stdout = output }
      end,
    }
  end

  rocks.refresh()
  lu.assertNotNil(rocks.get('first'))
  lu.assertNil(rocks.get('second'))

  output = 'first\t1.0\tinstalled\t/tmp/deploy\n'
    .. 'second\t2.0\tinstalled\t/tmp/deploy\n'
  rocks.refresh()

  lu.assertNotNil(rocks.get('second'))
end

--- Missing luarocks must not spawn a subprocess at all.
function TestRocks:testGetWithoutLuarocksDoesNotSpawn()
  local spawned = false
  vim.fn.executable = function()
    return 0
  end
  vim.system = function()
    spawned = true
    return { wait = function() return { stdout = '' } end }
  end

  rocks.refresh()
  lu.assertNil(rocks.get('anything'))
  lu.assertFalse(spawned)
end

--- A failing `luarocks list` run is logged, not raised.
function TestRocks:testGetSurvivesSystemError()
  vim.fn.executable = function()
    return 1
  end
  vim.system = function()
    error('luarocks exploded')
  end

  rocks.refresh()
  local ok = pcall(rocks.get, 'anything')
  lu.assertTrue(ok)
end

-----------------------------------------------------------
-- enable() / set_rtp()
-----------------------------------------------------------

function TestRocks:testEnableDoesNotError()
  rocks.enable()
  lu.assertTrue(true)
end

function TestRocks:testEnableWithoutLuarocksDoesNotSpawn()
  local spawned = false
  vim.fn.executable = function()
    return 0
  end
  vim.system = function()
    spawned = true
    return { wait = function() return { stdout = '{}' } end }
  end

  rocks.enable()
  lu.assertFalse(spawned)

  -- restore so later tests see the real implementation
  vim.fn.executable = orig_executable
  vim.system = orig_system
end

function TestRocks:testSetRtpDoesNotErrorForUnknownSpec()
  rocks.set_rtp({ name = 'nonexistent-rock-12345' })
  lu.assertTrue(true)
end

--- set_rtp() fills in the rtp of a spec that maps to an installed rock.
function TestRocks:testSetRtpAssignsPath()
  vim.fn.executable = function()
    return 1
  end
  vim.system = function()
    return {
      wait = function()
        return { stdout = 'known\t1.0\tinstalled\t/tmp/deploy\n' }
      end,
    }
  end

  rocks.refresh()
  local spec = { name = 'known', type = 'rocks' }
  rocks.set_rtp(spec)

  lu.assertEquals(spec.rtp, '/tmp/deploy/known/1.0')
end

--- Verify that unify_path is no longer duplicated on the rocks module.
function TestRocks:testUnifyPathNotDuplicated()
  lu.assertNil(rocks.unify_path)
end

return TestRocks

