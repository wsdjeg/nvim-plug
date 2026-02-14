--=============================================================================
-- plug.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@param a string
---@return string[]
local function complete(a)
  local plug_name = {} ---@type string[]
  for k, _ in pairs(require('plug').get()) do
    if a and vim.startswith(k, a) then
      table.insert(plug_name, k)
    end
  end
  return plug_name
end

vim.api.nvim_create_user_command('PlugInstall', function(opt)
  local plugs = {} ---@type PluginSpec[]
  local all_plugins = require('plug').get()
  if vim.tbl_isempty(opt.fargs) then
    for _, v in pairs(all_plugins) do
      table.insert(plugs, v)
    end
  else
    for _, v in ipairs(opt.fargs) do
      if all_plugins[v] then
        table.insert(plugs, all_plugins[v])
      end
    end
  end
  require('plug.installer').install(plugs)
  local c = require('plug.config')
  if c.ui == 'default' then
    require('plug.ui').open()
  end
end, {
  nargs = '*',
  complete = complete,
})

vim.api.nvim_create_user_command('PlugUpdate', function(opt)
  local plugs = {} ---@type PluginSpec[]
  local force = false
  local all_plugins = require('plug').get()
  if vim.tbl_isempty(opt.fargs) then
    for _, v in pairs(all_plugins) do
      table.insert(plugs, v)
    end
  else
    force = true
    for _, v in ipairs(opt.fargs) do
      if all_plugins[v] then
        table.insert(plugs, all_plugins[v])
      end
    end
  end
  require('plug.installer').update(plugs, force)
  local c = require('plug.config')
  if c.ui == 'default' then
    require('plug.ui').open()
  end
end, {
  nargs = '*',
  complete = complete,
})

vim.api.nvim_create_user_command('Plug', function(opt)
  require('plug.command').run(opt)
end, {
  nargs = '*',
  complete = require('plug.command').complete,
})
