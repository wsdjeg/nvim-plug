--=============================================================================
-- plug.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

vim.api.nvim_create_user_command("PlugInstall", function(opt)
	require("plug.installer").install(opt.fargs)
end, { nargs = "*", complete = function(...)
  local plugins = require('plug').get()
  local plug_name = {}
  for _, p in ipairs(plugins) do
    table.insert(plug_name, p.name)
  end
  return plug_name
end })
