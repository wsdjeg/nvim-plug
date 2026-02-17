--=============================================================================
-- installer.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@class Plug.Installer
local M = {}

local H = {}

local job = require('job')
local config = require('plug.config')
local loader = require('plug.loader')
local log = require('plug.logger')

local on_update

--- @class PlugUiData
--- @field command? string clone/pull/build/curl/luarocks
--- @field clone_process? string
--- @field clone_done? boolean
--- @field building? boolean
--- @field build_done? boolean
--- @field pull_done? boolean
--- @field pull_process? string
--- @field curl_done? boolean
--- @field luarocks_done? boolean
--- @field is_local? boolean

if config.ui == 'default' then
  on_update = require('plug.ui').on_update
elseif config.ui == 'notify' then
  on_update = require('plug.ui.notify').on_update
end

local processes = 0

local tasks = {} ---@type { [1]: fun(spec: PluginSpec), [2]: PluginSpec, [3]?: boolean }[]
local luarocks_tasks = {}
local luarocks_running = false

function H.run_first_task()
  local task = table.remove(tasks, 1)
  task[1](task[2], tasks[3])
end

function H.run_first_luarocks_task()
  local task = table.remove(luarocks_tasks, 1)
  task[1](task[2], tasks[3])
end

--- @param spec PluginSpec
function H.build(spec)
  if processes >= config.max_processes then
    table.insert(tasks, { H.build, spec })
    return
  end
  on_update(spec.name, { command = 'build' })
  local jobid = job.start(spec.build, {
    on_exit = function(_, data, single)
      if data == 0 and single == 0 then
        on_update(spec.name, { build_done = true })
        if spec.autoload then
          loader.load(spec)
        end
      else
        on_update(spec.name, { build_done = false })
      end
      processes = processes - 1
      if #tasks > 0 then
        H.run_first_task()
      end
    end,
    cwd = spec.path,
  })
  if jobid > 0 then
    processes = processes + 1
  else
    on_update(spec.name, { build_done = false })
  end
end

-- known issue:
--
-- luarocks does not support install multiple rocks
--
-- https://github.com/luarocks/luarocks/issues/1359
--
-- even can not be run with jobs when the previous luarocks process does not finished.
--
-- [ 13:22:15:577 ] [ Debug ] [   plug ] luarocks install todo.nvim stderr >{ "", "Error: command 'install' requires exclusive write access to D:/Scoop/apps/luarocks/current/rocks - try --force-lock to overwrite the lock" }
-- [ 13:22:15:577 ] [ Debug ] [   plug ] luarocks install todo.nvim exit code 4 single 0

---@param spec PluginSpec
function H.luarocks_install(spec)
  if luarocks_running then
    table.insert(luarocks_tasks, { H.luarocks_install, spec })
    return
  end
  local cmd = { 'luarocks', 'install', spec.name }
  on_update(spec.name, {
    command = 'luarocks',
  })
  local jobid = job.start(cmd, {
    on_stdout = function(_, date)
      log.debug(
        'luarocks install ' .. spec.name .. ' stdout >' .. vim.inspect(date)
      )
    end,
    on_stderr = function(_, date)
      log.debug(
        'luarocks install ' .. spec.name .. ' stderr >' .. vim.inspect(date)
      )
    end,
    on_exit = function(_, data, single)
      log.debug(
        'luarocks install '
          .. spec.name
          .. ' exit code '
          .. data
          .. ' single '
          .. single
      )
      if data == 0 and single == 0 then
        on_update(spec.name, {
          luarocks_done = true,
        })
      else
        on_update(spec.name, {
          luarocks_done = false,
        })
      end
      luarocks_running = false
      if #luarocks_tasks > 0 then
        H.run_first_luarocks_task()
      end
    end,
  })
  if jobid > 0 then
    luarocks_running = true
  else
    on_update(spec.name, {
      luarocks_done = false,
    })
  end
end

--- @param spec PluginSpec
--- @param force? boolean
function H.download_raw(spec, force)
  if processes >= config.max_processes then
    table.insert(tasks, { H.download_raw, spec })
    return
  elseif vim.fn.filereadable(spec.path) == 1 and not force then
    on_update(spec.name, { command = 'curl', curl_done = true })
    return
  end

  local cmd = { 'curl', '-fLo', spec.path, '--create-dirs', spec.url }
  on_update(spec.name, { command = 'curl' })
  local jobid = job.start(cmd, {
    on_exit = function(_, data, single)
      on_update(spec.name, { curl_done = data == 0 and single == 0 })

      processes = processes - 1
      if #tasks > 0 then
        H.run_first_task()
      end
    end,
    env = {
      http_proxy = config.http_proxy,
      https_proxy = config.https_proxy,
    },
  })
  processes = processes + 1
