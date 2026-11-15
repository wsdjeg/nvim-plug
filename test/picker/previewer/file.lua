-- test/picker/previewer/file.lua
-- Stub for picker.nvim's file previewer, used by test/picker_spec.lua.

local M = {}

local calls = {}

---@param path string
---@param win integer
---@param buf integer
function M.preview(path, win, buf)
  table.insert(calls, { path = path, win = win, buf = buf })
end

---@return table[]
function M.calls()
  return calls
end

function M.reset()
  calls = {}
end

return M

