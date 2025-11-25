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
    - [Add plugins](#add-plugins)
    - [`import` option](#import-option)
    - [Self upgrade](#self-upgrade)
- [📄 Plugin Spec](#-plugin-spec)
- [💻 Commands](#-commands)
- [🎨 UI](#-ui)
    - [Default UI](#default-ui)
    - [Notify UI](#notify-ui)
    - [Custom Plugin UI](#custom-plugin-ui)
- [📊 Plugin priority](#-plugin-priority)
- [🔍 Picker sources](#-picker-sources)
- [📣 Self-Promotion](#-self-promotion)
- [💬 Feedback](#-feedback)

<!-- vim-markdown-toc -->

## 📘 Intro

nvim-plug is an asynchronous Neovim plugin manager written in Lua.
There is also a [Chinese introduction](https://wsdjeg.net/neovim-plugin-manager-nvim-plug/) about this plugin.

## ✨ Features

- **🚀 Fast** — Fully implemented in Lua for minimal overhead and quick startup.
- **⚡ Asynchronous operations** — Plugin download and build steps run in parallel using Neovim jobs.
- **🛌 Flexible lazy-loading** — Load plugins on events, commands, mappings, filetypes, and more.
- **📦 LuaRocks integration** — Install and manage LuaRocks dependencies seamlessly alongside plugins.
- **🎨 Custom UI** — Provides an extensible UI API for building your own installation/update interface.

## 📦 Installation

To install nvim-plug automatically:

```lua
local dir = vim.fn.stdpath('data') .. '/repos/'

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
  vim.opt.runtimepath:append(dir .. repo)
end

bootstrap('wsdjeg/job.nvim')
bootstrap('wsdjeg/logger.nvim')
bootstrap('wsdjeg/nvim-plug')
```

Using [luarocks](https://luarocks.org/)

```
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

### Add plugins

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

### `import` option

The default `import` option is `plugins` which means nvim-plug will load `PluginSpec` automatically from `plugins` directory im runtimepath.

To use this option, you need to call `plug.load()` function.

### Self upgrade

you can use nvim-plug to manager nvim-plug:

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
vim.opt.runtimepath:append('D:/bundle_dir/wsdjeg/nvim-plug')
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

| name            | description                                                                                                                 |
| --------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `[1]`           | `string`, plugin repo short name, `wsdjeg/flygrep.nvim`                                                                     |
| `cmds`          | `string`, or `table<string>`, commands lazy loading                                                                         |
| `events`        | `string`, or `table<string>`, events lazy loading                                                                           |
| `keys`          | `table`, key bindings for this plugin                                                                                       |
| `opts`          | `table`, setup opts for this plugin                                                                                         |
| `config`        | `function`, function called after adding plugin path to nvim rtp, before loading files in `plugin/` directory               |
| `config_after`  | `function`, function called after loading files in `plugin/` directory                                                      |
| `config_before` | `function`, function called when `plug.add()` function is called                                                            |
| `on_ft`         | `string`, or `table<string>`, filetypes lazy loading                                                                        |
| `on_map`        | `string`, or `table<string>`, key bindings lazy loading                                                                     |
| `on_func`       | `string`, or `table<string>`, vim function lazy loading                                                                     |
| `script_type`   | `string`, plugin type including `color`, `plugin`, etc..                                                                    |
| `build`         | `string`, or `table<string>`, executed by [job.nvim](https://github.com/wsdjeg/job.nvim)                                    |
| `enabled`       | `boolean`, or `function` evaluated when startup, when it is false, plugin will be skiped                                    |
| `frozen`        | `booleadn`, update only when specific with `PlugUpdate name`                                                                |
| `depends`       | `table<PluginSpec>`, a list of plugins                                                                                      |
| `branch`        | `string`, specific git branch                                                                                               |
| `tag`           | `string`, specific git tag                                                                                                  |
| `type`          | `string`, specific plugin type, this can be git, rocks, raw or none, if it is raw, `script_type` must be set                |
| `autoload`      | `boolean`, load plugin after git clone                                                                                      |
| `priority`      | `number`, default is 50, set the order in which plugins are loaded                                                          |
| `fetch`         | `boolean`, If set to true, nvim-plug doesn't add the path to user runtimepath. It is useful to manager no-plugin repository |
| `dev`           | `boolead`, default is false, if true, then dev path will be used instead if bundle path                                     |

- `config` and `config_after` function will be not be called if the plugin has not been installed.
- `priority` does not work for lazy plugins.
- dev path works only when exists. nvim-plug will not clone repos into dev_path
- `keys` is not lazy mapping, use `on_map` instead.

## 💻 Commands

- `:Plug install`: install specific plugin or all plugins
- `:Plug update`: update specific plugin or all plugins

`:PlugInstall` and `:PlugUpdate` is deprecated, and will be removed when 1.0.0 released.

## 🎨 UI

### Default UI

The default is ui is inspired by [vundle](https://github.com/VundleVim/Vundle.vim)

The default highlight group.

| highlight group name | default link | description                     |
| -------------------- | ------------ | ------------------------------- |
| `PlugTitle`          | `TODO`       | the first line of plugin window |
| `PlugProcess`        | `Repeat`     | the process of downloading      |
| `PlugDone`           | `Type`       | clone/build/install done        |
| `PlugFailed`         | `WarningMsg` | clone/build/install failed      |
| `PlugDoing`          | `Number`     | job is running                  |

To change the default highlight group:

```lua
vim.cmd('hi def link PlugTitle TODO')
vim.cmd('hi def link PlugProcess Repeat')
vim.cmd('hi def link PlugDone Type')
vim.cmd('hi def link PlugFailed WarningMsg')
vim.cmd('hi def link PlugDoing Number')
```

### Notify UI

You can also change the ui to `notify`:

![plug-notify](https://github.com/user-attachments/assets/74c16409-02e9-4042-9874-17e656e4295a)

This UI is based on [notify.nvim](https://github.com/wsdjeg/notify.nvim). So you need to install it before using nvim-plug:

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
vim.opt.runtimepath:append('D:/bundle_dir/wsdjeg/nvim-plug')
if vim.fn.isdirectory('D:/bundle_dir/wsdjeg/notify.nvim') == 0 then
  vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wsdjeg/notify.nvim.git',
    'D:/bundle_dir/wsdjeg/notify.nvim',
  })
end
vim.opt.runtimepath:append('D:/bundle_dir/wsdjeg/notify.nvim')

require('plug').setup({

  bundle_dir = 'D:/bundle_dir',
  raw_plugin_dir = 'D:/bundle_dir/raw_plugin',
  ui = 'notify',
  http_proxy = 'http://127.0.0.1:7890',
  https_proxy = 'http://127.0.0.1:7890',
  enable_priority = true,
  max_processes = 16,
})

require('plug').add({
  {
    'wsdjeg/logger.nvim',
    config = function()
      require('logger').setup({ level = 0 })
      vim.keymap.set(
        'n',
        '<leader>hL',
        '<cmd>lua require("logger").viewRuntimeLog()<cr>',
        { silent = true }
      )
    end,
  },
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

To setup custom UI, you need to creat a on_update function, this function is called with two arges, `name` and `plugUiData`.

The plugUiData is table with following keys:

| key             | description                                          |
| --------------- | ---------------------------------------------------- |
| `clone_done`    | boolead, is true when clone successfully             |
| `command`       | string, clone, pull, curl or build                   |
| `clone_process` | string, git clone progress, such as `16% (160/1000)` |
| `clone_done`    | boolean, git clone exit status                       |
| `building`      | boolean                                              |
| `build_done`    | boolean                                              |
| `pull_done`     | boolean                                              |
| `pull_process`  | string                                               |
| `curl_done`     | boolean                                              |

```lua
--- your custom UI

local function on_ui_update(name, data)
  -- logic
end


require('plug').setup({
  bundle_dir = 'D:/bundle_dir',
  max_processes = 5, -- max number of processes used for nvim-plug job
  base_url = 'https://github.com',
  ui = on_ui_update, -- default ui is notify, use `default` for split window UI
})
```

## 📊 Plugin priority

By default this feature is disabled, plugins will be loaded when run `add({plugins})` function.
To enable plugin priority feature, you need to call `plug.load()` after `plug.add()` function.
This option is not for lazy plugins.

for example:

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
    config = function()
      vim.cmd('colorscheme one')
    end,
    priority = 100,
  },
})
require('plug').load()
```

## 🔍 Picker sources

nvim-plug also provides a source for [picker.nvim](https://github.com/wsdjeg/picker.nvim),
which can be opened by following command:

```
:Picker plug
```

| action        | key binding | description                                                                                            |
| ------------- | ----------- | ------------------------------------------------------------------------------------------------------ |
| open_terminal | `<C-t>`     | open floating terminal with plugin.dir, need [terminal.nvim](https://github.com/wsdjeg/terminal.nvim). |
| open_plug_url | `<C-b>`     | open the url of selected plugin via default browser.                                                   |
| copy_plug_url | `<C-y>`     | copy the url of selected plugin, use register `"`.                                                     |
| tabnew_lcd    | `<Enter>`   | create new tab, change current dir to the plugin root                                                  |

## 📣 Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).

## 💬 Feedback

If you encounter any bugs or have suggestions, please file an issue in the [issue tracker](https://github.com/wsdjeg/nvim-plug/issues).
