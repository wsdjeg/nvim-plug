-- test/picker/previewer/cmd.lua
-- Stub for picker.nvim's command previewer, used by test/picker_spec.lua.

local M = {}

local calls = {}

---@param cmd string[]
---@param win integer
---@param buf integer
function M.preview(cmd, win, buf)
  table.insert(calls, { cmd = cmd, win = win, buf = buf })
end

---@return table[]
function M.calls()
  return calls
end

function M.reset()
  calls = {}
end

return M

