local M = {}
local plug = require('plug')

local previewer = require('picker.previewer.file')
local cmd_previewer = require('picker.previewer.cmd')

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
    ['<C-y>'] = M._copy_url,
  }
end

function M.default_action(entry)
  local p
  if entry.value.dev and entry.value.dev_path then
    p = entry.value.dev_path
  elseif entry.value.type == 'rocks' then
    if entry.value.rtp then
      p = entry.value.rtp
    end
  else
    p = entry.value.path
  end
  if p then
    require('terminal').open(p)
    vim.fn.timer_start(200, function()
      vim.cmd('noautocmd startinsert')
    end)
  end
end

function M._open_url(entry)
  if entry.value.url then
    vim.ui.open(entry.value.url)
  end
end

function M._tabnew_lcd(entry)
  if entry.value.dev and entry.value.dev_path then
    vim.cmd('tabnew')
    vim.cmd.lcd(entry.value.dev_path)
    if vim.fn.filereadable('README.md') == 1 then
      vim.cmd.edit('README.md')
    end
  elseif entry.value.type == 'rocks' then
    if entry.value.rtp then
      vim.cmd('tabnew')
      vim.cmd.lcd(entry.value.rtp)
    else
      vim.notify(entry.value.name .. ' is not installed!')
    end
  else
    vim.cmd('tabnew')
    vim.cmd.lcd(entry.value.path)
  end
end

function M._copy_url(entry)
  if entry.value.url then
    vim.fn.setreg('"', entry.value.url)
  end
end

M.preview_win = true

---@field item PickerItem
function M.preview(item, win, buf)
  if item.value.dev and item.value.dev_path then
    previewer.preview(item.value.dev_path .. '/README.md', win, buf)
  elseif item.value.type == 'rocks' then
    if item.value.rtp then
      if vim.fn.filereadable(item.value.rtp .. '/doc/README.md') == 1 then
        previewer.preview(item.value.rtp .. '/doc/README.md', win, buf)
      else
        cmd_previewer.preview(
          { 'luarocks', 'show', item.value.name },
          win,
          buf
        )
      end
    end
  else
    previewer.preview(item.value.path .. '/README.md', win, buf)
  end
end

return M
