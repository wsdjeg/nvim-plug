---@class Plug.Command
local M = {}

--- Collect the PluginSpecs a `install` / `update` subcommand applies to.
---
--- Names listed after the subcommand are resolved against the registered
--- plugins; unknown names are dropped rather than producing nil specs.
--- `force` is only meaningful for `update`, where listing plugins means
--- "update these even if frozen".
---@param fargs string[] full argument list, `fargs[1]` is the subcommand
---@return PluginSpec[] specs
---@return boolean force
function M.collect(fargs)
  local specs = {} ---@type PluginSpec[]
  local all_plugins = require('plug').get()
  local force = false

  if #fargs <= 1 then
    for _, v in pairs(all_plugins) do
      table.insert(specs, v)
    end
    return specs, force
  end

  force = fargs[1] ~= 'install'
  for i = 2, #fargs do
    local spec = all_plugins[fargs[i]]
    if spec then
      table.insert(specs, spec)
    end
  end

  return specs, force
end

--- Open the default UI window, unless a different UI is configured.
function M.open_ui()
  if require('plug.config').ui == 'default' then
    require('plug.ui').open()
  end
end

--- Complete registered plugin names matching `arglead`.
---@param arglead string
---@return string[] completions
function M.complete_names(arglead)
  local names = {} ---@type string[]
  for name, _ in pairs(require('plug').get()) do
    if vim.startswith(name, arglead or '') then
      table.insert(names, name)
    end
  end
  return names
end

---@param opt vim.api.keyset.create_user_command.command_args
function M.run(opt)
  if vim.tbl_isempty(opt.fargs) then
    return
  end

  local sub = opt.fargs[1]
  if sub ~= 'install' and sub ~= 'update' then
    return
  end

  local specs, force = M.collect(opt.fargs)
  if sub == 'install' then
    require('plug.installer').install(specs)
  else
    require('plug.installer').update(specs, force)
  end
  M.open_ui()
end

---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[] completions
function M.complete(arglead, cmdline, cursorpos)
  if
    vim
      .regex('^Plug[!]\\?\\s*\\S*$')
      :match_str(string.sub(cmdline, 1, cursorpos))
  then
    return vim.tbl_filter(function(t)
      return vim.startswith(t, arglead)
    end, { 'install', 'update' })
  end

  return M.complete_names(arglead)
end

return M

