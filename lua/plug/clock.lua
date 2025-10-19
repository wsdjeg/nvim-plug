local M = {}

local started = vim.uv.hrtime()

function M.start()
  started = vim.uv.hrtime()
end

function M.time()
  return (vim.uv.hrtime() - started) / 1e6
end

return M
