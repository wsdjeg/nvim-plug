--=============================================================================
-- ui.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

---@class Plug.Ui
local M = {}

local bufnr = -1 ---@type integer
local winid = -1 ---@type integer
local done = 0 ---@type integer
local total = -1 ---@type integer
local weight = 100 ---@type integer
local plugin_status = {} ---@type table<string, PlugUiData>

---@param data table<string, PlugUiData>
---@return integer done
local function count_done(data)
  done = 0
  for _, v in pairs(data) do
    if v.command and v[v.command .. '_done'] or v.is_local then
      done = done + 1
    end
  end
  return done
end

---@return string[] base
local function base()
  total = #vim.tbl_keys(plugin_status)
  done = count_done(plugin_status)
  weight = vim.api.nvim_win_get_width(winid) - 10
  return {
    string.format('Plugins:(%s/%s)', done, total),
    '',
    string.format(
      '[%s%s]',
      string.rep('=', math.floor(done / total * weight)),
      string.rep(' ', weight - math.floor(done / total * weight))
    ),
    '',
  }
end

---@return string[] context
local function build_context()
  local b = base()

  for k, plug in pairs(plugin_status) do
    if plug.is_local then
      table.insert(b, string.format('√ %s skip local plugin', k))
    elseif plug.command == 'pull' then
      if plug.pull_done then
        table.insert(b, string.format('√ %s updated', k))
      elseif plug.pull_done == false then
        table.insert(b, string.format('× %s failed to update', k))
      elseif plug.pull_process and plug.pull_process ~= '' then
        table.insert(
          b,
          string.format('- %s updating: %s', k, plug.pull_process)
        )
      else
        table.insert(b, '- ' .. k)
      end
    elseif plug.command == 'clone' then
      if plug.clone_done then
        table.insert(b, string.format('√ %s installed', k))
      elseif plug.clone_done == false then
        table.insert(b, string.format('× %s failed to install', k))
      elseif plug.clone_process and plug.clone_process ~= '' then
        table.insert(
          b,
          string.format('- %s cloning: %s', k, plug.clone_process)
        )
      else
        table.insert(b, '- ' .. k)
      end
    elseif plug.command == 'build' then
      if plug.build_done then
        table.insert(b, string.format('√ %s build done', k))
      elseif plug.build_done == false then
        table.insert(b, string.format('× %s failed to build', k))
      elseif plug.building == true then
        table.insert(b, string.format('- %s building', k))
      else
        table.insert(b, '- ' .. k)
      end
    elseif plug.command == 'curl' then
      if plug.curl_done then
        table.insert(b, string.format('√ %s dowload', k))
      elseif plug.curl_done == false then
        table.insert(b, string.format('× %s failed to dowload', k))
      else
        table.insert(b, string.format('- %s downloading', k))
      end
    elseif plug.command == 'luarocks' then
      if plug.luarocks_done then
        table.insert(b, string.format('√ luarocks install done', k))
      elseif plug.luarocks_done == false then
        table.insert(b, string.format('× %s luarocks install failed', k))
      else
        table.insert(b, string.format('- %s luarocks installing', k))
      end
    end
  end

  return b
end

function M.open()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
  end
  if not vim.api.nvim_win_is_valid(winid) then
    local focus = require('plug.config').focus_window
    winid = vim.api.nvim_open_win(bufnr, focus, {
      split = 'left',
    })
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, build_context())
    vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
  end
  --- setup highlight
  if vim.fn.hlexists('PlugTitle') == 0 then
    vim.api.nvim_set_hl(0, 'PlugTitle', { link = 'TODO', default = true })
  end
  if vim.fn.hlexists('PlugProcess') == 0 then
    vim.api.nvim_set_hl(0, 'PlugProcess', { link = 'Repeat', default = true })
  end
  if vim.fn.hlexists('PlugDone') == 0 then
    vim.api.nvim_set_hl(0, 'PlugDone', { link = 'Type', default = true })
  end
  if vim.fn.hlexists('PlugFailed') == 0 then
    vim.api.nvim_set_hl(
      0,
      'PlugFailed',
      { link = 'WarningMsg', default = true }
    )
  end
  if vim.fn.hlexists('PlugDoing') == 0 then
    vim.api.nvim_set_hl(0, 'PlugDoing', { link = 'Number', default = true })
  end
  vim.fn.matchadd('PlugTitle', '^Plugins.*', 2, -1, { window = winid })
  vim.fn.matchadd('PlugProcess', '^\\[\\zs=*', 2, -1, { window = winid })
  vim.fn.matchadd('PlugDone', '^√.*', 2, -1, { window = winid })
  vim.fn.matchadd('PlugFailed', '^×.*', 2, -1, { window = winid })
  vim.fn.matchadd('PlugDoing', '^-.*', 2, -1, { window = winid })
end

--- @param name string
--- @param data PlugUiData
function M.on_update(name, data)
  plugin_status[name] =
    vim.tbl_deep_extend('force', plugin_status[name] or {}, data)
  if
    vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_win_is_valid(winid)
  then
    vim.api.nvim_set_option_value('modifiable', true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, build_context())
    vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
  end
end

return M
