-- test/picker_spec.lua
-- Tests for the picker.nvim source (lua/picker/sources/plug.lua)

local lu = require('luaunit')
local picker = require('picker.sources.plug')
local plug = require('plug')

local TestPicker = {}

local file_previewer = require('picker.previewer.file')
local cmd_previewer = require('picker.previewer.cmd')
local terminal = require('terminal')

local orig_tab ---@type integer
local orig_cwd ---@type string

---@param dirs string[]
local function delete_dirs(dirs)
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      vim.fn.delete(dir, 'rf')
    end
  end
end

--- Create a temp plugin directory, optionally with a README.md.
---@param with_readme? boolean
---@return string dir
local function make_plugin_dir(with_readme)
  local dir = vim.fn.tempname() .. '_picker_plugin'
  vim.fn.mkdir(dir, 'p')
  if with_readme then
    vim.fn.writefile({ '# readme' }, dir .. '/README.md')
  end
  table.insert(TestPicker._dirs, dir)
  return dir
end

--- Build a picker entry for an ad-hoc spec.
---@param spec PluginSpec
---@return PlugPickerItem
local function entry(spec)
  return { value = spec, str = spec.name or '' }
end

function TestPicker:setUp()
  self._dirs = {}
  orig_tab = vim.fn.tabpagenr('$')
  orig_cwd = vim.fn.getcwd()

  file_previewer.reset()
  cmd_previewer.reset()
  terminal.reset()

  self.orig_open = vim.ui.open
  self.orig_notify = vim.notify
end

function TestPicker:tearDown()
  while vim.fn.tabpagenr('$') > orig_tab do
    pcall(vim.cmd, 'tabclose')
  end
  if vim.fn.getcwd() ~= orig_cwd then
    pcall(vim.cmd, 'lcd ' .. vim.fn.fnameescape(orig_cwd))
  end

  delete_dirs(self._dirs)

  vim.ui.open = self.orig_open
  vim.notify = self.orig_notify
end

-----------------------------------------------------------
-- get()
-----------------------------------------------------------

function TestPicker:testGetReturnsItemPerSpec()
  plug.add({ { 'wsdjeg/pick-a.nvim', fetch = true } })

  local items = picker.get()
  local found = nil ---@type PlugPickerItem|nil
  for _, item in ipairs(items) do
    if item.value.name == 'pick-a.nvim' then
      found = item
    end
  end

  lu.assertNotNil(found)
  lu.assertEquals(found.str, 'pick-a.nvim')
end

function TestPicker:testGetShowsDesc()
  plug.add({
    { 'wsdjeg/pick-desc.nvim', fetch = true, desc = 'a picker plugin' },
  })

  local items = picker.get()
  local found = nil ---@type PlugPickerItem|nil
  for _, item in ipairs(items) do
    if item.value.name == 'pick-desc.nvim' then
      found = item
    end
  end

  lu.assertNotNil(found)
  lu.assertEquals(found.str, 'pick-desc.nvim - a picker plugin')
  lu.assertNotNil(found.highlight)
end

