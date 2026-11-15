---@class Plug.Rocks
local M = {}

local log = require('plug.logger')

local rocks = {} ---@type table<string, { rtp: string }>

--- Whether the installed rock list has already been scanned.
--- Kept separate from `rocks` so an empty result is not re-scanned: a single
--- `luarocks list` subprocess should serve every lookup until refresh().
local scanned = false ---@type boolean

--- Join a deploy directory with a rock name and version.
---
--- The deploy directory does not necessarily exist on disk, so it cannot
--- rely on util.unify_path() adding a trailing separator: a missing one would
--- concatenate `/tmp/deploy/lua` with `foo` into `/tmp/deploy/lua/foo` — or
--- worse, `/tmp/deploy/luafoo`.
---@param dir string
---@param name string
---@param version string
---@return string rtp
local function join_rtp(dir, name, version)
  if dir == '' then
    return ''
  end
  local base = dir
  if base:sub(-1) ~= '/' and base:sub(-1) ~= '\\' then
    base = base .. '/'
  end
  return base .. name .. '/' .. version
end

--- Parse `luarocks list --porcelain` output.
---
--- Each line is tab separated: `name`, `version`, `status`, `deploy dir`.
--- Blank and short lines are skipped; indexing them blindly put entries with
--- a nil key into the cache table.
---@param output string|nil
---@return table<string, { rtp: string }> parsed
function M.parse_list(output)
  local parsed = {} ---@type table<string, { rtp: string }>
  if type(output) ~= 'string' or output == '' then
    return parsed
  end

  for _, line in ipairs(vim.split(output, '\n')) do
    if line ~= '' then
      local fields = vim.split(line, '\t')
      if #fields >= 4 and fields[1] ~= '' and fields[2] ~= '' then
        parsed[fields[1]] = {
          rtp = join_rtp(fields[4], fields[1], fields[2]),
        }
      end
    end
  end

  return parsed
end

--- Drop the cache so the next lookup rescans installed rocks.
function M.refresh()
  rocks = {}
  scanned = false
end

--- Scan installed rocks, at most once per cache generation.
local function scan()
  if scanned then
    return
  end
  scanned = true

  if vim.fn.executable('luarocks') == 0 then
    return
  end

  local ok, output = pcall(function()
    return vim
      .system({ 'luarocks', 'list', '--porcelain' }, { text = true })
      :wait().stdout
  end)
  if not ok then
    log.warn('failed to list luarocks packages: ' .. tostring(output))
    return
  end

  rocks = M.parse_list(output)
end

local enabled = false ---@type boolean

function M.enable()
  if enabled then
    return
  end
  if vim.fn.executable('luarocks') == 0 then
    return
  end

  local ok, err = pcall(function()
    local luarocks_config = vim.json.decode(
      vim.system({ 'luarocks', 'config', '--json' }):wait().stdout
    )
    package.path = string.format(
      '%s;%s/?.lua;%s/?/init.lua;',
      package.path,
      luarocks_config.deploy_lua_dir,
      luarocks_config.deploy_lua_dir
    )
    --- D:\Scoop\apps\luarocks\current\rocks\lib\lua\5.4\?.dll
    package.cpath = package.cpath
      .. ';'
      .. luarocks_config.deploy_lib_dir
      .. '/?.'
      .. luarocks_config.external_lib_extension
    vim.env.LUA_PATH = package.path
    vim.env.LUA_CPATH = package.cpath
  end)
  if ok then
    enabled = true
  else
    log.warn('failed to enable luarocks support: ' .. tostring(err))
  end
end

---@param rock string
---@return { rtp: string }|nil retrieved
function M.get(rock)
  scan()
  return rocks[rock]
end

---@param spec PluginSpec
function M.set_rtp(spec)
  local rock = M.get(spec.name)
  if rock then
    spec.rtp = rock.rtp
  end
end

return M

