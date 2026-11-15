---@class Plug.Hooks
local M = {}

local group = vim.api.nvim_create_augroup('plugin_hooks', { clear = true })

local plugin_loader = require('plug.loader')

local event_plugins = {} ---@type table<string, integer>
local cmd_plugins = {} ---@type table<string, PluginSpec>
local on_ft_plugins = {} ---@type table<string, integer>
local on_fn_plugins = {} ---@type table<string, integer>

--- Normalise a `string|string[]` spec field into a `string[]`.
---
--- The normalised list is written back onto the spec, because the trigger
--- callbacks below iterate the spec field (not the local argument) to clean
--- up placeholders. Leaving a bare string there made `ipairs()` iterate zero
--- times, so placeholder commands and mappings were never removed.
---@param value string|string[]
---@return string[]
local function as_list(value)
  if type(value) == 'string' then
    return { value }
  end
  return value
end

--- Delete a recorded autocmd id, tolerating an id that is already gone.
---
--- Re-registering the same spec used to leave two callbacks pointing at the
--- same id: the first one deleted it, the second one errored with "Invalid
--- autocmd id".
---@param store table<string, integer>
---@param name string
local function del_autocmd(store, name)
  local id = store[name]
  if id then
    pcall(vim.api.nvim_del_autocmd, id)
    store[name] = nil
  end
end

--- Remove every lazy trigger registered for the spec.
---@param spec PluginSpec
local function clear_triggers(spec)
  del_autocmd(event_plugins, spec.name)
  del_autocmd(on_ft_plugins, spec.name)
  del_autocmd(on_fn_plugins, spec.name)
end

--- @param events string[] | string
--- @param spec PluginSpec
function M.on_events(events, spec)
  spec.events = as_list(events)
  -- replace a previous registration instead of stacking callbacks
  del_autocmd(event_plugins, spec.name)
  event_plugins[spec.name] = vim.api.nvim_create_autocmd(spec.events, {
    group = group,
    pattern = { '*' },
    callback = function()
      clear_triggers(spec)
      plugin_loader.load(spec)
    end,
  })
end

--- @param cmds string[] | string
--- @param spec PluginSpec
function M.on_cmds(cmds, spec)
  spec.cmds = as_list(cmds)
  for _, cmd in ipairs(spec.cmds) do
    cmd_plugins[cmd] = spec
    vim.api.nvim_create_user_command(cmd, function(opt)
      -- drop every placeholder of this spec, so the real command defined by
      -- the plugin (if any) takes over. pcall: some may already be gone.
      for _, placeholder in ipairs(spec.cmds or {}) do
        pcall(vim.api.nvim_del_user_command, placeholder)
      end
      plugin_loader.load(cmd_plugins[opt.name] or spec)
      if vim.fn.exists(':' .. opt.name) ~= 2 then
        vim.api.nvim_echo({
          {
            string.format('command %s is not found.', opt.name),
            'WarningMsg',
          },
        }, false, {})
        return
      end
      local excmd = opt.name
      if opt.bang then
        excmd = excmd .. '!'
      end
      if opt.line1 < opt.line2 then
        excmd = opt.line1 .. ',' .. opt.line2 .. excmd
      end
      vim.cmd(excmd .. ' ' .. opt.args)
    end, {
      nargs = '*',
      complete = function()
        return {}
      end,
      bang = true,
      range = true,
    })
  end
end

---@param fts string[] | string
---@param spec PluginSpec
function M.on_ft(fts, spec)
  spec.on_ft = as_list(fts)
  del_autocmd(on_ft_plugins, spec.name)
  on_ft_plugins[spec.name] = vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = group,
    pattern = spec.on_ft,
    callback = function()
      clear_triggers(spec)
      plugin_loader.load(spec)
    end,
  })
end

---@param maps string[] | string
---@param spec PluginSpec
function M.on_map(maps, spec)
  spec.on_map = as_list(maps)
  for _, lhs in ipairs(spec.on_map) do
    vim.keymap.set('n', lhs, function()
      -- remove all placeholder mappings of this spec before loading, then
      -- replay the keys the user typed after the lhs.
      for _, placeholder in ipairs(spec.on_map or {}) do
        pcall(vim.keymap.del, 'n', placeholder, {})
      end
      plugin_loader.load(spec)

      local termstr = '<M-_>'
      local input = ''

      vim.fn.feedkeys(termstr, 'n')

      while true do
        local char = vim.fn.getchar()
        input = input
          .. (type(char) == 'number' and vim.fn.nr2char(char) or char)

        local idx = vim.fn.stridx(input, termstr)
        if idx >= 1 then
          input = string.sub(input, 1, idx)
          break
        end
        if idx == 0 then
          input = ''
          break
        end
      end

      vim.fn.feedkeys(
        vim.api.nvim_replace_termcodes(lhs .. input, false, true, true),
        'm'
      )
    end, { silent = true, desc = spec.name .. ' on_map hooks' })
  end
end

---@param fn string[] | string
---@param spec PluginSpec
function M.on_func(fn, spec)
  spec.on_func = as_list(fn)
  del_autocmd(on_fn_plugins, spec.name)
  on_fn_plugins[spec.name] = vim.api.nvim_create_autocmd(
    { 'FuncUndefined' },
    {
      group = group,
      pattern = spec.on_func,
      callback = function()
        clear_triggers(spec)
        plugin_loader.load(spec)
      end,
    }
  )
end

return M

