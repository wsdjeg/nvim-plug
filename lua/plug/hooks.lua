local M = {}

local group = vim.api.nvim_create_augroup('plugin_hooks', { clear = true })

local plugin_loader = require('plug.loader')

local event_plugins = {}
local cmd_plugins = {}
local on_ft_plugins = {}

function M.on_events(events, plugSpec)
  event_plugins[plugSpec.name] = vim.api.nvim_create_autocmd(events, {
    group = group,
    pattern = { '*' },
    callback = function(_)
      vim.api.nvim_del_autocmd(event_plugins[plugSpec.name])
      if on_ft_plugins[plugSpec.name] then
        vim.api.nvim_del_autocmd(on_ft_plugins[plugSpec.name])
      end
      plugin_loader.load(plugSpec)
    end,
  })
end

--- @param cmds table<string>
--- @param plugSpec PluginSpec
function M.on_cmds(cmds, plugSpec)
  for _, cmd in ipairs(cmds) do
    cmd_plugins[cmd] = plugSpec
    vim.api.nvim_create_user_command(cmd, function(opt)
      plugin_loader.load(cmd_plugins[opt.name])
      vim.cmd(opt.name .. ' ' .. opt.args)
    end, {
      nargs = '*',
      complete = function(...)
        return {}
      end,
    })
  end
end

function M.on_ft(fts, plugSpec)
  on_ft_plugins[plugSpec.name] = vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = group,
    pattern = fts,
    callback = function(_)
      vim.api.nvim_del_autocmd(on_ft_plugins[plugSpec.name])
      if event_plugins[plugSpec.name] then
        vim.api.nvim_del_autocmd(event_plugins[plugSpec.name])
      end
      plugin_loader.load(plugSpec)
    end,
  })
end

function M.on_map(maps, plugSpec)
  for _, lhs in ipairs(maps) do
    vim.keymap.set('n', lhs, function()
      for _, v in ipairs(plugSpec.on_map) do
        vim.keymap.del('n', v, {})
      end
      plugin_loader.load(plugSpec)

      local termstr = '<M-_>'
      local input = ''

      vim.fn.feedkeys(termstr, 'n')

      while true do
        local char = vim.fn.getchar()
        if type(char) == 'number' then
          input = input .. vim.fn.nr2char(char)
        else
          input = input .. char
        end
        local idx = vim.fn.stridx(input, termstr)
        if idx >= 1 then
          input = string.sub(input, 1, idx)
          break
        elseif idx == 0 then
          input = ''
          break
        end
      end

      vim.fn.feedkeys(lhs .. input, 'm')
    end, {})
  end
end

return M
