--=============================================================================
-- loader.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@class Plug.Loader
local M = {}

local config = require('plug.config')
local log = require('plug.logger')
local clock = require('plug.clock')
local util = require('plug.util')

local add_raw_rtp = false ---@type boolean

--- @class PluginSpec
--- @field [1] string repo
--- @field rtp? string default rtp path
--- @field depends? PluginSpec[] plugin dependencies
--- @field events? string[] lazy events to load this plugin
--- @field cmds? string[] lazy cmds to load this plugins
--- @field name? string plugin name
--- @field branch? string branch name
--- @field tag? string tag name
--- @field url? string upstream url
--- @field path? string download path
--- @field build? string[]|string build commands
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
--- @field enabled? boolean|fun(): boolean
--- @field dev? boolean # if set to true, dev_path will be used if it is existed.
--- @field dev_path? string development directory of the plugin
--- @field load_time? integer loading time in ms
--- @field module? string lua main module name
--- @field on_ft? string[]|string filetypes lazy loading
--- @field on_map? string[]|string key bindings lazy loading
--- @field on_func? string[]|string vim function lazy loading

--- @param spec PluginSpec
--- @return boolean is_local
local function is_local_plugin(spec)
  if spec.is_local or vim.fn.isdirectory(spec[1]) == 1 then
    spec.is_local = true
    return true
  end
  return false
end
--- @param spec PluginSpec
--- @return string plugin_name
local function check_name(spec)
  if not spec[1] and not spec.url then
    return ''
  end
  local s = vim.split(spec[1] or spec.url, '/')
  return s[#s]
end

--- @param name string
--- @return string module
local function get_default_module(name)
  local module =
    name:gsub('[%.%-]lua$', ''):gsub('^n?vim-', ''):gsub('[%.%-]n?vim', '')

  return module
end

--- @param spec PluginSpec
function M.parser(spec)
  if spec.enabled == nil then
    spec.enabled = true
  elseif
    type(spec.enabled) == 'function' and vim.is_callable(spec.enabled)
  then
    spec.enabled = spec.enabled()
    -- make sure enabled() return boolean
    if type(spec.enabled) ~= 'boolean' then
      spec.enabled = false
    end
    if not spec.enabled then
      return spec
    end
  elseif type(spec.enabled) ~= 'boolean' or spec.enabled == false then
    spec.enabled = false
    return spec
  end
  spec.name = check_name(spec)
  if not spec.module then
    spec.module = get_default_module(spec.name)
    log.info(
      string.format(
        'set %s default module name to %s',
        spec.name,
        spec.module
      )
    )
  end
  if spec.name:len() == 0 then
    spec.enabled = false
    return spec
  end
  if spec.dev then
    local dev_path = util.unify_path(config.dev_path) .. spec.name
    if vim.fn.isdirectory(dev_path) == 1 then
      spec.dev_path = dev_path
    end
  end
  if is_local_plugin(spec) then
    spec.rtp = spec[1]
    spec.path = spec[1]
    spec.url = nil
  elseif spec.type == 'raw' then
    if not spec.script_type or spec.script_type == 'none' then
      spec.enabled = false
      return spec
    end
    spec.path = config.raw_plugin_dir
      .. '/'
      .. spec.script_type
      .. '/'
      .. spec.name
    if not add_raw_rtp then
      local rtp_list = vim.split(vim.o.rtp, ',')
      table.insert(rtp_list, 1, config.raw_plugin_dir) -- PREPEND
      table.insert(rtp_list, config.raw_plugin_dir .. '/after') -- APPEND
      vim.o.rtp = table.concat(rtp_list, ',')
      add_raw_rtp = true
    end
  elseif spec.type == 'rocks' then -- NOTE: (DrKJeff16) ????
  elseif not spec.script_type or spec.script_type == 'none' then
    spec.rtp = config.bundle_dir .. '/' .. spec[1]
    spec.path = config.bundle_dir .. '/' .. spec[1]
    spec.url = config.base_url .. '/' .. spec[1]
  elseif spec.script_type == 'color' then
    spec.rtp = config.bundle_dir .. '/' .. spec[1]
    spec.path = config.bundle_dir .. '/' .. spec[1] .. '/color'
    spec.url = config.base_url .. '/' .. spec[1]
  elseif spec.script_type == 'plugin' then
    spec.rtp = config.bundle_dir .. '/' .. spec[1]
    spec.path = config.bundle_dir .. '/' .. spec[1] .. '/plugin'
    spec.url = config.base_url .. '/' .. spec[1]
  end
  if spec.autoload == nil and spec.type ~= 'raw' and not spec.fetch then
    spec.autoload = true
  end

  if type(spec.config_before) == 'function' and vim.is_callable(spec.config_before) then
    spec.config_before()
  end

  return spec
end

--- @param spec PluginSpec
function M.load(spec)
  if spec.type and spec.type == 'rocks' and not spec.rtp then
    require('plug.rocks').set_rtp(spec)
  end
  if
    spec.rtp
    and vim.fn.isdirectory(spec.rtp) == 1
    and not spec.loaded
    and not spec.fetch
  then
    clock.start()
    local rtp = spec.rtp
    if spec.dev and spec.dev_path then
      rtp = spec.dev_path
    end
    local rtp_list = vim.split(vim.o.rtp, ',')
    table.insert(rtp_list, 1, rtp)
    if vim.fn.isdirectory(rtp .. '/after') == 1 then
      table.insert(rtp_list, rtp .. '/after')
    end
    vim.o.runtimepath = table.concat(rtp_list, ',')

    spec.loaded = true
    if spec.opts then
      if spec.module then
        local ok, module = pcall(require, spec.module)
        if ok then
          if module.setup then
            module.setup(spec.opts)
          else
            log.info(
              string.format('%s does not provide setup func', spec.name)
            )
          end
        else
          log.info(
            string.format(
              'failed to require %s module for %s',
              spec.module,
              spec.name
            )
          )
        end
      else
        log.info('failed to set default module name for ' .. spec.name)
      end
    end
    if type(spec.config) == 'function' and vim.is_callable(spec.config) then
      spec.config()
    end
    -- if on_map contains key in spec.keys, it will be cleared by nvim-plug on_map hook.
    -- so we need to reset them.
    if spec.keys then
      for _, key in ipairs(spec.keys) do
        pcall(function()
          vim.keymap.set(unpack(key))
        end)
      end
    end
    if vim.fn.has('vim_starting') ~= 1 then
      local plugin_directory_files =
        vim.fn.globpath(rtp, 'plugin/*.{lua,vim}', false, true)
      for _, f in ipairs(plugin_directory_files) do
        vim.cmd.source(f)
      end
      if type(spec.config_after) == 'function' and vim.is_callable(spec.config_after) then
        spec.config_after()
      end
    end
    spec.load_time = clock.time()
    log.info(
      string.format('load plug: %s in %sms', spec.name, spec.load_time)
    )
  end
end

return M
