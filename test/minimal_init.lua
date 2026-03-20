-- test/minimal_init.lua
-- Minimal Neovim configuration for testing

print('Initializing test environment...')

-- Set up essential settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false
vim.opt.verbose = 1

-- Set up package path
vim.opt.runtimepath:prepend('.')

-- Create temporary test directory
local test_dir = vim.fn.tempname() .. '_chat_nvim_test'
vim.fn.mkdir(test_dir, 'p')

-- Load plugin with test configuration
local ok, err = pcall(function()
  require('chat').setup({
    provider = 'test-provider',
    model = 'test-model',
    api_key = {
      test_provider = 'test-key',
    },
    memory = {
      enable = true,
      storage_dir = test_dir .. '/memory/',
    },
    http = {
      api_key = '', -- Disable HTTP server for tests
    },
    allowed_path = vim.fn.getcwd(),
  })
end)

if not ok then
  print('Error initializing test environment: ' .. err)
else
  print('Test environment initialized successfully')
  print('Test directory: ' .. test_dir)
end
