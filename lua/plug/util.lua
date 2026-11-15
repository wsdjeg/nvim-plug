---@class Plug.Util
local M = {}

local is_win = vim.fn.has('win32') == 1

--- Normalise a path for internal use.
---
--- Returns `''` for `nil`, non-string and empty input instead of raising.
--- Callers build paths by concatenation, e.g.
--- `util.unify_path(config.dev_path) .. spec.name`, and `dev_path` is `nil`
--- by default, so raising here would break any `dev = true` spec when no
--- dev directory is configured.
---
--- Directories always come back with a trailing `/`, so that
--- `path .. 'sub/dir'` stays valid on every platform.
---@param _path string|nil path to normalise
---@param ... string|nil fnamemodify modifier, defaults to `:p`
---@return string path normalised path, `''` when the input is unusable
function M.unify_path(_path, ...)
  if type(_path) ~= 'string' or _path == '' then
    return ''
  end

  local mod = select(1, ...)
  if type(mod) ~= 'string' or mod == '' then
    mod = ':p'
  end

  local path = vim.fn.fnamemodify(_path, mod .. ':gs?[\\\\/]?/?')
  if is_win and vim.regex('^[a-zA-Z]:/'):match_str(path) then
    path = path:sub(1, 1):upper() .. path:sub(2)
  end

  if vim.fn.isdirectory(path) == 1 then
    if path:sub(-1) ~= '/' then
      return path .. '/'
    end
    return path
  end

  if _path:sub(-1) == '/' and path:sub(-1) ~= '/' then
    return path .. '/'
  end

  return path
end

return M

