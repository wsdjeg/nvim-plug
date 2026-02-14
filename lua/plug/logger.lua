---@class Plug.Logger
---@field info fun(msg: string)
---@field debug fun(msg: string)
---@field warn fun(msg: string)
---@field error fun(msg: string)
local M = {}

local logger

for _, f in ipairs({ 'info', 'debug', 'warn', 'error' }) do
  M[f] = function(msg) ---@param msg string
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
