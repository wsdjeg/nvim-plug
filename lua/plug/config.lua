--=============================================================================
-- config.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@class Plug.Config
local M = {}

---@class NvimPlugOpts
-- set the bundle dir
---@field bundle_dir? string
-- set the path where raw plugin is download to
---@field raw_plugin_dir? string
-- max number of processes used for nvim-plug job
---@field max_processes? integer
---@field base_url? string
-- default ui is `default`,
-- to use `notify` for floating window notify
-- you need to install wsdjeg/notify.nvim
---@field ui? 'default'|'notify'
-- default is nil
---@field http_proxy? nil|string
-- default is nil
---@field https_proxy? nil|string
-- default history depth for `git clone`
---@field clone_depth? integer
-- plugin priority, readme [plugin priority] for more info
---@field enable_priority? boolean
---@field import? string
---@field enable_luarocks? boolean
---@field dev_path? nil|string

M.bundle_dir = vim.fn.stdpath('data') .. '/repos'
M.raw_plugin_dir = vim.fn.stdpath('data') .. '/repos/raw_plugin'
M.dev_path = nil
M.max_processes = 5
M.base_url = 'https://github.com'
M.ui = 'default'
M.clone_depth = '1'
M.import = 'plugins'
M.enable_priority = false
M.enable_luarocks = false

---@param opt? NvimPlugOpts
function M.setup(opt)
  opt = opt or {}

  M.bundle_dir = opt.bundle_dir or M.bundle_dir
  M.max_processes = opt.max_processes or M.max_processes
  M.base_url = opt.base_url or M.base_url
  M.ui = opt.ui or M.ui
  M.http_proxy = opt.http_proxy
  M.https_proxy = opt.https_proxy
  M.clone_depth = opt.clone_depth or M.clone_depth
  M.raw_plugin_dir = opt.raw_plugin_dir or M.raw_plugin_dir
  M.enable_priority = opt.enable_priority or M.enable_priority
  M.import = opt.import or M.import
  M.dev_path = opt.dev_path or M.dev_path
  M.enable_luarocks = opt.enable_luarocks or M.enable_luarocks
  if M.enable_luarocks then
    require('plug.rocks').enable()
  end
end

return M
