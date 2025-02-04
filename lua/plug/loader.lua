--=============================================================================
-- loader.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================


local M = {}


--- @class PluginSpec
--- @field rtp string
--- @field events table<string>
--- @field cmds table<string>
--- @field config function

-- {'loadconf': 1,
-- 'type': 'none',
-- 'overwrite': 1,
-- 'lazy': 0,
-- 'name': 'defx-git',
-- 'rtp': 'C:/Users/wsdjeg/.SpaceVim/bundle/defx-git',
-- 'normalized_name': 'defx-git',
-- 'local': 1,
-- 'sourced': 1,
-- 'orig_opts': {'repo': 'C:/Users/wsdjeg/.SpaceVim/bundle/defx-git',
-- 'loadconf': 1,
-- 'type': 'none',
-- 'merged': 0,
-- 'hook_source': 'call SpaceVim#util#loadConfig(''plugins/defx-git.vim'')',
-- 'overwrite': 1},
-- 'repo': 'C:/Users/wsdjeg/.SpaceVim/bundle/defx-git',
-- 'hook_source': 'call SpaceVim#util#loadConfig(''plugins/defx-git.vim'')',
-- 'called': {'''call SpaceVim#util#loadConfig(''''plugins/defx-git.vim'''')''': v:true},
-- 'merged': 0,
-- 'path': 'C:/Users/wsdjeg/.SpaceVim/bundle/defx-git'}
function M.load(plugSpec)
  if vim.fn.isdirectory(plugSpec.rtp) == 1 then
    vim.opt.runtimepath:append(plugSpec.rtp)
    if vim.fn.has('vim_starting') ~= 1 then
      local plugin_directory_files = vim.fn.globpath(plugSpec.rtp, 'plugin/*.{lua,vim}')
      for _, f in ipairs(plugin_directory_files) do
        vim.cmd.source(f)
      end
    end
  end
end


return M
