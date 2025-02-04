# nvim-plug

> _nvim-plug_ is a simple plugin manager for neovim

## Usage

```lua
require("plug").setup({

	bundle_dir = "D:\\bundle_dir\\",
})

require("plug").add({
	{
		"wsdjeg/scrollbar.vim",
		events = { "VimEnter" },
		config = function() end,
	},
	{
		"wsdjeg/flygrep.nvim",
		cmds = { "FlyGrep" },
		config = function()
			require("flygrep").setup()
		end,
	},
})
```

## Plugin Spec

| name   | description                                             |
| ------ | ------------------------------------------------------- |
| `[1]`  | `string`, plugin repo short name, `wsdjeg/flygrep.nvim` |
| `cmds` | `table<string>`, commands lazy loading                  |
