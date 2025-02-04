--=============================================================================
-- autocmds.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local mygroup = vim.api.nvim_create_augroup("nvim-config", { clear = true })

local au = function(events, opts)
	if not opts.group then
		opts.group = mygroup
	end

	if not opts.pattern then
		opts.pattern = { "*" }
	end
	vim.api.nvim_create_autocmd(events, opts)
end



