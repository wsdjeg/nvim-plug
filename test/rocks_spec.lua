-- test/rocks_spec.lua
-- Tests for plug.rocks module

local lu = require('luaunit')
local rocks = require('plug.rocks')

local TestRocks = {}

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

--- Verify that unify_path is no longer duplicated on the rocks module.
--- It should use plug.util.unify_path instead.
function TestRocks:testUnifyPathNotDuplicated()
  lu.assertNil(rocks.unify_path)
end

return TestRocks

