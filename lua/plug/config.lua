--=============================================================================
-- config.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================


local M = {}

M.budnle_dir = vim.fn.stdpath('data') .. '/bundle_dir' 

function M.setup(opt)
  M.budnle_dir = opt.budnle_dir or M.budnle_dir
end

return M
