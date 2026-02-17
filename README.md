# nvim-plug

[![GitHub License](https://img.shields.io/github/license/wsdjeg/nvim-plug)](LICENSE)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/wsdjeg/nvim-plug)](https://github.com/wsdjeg/nvim-plug/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/wsdjeg/nvim-plug)](https://github.com/wsdjeg/nvim-plug/commits/master/)
[![GitHub Release](https://img.shields.io/github/v/release/wsdjeg/nvim-plug)](https://github.com/wsdjeg/nvim-plug/releases)
[![luarocks](https://img.shields.io/luarocks/v/wsdjeg/nvim-plug)](https://luarocks.org/modules/wsdjeg/nvim-plug)

![nvim-plug](https://wsdjeg.net/images/nvim-plug.gif)

<!-- vim-markdown-toc GFM -->

- [📘 Intro](#-intro)
- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🔧 Configuration](#-configuration)
- [⚙️ Basic Usage](#-basic-usage)
    - [Adding Plugins](#adding-plugins)
    - [The `import` Option](#the-import-option)
    - [Self-Upgrade](#self-upgrade)
- [📄 Plugin Spec](#-plugin-spec)
- [💻 Commands](#-commands)
- [🎨 UI](#-ui)
  - [Default UI](#default-ui)
  - [Notify UI](#notify-ui)
  - [Custom Plugin UI](#custom-plugin-ui)
- [📊 Plugin Priority](#-plugin-priority)
- [🔍 Picker Sources](#-picker-sources)
- [📣 Self-Promotion](#-self-promotion)
- [💬 Feedback](#-feedback)

<!-- vim-markdown-toc -->

## 📘 Intro

`nvim-plug` is an asynchronous Neovim plugin manager written in Lua.
There is also a [Chinese introduction](https://wsdjeg.net/neovim-plugin-manager-nvim-plug/) about this plugin.

## ✨ Features

- **🚀 Fast** — Fully implemented in Lua for minimal overhead and quick startup.
- **⚡ Asynchronous Operations** — Plugin download and build steps run in parallel using Neovim jobs.
- **🛌 Flexible lazy-loading** — Load plugins on events, commands, mappings, filetypes, and more.
- **📦 LuaRocks Integration** — Install and manage LuaRocks dependencies seamlessly alongside plugins.
- **🎨 Custom UI** — Provides an extensible UI API for building your own installation/update interface.

## 📦 Installation

To install `nvim-plug` automatically:

```lua
local dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'repos/')

local function bootstrap(repo)
  if vim.fn.isdirectory(dir .. repo) == 0 then
    vim.fn.system({
      'git',
      'clone',
      '--depth',
      '1',
      'https://github.com/' .. repo .. '.git',
      dir .. repo,
    })
  end
  vim.o.runtimepath = vim.o.runtimepath .. ',' .. dir .. repo
end

bootstrap('wsdjeg/job.nvim')
bootstrap('wsdjeg/logger.nvim')
bootstrap('wsdjeg/nvim-plug')
```

Using [LuaRocks](https://luarocks.org/):

```sh
luarocks install nvim-plug
```

## 🔧 Configuration

The following is the default option of nvim-plug.

```lua
require('plug').setup({
  -- set the bundle dir
  bundle_dir = vim.fn.stdpath('data') .. '/repos',
  -- set the path where raw plugin is download to
  raw_plugin_dir = vim.fn.stdpath('data') .. '/repos/raw_plugin',
  -- max number of processes used for nvim-plug job
  max_processes = 5,
  base_url = 'https://github.com',
  -- default ui is `default`,
  -- to use `notify` for floating window notify
  -- you need to install wsdjeg/notify.nvim
  ui = 'default',
  -- default is nil
  http_proxy = 'http://127.0.0.1:7890',
  -- default is nil
  https_proxy = 'http://127.0.0.1:7890',
  -- default history depth for `git clone`
  clone_depth = 1,
  -- plugin priority, readme [plugin priority] for more info
  enable_priority = false,
})
```

## ⚙️ Basic Usage

### Adding plugins

```lua
require('plug').add({
  {
    'wsdjeg/scrollbar.vim',
    events = { 'VimEnter' },
  },
  {
    'wsdjeg/vim-chat',
    enabled = function()
      return vim.fn.has('nvim-0.10.0') == 1
    end,
  },
  {
    'wsdjeg/flygrep.nvim',
    cmds = { 'FlyGrep' },
    config = function()
      require('flygrep').setup()
    end,
  },
  {
    type = 'raw',
    url = 'https://gist.githubusercontent.com/wsdjeg/4ac99019c5ca156d35704550648ba321/raw/4e8c202c74e98b5d56616c784bfbf9b873dc8868/markdown.vim',
    script_type = 'after/syntax'
  },
  {
    'D:/wsdjeg/winbar.nvim',
    events = { 'VimEnter' },
  },
  {
    'wsdjeg/vim-mail',
    on_func = 'mail#',
  },
})
```

### The `import` Option

The default `import` option is `plugins` which means nvim-plug will load `PluginSpec` automatically
from `plugins` directory in runtimepath.

To use this option, you need to call `plug.load()` function.

### Self-Upgrade

You can use `nvim-plug` to manage itself:

```lua
if vim.fn.isdirectory('D:/bundle_dir/wsdjeg/nvim-plug') == 0 then
  vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wsdjeg/nvim-plug.git',
    'D:/bundle_dir/wsdjeg/nvim-plug',
  })
end
vim.o.runtimepath = vim.o.runtimepath .. ',' .. ('D:/bundle_dir/wsdjeg/nvim-plug')
require('plug').setup({
  -- set the bundle dir
  bundle_dir = 'D:/bundle_dir',
})
require('plug').add({
  {
    'wsdjeg/nvim-plug',
    fetch = true,
  },
})
```

## 📄 Plugin Spec

The plugin spec is inspired by [dein.nvim](https://github.com/Shougo/dein.vim).

| Name            | Description                                                                                                                 |
| --------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `[1]`           | (`string`) plugin repo short name, e.g. `wsdjeg/flygrep.nvim`                                                               |
| `autoload`      | (`boolean`) load plugin after `git clone`                                                                                   |
| `branch`        | (`string`) specify a git branch                                                                                             |
| `build`         | (`string\|string[]`) custom build command executed by [job.nvim](https://github.com/wsdjeg/job.nvim)                        |
| `cmds`          | (`string\|string[]`) commands lazy loading                                                                                  |
| `config_after`  | (`function`) function called after loading files in `plugin/` directory                                                     |
| `config_before` | (`function`) function called after running `plug.add()`                                                                     |
| `config`        | (`function`) function called after adding plugin path to Neovim's runtimepath, before loading files in `plugin/` directory  |
| `depends`       | (`PluginSpec[]`) a list of dependencies for a plugin                                                                        |
| `desc`          | (`string`) short description of the plugin                                                                                  |
| `dev`           | (`boolead`) default is `false`. If `true`, then dev path will be used instead if bundle path                                |
| `enabled`       | (`boolean\|function`) evaluated when startup. If `false` the plugin will be skiped                                          |
| `events`        | (`string\|string[]`) events to lazy-load the plugin                                                                         |
| `fetch`         | (`boolean`) if set to `true`, nvim-plug won't add the path to user runtimepath. Useful to manage no-plugin repositories     |
| `frozen`        | (`booleadn`) update only when specific with `Plug update name`                                                              |
| `keys`          | (`table`) key bindings for this plugin                                                                                      |
| `on_ft`         | (`string\|string[]`) filetypes lazy loading                                                                                 |
| `on_func`       | (`string\|string[]`) Vim function lazy loading                                                                              |
| `on_map`        | (`string\|string[]`) keybindings lazy loading                                                                               |
| `opts`          | (`table`) setup options for the plugin                                                                                      |
| `priority`      | (`integer`) set the order in which plugins are loaded, default: `50`                                                        |
| `script_type`   | (`string`) plugin type including `color`, `plugin`, etc.                                                                    |
| `tag`           | (`string`) specific Git tag                                                                                                 |
| `type`          | (`'git'\|'rocks'\|'raw'\|'none'`) specific plugin type. If it is `raw` then `script_type` must be set                       |

- `config` and `config_after` will be not be called until the plugin has been installed.
- `priority` does not work for lazy plugins.
- if `dev` is true, and the develop directory exists, it will be added to runtimepath.
- `keys` is not lazy mapping, use `on_map` instead.

## 💻 Commands

- `:Plug install`: install specific plugin or all plugins
- `:Plug update`: update specific plugin or all plugins

`:PlugInstall` and `:PlugUpdate` are deprecated and will be removed when v1.0.0 is released.

## 🎨 UI

### Default UI

The default is UI is inspired by [Vundle.vim](https://github.com/VundleVim/Vundle.vim).

The default highlight groups are:

| Highlight Group Name | Default Link | Description                     |
| -------------------- | ------------ | ------------------------------- |
| `PlugTitle`          | `TODO`       | the first line of plugin window |
| `PlugProcess`        | `Repeat`     | the downloading progress        |
| `PlugDone`           | `Type`       | clone/build/install done        |
| `PlugFailed`         | `WarningMsg` | clone/build/install failed      |
| `PlugDoing`          | `Number`     | job is running                  |

To change the default highlight group:

```lua
-- In Lua
vim.api.nvim_set_hl(0, 'PlugTitle', { default = true, link = 'TODO' })
vim.api.nvim_set_hl(0, 'PlugProcess', { default = true, link = 'Repeat' })
vim.api.nvim_set_hl(0, 'PlugDone', { default = true, link = 'Type' })
vim.api.nvim_set_hl(0, 'PlugFailed', { default = true, link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'PlugDoing', { default = true, link = 'Number' })
```

```vim
" In Vimscript
hi def link PlugTitle TODO
hi def link PlugProcess Repeat
hi def link PlugDone Type
hi def link PlugFailed WarningMsg
hi def link PlugDoing Number
```

### Notify UI

![plug-notify](https://github.com/user-attachments/assets/74c16409-02e9-4042-9874-17e656e4295a)

You can also change the UI to `notify`, provided by [wsdjeg/notify.nvim](https://github.com/wsdjeg/notify.nvim).

**You need to install it before using nvim-plug**!

```lua
local function bootstrap(repo)
  if vim.fn.isdirectory(dir .. repo) == 0 then
    vim.fn.system({
      'git',
      'clone',
      '--depth',
      '1',
      'https://github.com/' .. repo .. '.git',
      dir .. repo,
    })
  end
  vim.o.runtimepath = vim.o.runtimepath .. ',' .. dir .. repo
end

bootstrap('wsdjeg/job.nvim')
bootstrap('wsdjeg/logger.nvim')
bootstrap('wsdjeg/notify.nvim')
bootstrap('wsdjeg/nvim-plug')

require('plug').setup({
  ui = 'notify',
})

require('plug').add({
  {
    'wsdjeg/notify.nvim',
    fetch = true,
  },
  {
    'wsdjeg/nvim-plug',
    fetch = true,
  },
})
```

### Custom Plugin UI

To setup custom UI, you need to create an `on_update()` function.
This function requires two parameters:

- `name` (`string`)
- `plugUiData` (_see below_)

`plugUiData` is table with following keys:

| key             | description                                               |
| --------------- | --------------------------------------------------------- |
| `build_done`    | (`boolean`)                                               |
| `building`      | (`boolean`)                                               |
| `clone_done`    | (`boolean`) `git clone` exit status                       |
| `clone_done`    | (`boolean`) `true` when cloned successfully               |
| `clone_process` | (`string`) `git clone` progress, such as `16% (160/1000)` |
| `command`       | (`'clone'\|'pull'\|'curl'\|'build'`)                      |
| `curl_done`     | (`boolean`)                                               |
| `pull_done`     | (`boolean`)                                               |
| `pull_process`  | (`string`)                                                |

```lua
--- your custom UI

local function on_ui_update(name, data)
  -- logic
end


require('plug').setup({
  ui = on_ui_update,
})
```

## 📊 Plugin Priority

By default this feature is disabled. Plugins will be loaded when running `add()`.
To enable plugin the priority feature you will have to run `plug.load()` after executing`plug.add()`.

This option is not available for lazy-loading!

For example:

```lua
require('plug').setup({
  max_processes = 5,
  enable_priority = true,
})
require('plug').add({
  {
    'wsdjeg/scrollbar.vim',
    events = { 'VimEnter' },
  },
  {
    'wsdjeg/vim-chat',
    enabled = function()
      return vim.fn.has('nvim-0.10.0') == 1
    end,
  },
  {
    'wsdjeg/flygrep.nvim',
    cmds = { 'FlyGrep' },
    config = function()
      require('flygrep').setup()
    end,
  },
  {
    'rakr/vim-one',
    priority = 100,
    config = function()
      vim.cmd('colorscheme one')
    end,
  },
})
require('plug').load()
```

## 🔍 Picker Sources

`nvim-plug` also provides a source for [picker.nvim](https://github.com/wsdjeg/picker.nvim),
which can be opened with `:Picker plug`.

| Action          | Key Binding | Description                                                                                                  |
| --------------- | ----------- | ------------------------------------------------------------------------------------------------------------ |
| `open_terminal` | `<C-t>`     | open floating terminal with `plugin.dir`. Requires [terminal.nvim](https://github.com/wsdjeg/terminal.nvim). |
| `open_plug_url` | `<C-b>`     | open the URL of the selected plugin via default browser.                                                     |
| `copy_plug_url` | `<C-y>`     | copy the URL of the selected plugin. Use the `"` register.                                                   |
| `tabnew_lcd`    | `<Enter>`   | create new tab, then change current dir to the plugin root                                                   |

## 📣 Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).

## 💬 Feedback

If you encounter any bugs or have suggestions, please file an issue in the
[issue tracker](https://github.com/wsdjeg/nvim-plug/issues).
