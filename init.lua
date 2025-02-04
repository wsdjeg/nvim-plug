--=============================================================================
-- init.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

require("plug").add({
	{
		"wsdjeg/scrollbar.vim",
		events = { "VimEnter" },
	},
	{
		"wsdjeg/flygrep.nvim",
		cmds = { "FlyGrep" },
	},
})
