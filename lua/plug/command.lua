---@class Plug.Command
local M = {}

---@param opt vim.api.keyset.create_user_command.command_args
function M.run(opt)
  if #opt.fargs > 0 and opt.fargs[1] == 'install' then
    local plugs = {} ---@type PluginSpec[]
    local all_plugins = require('plug').get()
    if #opt.fargs == 1 then
      for _, v in pairs(all_plugins) do
        table.insert(plugs, v)
      end
    else
      for i = 2, #opt.fargs do
        if all_plugins[opt.fargs[i]] then
          table.insert(plugs, all_plugins[opt.fargs[i]])
        end
      end
    end
    require('plug.installer').install(plugs)

    if require('plug.config').ui == 'default' then
      require('plug.ui').open()
    end
    return
  end
  if #opt.fargs > 0 and opt.fargs[1] == 'update' then
    local plugs = {} ---@type PluginSpec[]
    local all_plugins = require('plug').get()
    local force = false
    if #opt.fargs == 1 then
      for _, v in pairs(all_plugins) do
        table.insert(plugs, v)
      end
    else
      force = true
      for i = 2, #opt.fargs do
        if all_plugins[opt.fargs[i]] then
          table.insert(plugs, all_plugins[opt.fargs[i]])
        end
      end
    end
    require('plug.installer').update(plugs, force)

    if require('plug.config').ui == 'default' then
      require('plug.ui').open()
    end
  end
end

---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[] completions
function M.complete(arglead, cmdline, cursorpos)
  if vim.regex('^Plug[!]\\?\\s*\\S*$'):match_str(string.sub(cmdline, 1, cursorpos)) then
    return vim.tbl_filter(function(t)
      return vim.startswith(t, arglead)
    end, { 'install', 'update' })
  end

  local plug_name = {} ---@type string[]
  for k, _ in pairs(require('plug').get()) do
    if arglead and vim.startswith(k, arglead) then
      table.insert(plug_name, k)
    end
  end
  return plug_name
end

return M
