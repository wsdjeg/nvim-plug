--=============================================================================
-- loader.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local M = {}

local config = require('plug.config')
local log = require('plug.logger')
local clock = require('plug.clock')

local add_raw_rtp = false

--- @class PluginSpec
--- @field [1] string repo
--- @field rtp? string default rtp path
--- @field events? table<string> lazy events to load this plugin
--- @field cmds? table<string> lazy cmds to load this plugins
--- @field name? string plugin name
--- @field branch? string branch name
--- @field tag? string tag name
--- @field url? string upstream url
--- @field path? string download path
--- @field build? string|table<string> build commands
--- @field is_local? boolean true for local plugin
--- @field when boolean|string|function
--- @field frozen? boolean if set to true, :PlugUpdate will not update this plugin without bang
--- @field type? string "git", "raw" or "none"
--- @field script_type? string "git", "raw" or "none"
--- @field opts? table plugin setup opts
--- @field keys? table list of key bindings
--- @field config? function function called after update rtp
--- @field config_before? function function called after update rtp
--- @field config_after? function function called after update rtp
--- @field hook_install_done? function
--- @field autoload? boolean
--- @field fetch? boolean If set to true, nvim-plug doesn't add the path to user runtimepath, and doesn't load the bundle
--- @field loaded? boolean
--- @field enabled? boolean
--- @field dev? boolean # if set to true, dev_path will be used if it is existed.
--- @field dev_path? string development directory of the plugin
--- @field load_time? integer loading time in ms

--- @param plugSpec PluginSpec
--- @return boolean
local function is_local_plugin(plugSpec)
  if plugSpec.is_local or vim.fn.isdirectory(plugSpec[1]) == 1 then
    plugSpec.is_local = true
    return true
  else
    return false
  end
end
--- @param plugSpec PluginSpec
--- @return string
local function check_name(plugSpec)
  if not plugSpec[1] and not plugSpec.url then
    return ''
  end
  local s = vim.split(plugSpec[1] or plugSpec.url, '/')
  return s[#s]
end

--- @param name string
--- @return string
local function get_default_module(name)
  return name:lower():gsub('[%.%-]lua$', ''):gsub('^n?vim-', ''):gsub('[%.%-]n?vim', '')
end

--- @param plugSpec PluginSpec
function M.parser(plugSpec)
  if type(plugSpec.enabled) == 'nil' then
    plugSpec.enabled = true
  elseif type(plugSpec.enabled) == 'function' then
    plugSpec.enabled = plugSpec.enabled()
    -- make sure enabled() return boolean
    if type(plugSpec.enabled) ~= 'boolean' then
      plugSpec.enabled = false
    end
    if not plugSpec.enabled then
      return plugSpec
    end
  elseif type(plugSpec.enabled) ~= 'boolean' or plugSpec.enabled == false then
    plugSpec.enabled = false
    return plugSpec
  end
  plugSpec.name = check_name(plugSpec)
  if not plugSpec.module then
    plugSpec.module = get_default_module(plugSpec.name)
  end
  if #plugSpec.name == 0 then
    plugSpec.enabled = false
    return plugSpec
  end
  if plugSpec.dev then
    local dev_path = config.dev_path .. plugSpec[1]
    if vim.fn.isdirectory(dev_path) == 1 then
      plugSpec.dev_path = dev_path
    end
  end
  if is_local_plugin(plugSpec) then
    plugSpec.rtp = plugSpec[1]
    plugSpec.path = plugSpec[1]
    plugSpec.url = nil
  elseif plugSpec.type == 'raw' then
    if not plugSpec.script_type or plugSpec.script_type == 'none' then
      plugSpec.enabled = false
      return plugSpec
    else
      plugSpec.path = config.raw_plugin_dir .. '/' .. plugSpec.script_type .. '/' .. plugSpec.name
      if not add_raw_rtp then
        vim.opt.runtimepath:prepend(config.raw_plugin_dir)
        vim.opt.runtimepath:append(config.raw_plugin_dir .. '/after')
        add_raw_rtp = true
      end
    end
  elseif not plugSpec.script_type or plugSpec.script_type == 'none' then
    plugSpec.rtp = config.bundle_dir .. '/' .. plugSpec[1]
    plugSpec.path = config.bundle_dir .. '/' .. plugSpec[1]
    plugSpec.url = config.base_url .. '/' .. plugSpec[1]
  elseif plugSpec.script_type == 'color' then
    plugSpec.rtp = config.bundle_dir .. '/' .. plugSpec[1]
    plugSpec.path = config.bundle_dir .. '/' .. plugSpec[1] .. '/color'
    plugSpec.url = config.base_url .. '/' .. plugSpec[1]
  elseif plugSpec.script_type == 'plugin' then
    plugSpec.rtp = config.bundle_dir .. '/' .. plugSpec[1]
    plugSpec.path = config.bundle_dir .. '/' .. plugSpec[1] .. '/plugin'
    plugSpec.url = config.base_url .. '/' .. plugSpec[1]
  end
  if type(plugSpec.autoload) == 'nil' and plugSpec.type ~= 'raw' and not plugSpec.fetch then
    plugSpec.autoload = true
  end

  if type(plugSpec.config_before) == 'function' then
    plugSpec.config_before()
  end

  return plugSpec
end

--- @param plugSpec PluginSpec
function M.load(plugSpec)
  if
    plugSpec.rtp
    and vim.fn.isdirectory(plugSpec.rtp) == 1
    and not plugSpec.loaded
    and not plugSpec.fetch
  then
    clock.start()
    local rtp
    if plugSpec.dev and plugSpec.dev_path then
      rtp = plugSpec.dev_path
    else
      rtp = plugSpec.rtp
    end
    vim.opt.runtimepath:prepend(rtp)
    if vim.fn.isdirectory(rtp .. '/after') == 1 then
      vim.opt.runtimepath:append(rtp .. '/after')
    end
    plugSpec.loaded = true
    if plugSpec.opts then
      if plugSpec.module then
        local ok, module = pcall(require, plugSpec.module)
        if ok then
          if module.setup then
            module.setup(plugSpec.opts)
          else
            log.info(string.format('%s does not provide setup func', plugSpec.name))
          end
        else
          log.info(
            string.format('failed to require %s module for %s', plugSpec.module, plugSpec.name)
          )
        end
      else
        log.info('failed to set default module name for ' .. plugSpec.name)
      end
    end
    if type(plugSpec.config) == 'function' then
      plugSpec.config()
    end
    -- if on_map contains key in plugSpec.keys, it will be cleared by nvim-plug on_map hook.
    -- so we need to reset them.
    if plugSpec.keys then
      for _, key in ipairs(plugSpec.keys) do
        pcall(function()
          vim.keymap.set(unpack(key))
        end)
      end
    end
    if vim.fn.has('vim_starting') ~= 1 then
      local plugin_directory_files = vim.fn.globpath(rtp, 'plugin/*.{lua,vim}', false, true)
      for _, f in ipairs(plugin_directory_files) do
        vim.cmd.source(f)
      end
      if type(plugSpec.config_after) == 'function' then
        plugSpec.config_after()
      end
    end
    plugSpec.load_time = clock.time()
    log.info(string.format('load plug: %s in %sms', plugSpec.name, plugSpec.load_time))
  end
end

return M
