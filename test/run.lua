-- test/run.lua
-- Test runner for headless Neovim

local lu = require('luaunit')

-- Add test directory to runtime path
vim.opt.runtimepath:append('.')

-- Setup package.path to support test submodules
package.path = 'test/?.lua;lua/?.lua;' .. package.path

-- Get test files based on PATTERN parameter
local function get_test_files()
  local pattern = _G.TEST_PATTERN
  -- Clear global to avoid LuaUnit picking it up as a test name
  _G.TEST_PATTERN = nil

  if not pattern or pattern == '' then
    -- No PATTERN specified, run all tests
    local files = vim.split(vim.fn.globpath('test', '**/*_spec.lua'), '\n')
    if files[#files] == '' then
      table.remove(files)
    end
    return files
  end

  -- PATTERN parameter specified
  local files = {}

  -- Check if it's a full path
  if pattern:match('^test/') or pattern:match('^test\\') then
    -- Full path provided
    if vim.fn.filereadable(pattern) == 1 then
      table.insert(files, pattern)
    else
      print(string.format('[ERROR] Test file not found: %s', pattern))
      return {}
    end
  else
    -- Shorthand: search for matching files
    -- e.g., "util" -> test/**/*util*_spec.lua
    files = vim.split(vim.fn.globpath('test', string.format('**/*%s*_spec.lua', pattern)), '\n')

    -- Also try exact match: e.g., "util_spec.lua"
    if #files == 0 then
      files = vim.split(vim.fn.globpath('test', string.format('%s*_spec.lua', pattern)), '\n')
    end

    -- Try with _spec.lua suffix
    if #files == 0 then
      files = vim.split(vim.fn.globpath('test', string.format('**/%s_spec.lua', pattern)), '\n')
    end

    -- Remove empty strings
    local filtered = {}
    for _, f in ipairs(files) do
      if f ~= '' then
        table.insert(filtered, f)
      end
    end
    files = filtered
  end

  return files
end

-- Run all tests
local function run_tests()
  local test_files = get_test_files()

  print('=== nvim-plug Test Suite ===')
  if _G.TEST_PATTERN and _G.TEST_PATTERN ~= '' then
    print(string.format('Filter: %s', _G.TEST_PATTERN))
  end
  print(string.format('Found %d test file(s)\n', #test_files))

  if #test_files == 0 then
    print('[ERROR] No test files found')
    return 1
  end

  local loaded_count = 0
  local failed_count = 0

  -- Load each test file
  for _, test_file in ipairs(test_files) do
    local ok, err = pcall(dofile, test_file)
    if ok then
      print(string.format('[OK] Loaded: %s', test_file))
      loaded_count = loaded_count + 1
    else
      print(string.format('[FAIL] Failed to load: %s', test_file))
      print(string.format('  Error: %s', err))
      failed_count = failed_count + 1
    end
  end

  print(
    string.format(
      '\n=== Loaded %d/%d test files ===',
      loaded_count,
      #test_files
    )
  )

  if failed_count > 0 then
    print(string.format('[ERROR] Failed to load %d test files', failed_count))
    return 1
  end

  -- Run test suite (LuaUnit automatically finds all Test* classes in global namespace)
  print('\nRunning tests...\n')
  local runner = lu.LuaUnit:new()
  runner:setOutputType('tap')
  local result = runner:runSuite()

  return result
end

-- Run tests and exit
local exit_code = run_tests()

-- Clean up temporary test files
local temp_pattern = '/tmp/nvim_plug_test_'
local temp_files = vim.fn.glob(temp_pattern .. '*', true, true)
for _, file in ipairs(temp_files) do
  vim.fn.delete(file, 'rf')
end

os.exit(exit_code)

