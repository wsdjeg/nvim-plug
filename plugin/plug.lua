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
end })
