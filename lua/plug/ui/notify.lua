---@class Plug.Ui.Notify
local M = {}

--- Resolve the notify backend on every call.
---
--- notify.nvim is optional: when it is missing, fall back to vim.notify.
--- Resolving at call time (instead of module load time) means installing
--- notify.nvim later takes effect without restarting.
---@return fun(msg: string, level?: integer)
local function backend()
  local ok, notify = pcall(require, 'notify')
  if ok and type(notify) == 'table' and type(notify.notify) == 'function' then
    return notify.notify
  end
  return vim.notify
end

--- Emit a notification, swallowing backend errors.
---
--- A throwing notify backend must never break installer callbacks, which
--- would otherwise abort the whole install/update run.
---@param msg string
local function notify(msg)
  local fn = backend()
  pcall(fn, msg)
end

--- Report the result of an operation.
---
--- `done == false` is a real value, not "no information": it used to be
--- checked with a plain truthiness test, so every failure was silently
--- dropped and the user saw no feedback at all.
---@param name string
---@param done boolean|nil
---@param ok_msg string
---@param fail_msg string
---@return boolean reported
local function report(name, done, ok_msg, fail_msg)
  if done == nil then
    return false
  end
  if done then
    notify(string.format('%s %s', name, ok_msg))
  else
    notify(string.format('%s %s', name, fail_msg))
  end
  return true
end

--- Fetch the download result for the given command.
---
--- `data.clone_done or data.curl_done` is wrong: `false or nil` evaluates to
--- nil, so a failed clone with no curl field looked like "no information"
--- and stayed silent. Pick the field that belongs to the command instead.
---@param command string
---@param data PlugUiData
---@return boolean|nil done
local function download_result(command, data)
  if command == 'clone' then
    return data.clone_done
  end
  return data.curl_done
end

---@param name string
---@param data PlugUiData
function M.on_update(name, data)
  if data.is_local then
    notify(string.format('%s is a local plugin, skipped', name))
    return
  end

  local ok_msg, fail_msg
  local done = nil ---@type boolean|nil
  if data.command == 'build' then
    done = data.build_done
    ok_msg, fail_msg = 'build done', 'failed to build'
  elseif data.command == 'clone' or data.command == 'curl' then
    done = download_result(data.command, data)
    ok_msg, fail_msg = 'downloaded', 'failed to download'
  elseif data.command == 'pull' then
    done = data.pull_done
    ok_msg, fail_msg = 'updated', 'failed to update'
  elseif data.command == 'luarocks' then
    done = data.luarocks_done
    ok_msg, fail_msg = 'luarocks install done', 'luarocks install failed'
  else
    -- progress-only updates (clone_process, pull_process, ...) stay silent,
    -- otherwise every percentage tick would raise a notification.
    return
  end

  report(name, done, ok_msg, fail_msg)
end

return M

