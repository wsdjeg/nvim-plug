--=============================================================================
-- installer.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local M = {}

local job = require("spacevim.api.job")
local notify = require("spacevim.api.notify")
local jobs = {}

M.install = function(plugSpec)
	local cmd = { "git", "clone", "--depth", "1" }
	if plugSpec.branch then
		table.insert(cmd, "--branch")
		table.insert(cmd, plugSpec.branch)
	elseif plugSpec.tag then
		table.insert(cmd, "--branch")
		table.insert(cmd, plugSpec.tag)
	end

	table.insert(cmd, plugSpec.url)
	table.insert(cmd, plugSpec.path)
  vim.print(cmd)
	jobs[job.start(cmd, {
		on_exit = function(id, data, single)
			if data == 0 and single == 0 then
        notify.notify('Successfully installed ' .. jobs[id])
      else
        notify.notify('failed to install ' .. jobs[id])
			end
		end,
	})] =
		plugSpec.name
end

return M
