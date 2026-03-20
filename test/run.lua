-- test/run.lua
-- Test runner for headless Neovim

local lu = require('luaunit')

-- Add test directory to runtime path
vim.opt.runtimepath:append('.')

-- Get all test files dynamically
local test_files = vim.split(vim.fn.globpath('test', '*_spec.lua'), '\n')
-- Remove empty string if no matches
if test_files[#test_files] == '' then
  table.remove(test_files)
end

-- Run all tests
local function run_tests()
  print('=== Chat.nvim Test Suite ===')
  print(string.format('Found %d test file(s)\n', #test_files))

  if #test_files == 0 then
    print('[ERROR] No test files found')
    return 1
  end

  local loaded_count = 0
  local failed_count = 0

  -- Load each test file
  for _, test_file in ipairs(test_files) do
    local ok, result = pcall(dofile, test_file)
    if ok then
      print(string.format('[OK] Loaded: %s', test_file))
      loaded_count = loaded_count + 1
    else
      print(string.format('[FAIL] Failed to load: %s', test_file))
      print(string.format('  Error: %s', result))
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

  -- Run test suite with tap output (shows each test on separate line)
  print('\nRunning tests...\n')
  local runner = lu.LuaUnit:new()
  runner:setOutputType('tap')
  local result = runner:runSuite()

  return result
end

-- Run tests and exit
local exit_code = run_tests()

-- Clean up temporary test files
local temp_pattern = '/tmp/nvim-plug_test_'
local temp_files = vim.fn.glob(temp_pattern .. '*', true, true)
for _, file in ipairs(temp_files) do
  vim.fn.delete(file, 'rf')
end

-- vim.cmd('qa!')
os.exit(exit_code)
