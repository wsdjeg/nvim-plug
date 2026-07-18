-- test/example_spec.lua
-- Example test file demonstrating the test framework usage

local lu = require('luaunit')
local plug = require('plug')

local TestExample = {}

function TestExample:setUp()
  -- This runs before each test
end

function TestExample:tearDown()
  -- This runs after each test
end

function TestExample:test_plug_module_exists()
  lu.assertNotNil(plug)
  lu.assertEquals(type(plug), 'table')
end

function TestExample:test_setup_function_exists()
  lu.assertEquals(type(plug.setup), 'function')
end

function TestExample:test_add_function_exists()
  lu.assertEquals(type(plug.add), 'function')
end

function TestExample:test_get_function_exists()
  lu.assertEquals(type(plug.get), 'function')
end

function TestExample:test_load_function_exists()
  lu.assertEquals(type(plug.load), 'function')
end

function TestExample:test_get_returns_table()
  local result = plug.get()
  lu.assertEquals(type(result), 'table')
end

return TestExample

