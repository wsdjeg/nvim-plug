--=============================================================================
-- installer.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local M = {}

local H = {}

local job = require('job')
local config = require('plug.config')
local loader = require('plug.loader')
local log = require('plug.logger')

local on_uidate

--- @class PlugUiData
--- @field command? string clone/pull/build/curl/luarocks
--- @filed clone_process? string
--- @filed clone_done? boolean
--- @filed building? boolean
--- @filed build_done? boolean
--- @field pull_done? boolean
--- @field pull_process? string
--- @field curl_done? boolean
--- @field luarocks_done? boolean

if config.ui == 'default' then
    on_uidate = require('plug.ui').on_update
elseif config.ui == 'notify' then
    on_uidate = require('plug.ui.notify').on_uidate
end

local processes = 0

local tasks = {}
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

--- @param plugSpec PluginSpec
function H.build(plugSpec)
    if processes >= config.max_processes then
        table.insert(tasks, { H.build, plugSpec })
        return
    end
    on_uidate(plugSpec.name, { command = 'build' })
    local jobid = job.start(plugSpec.build, {
        on_exit = function(id, data, single)
            if data == 0 and single == 0 then
                on_uidate(plugSpec.name, { build_done = true })
                if plugSpec.autoload then
                    loader.load(plugSpec)
                end
            else
                on_uidate(plugSpec.name, { build_done = false })
            end
            processes = processes - 1
            if #tasks > 0 then
                H.run_first_task()
            end
        end,
        cwd = plugSpec.path,
    })
    if jobid > 0 then
        processes = processes + 1
    else
        on_uidate(plugSpec.name, { build_done = false })
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

