local M = {}
local logger
for _, f in ipairs({ 'info', 'debug', 'warn', 'error' }) do
  M[f] = function(msg)
    if not logger then
      pcall(function()
        logger = require('logger').derive('plug')
        logger[f](msg)
      end)
    else
      logger[f](msg)
    end
  end
end

return M
