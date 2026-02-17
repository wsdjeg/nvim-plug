---@module 'picker.types'

---@class PlugPickerItem: PickerItem
---@field value PluginSpec

---@class PlugPicker: PickerSource
local M = {}
local plug = require('plug')

local previewer = require('picker.previewer.file')
local cmd_previewer = require('picker.previewer.cmd')

---@return PlugPickerItem[] items
function M.get()
  return vim.tbl_map(function(t) ---@param t PluginSpec
    if t.desc then
      return {
        value = t,
        str = t.name .. ' - ' .. t.desc,
        highlight = {
          {

            0,
            string.len(t.name),
            'Normal',
          },
          {

            string.len(t.name),
            string.len(t.name) + 3 + string.len(t.desc),
            'Comment',
          },
        },
      }
    end

    return { value = t, str = t.name }
  end, vim.tbl_values(plug.get()))
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
  local p = entry.value.path or nil ---@type string|nil
  if entry.value.dev and entry.value.dev_path then
    p = entry.value.dev_path --[[@as string]]
  elseif entry.value.type == 'rocks' and entry.value.rtp then
    p = entry.value.rtp --[[@as string]]
  end
  if not p then
    return
  end

  require('terminal').open(p)
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

---@param entry PlugPickerItem
function M._tabnew_lcd(entry)
  if entry.value.dev and entry.value.dev_path then
    vim.cmd.tabnew()
    vim.cmd.lcd(entry.value.dev_path)
    if vim.fn.filereadable('README.md') == 1 then
      vim.cmd.edit('README.md')
    end
  elseif entry.value.type == 'rocks' then
    if entry.value.rtp then
      vim.cmd.tabnew()
      vim.cmd.lcd(entry.value.rtp)
    else
      vim.notify(entry.value.name .. ' is not installed!')
    end
  else
    vim.cmd.tabnew()
    vim.cmd.lcd(entry.value.path)
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
  local path = vim.fs.joinpath(item.value.path or '', 'README.md') ---@type string

  if item.value.dev and item.value.dev_path then
    path = vim.fs.joinpath(item.value.dev_path, 'README.md')
  elseif item.value.type == 'rocks' and item.value.rtp then
    path = vim.fs.joinpath(item.value.rtp, 'doc/README.md')
    if vim.fn.filereadable(path) ~= 1 then
      cmd_previewer.preview({ 'luarocks', 'show', item.value.name }, win, buf)
      return
    end
  end

  previewer.preview(path, win, buf)
end

return M