--- Highlight ranges must cover the name and the ` - desc` suffix without
--- overlapping, otherwise picker.nvim renders the wrong colours.
function TestPicker:testGetHighlightRanges()
  plug.add({ { 'wsdjeg/pick-hl.nvim', fetch = true, desc = 'hl' } })

  local items = picker.get()
  local found = nil ---@type PlugPickerItem|nil
  for _, item in ipairs(items) do
    if item.value.name == 'pick-hl.nvim' then
      found = item
    end
  end

  lu.assertNotNil(found)
  lu.assertEquals(found.highlight[1][1], 0)
  lu.assertEquals(found.highlight[1][2], #'pick-hl.nvim')
  lu.assertEquals(found.highlight[2][1], #'pick-hl.nvim')
  lu.assertEquals(found.highlight[2][2], #'pick-hl.nvim - hl')
end

function TestPicker:testGetWithoutPlugins()
  -- must not raise when the registry is empty
  local ok = pcall(picker.get)
  lu.assertTrue(ok)
  lu.assertEquals(type(picker.get()), 'table')
end

-----------------------------------------------------------
-- actions()
-----------------------------------------------------------

function TestPicker:testActionsAreFunctions()
  for key, fn in pairs(picker.actions()) do
    lu.assertEquals(type(fn), 'function', key)
  end
end

-----------------------------------------------------------
-- url actions
-----------------------------------------------------------

function TestPicker:testCopyUrlSetsRegister()
  picker._copy_url(entry({ name = 'copy.nvim', url = 'https://x/y' }))
  lu.assertEquals(vim.fn.getreg('"'), 'https://x/y')
end

function TestPicker:testCopyUrlWithoutUrlIsNoop()
  vim.fn.setreg('"', 'sentinel')
  picker._copy_url(entry({ name = 'copy-none.nvim' }))
  lu.assertEquals(vim.fn.getreg('"'), 'sentinel')
end

function TestPicker:testOpenUrlOpensBrowser()
  local opened = {} ---@type string[]
  vim.ui.open = function(url)
    table.insert(opened, url)
  end

  picker._open_url(entry({ name = 'open.nvim', url = 'https://x/y' }))
  lu.assertEquals(opened, { 'https://x/y' })
end

function TestPicker:testOpenUrlWithoutUrlIsNoop()
  local opened = {} ---@type string[]
  vim.ui.open = function(url)
    table.insert(opened, url)
  end

  picker._open_url(entry({ name = 'open-none.nvim' }))
  lu.assertEquals(#opened, 0)
end

-----------------------------------------------------------
-- default_action (open terminal)
-----------------------------------------------------------

function TestPicker:testDefaultActionOpensTerminal()
  local dir = make_plugin_dir()

  picker.default_action(entry({ name = 'term.nvim', path = dir }))
  lu.assertEquals(terminal.calls(), { dir })
end

--- A rocks plugin uses its rtp, a dev plugin uses its dev path.
function TestPicker:testDefaultActionPrefersDevPath()
  local bundle = make_plugin_dir()
  local dev = make_plugin_dir()

  picker.default_action(entry({
    name = 'term-dev.nvim',
    path = bundle,
    dev = true,
    dev_path = dev,
  }))
  lu.assertEquals(terminal.calls(), { dev })
end

function TestPicker:testDefaultActionUsesRocksRtp()
  local rtp = make_plugin_dir()

  picker.default_action(entry({ name = 'term-rock', type = 'rocks', rtp = rtp }))
  lu.assertEquals(terminal.calls(), { rtp })
end

function TestPicker:testDefaultActionWithoutPathIsNoop()
  picker.default_action(entry({ name = 'term-none.nvim' }))
  lu.assertEquals(#terminal.calls(), 0)
end

-----------------------------------------------------------
-- _tabnew_lcd
-----------------------------------------------------------

function TestPicker:testTabnewLcdDevPlugin()
  local dev = make_plugin_dir(true)

  picker._tabnew_lcd(entry({
    name = 'tab-dev.nvim',
    dev = true,
    dev_path = dev,
  }))

  lu.assertEquals(vim.fn.getcwd(), dev)
  lu.assertEquals(vim.api.nvim_buf_get_name(0), dev .. '/README.md')
end

function TestPicker:testTabnewLcdRocksInstalled()
  local rtp = make_plugin_dir()

  picker._tabnew_lcd(entry({ name = 'tab-rock', type = 'rocks', rtp = rtp }))

  lu.assertEquals(vim.fn.getcwd(), rtp)
  lu.assertEquals(vim.fn.tabpagenr('$'), orig_tab + 1)
end

--- An uninstalled rocks plugin must be reported without opening a tab.
function TestPicker:testTabnewLcdRocksNotInstalled()
  local notified = {} ---@type string[]
  vim.notify = function(msg)
    table.insert(notified, msg)
  end

  picker._tabnew_lcd(entry({ name = 'tab-rock-missing', type = 'rocks' }))

  lu.assertEquals(#notified, 1)
  lu.assertStrContains(notified[1], 'not installed')
  lu.assertEquals(vim.fn.tabpagenr('$'), orig_tab)
end

function TestPicker:testTabnewLcdPlainPlugin()
  local dir = make_plugin_dir()

  picker._tabnew_lcd(entry({ name = 'tab-plain.nvim', path = dir }))

  lu.assertEquals(vim.fn.getcwd(), dir)
  lu.assertEquals(vim.fn.tabpagenr('$'), orig_tab + 1)
end

--- Pressing Enter on a plugin that is not cloned yet must not raise and
--- must not leave a stray tab behind. Before, `tabnew()` ran before
--- `lcd()` discovered the missing directory.
function TestPicker:testTabnewLcdMissingDirDoesNotRaise()
  local notified = {} ---@type string[]
  vim.notify = function(msg)
    table.insert(notified, msg)
  end

  local missing = vim.fn.tempname() .. '_not_cloned'
  local ok, err = pcall(
    picker._tabnew_lcd,
    entry({ name = 'tab-missing.nvim', path = missing })
  )

  lu.assertTrue(ok, tostring(err))
  lu.assertEquals(vim.fn.tabpagenr('$'), orig_tab)
  lu.assertEquals(#notified, 1)
end

--- A spec whose path is nil must be handled the same way.
function TestPicker:testTabnewLcdNilPathDoesNotRaise()
  local notified = {} ---@type string[]
  vim.notify = function(msg)
    table.insert(notified, msg)
  end

  local ok, err = pcall(
    picker._tabnew_lcd,
    entry({ name = 'tab-nil.nvim' })
  )

  lu.assertTrue(ok, tostring(err))
  lu.assertEquals(vim.fn.tabpagenr('$'), orig_tab)
  lu.assertEquals(#notified, 1)
end

-----------------------------------------------------------
-- preview()
-----------------------------------------------------------

function TestPicker:testPreviewDevUsesDevReadme()
  local dev = make_plugin_dir(true)

  picker.preview(entry({ name = 'prev-dev.nvim', dev = true, dev_path = dev }), 0, 0)

  lu.assertEquals(#file_previewer.calls(), 1)
  lu.assertEquals(file_previewer.calls()[1].path, dev .. '/README.md')
end

function TestPicker:testPreviewPlainPlugin()
  local dir = make_plugin_dir(true)

  picker.preview(entry({ name = 'prev-plain.nvim', path = dir }), 0, 0)

  lu.assertEquals(#file_previewer.calls(), 1)
  lu.assertEquals(file_previewer.calls()[1].path, dir .. '/README.md')
end

--- Rocks plugins have no README.md; fall back to `luarocks show`.
function TestPicker:testPreviewRocksFallsBackToCmd()
  local rtp = make_plugin_dir()

  picker.preview(entry({ name = 'prev-rock', type = 'rocks', rtp = rtp }), 0, 0)

  lu.assertEquals(#file_previewer.calls(), 0)
  lu.assertEquals(#cmd_previewer.calls(), 1)
  lu.assertEquals(cmd_previewer.calls()[1].cmd, {
    'luarocks',
    'show',
    'prev-rock',
  })
end

--- A rocks plugin that ships doc/README.md is previewed as a file.
function TestPicker:testPreviewRocksWithDocReadme()
  local rtp = make_plugin_dir()
  vim.fn.mkdir(rtp .. '/doc', 'p')
  vim.fn.writefile({ '# rock' }, rtp .. '/doc/README.md')

  picker.preview(entry({ name = 'prev-rock-doc', type = 'rocks', rtp = rtp }), 0, 0)

  lu.assertEquals(#file_previewer.calls(), 1)
  lu.assertEquals(file_previewer.calls()[1].path, rtp .. '/doc/README.md')
  lu.assertEquals(#cmd_previewer.calls(), 0)
end

--- A spec without any path must not raise.
function TestPicker:testPreviewWithoutPathDoesNotRaise()
  local ok, err = pcall(
    picker.preview,
    entry({ name = 'prev-none.nvim' }),
    0,
    0
  )
  lu.assertTrue(ok, tostring(err))
end

return TestPicker

