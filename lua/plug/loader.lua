--=============================================================================
-- loader.lua
-- Copyright 2025 Eric Wong
-- Author: Eric Wong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================


local M = {}

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
  if plugSpec.rtp then
    vim.opt.runtimepath:append(plugSpec.rtp)
  end
end


return M
