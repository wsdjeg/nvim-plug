-- test/util_spec.lua
local lu = require('luaunit')
local util = require('plug.util')

local TestUtil = {}

function TestUtil:testUnifyPath()
  local result = util.unify_path('/tmp/test.lua')
  lu.assertNotNil(result)
  lu.assertStrContains(result, 'test.lua')
end

function TestUtil:testUnifyPathWithMod()
  local result = util.unify_path('/tmp/test.lua', ':p')
  lu.assertNotNil(result)
  lu.assertStrContains(result, 'test.lua')
end

function TestUtil:testUnifyPathDirectory()
  local test_dir = vim.fn.tempname() .. '_test_dir'
  vim.fn.mkdir(test_dir, 'p')

  local result = util.unify_path(test_dir)
  lu.assertNotNil(result)
  lu.assertEquals(result:sub(-1), '/')

  vim.fn.delete(test_dir, 'rf')
end

function TestUtil:testUnifyPathTrailingSlash()
  local result = util.unify_path('/tmp/test/', ':p')
  lu.assertNotNil(result)
  lu.assertEquals(result:sub(-1), '/')
end

function TestUtil:testUnifyPathWindows()
  if vim.fn.has('win32') == 1 then
    local result = util.unify_path('c:/test/path')
    lu.assertNotNil(result)
    lu.assertEquals(result:sub(1, 1), 'C')
  else
    lu.assertTrue(true)
  end
end

-----------------------------------------------------------
-- nil / empty input
-----------------------------------------------------------

--- Callers concatenate the result, e.g.
--- `util.unify_path(config.dev_path) .. spec.name`. `dev_path` is nil by
--- default, so unify_path must return '' instead of raising
--- "String required for argument 1" from fnamemodify(nil).
function TestUtil:testUnifyPathNilReturnsEmpty()
  local ok, result = pcall(util.unify_path, nil)
  lu.assertTrue(ok, tostring(result))
  lu.assertEquals(result, '')
end

function TestUtil:testUnifyPathEmptyReturnsEmpty()
  lu.assertEquals(util.unify_path(''), '')
end

--- Non-string input must not raise either.
function TestUtil:testUnifyPathNonStringReturnsEmpty()
  local ok, result = pcall(util.unify_path, 123)
  lu.assertTrue(ok, tostring(result))
  lu.assertEquals(result, '')
end

--- An explicit nil modifier keeps the default ':p' behaviour.
function TestUtil:testUnifyPathNilModUsesDefault()
  local result = util.unify_path('/tmp/test.lua', nil)
  lu.assertEquals(result, util.unify_path('/tmp/test.lua', ':p'))
end

--- Only the first modifier argument is honoured (legacy vararg call style).
function TestUtil:testUnifyPathExtraArgsAreIgnored()
  local ok = pcall(util.unify_path, '/tmp/test.lua', ':p', 'ignored')
  lu.assertTrue(ok)
end

--- A non-directory path must not gain a trailing slash.
function TestUtil:testUnifyPathFileHasNoTrailingSlash()
  local tmp = vim.fn.tempname()
  vim.fn.writefile({ 'x' }, tmp)

  local result = util.unify_path(tmp)
  lu.assertEquals(result:sub(-1) == '/', false)

  vim.fn.delete(tmp)
end

return TestUtil

