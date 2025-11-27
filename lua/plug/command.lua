local M = {}

function M.run(opt)
    if #opt.fargs > 0 and opt.fargs[1] == 'install' then
        local plugs = {}
        local all_plugins = require('plug').get()
        if #opt.fargs == 1 then
            for _, v in pairs(all_plugins) do
                table.insert(plugs, v)
            end
            require('plug.installer').install(plugs)
        else
            for i = 2, #opt.fargs do
                local p = all_plugins[opt.fargs[i]]
                if p then
                    table.insert(plugs, p)
                end
            end
            require('plug.installer').install(plugs)
        end
        local c = require('plug.config')
        if c.ui == 'default' then
            require('plug.ui').open()
        end
    elseif #opt.fargs > 0 and opt.fargs[1] == 'update' then
        local plugs = {}
        local all_plugins = require('plug').get()
        if #opt.fargs == 1 then
            for _, v in pairs(all_plugins) do
                table.insert(plugs, v)
            end
            require('plug.installer').update(plugs, false)
        else
            for i = 2, #opt.fargs do
                local p = all_plugins[opt.fargs[i]]
                if p then
                    table.insert(plugs, p)
                end
            end
            require('plug.installer').update(plugs, true)
        end
        local c = require('plug.config')
        if c.ui == 'default' then
            require('plug.ui').open()
        end
    end
end

function M.complete(arglead, cmdline, cursorpos)
    local re = vim.regex('^Plug[!]\\?\\s*\\S*$')
    if re:match_str(string.sub(cmdline, 1, cursorpos)) then
        return vim.tbl_filter(function(t)
            return vim.startswith(t, arglead)
        end, { 'install', 'update' })
    end

    local plug_name = {}
    for k, _ in pairs(require('plug').get()) do
        if arglead and vim.startswith(k, arglead) then
            table.insert(plug_name, k)
        end
    end
    return plug_name
end

return M
