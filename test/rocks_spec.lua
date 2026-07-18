-- test/rocks_spec.lua
-- Tests for plug.rocks module

local lu = require('luaunit')
local rocks = require('plug.rocks')

local TestRocks = {}

function TestRocks:testUnifyPathExists()
  lu.assertEquals(type(rocks.unify_path), 'function')
end

function TestRocks:testUnifyPathBasic()
  local result = rocks.unify_path('/tmp/test.lua')
  lu.assertNotNil(result)
  lu.assertStrContains(result, 'test.lua')
end

function TestRocks:testGetReturnsNilForUnknownRock()
  -- get() should return nil for a non-existent rock name
  local result = rocks.get('nonexistent-rock-12345')
  lu.assertNil(result)
end

function TestRocks:testEnableDoesNotError()
  -- enable() should not error even if luarocks is not installed
  rocks.enable()
  lu.assertTrue(true)
end

function TestRocks:testSetRtpDoesNotErrorForUnknownSpec()
  rocks.set_rtp({ name = 'nonexistent-rock-12345' })
  lu.assertTrue(true)
end

return TestRocks

