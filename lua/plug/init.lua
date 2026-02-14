--=============================================================================
-- plug.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@class Plug
local M = {}

local all_plugins = {} ---@type table<string, PluginSpec>

local hooks = require('plug.hooks')
local loader = require('plug.loader')
local config = require('plug.config')

---@param opt? NvimPlugOpts
function M.setup(opt)
  config.setup(opt)
end

--- @param plugins PluginSpec[]
function M.add(plugins, skip_deps)
  for _, plug in ipairs(plugins) do
    if plug.depends and not skip_deps then
      M.add(plug.depends)
      M.add({ plug }, true)
    else
      loader.parser(plug)
      if plug.enabled then
        all_plugins[plug.name] = plug
        if plug.keys then
          for _, key in ipairs(plug.keys) do
            pcall(function()
              vim.keymap.set(unpack(key))
            end)
          end
        end
        if plug.cmds then
          hooks.on_cmds(plug.cmds, plug)
        end
        if plug.events then
          hooks.on_events(plug.events, plug)
        end

        if plug.on_ft then
          hooks.on_ft(plug.on_ft, plug)
        end

        if plug.on_map then
          hooks.on_map(plug.on_map, plug)
        end

        if plug.on_func then
          hooks.on_func(plug.on_func, plug)
        end

        if
          not (
            config.enable_priority
            or plug.events
            or plug.cmds
            or plug.on_ft
            or plug.on_map
            or plug.on_func
          )
        then
          loader.load(plug)
        end
      end
    end
  end
end

---@return table<string, PluginSpec> all_plugins
function M.get()
  return all_plugins
end

function M.load()
  if config.enable_priority then
    local start = {}
    for _, v in pairs(all_plugins) do
      if not (v.events or v.cmds or v.on_ft or v.on_map or v.on_func) then
        table.insert(start, v)
      end
    end
    table.sort(start, function(a, b)
      local priority_a = a.priority or 50
      local priority_b = b.priority or 50
      return priority_a > priority_b
    end)
    for _, v in ipairs(start) do
      loader.load(v)
    end
  end
  if not config.import then
    return
  end
  for _, v in
    ipairs(vim.api.nvim_get_runtime_file(config.import .. '/*.lua', true))
  do
    local plug = assert(loadfile(v))() ---@type any?
    if plug then
      if type(plug) == 'table' and type(plug[1]) == 'string' then
        M.add({ plug })
      elseif type(plug) == 'table' and type(plug[1]) == 'table' then
        M.add(plug)
      end
    end
  end
end

return M
