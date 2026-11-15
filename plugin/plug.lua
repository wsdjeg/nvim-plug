--=============================================================================
-- plug.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

--- @param a string
--- @return string[]
local function complete(a)
  return require('plug.command').complete_names(a)
end

--- Deprecated `:PlugInstall` / `:PlugUpdate`.
---
--- Both used to re-implement plugin collection themselves. They are now
--- thin wrappers around the `:Plug` subcommands: the subcommand name is
--- prefixed onto the user supplied arguments so spec collection and UI
--- handling stay in one place (plug.command).
--- @param sub 'install'|'update'
--- @return fun(opt: vim.api.keyset.create_user_command.command_args)
local function deprecated(sub)
  return function(opt)
    local command = require('plug.command')
    local fargs = { sub }
    vim.list_extend(fargs, opt.fargs)
    local specs, force = command.collect(fargs)
    if sub == 'install' then
      require('plug.installer').install(specs)
    else
      require('plug.installer').update(specs, force)
    end
    command.open_ui()
  end
end

vim.api.nvim_create_user_command('PlugInstall', deprecated('install'), {
  nargs = '*',
  complete = complete,
})

vim.api.nvim_create_user_command('PlugUpdate', deprecated('update'), {
  nargs = '*',
  complete = complete,
})

vim.api.nvim_create_user_command('Plug', function(opt)
  require('plug.command').run(opt)
end, {
  nargs = '*',
  complete = require('plug.command').complete,
})

