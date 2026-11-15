---@class Plug.Logger
---@field info fun(msg: string)
---@field debug fun(msg: string)
---@field warn fun(msg: string)
---@field error fun(msg: string)
local M = {}

local LEVELS = { 'info', 'debug', 'warn', 'error' }

--- Cached logger instance.
---
--- `false` is a sentinel meaning "logger.nvim is unusable", so a failed or
--- broken lookup is not retried on every single log call. Without it each
--- log line re-ran require() (and re-raised) when logger.nvim was missing.
---@type table<string, fun(msg: string)>|false|nil
local logger = nil

--- Resolve (and cache) the plug logger instance.
---@return table<string, fun(msg: string)>|nil
local function instance()
  if logger == false then
    return nil
  end
  if logger then
    return logger
  end

  local ok, instance = pcall(function()
    return require('logger').derive('plug')
  end)
  if ok and type(instance) == 'table' then
    logger = instance
    return logger
  end

  logger = false
  return nil
end

for _, level in ipairs(LEVELS) do
  M[level] = function(msg)
    local l = instance()
    if not l then
      return
    end

    -- Guard every call, not just the first one: a logger.nvim version without
    -- this level, or a level that raises, must never break plugin loading.
    local fn = l[level]
    if type(fn) ~= 'function' then
      return
    end

    pcall(fn, msg)
  end
end

return M

