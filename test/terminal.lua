-- test/terminal.lua
-- Stub for terminal.nvim, used by test/picker_spec.lua.
-- Resolved before the real plugin because `test/?.lua` is on package.path.

local M = {}

local calls = {}

---@param dir string
function M.open(dir)
  table.insert(calls, dir)
end

---@return string[]
function M.calls()
  return calls
end

function M.reset()
  calls = {}
end

return M

