-- test/util_spec.lua
local lu = require('luaunit')
local util = require('plug.util')

local TestUtil = {}

function TestUtil:testUnifyPath()
  -- Test path normalization
  local result = util.unify_path('/tmp/test.lua')
  lu.assertNotNil(result)
  lu.assertStrContains(result, 'test.lua')
end

function TestUtil:testUnifyPathWithMod()
  -- Test with different mods
  local result = util.unify_path('/tmp/test.lua', ':p')
  lu.assertNotNil(result)
  lu.assertStrContains(result, 'test.lua')
end

function TestUtil:testUnifyPathDirectory()
  -- Test directory path
  local test_dir = vim.fn.tempname() .. '_test_dir'
  vim.fn.mkdir(test_dir, 'p')
  
  local result = util.unify_path(test_dir)
  lu.assertNotNil(result)
  -- Directory should end with /
  if vim.fn.isdirectory(test_dir) == 1 then
    lu.assertEquals(string.sub(result, -1), '/')
  end
  
  -- Clean up
  vim.fn.delete(test_dir, 'rf')
end

function TestUtil:testUnifyPathTrailingSlash()
  -- Test path with trailing slash
  local result = util.unify_path('/tmp/test/', ':p')
  lu.assertNotNil(result)
  -- Should preserve trailing slash
  lu.assertEquals(string.sub(result, -1), '/')
end

function TestUtil:testUnifyPathWindows()
  -- Test Windows path normalization (only on Windows)
  if vim.fn.has('win32') == 1 then
    local result = util.unify_path('c:/test/path')
    lu.assertNotNil(result)
    -- Drive letter should be uppercase
    lu.assertEquals(string.sub(result, 1, 1), 'C')
  else
    -- Skip on non-Windows
    lu.assertTrue(true)
  end
end

return TestUtil

