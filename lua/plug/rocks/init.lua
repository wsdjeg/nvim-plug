local M = {}

local rocks = {}

local function get_installed_rocks()
    if vim.fn.executable('luarocks') == 0 then
        return {}
    else
        --- @type string
        local installed_output =
            vim.system({ 'luarocks', 'list', '--porcelain' }, { text = true })
                :wait().stdout
        for _, v in
            ipairs(vim.tbl_map(
                function(t)
                    return vim.split(t, '\t')
                end,
                vim.tbl_filter(function(t)
                    return t ~= ''
                end, vim.split(installed_output, '\n'))
            ))
        do
            rocks[v[1]] = {
                rtp = M.unify_path(v[4]) .. v[1] .. '/' .. v[2],
            }
        end
    end
end

local is_win = vim.fn.has('win32') == 1
M.unify_path = function(_path, ...)
    local mod = select(1, ...)
    if mod == nil then
        mod = ':p'
    end
    local path = vim.fn.fnamemodify(_path, mod .. ':gs?[\\\\/]?/?')
    if is_win then
        local re = vim.regex('^[a-zA-Z]:/')
        if re:match_str(path) then
            path = string.upper(string.sub(path, 1, 1)) .. string.sub(path, 2)
        end
    end
    if vim.fn.isdirectory(path) == 1 and string.sub(path, -1) ~= '/' then
        return path .. '/'
    elseif string.sub(_path, -1) == '/' and string.sub(path, -1) ~= '/' then
        return path .. '/'
    else
        return path
    end
end
local enabled
function M.enable()
    if enabled then
        return
    end
    local ok, _ = pcall(function()
        local luarocks_config = vim.json.decode(
            vim.system({ 'luarocks', 'config', '--json' }):wait().stdout
        )
        package.path = package.path
            .. ';'
            .. luarocks_config.deploy_lua_dir
            .. [[\?.lua]]
            .. ';'
            .. luarocks_config.deploy_lua_dir
            .. [[\?\init.lua]]
            .. ';'
        --- D:\Scoop\apps\luarocks\current\rocks\lib\lua\5.4\?.dll
        package.cpath = package.cpath
            .. ';'
            .. luarocks_config.deploy_lib_dir
            .. '\\?.'
            .. luarocks_config.external_lib_extension
    end)
    if ok then
        enabled = true
    end
end

function M.get(rock)
    if not rocks[rock] then
        get_installed_rocks()
    end
    return rocks[rock]
end

function M.set_rtp(plugSpec)
    local rock = M.get(plugSpec.name)
    if rock then
        plugSpec.rtp = rock.rtp
    end
end

return M
