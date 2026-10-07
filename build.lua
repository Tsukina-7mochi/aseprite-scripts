local neblua = require("lib.neblua")

local preInitCode = [[
    local function snapshot(target)
        local addedKeys = {}
        setmetatable(target, {
            __newindex = function (t, k, v)
                table.insert(addedKeys, k)
                rawset(t, k, v)
            end,
        })

        local rollback = function()
            for _, k in ipairs(addedKeys) do
                rawset(target, k, nil)
            end
            setmetatable(target, nil)
        end

        return rollback
    end

    local rollbackLoaded = snapshot(package.loaded)
    local rollbackPreload = snapshot(package.preload)
    local rollbackSearchers = snapshot(package.searchers)
]]

local postRunCode = [[
    rollbackLoaded()
    rollbackPreload()
    rollbackSearchers()
]]

neblua.bundle({
    entry = "app.iconCursor",
    output = "./icon-and-cursor/Export as ico cur ani.lua",
    include = {
        "./app/iconCursor/init.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
    preInitCode = preInitCode,
    postRunCode = postRunCode,
})

neblua.bundle({
    entry = "app.psd",
    output = "./psd/Export as psd.lua",
    include = {
        "./app/psd/init.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
    preInitCode = preInitCode,
    postRunCode = postRunCode,
})
