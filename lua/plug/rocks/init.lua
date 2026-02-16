---@class Plug.Rocks
local M = {}

local rocks = {} ---@type table<string, { rtp: string }>

local function get_installed_rocks()
  if vim.fn.executable('luarocks') == 0 then
    return {}
  end
  --- @type string
  local installed_output = vim
    .system({ 'luarocks', 'list', '--porcelain' }, { text = true })
    :wait().stdout

  for _, v in
    ipairs(vim.tbl_map(
      function(t) ---@param t string
        return vim.split(t, '\t')
      end,
      vim.tbl_filter(function(t) ---@param t string
        return t ~= ''
      end, vim.split(installed_output, '\n'))
    ))
  do
    ---@cast v string[]
    rocks[v[1]] = {
      rtp = M.unify_path(v[4]) .. v[1] .. '/' .. v[2],
    }
  end
end

local is_win = vim.fn.has('win32') == 1

---@param _path string
function M.unify_path(_path, ...)
  local mod = select(1, ...)
  if mod == nil then
    mod = ':p'
  end
  local path = vim.fn.fnamemodify(_path, mod .. ':gs?[\\\\/]?/?')
  if is_win and vim.regex('^[a-zA-Z]:/'):match_str(path) then
    path = string.upper(string.sub(path, 1, 1)) .. string.sub(path, 2)
  end
  if vim.fn.isdirectory(path) == 1 and string.sub(path, -1) ~= '/' then
    return path .. '/'
  end
  if string.sub(_path, -1) == '/' and string.sub(path, -1) ~= '/' then
    return path .. '/'
  end

  return path
end

local enabled ---@type boolean
function M.enable()
  if enabled then
    return
  end
  local ok, _ = pcall(function()
    local luarocks_config = vim.json.decode(
      vim.system({ 'luarocks', 'config', '--json' }):wait().stdout
    )
    package.path = string.format(
      '%s;%s%s;%s%s;',
      package.path,
      luarocks_config.deploy_lua_dir,
      [[\?.lua]],
      luarocks_config.deploy_lua_dir,
      [[\?\init.lua]]
    )
    --- D:\Scoop\apps\luarocks\current\rocks\lib\lua\5.4\?.dll
    package.cpath = package.cpath
      .. ';'
      .. luarocks_config.deploy_lib_dir
      .. '\\?.'
      .. luarocks_config.external_lib_extension
    vim.env.LUA_PATH = package.path
    vim.env.LUA_CPATH = package.cpath
  end)
  if ok then
    enabled = true
  end
end

---@param rock string
---@return { rtp: string } retrieved
function M.get(rock)
  if not rocks[rock] then
    get_installed_rocks()
  end
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
