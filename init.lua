--=============================================================================
-- init.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

require('plug').setup({

  bundle_dir = 'D:\\bundle_dir\\',

})

require('autocmds')
require('options')
require('keymaps')

require("plug").add({
	{
		"wsdjeg/scrollbar.vim",
		events = { "VimEnter" },
    config = function()
    end
	},
	{
		"wsdjeg/flygrep.nvim",
		cmds = { "FlyGrep" },
    config = function()
      require('flygrep').setup()
    end
	},
})