function H.luarocks_install(plugSpec)
    if luarocks_running then
        table.insert(luarocks_tasks, { H.luarocks_install, plugSpec })
        return
    end
    local cmd = { 'luarocks', 'install', plugSpec.name }
    on_uidate(plugSpec.name, {
        command = 'luarocks',
    })
    local jobid = job.start(cmd, {
        on_stdout = function(id, date)
            log.debug(
                'luarocks install '
                    .. plugSpec.name
                    .. ' stdout >'
                    .. vim.inspect(date)
            )
        end,
        on_stderr = function(id, date)
            log.debug(
                'luarocks install '
                    .. plugSpec.name
                    .. ' stderr >'
                    .. vim.inspect(date)
            )
        end,
        on_exit = function(id, data, single)
            log.debug(
                'luarocks install '
                    .. plugSpec.name
                    .. ' exit code '
                    .. data
                    .. ' single '
                    .. single
            )
            if data == 0 and single == 0 then
                on_uidate(plugSpec.name, {
                    luarocks_done = true,
                })
            else
                on_uidate(plugSpec.name, {
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
        on_uidate(plugSpec.name, {
            luarocks_done = false,
        })
    end
end

--- @param plugSpec PluginSpec
function H.download_raw(plugSpec, force)
    if processes >= config.max_processes then
        tasks.insert(tasks, { H.download_raw, plugSpec })
        return
    elseif vim.fn.filereadable(plugSpec.path) == 1 and not force then
        on_uidate(plugSpec.name, { command = 'curl', curl_done = true })
        return
    end

    local cmd = { 'curl', '-fLo', plugSpec.path, '--create-dirs', plugSpec.url }
    on_uidate(plugSpec.name, { command = 'curl' })
    local jobid = job.start(cmd, {
        on_exit = function(id, data, single)
            if data == 0 and single == 0 then
                on_uidate(plugSpec.name, { curl_done = true })
            else
                on_uidate(plugSpec.name, { curl_done = false })
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
    processes = processes + 1
end

--- @param plugSpec PluginSpec
function H.install_plugin(plugSpec)
    if processes >= config.max_processes then
        table.insert(tasks, { H.install_plugin, plugSpec })
        return
    elseif vim.fn.isdirectory(plugSpec.path) == 1 then
        -- if the directory exists, skip installation
        on_uidate(plugSpec.name, { command = 'clone', clone_done = true })
        return
    end
    local cmd = { 'git', 'clone', '--progress' }
    if config.clone_depth ~= 0 then
        table.insert(cmd, '--depth')
        table.insert(cmd, tostring(config.clone_depth))
    end
    if plugSpec.branch then
        table.insert(cmd, '--branch')
        table.insert(cmd, plugSpec.branch)
    elseif plugSpec.tag then
        table.insert(cmd, '--branch')
        table.insert(cmd, plugSpec.tag)
    end

    table.insert(cmd, plugSpec.url)
    table.insert(cmd, plugSpec.path)
    on_uidate(plugSpec.name, { command = 'clone', clone_process = '' })
    log.info('downloading ' .. plugSpec.name .. ':' .. vim.inspect(cmd))
    local jobid = job.start(cmd, {
        on_stderr = function(id, data)
            for _, v in ipairs(data) do
                local status = vim.fn.matchstr(v, [[\d\+%\s(\d\+/\d\+)]])
                if vim.fn.empty(status) == 0 then
                    on_uidate(plugSpec.name, { clone_process = status })
                end
            end
        end,
        on_exit = function(id, data, single)
            if data == 0 and single == 0 then
                on_uidate(
                    plugSpec.name,
                    { clone_done = true, download_process = 100 }
                )
                if plugSpec.build then
                    H.build(plugSpec)
                elseif plugSpec.autoload then
                    loader.load(plugSpec)
                end
            else
                on_uidate(
                    plugSpec.name,
                    { clone_done = false, download_process = 0 }
                )
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

--- @param plugSpec PluginSpec
function H.update_plugin(plugSpec, force)
    if processes >= config.max_processes then
        table.insert(tasks, { H.update_plugin, plugSpec, force })
        return
    elseif vim.fn.isdirectory(plugSpec.path) ~= 1 then
        -- if the directory does not exist, return failed
        on_uidate(plugSpec.name, { command = 'pull', pull_done = false })
        return
    elseif vim.fn.isdirectory(plugSpec.path .. '/.git') ~= 1 then
        -- if the directory is not git repo
        on_uidate(plugSpec.name, { command = 'pull', pull_done = false })
        return
    elseif plugSpec.frozen and not force then
        on_uidate(plugSpec.name, { command = 'pull', pull_done = true })
        return
    end
    local cmd = { 'git', 'pull', '--progress' }
    on_uidate(plugSpec.name, { command = 'pull', pull_process = '' })
    local jobid = job.start(cmd, {
        on_stderr = function(id, data)
            for _, v in ipairs(data) do
                local status = vim.fn.matchstr(v, [[\d\+%\s(\d\+/\d\+)]])
                if vim.fn.empty(status) == 0 then
                    on_uidate(plugSpec.name, { pull_process = status })
                end
            end
        end,
        on_exit = function(id, data, single)
            if data == 0 and single == 0 then
                on_uidate(plugSpec.name, { pull_done = true })
                if plugSpec.build then
                    H.build(plugSpec)
                end
            else
                on_uidate(plugSpec.name, { pull_done = false })
            end
            processes = processes - 1
            if #tasks > 0 then
                H.run_first_task()
            end
        end,
        cwd = plugSpec.path,
        env = {
            http_proxy = config.http_proxy,
            https_proxy = config.https_proxy,
        },
    })
    if jobid > 0 then
        processes = processes + 1
    else
        on_uidate(plugSpec.name, { pull_done = false })
    end
end

M.install = function(plugSpecs)
    for _, v in ipairs(plugSpecs) do
        if v.is_local then
            on_uidate(v.name, { is_local = true })
        elseif v.type == 'raw' then
            H.download_raw(v)
        elseif v.type == 'rocks' then
            H.luarocks_install(v)
        else
            H.install_plugin(v)
        end
    end
end

M.update = function(plugSpecs, force)
    for _, v in ipairs(plugSpecs) do
        if v.is_local then
            on_uidate(v.name, { is_local = true })
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
