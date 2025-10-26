local M = {}
local plug = require('plug')

local previewer = require('picker.previewer.file')

function M.get()
  local p = {}
  local plugins = plug.get()

  for _, k in pairs(plugins) do
    table.insert(p, k)
  end
  return vim.tbl_map(function(t)
    return { value = t, str = t.name }
  end, p)
end

function M.actions()
  return {
    ['<C-t>'] = M.default_action,
    ['<C-b>'] = M._open_url,
    ['<Enter>'] = M._tabnew_lcd,
    ['<C-y>'] = M._copu_url,
  }
end

function M.default_action(entry)
  require('terminal').open(entry.value.path)
  vim.fn.timer_start(200, function()
    vim.cmd('noautocmd startinsert')
  end)
end

function M._open_url(entry)
  vim.ui.open(entry.value.url)
end

function M._tabnew_lcd(entry)
  vim.cmd('tabnew')
  vim.cmd('lcd ' .. entry.value.path)
end

function M._copu_url(entry)
  vim.fn.setreg('"', entry.value.url)
end

M.preview_win = true

---@field item PickerItem
function M.preview(item, win, buf)
  previewer.preview(item.value.path .. '/README.md', win, buf)
end

return M
