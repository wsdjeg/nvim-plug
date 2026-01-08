local notify = require('notify')

local M = {}

function M.on_uidate(name, data)
  if data.build_done then
    notify.notify(string.format('%s build done', name))
  elseif data.curl_done or data.clone_done then
    notify.notify(string.format('%s downloaded', name))
  elseif data.pull_done then
    notify.notify(string.format('%s updated', name))
  end
end

return M
