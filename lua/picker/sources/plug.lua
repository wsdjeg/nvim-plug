local M = {}
local plug = require('plug')
local terminal = require('terminal')

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
    ['<Enter>'] = M.default_action,
    ['<C-b>'] = M._open_url,
  }
end

function M.default_action(entry)
  terminal.open(entry.value.path)
  -- make sure it is terminal mode
  vim.cmd('noautocmd startinsert')
end

function M._open_url(entry)
  vim.ui.open(entry.value.url)
end

M.preview_win = true

---@field item PickerItem
function M.preview(item, win, buf)
  previewer.preview(item.value.path .. '/README.md', win, buf)
end

return M
