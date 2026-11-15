---@module 'picker.types'

---@class PlugPickerItem: PickerItem
---@field value PluginSpec

---@class PlugPicker: PickerSource
local M = {}
local plug = require('plug')

local previewer = require('picker.previewer.file')
local cmd_previewer = require('picker.previewer.cmd')

--- Directory a plugin lives in: dev path for dev specs, rtp for installed
--- rocks, otherwise the clone path.
---@param spec PluginSpec
---@return string|nil dir
local function plugin_dir(spec)
  if spec.dev and spec.dev_path then
    return spec.dev_path
  end
  if spec.type == 'rocks' then
    return spec.rtp
  end
  return spec.path
end

---@return PlugPickerItem[] items
function M.get()
  local items = {} ---@type PlugPickerItem[]
  for _, spec in pairs(plug.get()) do
    if spec.desc then
      items[#items + 1] = {
        value = spec,
        str = spec.name .. ' - ' .. spec.desc,
        highlight = {
          { 0, #spec.name, 'Normal' },
          { #spec.name, #spec.name + 3 + #spec.desc, 'Comment' },
        },
      }
    else
      items[#items + 1] = { value = spec, str = spec.name }
    end
  end
  return items
end

---@return table<string, fun(entry: PlugPickerItem)> actions
function M.actions()
  return {
    ['<C-t>'] = M.default_action,
    ['<C-b>'] = M._open_url,
    ['<Enter>'] = M._tabnew_lcd,
    ['<C-y>'] = M._copy_url,
  }
end

---@param entry PlugPickerItem
function M.default_action(entry)
  local dir = plugin_dir(entry.value)
  if not dir or dir == '' then
    return
  end

  require('terminal').open(dir)
  vim.fn.timer_start(200, function()
    vim.cmd('noautocmd startinsert')
  end)
end

---@param entry PlugPickerItem
function M._open_url(entry)
  if not entry.value.url then
    return
  end

  vim.ui.open(entry.value.url)
end

--- Open a new tab in the plugin directory.
---
--- The directory is checked *before* `tabnew()`: `lcd` on a missing
--- directory raises, and because the tab had already been created the
--- command left a stray empty tab behind on the current directory.
---@param entry PlugPickerItem
function M._tabnew_lcd(entry)
  local dir = plugin_dir(entry.value)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    vim.notify(
      string.format('%s is not installed!', entry.value.name),
      vim.log.levels.WARN
    )
    return
  end

  vim.cmd.tabnew()
  vim.cmd.lcd(dir)

  if entry.value.dev and vim.fn.filereadable('README.md') == 1 then
    vim.cmd.edit('README.md')
  end
end

---@param entry PlugPickerItem
function M._copy_url(entry)
  if not entry.value.url then
    return
  end

  vim.fn.setreg('"', entry.value.url)
end

M.preview_win = true ---@type boolean

---@param item PlugPickerItem
function M.preview(item, win, buf)
  local spec = item.value
  local path = vim.fs.joinpath(spec.path or '', 'README.md') ---@type string

  if spec.dev and spec.dev_path then
    path = vim.fs.joinpath(spec.dev_path, 'README.md')
  elseif spec.type == 'rocks' and spec.rtp then
    path = vim.fs.joinpath(spec.rtp, 'doc/README.md')
    if vim.fn.filereadable(path) ~= 1 then
      cmd_previewer.preview({ 'luarocks', 'show', spec.name }, win, buf)
      return
    end
  end

  previewer.preview(path, win, buf)
end

return M

