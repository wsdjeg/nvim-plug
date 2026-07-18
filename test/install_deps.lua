-- test/install_deps.lua
-- Cross-platform test dependency installer
-- Replaces shell-based makefile targets (if [ ... ]; then ... fi doesn't work on Windows)

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function download(url, dest)
  -- Use Neovim's built-in curl-like capability via vim.fn.system
  -- or fall back to LuaSocket if available
  local has_curl = vim.fn.executable('curl') == 1
  if has_curl then
    local cmd = { 'curl', '-fsSL', url, '-o', dest }
    local result = vim.fn.system(cmd)
    return vim.v.shell_error == 0
  end

  -- Fallback: try powershell on Windows
  if vim.fn.has('win32') == 1 then
    local ps_cmd = string.format(
      "Invoke-WebRequest -Uri '%s' -OutFile '%s'",
      url, dest
    )
    local result = vim.fn.system({ 'powershell', '-Command', ps_cmd })
    return vim.v.shell_error == 0
  end

  -- Fallback: try wget
  local has_wget = vim.fn.executable('wget') == 1
  if has_wget then
    local cmd = { 'wget', '-q', url, '-O', dest }
    local result = vim.fn.system(cmd)
    return vim.v.shell_error == 0
  end

  return false
end

local deps_dir = 'test/.deps'
mkdir(deps_dir)

-- Install luaunit
local luaunit_path = deps_dir .. '/luaunit.lua'
local luaunit_url = 'https://raw.githubusercontent.com/bluebird75/luaunit/main/luaunit.lua'

if file_exists(luaunit_path) then
  print('luaunit already installed')
else
  print('Installing luaunit...')
  if download(luaunit_url, luaunit_path) then
    print('luaunit installed to ' .. luaunit_path)
  else
    print('[ERROR] Failed to download luaunit')
    os.exit(1)
  end
end

-- Install job.nvim mock
local job_path = deps_dir .. '/job.lua'
local job_url = 'https://raw.githubusercontent.com/wsdjeg/job.nvim/refs/heads/master/lua/job/init.lua'

if file_exists(job_path) then
  print('job.nvim already installed')
else
  print('Installing job.nvim...')
  if download(job_url, job_path) then
    print('job.nvim installed to ' .. job_path)
  else
    print('[ERROR] Failed to download job.nvim')
    os.exit(1)
  end
end

print('All dependencies installed.')
os.exit(0)

