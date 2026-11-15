--=============================================================================
-- config.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@class PlugOpts
---@field bundle_dir? string                          # directory plugins are cloned into
---@field raw_plugin_dir? string                      # directory raw plugins are downloaded into
---@field max_processes? integer                      # max concurrent jobs
---@field base_url? string                            # base url used to build plugin urls
---@field ui? 'default'|'notify'|fun(name: string, data: table)
---@field http_proxy? string|nil                      # default: nil
---@field https_proxy? string|nil                     # default: nil
---@field clone_depth? integer|string                 # default `git clone` depth, 0 disables `--depth`
---@field enable_priority? boolean                    # load plugins ordered by priority
---@field focus_window? boolean                       # focus the UI window when it opens
---@field import? string                              # directory name for auto-loading plugin specs
---@field enable_luarocks? boolean                    # enable LuaRocks integration
---@field dev_path? string|nil                        # development directory for local plugins

---@class Plug.Config: PlugOpts
local M = {}

M.bundle_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'repos')
M.raw_plugin_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'repos/raw_plugin')
M.dev_path = nil
M.max_processes = 5
M.base_url = 'https://github.com'
M.ui = 'default'
M.clone_depth = 1
M.import = 'plugins'
M.enable_priority = false
M.enable_luarocks = false
M.focus_window = false
M.http_proxy = nil
M.https_proxy = nil

--- Merge user options into the current configuration.
---
--- Only keys present in `opt` are touched, and `false` / `0` / `''` are
--- treated as real values. Using `opt.k or M.k` here would silently drop
--- those, e.g. `enable_priority = false` could never turn the flag off and
--- repeated `setup()` calls would wipe the proxies.
---@param opt? PlugOpts
function M.setup(opt)
  opt = opt or {}

  local function merge(key, value)
    if value ~= nil then
      M[key] = value
    end
  end

  merge('bundle_dir', opt.bundle_dir)
  merge('max_processes', opt.max_processes)
  merge('base_url', opt.base_url)
  merge('ui', opt.ui)
  merge('http_proxy', opt.http_proxy)
  merge('https_proxy', opt.https_proxy)
  merge('clone_depth', opt.clone_depth)
  merge('raw_plugin_dir', opt.raw_plugin_dir)
  merge('enable_priority', opt.enable_priority)
  merge('focus_window', opt.focus_window)
  merge('import', opt.import)
  merge('dev_path', opt.dev_path)
  merge('enable_luarocks', opt.enable_luarocks)

  if M.enable_luarocks then
    require('plug.rocks').enable()
  end
end

return M

