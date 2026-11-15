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
local log = require('plug.logger')

--- Set a key mapping described by a `keys` entry.
---
--- Both documented forms are accepted:
---
---   { lhs, rhs }                              -- mode defaults to `n`
---   { mode, lhs, rhs [, opts] }               -- explicit mode
---   { lhs, rhs, opts }                        -- implicit `n` with opts
---
--- Invalid entries are skipped instead of raising, matching the previous
--- pcall-wrapped behaviour.
---@param key any
local function set_key(key)
  if type(key) ~= 'table' then
    log.warn('invalid keys entry: ' .. vim.inspect(key))
    return
  end

  local mode, lhs, rhs, opts
  local first = key[1]
  if
    type(first) == 'string'
    and #key >= 3
    and first:match('^[nvxsoilct]+$') ~= nil
  then
    -- explicit mode form
    mode, lhs, rhs, opts = first, key[2], key[3], key[4]
  else
    mode, lhs, rhs, opts = 'n', key[1], key[2], key[3]
  end

  local rhs_ok = type(rhs) == 'string' or type(rhs) == 'function'
  if type(lhs) ~= 'string' or not rhs_ok then
    log.warn('invalid keys entry: ' .. vim.inspect(key))
    return
  end

  local ok = pcall(vim.keymap.set, mode, lhs, rhs, opts)
  if not ok then
    log.warn('failed to set key mapping: ' .. vim.inspect(key))
  end
end

--- Register a single PluginSpec, resolving its dependencies first.
---
--- `seen` tracks specs already handled in this call tree. Without it, a spec
--- that directly or indirectly depends on itself recursed forever and ended
--- in a "stack overflow" error.
---@param plug PluginSpec
---@param seen table<PluginSpec, boolean>
---@param skip_deps? boolean
local function add_spec(plug, seen, skip_deps)
  if type(plug) ~= 'table' or seen[plug] then
    return
  end
  seen[plug] = true

  if not skip_deps and type(plug.depends) == 'table' then
    for _, dep in ipairs(plug.depends) do
      add_spec(dep, seen)
    end
  end

  loader.parser(plug)
  if not plug.enabled then
    return
  end

  all_plugins[plug.name] = plug

  if plug.keys then
    for _, key in ipairs(plug.keys) do
      set_key(key)
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

---@param opt? PlugOpts
function M.setup(opt)
  config.setup(opt)
end

--- @param plugins PluginSpec[]
--- @param skip_deps? boolean kept for backwards compatibility
function M.add(plugins, skip_deps)
  local seen = {} ---@type table<PluginSpec, boolean>
  for _, plug in ipairs(plugins or {}) do
    add_spec(plug, seen, skip_deps)
  end
end

---@return table<string, PluginSpec> all_plugins
function M.get()
  return all_plugins
end

--- Register the spec (or specs) declared by a `plugins/*.lua` file.
---
--- Load and evaluation errors are logged and the file skipped. Previously a
--- single malformed spec file aborted the whole import run, so every spec
--- after it was silently lost.
---@param path string
local function import_file(path)
  local chunk = loadfile(path)
  if not chunk then
    log.warn('failed to load plugin spec: ' .. path)
    return
  end

  local ok, spec = pcall(chunk)
  if not ok then
    log.warn(string.format('plugin spec %s failed to load: %s', path, spec))
    return
  end

  if type(spec) ~= 'table' then
    return
  end

  if type(spec[1]) == 'table' then
    -- a list of PluginSpec
    M.add(spec)
  elseif type(spec[1]) == 'string' or type(spec.url) == 'string' then
    -- a single PluginSpec, including url-only specs without a repo name
    M.add({ spec })
  end
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
  for _, path in
    ipairs(vim.api.nvim_get_runtime_file(config.import .. '/*.lua', true))
  do
    import_file(path)
  end
end

return M

