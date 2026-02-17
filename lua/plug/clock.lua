local uv = vim.uv or vim.loop

---@class Plug.Clock
local M = {}

local started = uv.hrtime()

function M.start()
  started = uv.hrtime()
end

---@return integer time
function M.time()
  return math.floor((uv.hrtime() - started) / 1e6)
end

return M
