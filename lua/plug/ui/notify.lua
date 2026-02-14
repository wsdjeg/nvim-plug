local notify = vim.notify
if pcall(require, 'notify') then
  notify = require('notify').notify
end

---@class Plug.Ui.Notify
local M = {}

---@param name string
---@param data PlugUiData
function M.on_update(name, data)
  if data.build_done then
    notify(string.format('%s build done', name))
    return
  end
  if data.curl_done or data.clone_done then
    notify(string.format('%s downloaded', name))
    return
  end
  if data.pull_done then
    notify(string.format('%s updated', name))
  end
end

return M