end

--- @param spec PluginSpec
function H.install_plugin(spec)
  if processes >= config.max_processes then
    table.insert(tasks, { H.install_plugin, spec })
    return
  end
  if vim.fn.isdirectory(spec.path) == 1 then
    -- if the directory exists, skip installation
    on_update(spec.name, { command = 'clone', clone_done = true })
    return
  end
  local cmd = { 'git', 'clone', '--progress' }
  if config.clone_depth ~= 0 then
    table.insert(cmd, '--depth')
    table.insert(cmd, tostring(config.clone_depth))
  end
  if spec.branch then
    table.insert(cmd, '--branch')
    table.insert(cmd, spec.branch)
  elseif spec.tag then
    table.insert(cmd, '--branch')
    table.insert(cmd, spec.tag)
  end

  table.insert(cmd, spec.url)
  table.insert(cmd, spec.path)
  on_update(spec.name, { command = 'clone', clone_process = '' })
  log.info('downloading ' .. spec.name .. ':' .. vim.inspect(cmd))
  local jobid = job.start(cmd, {
    on_stderr = function(_, data)
      for _, v in ipairs(data) do
        local status = vim.fn.matchstr(v, [[\d\+%\s(\d\+/\d\+)]])
        if vim.fn.empty(status) == 0 then
          on_update(spec.name, { clone_process = status })
        end
      end
    end,
    on_exit = function(_, data, single)
      if data == 0 and single == 0 then
        on_update(spec.name, { clone_done = true, download_process = 100 })
        if spec.build then
          H.build(spec)
        elseif spec.autoload then
          loader.load(spec)
        end
      else
        on_update(spec.name, { clone_done = false, download_process = 0 })
      end
      processes = processes - 1
      if #tasks > 0 then
        H.run_first_task()
      end
    end,
    env = {
      http_proxy = config.http_proxy,
      https_proxy = config.https_proxy,
    },
  })
  log.info('jobid is ' .. jobid)
  processes = processes + 1
end

--- @param spec PluginSpec
--- @param force? boolean
function H.update_plugin(spec, force)
  if processes >= config.max_processes then
    table.insert(tasks, { H.update_plugin, spec, force })
    return
  end
  if vim.fn.isdirectory(spec.path) ~= 1 then
    -- if the directory does not exist, return failed
    on_update(spec.name, { command = 'pull', pull_done = false })
    return
  end
  if vim.fn.isdirectory(vim.fs.joinpath(spec.path, '.git')) ~= 1 then
    -- if the directory is not git repo
    on_update(spec.name, { command = 'pull', pull_done = false })
    return
  end
  if spec.frozen and not force then
    on_update(spec.name, { command = 'pull', pull_done = true })
    return
  end
  local cmd = { 'git', 'pull', '--progress' }
  on_update(spec.name, { command = 'pull', pull_process = '' })
  local jobid = job.start(cmd, {
    on_stderr = function(_, data)
      for _, v in ipairs(data) do
        local status = vim.fn.matchstr(v, [[\d\+%\s(\d\+/\d\+)]])
        if vim.fn.empty(status) == 0 then
          on_update(spec.name, { pull_process = status })
        end
      end
    end,
    on_exit = function(_, data, single)
      on_update(spec.name, { pull_done = data == 0 and single == 0 })
      if data == 0 and single == 0 and spec.build then
        H.build(spec)
      end
      processes = processes - 1
      if #tasks > 0 then
        H.run_first_task()
      end
    end,
    cwd = spec.path,
    env = {
      http_proxy = config.http_proxy,
      https_proxy = config.https_proxy,
    },
  })
  if jobid > 0 then
    processes = processes + 1
  else
    on_update(spec.name, { pull_done = false })
  end
end

---@param specs PluginSpec[]
function M.install(specs)
  for _, v in ipairs(specs) do
    if v.is_local then
      on_update(v.name, { is_local = true })
    elseif v.type == 'raw' then
      H.download_raw(v)
    elseif v.type == 'rocks' then
      H.luarocks_install(v)
    else
      H.install_plugin(v)
    end
  end
end

--- @param specs PluginSpec[]
--- @param force? boolean
function M.update(specs, force)
  for _, v in ipairs(specs) do
    if v.is_local then
      on_update(v.name, { is_local = true })
    elseif v.type == 'raw' then
      H.download_raw(v, force)
    elseif v.type == 'rocks' then
      require('plug.rocks').update(v)
    else
      H.update_plugin(v, force)
    end
  end
end

return M
