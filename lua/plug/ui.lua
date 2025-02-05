--=============================================================================
-- ui.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local M = {}

local bufnr = -1
local winid = -1
local done = -1
local total = -1
local weight = -1
local base = function()
  return {
    'plugins:(' .. done .. '/' .. total .. ')',
    '',
    '[' .. string.rep('=', math.floor(done / total * weight)) .. string.rep(
      ' ',
      weight - math.floor(done / total * weight)
    ) .. ']',
    '',
  }
end

--- @clase PluginStatus
--- @filed downloaded boolean
--- @filed download_process number 0 - 100

local plugin_status = {}

local function build_context()
  local b = base()

  for _, plug in ipairs(plugin_status) do

    if plug.downloaded then
      table.insert(b, '+ ' .. plug.name .. ' downloaded')
    else
      table.insert(b, '- ' .. plug.name .. string.format(' (%s%%)', plug.download_process))
    end
  end

  return b
end

M.open = function()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
  end
  if vim.api.nvim_win_is_valid(winid) then
    winid = vim.api.nvim_open_win(bufnr, false, {
      split = 'left',
    })
  end
end


--- @class PlugUiData
--- @filed clone_process string
--- @filed clone_done boolean


--- @param name string
--- @param data PlugUiData
M.on_update = function(name, data)
  if not plugin_status[name] then
    plugin_status[name] = {
     downloaded = data.downloaded or false,
     download_process = data.download_process or 0
    }
  else
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, build_context())
  end
end

return M
